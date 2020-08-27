defmodule Games.Pig do
  alias __MODULE__
  alias Games.Pig.PlayerData

  @score_to_reach 50 
  @msg_tie "There was a tie for first place please role again."

  # players is a map with the user / opponent as key and there player_data as value.
  defstruct [:msg, players: %{}, turn: :undecided, winner: nil]

  @spec new(Games.PigServer.opponent()) :: %Pig{}
  def new(%Games.User{} = user) do
    %Games.Pig{
      players: %{user => PlayerData.new()},
      msg: ["Game started."]
    }
  end

  # Enforce 1 roll at a time and only on the players turn, unless
  # we haven't determined whos turn it is, then players can roll in 
  # any order but still 1 roll at a time.
  def allowed_to_roll?(%Pig{turn: :undecided} = pig, player) do
    !any_player_currently_rolling?(pig)
  end

  def allowed_to_roll?(%Pig{} = pig, player) do
    !any_player_currently_rolling?(pig) and
      players_turn?(pig, player)
  end

  def assign_opponent(pig, opponent) do
    if opponent_assigned?(pig) do
      pig
    else
      update_players(pig, fn players ->
        Map.put(players, opponent, PlayerData.new())
      end)
      |> update_msg("Opponent #{opponent.name} choosen.")
    end
  end

  def has_points?(%Pig{} = pig, player) do
    player_data = Map.get(pig.players, player)
    player_data.points > 0
  end

  def lock_in_points(%Pig{} = pig, player) do
    pig
    |> update_player_data(player, &PlayerData.lock_in_points/1)
    |> assign_next_turn()
  end

  def message_at(%Pig{} = pig, position) when is_integer(position) do
    Enum.at(pig.msg, position)
  end

  def opponent_assigned?(%Pig{} = pig) do
    length(Map.keys(pig.players)) > 1
  end

  def players_turn?(%Pig{} = pig, player) do
    pig.turn == player
  end

  @doc """
  Assigns a random number from 1-6 to the players data :rolling field.
  """
  def roll(%Pig{} = pig, player) do
    if allowed_to_roll?(pig, player) do
      roll = Enum.random(1..6)

      {:ok, update_player_data(pig, player, &PlayerData.assign_rolling(&1, roll))}
    else
      {:error, :not_allowed_to_roll}
    end
  end

  def rolled(%Pig{} = pig, player) do
    pig = update_player_data(pig, player, &PlayerData.assign_rolled(&1))

    pig
    |> update_msg("#{player.name} rolled a #{Map.get(pig.players, player).rolled}")
    |> manage_rolled(player)
  end

  # Gets the first {player, data} thats not the one passed in.
  def other_player(%Pig{} = pig, player) do
    Enum.find(pig.players, fn {player_x, _player_data} ->
      player_x != player
    end)
  end

  ### Private ###

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
  end

  defp any_player_currently_rolling?(%Pig{} = pig) do
    Enum.any?(pig.players, fn {_player, player_data} ->
      player_data.rolling != 0
    end)
  end

  defp complete_roll(pig, player) do
    roll = Enum.random(1..6)

    update_player_data(pig, player, fn player_data ->
      PlayerData.assign_rolling(player_data, roll)
    end)
  end

  defp decide_first_turn(%Pig{} = pig) do
    if everyone_has_rolled?(pig) do
      case highest_roller(pig) do
        :tie ->
          update_msg(pig, @msg_tie)
          |> clear_out_rolled()

        player ->
          pig
          |> update_msg("#{player.name} gets to play first.")
          |> assign_turn(player)
      end
    else
      pig
    end
  end

  defp everyone_has_rolled?(%Pig{} = pig) do
    Enum.all?(Map.values(pig.players), fn player_data ->
      player_data.rolled > 0
    end)
  end

  defp highest_roller(pig) do
    Enum.reduce(pig.players, %{player: nil, rolled: 0, tie: false}, fn {player, player_data},
                                                                       acc ->
      cond do
        player_data.rolled > acc.rolled ->
          %{player: player, rolled: player_data.rolled, tie: false}

        player_data.rolled == acc.rolled ->
          Map.put(acc, :tie, true)

        player_data.rolled < acc.rolled ->
          acc
      end
    end)
    |> case do
      %{tie: true} -> :tie
      %{player: player} -> player
    end
  end

  # If the turn is undecided we are rolling to determine who goes first.
  defp manage_roll(%Pig{turn: :undecided} = pig, player) do
    # If the player has already rolled we don't allow another roll, unless
    # all players have rolled and we determine its a tie and reset there rolls.
    if Map.get(pig.players, player).rolled == 0 do
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

        # |> points_acquired(player)
    end
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

  def clear_out_rolled(%Pig{} = pig) do
    update_players(pig, fn players ->
      Enum.reduce(players, %{}, fn {player, player_data}, acc ->
        Map.put(acc, player, PlayerData.assign_rolled(player_data))
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
