defmodule GamesWeb.PigComponent do
  @moduledoc """
  A LiveView Component specifically representing a game of Pig.
  """

  use GamesWeb, :live_component
  alias GamesWeb.PigComponentHelper

  alias Games.PigServer

  @opponent_not_found "The opponent you mentioned wasn't found. Are they online?"

  @impl true
  @doc """
  The component takes the socket from `GameLive` and specifically performs 
  assignments for its type. This gives change details from the specific assigns
  and lets us reference the assigns is the views.
  """
  def update(assigns, socket) do
    socket =
      PigComponentHelper.assignments(socket, assigns.current_user, assigns.game_server.game)

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(GamesWeb.GameView, "pig.html", assigns)
  end

  @impl true
  @doc """
  Handler for locking in points.
  """
  def handle_event("lock_in_points", _values, socket) do
    server_cast(socket, {:lock_in_points, socket.assigns.current_user})
  end

  @doc """
  Handler for finding/filtering opponents from users currently tracked by 
  Presence.

  Assigns `opponent_names` on the socket for use in the view. 
  """
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

  @doc """
  Handler for selecting an opponent. 
  """
  def handle_event("select_user_opponent", values, socket) do
    %{"opponent" => %{"name" => name}} = values

    opponent =
      GamesWeb.Presence.retrieve_users_from_presence()
      |> Enum.find(fn user ->
        user.name == name
      end)

    if opponent do
      server_cast(socket, {:assign_opponent, socket.assigns.current_user, opponent})
    else
      {:noreply, put_flash(socket, :error, @opponent_not_found)}
    end
  end

  @doc """
  Handler for selecting a computer opponent to play against.
  """
  def handle_event("select_computer_opponent", _values, socket) do
    server_cast(
      socket,
      {:assign_opponent, socket.assigns.current_user, Games.ComputerOpponent.new()}
    )
  end

  @doc """
  Handler for performing a roll.
  """
  def handle_event("roll", _values, socket) do
    server_cast(socket, {:roll, socket.assigns.current_user})
  end

  @doc """
  Handler for exiting a game of pig. This will stop the game server if its 
  currently running.
  """
  def handle_event("exit", _values, socket) do
    game = socket.assigns.game_server

    # Shutdown the Pig Server
    if game, do: Games.GameSupervisor.stop(GenServer.whereis(PigServer.via(game)))

    # Tell parent GameLive to exit.
    send(self(), {:exit})

    {:noreply, socket}
  end

  # The majority of event handling will be delagating the work to the `PigServer`
  # and simply returning a no reply.
  defp server_cast(socket, term) do
    PigServer.cast(socket.assigns.game_server, term)
    {:noreply, socket}
  end
end
