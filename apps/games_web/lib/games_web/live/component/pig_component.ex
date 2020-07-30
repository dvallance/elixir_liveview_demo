defmodule GamesWeb.PigComponent do
  use GamesWeb, :live_component

  alias Games.PigServer

  def render(assigns) do
    Phoenix.View.render(GamesWeb.GameView, "pig.html", assigns)
  end

  defp server_cast(socket, term) do
    PigServer.cast(socket.assigns.game_server, term)
    {:noreply, socket}
  end

  def handle_event("lock_in_points", _values, socket) do
    server_cast(socket, {:lock_in_points, socket.assigns.current_user})
  end

  def handle_event("search_user_opponent", values, socket) do
    %{"opponent" => %{"name" => name}} = values

    opponent_names =
      GamesWeb.Presence.retrieve_users_from_presence()
      |> Enum.filter(fn user ->
        String.match?(user.name, ~r/^#{name}.*/i)
      end)
      |> Enum.reject(fn user ->
        user.name == socket.assigns.current_user.name
      end)
      |> Enum.map(& &1.name)

    {:noreply, assign(socket, :opponent_names, opponent_names)}
  end

  def handle_event("select_user_opponent", values, socket) do
    %{"opponent" => %{"name" => name}} = values

    opponent =
      GamesWeb.Presence.retrieve_users_from_presence()
      |> Enum.find(fn user ->
        user.name == name
      end)

    server_cast(socket, {:assign_opponent, opponent})
  end

  def handle_event("select_computer_opponent", _values, socket) do
    server_cast(socket, {:assign_opponent, Games.ComputerOpponent.new()})
  end

  def handle_event("roll", _values, socket) do
    server_cast(socket, {:roll, socket.assigns.current_user})
  end

  def handle_event("reset", _values, socket) do
    server_cast(socket, {:reset, socket.assigns.current_user})
  end
end
