defmodule GamesWeb.PigComponentHelper do
  import Phoenix.LiveView, only: [assign: 3, assign: 2]

  @moduledoc """
  The place to put frontend specific code that helps with
  the rendering of PigComponent and assignments.

  e.g. Things like class names.
  """

  def assignments(socket, current_user, game) do
    {player_data, map_with_opponent} = Map.pop(game.players, current_user)

    {opponent, opponent_data} = Enum.at(map_with_opponent, 0, {nil, nil})

    assign(socket,
      current_user: current_user,
      game: game,
      player: current_user,
      player_data: player_data,
      opponent: opponent,
      opponent_data: opponent_data,
      messages: game.msg,
      turn: game.turn,
      winner: game.winner
    )
    |> assign_turn_indicator_class()
  end

  # PRIVATE #

  defp assign_turn_indicator_class(socket) do
    cond do
      socket.assigns.turn == :undecided ->
        assign(socket, :turn_indicator_class, "pig__turn_indicator--undecided")

      socket.assigns.turn == socket.assigns.current_user ->
        assign(socket, :turn_indicator_class, "pig__turn_indicator--player")

      true ->
        assign(socket, :turn_indicator_class, "pig__turn_indicator--opponent")
    end
  end
end
