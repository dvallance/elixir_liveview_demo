defmodule Games.Pig do
  alias __MODULE__

  defstruct players: [], scores: %{}, turn: :undecided, turn_total: 0, rolls_for_first_turn: %{} 

  def new(%Games.User{} = user) do
    %Games.Pig{
      players: [user]
    }
  end

  @doc """
  Determine the current status of the game.
  """

  # def stage(%Pig{players: [_]}), :

  # status
  # :assign_opponent -> :waiting_for_opponent

  # :roll_for_order

  # :started

  # :ended

  @doc """
  Assigns to the map in `rolls_for_first_turn` the user as the key and the
  roll (1-6) as the value.
  """
  def roll_for_first_turn(%Pig{} = pig, %Games.User{} = user) do
    %Pig{pig | rolls_for_first_turn: Map.put(pig.rolls_for_first_turn, user, 5)}
  end

  @spec players_roll_for_first_turn(%Pig{}, Games.PigServer.opponent) :: integer | nil
  def players_roll_for_first_turn(%Pig{} = pig, opponent) do
    Map.get(pig.rolls_for_first_turn, opponent)
  end

  def turn?(%Pig{} = pig, %Games.User{} = user) do
    pig.turn == user.name
  end

  def opponent_assigned?(%Pig{} = pig) do
    length(pig.players) > 1
  end

  def assign_opponent(%Pig{} = pig, opponent) do
    %Pig{pig | players: [opponent | pig.players]}
  end
end
