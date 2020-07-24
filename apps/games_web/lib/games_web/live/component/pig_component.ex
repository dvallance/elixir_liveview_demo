defmodule GamesWeb.PigComponent do
  use GamesWeb, :live_component

  def render(assigns) do
    Phoenix.View.render(GamesWeb.GameView, "pig.html", assigns)
  end

  def handle_event("select-computer-opponent", _values, socket) do
    Games.PigServer.assign_opponent(socket.assigns.game_server, Games.ComputerOpponent.new())

    {:noreply, socket}
  end

  def handle_event("roll", _values, socket) do
    Games.PigServer.roll(socket.assigns.game_server, socket.assigns.current_user)

    {:noreply, socket}
  end

  def handle_event("rolled", %{"player_name" => player_name, "rolled" => rolled}, socket) do
    Games.PigServer.rolled(socket.assigns.game_server, player_name, rolled)

    {:noreply, socket}
  end

  def handle_event("reset", _values, socket) do
    Games.PigServer.reset(socket.assigns.game_server)

    {:noreply, socket}
  end
end
