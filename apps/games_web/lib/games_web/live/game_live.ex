defmodule GamesWeb.GameLive do
  use GamesWeb, :live_view
  import GamesWeb.LiveHelper

  @error_starting_game "There was an issue starting the game."
  @error_to_many_games "Sorry there is a limited number currently running games."

  @impl true
  def render(assigns) do
    Phoenix.View.render(GamesWeb.GameView, "game.html", assigns)
  end

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign_current_user(session)
      |> recover_game_server()

    {:ok, socket}
  end

  @impl true
  def handle_event("start_game", %{"game-type" => game_type}, socket) do
    socket =
      case Games.GameSupervisor.start(game_type, current_user(socket)) do
        :ignore ->
          socket

        {:error, :max_children} ->
          put_flash(socket, :info, @error_to_many_games)

        {:error, _} ->
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
  Games.Servers will broadcast there state changes so we just update the
  sockets ':game_server' with the new values.
  """
  def handle_info(%Games.Server{} = server, socket) do
    socket =
      socket
      |> assign(:game_server, server)

    {:noreply, socket}
  end

  defp recover_game_server(socket) do
    game_server = Games.GameSupervisor.game_server_for_user(current_user(socket))

    socket
    |> assign(:game_server, game_server)
    |> subscribe_recovered_server(game_server)
  end

  defp subscribe_recovered_server(socket, nil), do: socket

  defp subscribe_recovered_server(socket, game_server) do
    if connected?(socket), do: Games.Server.subscribe(game_server)
    socket
  end
end
