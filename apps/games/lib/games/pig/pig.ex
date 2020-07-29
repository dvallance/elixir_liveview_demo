defmodule Games.Pig do
  alias __MODULE__
  alias Games.ComputerOpponent
  alias Games.Pig.PlayerData

  @score_to_reach 100

  # players is a map with the user / opponent as key and there player_data as value.
  defstruct [:msg, players: %{}, turn: :undecided, winner: nil]

  @spec new(Games.PigServer.opponent()) :: %Pig{}
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

  def assign_opponent(%Pig{} = pig, %ComputerOpponent{} = opponent) do
    pig
    |> add_opponent(opponent)
    |> roll(opponent)
  end

  def lock_in_points(%Pig{} = pig, player) do
    pig
    |> update_player_data(player, &PlayerData.lock_in_points/1)
    |> assign_next_turn()
  end

  # def can_roll?(%Pig{} = pig, %Games.ComputerOpponent{}), do: false
  # def can_roll?(%Pig{turn: :undecided} = pig, player), do: true

  def opponent_assigned?(%Pig{} = pig) do
    length(Map.keys(pig.players)) > 1
  end

  def turn?(%Pig{} = pig, %Games.User{} = user) do
    pig.turn == user
  end

  @doc """
  Assigns a random number from 1-6 to the players data :rolling field.
  """
  def roll(%Pig{} = pig, player) do
    if allowed_to_roll?(pig, player) do
      manage_roll(pig, player)
    else
      # no change
      pig
    end
  end

  def rolled(%Pig{} = pig, player_name, rolled) do
    player = find_player(pig, player_name)

    update_player_data(pig, player, &PlayerData.assign_rolled(&1, rolled))
    |> update_msg("#{player_name} rolled a #{rolled}.")
    |> manage_rolled(player)
  end

  ### Private ###

  # Enforce 1 roll at a time and only on the players turn, unless
  # we haven't determined whos turn it is, then players can roll in 
  # any order but still 1 roll at a time.
  defp allowed_to_roll?(%Pig{turn: :undecided} = pig, player) do
    !any_player_currently_rolling?(pig)
  end

  defp allowed_to_roll?(%Pig{} = pig, player) do
    !any_player_currently_rolling?(pig) and
      players_turn(pig, player)
  end

  # Since this is just a demo I'll assume only two players and swap them.
  # If I wanted to support multiple players (most code written to) I 
  # would store a turn_list and rotate through it.
  defp assign_next_turn(%Pig{} = pig) do
    {next_player, _player_data} =
      Enum.find(pig.players, fn {player, _player_data} ->
        pig.turn != player
      end)

    assign_turn(pig, next_player)
  end

  defp assign_points(%Pig{} = pig, player) do
    update_player_data(pig, player, &PlayerData.assign_points/1)
  end

  defp assign_turn(%Pig{} = pig, player) do
    %Pig{pig | turn: player}
    |> update_player_data(player, &PlayerData.reset_points/1)
    |> turn_assigned(player)
  end

  defp turn_assigned(%Pig{} = pig, %ComputerOpponent{} = opponent) do
    roll(pig, opponent)
  end

  defp turn_assigned(%Pig{} = pig, player), do: pig

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
    [player_and_data | players] = Enum.map(pig.players, & &1)

    highest_roller(players, player_and_data)
    |> case do
      :waiting_on_roll ->
        pig
        |> update_msg("Waiting on die role to determine who starts first.")

      :tie ->
        pig
        |> update_msg("There was a tie for first place please role again.")
        |> tie_occured()

      {player, _player_data} ->
        pig
        |> update_msg("#{player.name} gets to play first.")
        |> assign_turn(player)
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

  defp manage_rolled(%Pig{} = pig, player) do
    case Map.get(pig.players, player).rolled do
      1 ->
        turn_lost(pig, player)

      rolled ->
        assign_points(pig, player)
        |> check_for_a_win(player)
        |> points_acquired(player)
    end
  end

  defp players_turn(%Pig{} = pig, player) do
    pig.turn == player
  end

  defp turn_lost(%Pig{} = pig, player) do
    update_player_data(pig, player, &PlayerData.reset_points/1)
    |> assign_next_turn()
  end

  def check_for_a_win(%Pig{} = pig, player) do
    player_data = Map.get(pig.players, player)

    if PlayerData.has_won?(player_data, @score_to_reach) do
      %Pig{pig | turn: :finished, winner: player}
      |> update_msg("#{player.name} has won the game!")
    else
      pig
    end
  end

  def points_acquired(%Pig{turn: :finished} = pig, player), do: pig

  def points_acquired(%Pig{} = pig, %ComputerOpponent{} = opponent) do
    # Simple AI for the computer.
    # If we roll a 1 right now, lock in points otherwise keep rolling! 
    Enum.random(1..6)
    |> case do
      1 -> lock_in_points(pig, opponent)
      _ -> roll(pig, opponent)
    end
  end

  def points_acquired(%Pig{} = pig, player), do: pig

  def tie_occured(%Pig{} = pig) do
    pig = clear_out_rolled(pig)

    computer_opponent =
      Enum.find_value(pig.players, fn {player, player_data} ->
        if match?(%ComputerOpponent{}, player), do: player
      end)

    if computer_opponent do
      roll(pig, computer_opponent)
    else
      pig
    end
  end

  def clear_out_rolled(%Pig{} = pig) do
    update_players(pig, fn players ->
      Enum.reduce(players, %{}, fn {player, player_data}, acc ->
        Map.put(acc, player, PlayerData.assign_rolled(player_data, nil))
      end)
    end)
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
    %Pig{pig | msg: [msg | pig.msg]}
  end
end
