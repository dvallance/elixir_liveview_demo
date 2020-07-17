defmodule Games.Pig do
  alias __MODULE__
  alias Games.Pig.PlayerData

  # players is a map with the user / opponent as key and there player_data as value.
  defstruct players: %{}, turn: :undecided

  @spec new(Games.PigServer.opponent()) :: %PlayerData{}
  def new(%Games.User{} = user) do
    %Games.Pig{
      players: %{user => PlayerData.new()}
    }
  end

  @doc """
  Assigns a random number from 1-6 to the players data :rolling field.
  """
  def roll(%Pig{} = pig, player) do
    roll = Enum.random(1..6)
    
    update_player_data(pig, player, fn player_data ->
      player_data
      |> PlayerData.assign_rolling(roll)
    end)
  end

  def rolled(%Pig{} = pig, player_name, rolled) do
    player = find_player(pig, player_name)

    update_player_data(pig, player, fn player_data -> 
      PlayerData.assign_rolled(player_data, rolled)
    end)
  end

  def find_player(%Pig{} = pig, player_name) do
    Map.keys(pig.players)
    |> Enum.find(&(&1.name == player_name))
  end

  defp add_opponent(%Pig{} = pig, opponent) do
    if opponent_assigned?(pig) do
      pig
    else
      update_players(pig, fn players ->
        Map.put(players, opponent, PlayerData.new())
      end)
    end
  end

  defp update_players(%Pig{} = pig, function) do
    %Pig{pig | players: function.(pig.players)}
  end

  defp update_player_data(%Pig{} = pig, player, function) do
    %Pig{
      pig
      | players: Map.update!(pig.players, player, function)
    }
  end

  @spec players_first_turn_roll(%Pig{}, Games.PigServer.opponent()) :: integer | nil
  def players_first_turn_roll(%Pig{} = pig, opponent) do
    Map.get(pig.first_turn_rolls, opponent)
  end

  def turn?(%Pig{} = pig, %Games.User{} = user) do
    pig.turn == user.name
  end

  def opponent_assigned?(%Pig{} = pig) do
    length(Map.keys(pig.players)) > 1
  end

  def assign_opponent(%Pig{} = pig, %Games.User{} = opponent) do
    pig
    |> add_opponent(opponent)
  end

  def assign_opponent(%Pig{} = pig, %Games.ComputerOpponent{} = opponent) do
    pig
    |> add_opponent(opponent)
    |> roll(opponent)
  end

  def assign_roll(%Pig{} = pig, player, roll) do
    update_player_data(pig, player, &PlayerData.assign_roll(&1, roll))
  end

  def can_roll?(%Pig{} = pig, %Games.ComputerOpponent{}), do: false
  def can_roll?(%Pig{turn: :undecided} = pig, player), do: true
end
