defmodule Games.Pig do
  alias __MODULE__
  alias Games.Pig.PlayerData

  # players is a map with the user / opponent as key and there player_data as value.
  defstruct [:msg, players: %{}, turn: :undecided]

  @spec new(Games.PigServer.opponent()) :: %PlayerData{}
  def new(%Games.User{} = user) do
    %Games.Pig{
      players: %{user => PlayerData.new()},
      msg: ["Game started."]
    }
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

  # def can_roll?(%Pig{} = pig, %Games.ComputerOpponent{}), do: false
  # def can_roll?(%Pig{turn: :undecided} = pig, player), do: true

  def opponent_assigned?(%Pig{} = pig) do
    length(Map.keys(pig.players)) > 1
  end

  def turn?(%Pig{} = pig, %Games.User{} = user) do
    pig.turn == user.name
  end

  @doc """
  Assigns a random number from 1-6 to the players data :rolling field.
  """
  def roll(%Pig{} = pig, player) do
    if any_player_currently_rolling?(pig) do
      # enforce 1 roll at a time across the board
      # no change
      pig
    else
      manage_roll(pig, player)
    end
  end

  def rolled(%Pig{} = pig, player_name, rolled) do
    player = find_player(pig, player_name)

    update_player_data(pig, player, &PlayerData.assign_rolled(&1, rolled))
    |> update_msg("#{player_name} rolled a #{rolled}.")
    |> manage_rolled(player)
  end

  # @spec players_first_turn_roll(%Pig{}, Games.PigServer.opponent()) :: integer | nil
  # def players_first_turn_roll(%Pig{} = pig, opponent) do
  #  Map.get(pig.first_turn_rolls, opponent)
  # end

  ### Private ###

  defp any_player_currently_rolling?(%Pig{} = pig) do
    Enum.any?(pig.players, fn {_player, player_data} ->
      player_data.rolling != nil
    end)
  end

  defp add_opponent(%Pig{} = pig, opponent) do
    if opponent_assigned?(pig) do
      pig
    else
      update_players(pig, fn players ->
        Map.put(players, opponent, PlayerData.new())
      end)
      |> update_msg("Opponent #{opponent.name} choosen.")
    end
  end

  defp complete_roll(pig, player) do
    roll = Enum.random(1..6)

    update_player_data(pig, player, fn player_data ->
      PlayerData.assign_rolling(player_data, roll)
    end)
  end

  defp decide_first_turn(%Pig{} = pig) do
    [player_and_data | players] = Enum.map(pig.players, &(&1))

    highest_roller(players, player_and_data)
    |> case do
      :waiting_on_roll ->
        pig
        |> update_msg("Waiting on die role to determine who starts first.")

      :tie ->
        pig
        |> update_msg("There was a tie for first place please role again.")

      {player, _player_data} ->
        %Pig{pig | turn: player}
        |> update_msg("#{player.name} gets to play first.")
    end
  end

  defp highest_roller([player_and_data | []], player_and_data_highest_roll) do
    rolled = elem(player_and_data, 1).rolled
    highest_rolled = elem(player_and_data_highest_roll, 1).rolled

    cond do
      rolled == nil -> :waiting_on_roll
      rolled > highest_rolled -> player_and_data
      rolled == highest_rolled -> :tie
      rolled < highest_rolled -> player_and_data_highest_roll
    end
  end

  defp highest_roller([player_and_data | players], player_and_data_highest_roll) do
    rolled = elem(player_and_data, 1).rolled
    highest_rolled = elem(player_and_data_highest_roll, 1).rolled

    cond do
      rolled == nil -> :waiting_on_roll
      rolled >= highest_rolled -> highest_roller(players, player_and_data)
      true -> highest_roller(players, player_and_data_highest_roll)
    end
  end

  defp find_player(%Pig{} = pig, player_name) do
    Map.keys(pig.players)
    |> Enum.find(&(&1.name == player_name))
  end

  # If the turn is undecided we are rolling to determine who goes first.
  defp manage_roll(%Pig{turn: :undecided} = pig, player) do
    # If the player has already rolled we don't allow another roll, unless
    # all players have rolled and we determine its a tie and reset there rolls.
    if Map.get(pig.players, player).rolled == nil do
      complete_roll(pig, player)
    else
      # no change
      pig
    end
  end

  # If its not the players turn don't allow the roll.
  defp manage_roll(%Pig{} = pig, player) do
    if pig.turn == player do
      complete_roll(pig, player)
    else
      # no change
      pig
    end
  end

  defp manage_rolled(%Pig{turn: :undecided} = pig, player) do
    decide_first_turn(pig)
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

  defp update_msg(%Pig{} = pig, msg) do
    %Pig{ pig | msg: [msg | pig.msg]}
  end
end
