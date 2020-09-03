defmodule Games.Pig do
  @moduledoc """
  This module defines a structure `t:t/0` for representing a game of pig, and
  has functions that operate on that data.
  """

  alias __MODULE__
  alias Games.Pig.PlayerData

  @score_to_reach 50
  @msg_tie "There was a tie for first place please role again."

  defstruct [:msg, players: %{}, turn: :undecided, winner: nil]

  @typedoc """
  Data representing the state of a game of pig.
  """
  @type t :: %Pig{
          msg: [Games.Chat.Message.t()],
          players: %{optional(Games.PigServer.player()) => Games.Pig.PlayerData.t()},
          turn: :undecided | Games.PigServer.player(),
          winner: nil | Games.PigServer.player()
        }

  @spec new(Games.PigServer.player()) :: %Pig{}
  def new(%Games.User{} = user) do
    %Games.Pig{
      players: %{user => PlayerData.new()},
      msg: ["Game started."]
    }
  end

  @doc """
  Determines if a player is eligible to perform a dice roll.

  Only 1 player can roll at a time, and after a turn is decided only the player
  whos turn it is can roll.
  """
  def allowed_to_roll?(%Pig{turn: :undecided} = pig, _player) do
    !any_player_currently_rolling?(pig)
  end

  def allowed_to_roll?(%Pig{} = pig, player) do
    !any_player_currently_rolling?(pig) and
      players_turn?(pig, player)
  end

  @doc """
  Assigns an opponent to this game of pig.
  """
  @spec assign_opponent(t(), Games.PigServer.player()) :: t()
  def assign_opponent(pig, player) do
    if opponent_assigned?(pig) do
      pig
    else
      update_players(pig, fn players ->
        Map.put(players, player, PlayerData.new())
      end)
      |> update_msg("Opponent #{player.name} choosen.")
    end
  end

  @doc """
  Checks if a player currently has any points. 
  """
  @spec has_points?(t(), Games.PigServer.player()) :: boolean()
  def has_points?(%Pig{} = pig, player) do
    player_data = Map.get(pig.players, player)
    player_data.points > 0
  end

  @doc """
  Locks in points for a specific player and ends that players turn. 
  """
  @spec lock_in_points(t(), Games.PigServer.player()) :: t()
  def lock_in_points(%Pig{} = pig, player) do
    pig
    |> update_player_data(player, &PlayerData.lock_in_points/1)
    |> assign_next_turn()
  end

  @doc """
  Returns a `t:Games.Chat.Message.t/0` from the __msg__ field at a specific
  index.
  """
  @spec message_at(t(), non_neg_integer()) :: Games.Chat.Message.t()
  def message_at(%Pig{} = pig, position) when is_integer(position) do
    Enum.at(pig.msg, position)
  end

  @doc """
  Check to see if there is an assigned opponent, by simple determining if there
  are more then 1 players.
  """
  @spec opponent_assigned?(t()) :: boolean()
  def opponent_assigned?(%Pig{} = pig) do
    length(Map.keys(pig.players)) > 1
  end

  @doc """
  Is it currently the players turn?
  """
  @spec players_turn?(t(), Games.PigServer.player()) :: boolean()
  def players_turn?(%Pig{} = pig, player) do
    pig.turn == player
  end

  @doc """
  If the player is allowed to roll it assigns randomly a value from 1..6 to
  the player's data __rolling__ field.
  """
  @spec roll(t(), Games.PigServer.player()) :: {:ok, t()} | {:error, :not_allowed_to_roll}
  def roll(%Pig{} = pig, player) do
    if allowed_to_roll?(pig, player) do
      roll = Enum.random(1..6)

      {:ok, update_player_data(pig, player, &PlayerData.assign_rolling(&1, roll))}
    else
      {:error, :not_allowed_to_roll}
    end
  end

  @doc """
  Assigns the rolling value to rolled.
  """
  @spec rolled(t(), Games.PigServer.player()) :: t()
  def rolled(%Pig{} = pig, player) do
    pig = update_player_data(pig, player, &PlayerData.assign_rolled(&1))

    pig
    |> update_msg("#{player.name} rolled a #{Map.get(pig.players, player).rolled}")
    |> manage_rolled(player)
  end

  @doc """
  Finds the first {player, data} that is not the one passed in.
  """
  @spec other_player(t(), Games.PigServer.player()) ::
          nil | {Games.PigServer.player(), Games.Pig.PlayerData.t()}

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

  defp manage_rolled(%Pig{turn: :undecided} = pig, _player) do
    decide_first_turn(pig)
  end

  defp manage_rolled(%Pig{} = pig, player) do
    case Map.get(pig.players, player).rolled do
      1 ->
        turn_lost(pig, player)

      _rolled ->
        assign_points(pig, player)
        |> check_for_a_win(player)
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
