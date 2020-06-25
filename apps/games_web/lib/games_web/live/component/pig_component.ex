defmodule GamesWeb.PigComponent do
  use GamesWeb, :live_component

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    
    if connected?(socket) do
      Games.Server.subscribe(socket.assigns.game_server)
    end

    {:ok, socket}
  end

  def render(assigns) do
    Phoenix.View.render(GamesWeb.GameView, "pig.html", assigns)
  end

  def handle_event("select-computer-opponent", values, socket) do
    # we might want different skill level computer opponents
    # for now we create a user of type computer.5

    Games.PigServer.assign_opponent(socket.assigns.game_server, Games.ComputerOpponent.new())

    {:noreply, socket}
  end

  def handle_event("roll_for_first_turn", values, socket) do
    Games.PigServer.roll_for_first_turn(socket.assigns.game_server, socket.assigns.current_user)

    {:noreply, socket}
  end
end
