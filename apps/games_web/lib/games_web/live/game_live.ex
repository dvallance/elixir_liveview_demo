defmodule GamesWeb.GameLive do
  @moduledoc """
  LiveView for games.
  """

  use GamesWeb, :live_view

  import GamesWeb.LiveHelper

  @error_starting_game "There was an issue starting the game."
  @error_to_many_games "Sorry too many games already running."

  @impl true
  def render(assigns) do
    Phoenix.View.render(GamesWeb.GameView, "game.html", assigns)
  end

  @impl true
  @doc """
  Assigns the current_user from the session and recovers any in progress game.
  """
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign_current_user(session)
      |> recover_game_server()

    {:ok, socket}
  end

  @impl true
  @doc """
    Handler for the "start_game" event. Currently there is no cleanup of
    abondoned games, so for the demo I'll add a max games to prevent to many
    from piling up.
  """
  def handle_event("start_game", %{"game-type" => game_type}, socket) do
    socket =
      case Games.GameSupervisor.start(game_type, current_user(socket)) do
        :ignore ->
          socket

        {:error, :max_children} ->
          put_flash(socket, :error, @error_to_many_games)

        {:error, _error} ->
          put_flash(socket, :error, @error_starting_game)

        {:ok, _pid} ->
          game_server = Games.GameSupervisor.game_server_state(game_type, current_user(socket))
          # Here we'll subscribe to specific games PubSub channel.
          # We unsubscribe first as a measure to prevent duplicate subscriptions.
          Games.Server.unsubscribe(game_server)
          Games.Server.subscribe(game_server)
          assign(socket, :game_server, game_server)
      end

    {:noreply, socket}
  end

  @impl true
  @doc """
  Exiting the game sets the sockets `game_server` to nil.
  """
  def handle_info({:exit}, socket) do
    {:noreply, assign(socket, game_server: nil)}
  end

  @impl true
  @doc """
  PubSub handler.

  Games.Servers will broadcast there state changes so we just update the
  sockets ':game_server' with the new values.
  """
  def handle_info(%Games.Server{} = server, socket) do
    socket = assign(socket, :game_server, server)

    {:noreply, socket}
  end

  # Assigns a `game_server` to the socket, which can be nil or an actual game.
  defp recover_game_server(socket) do
    game_server = Games.GameSupervisor.game_server_for_user(current_user(socket))

    socket
    |> assign(:game_server, game_server)
    |> subscribe_recovered_server(game_server)
  end

  # Subscribes to a game server via PubSub.
  defp subscribe_recovered_server(socket, nil), do: socket

  defp subscribe_recovered_server(socket, game_server) do
    if connected?(socket), do: Games.Server.subscribe(game_server)
    socket
  end
end
