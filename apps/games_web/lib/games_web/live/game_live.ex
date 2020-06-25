defmodule GamesWeb.GameLive do
  use GamesWeb, :live_view
  import GamesWeb.LiveHelper

  @error_starting_game "There was an issue starting the game."
  @error_to_many_games "Sorry there is a limited number currently running games."

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
          assign(
            socket,
            :game_server,
            Games.GameSupervisor.game_server_state(game_type, current_user(socket))
          )
      end

    {:noreply, socket}
  end

  @doc """
  Games.Servers will broadcast there state changes so we just update the
  sockets ':game_server' with the new values.
  """
  def handle_info(%Games.Server{} = server, socket) do
    {:noreply, assign(socket, :game_server, server)}
  end

  defp recover_game_server(socket) do
    game_server = Games.GameSupervisor.game_server_for_user(current_user(socket))
    assign(socket, :game_server, game_server)
  end
end
