defmodule Games.Pig.PlayerData do
  @moduledoc """
  This module defines a structure `t:t/0` for storing each players data in 
  a game of `Games.Pig` as well as functions that operate on that data.
  """
  alias __MODULE__

  defstruct rolled: 0, rolling: 0, points: 0, score: 0

  @typedoc """
  Player data as part of a game of Pig.
  """
  @type t :: %PlayerData{
          rolled: non_neg_integer(),
          rolling: non_neg_integer(),
          points: non_neg_integer(),
          score: non_neg_integer()
        }

  @doc """
  Preferred way to create a new `t:t/0` struct.
  """
  @spec new() :: %Games.Pig.PlayerData{}
  def new() do
    %Games.Pig.PlayerData{}
  end

  @doc """
  Sets the __rolling__ field to a value that is to be recorded as a roll. The 
  rolling state lets us know a roll is in progress and allows the frontend to 
  take action (e.g. animate a dice roll).
  """
  @spec assign_rolling(PlayerData.t(), non_neg_integer()) :: PlayerData.t()
  def assign_rolling(%PlayerData{} = player_data, roll) do
    %PlayerData{player_data | rolling: roll}
  end

  @doc """
  Assigns the __rolling__ value to __rolled__. This brings us out of the rolling
  state and represents the last known rolled value.
  """
  @spec assign_rolled(PlayerData.t()) :: PlayerData.t()
  def assign_rolled(%PlayerData{} = player_data) do
    %PlayerData{player_data | rolled: player_data.rolling, rolling: 0}
  end

  @doc """
  Increments the __points__ field by the last __rolled__ value.
  """
  @spec assign_points(PlayerData.t()) :: PlayerData.t()
  def assign_points(%PlayerData{} = player_data) do
    %PlayerData{player_data | points: player_data.points + player_data.rolled}
  end

  @doc """
  Has the player won the game by reaching the desired score?
  """
  @spec has_won?(PlayerData.t(), non_neg_integer()) :: boolean()
  def has_won?(%PlayerData{} = player_data, points_to_reach) when is_integer(points_to_reach) do
    player_data.points + player_data.score >= points_to_reach
  end

  @doc """
  Adds the current __points__ to the __score__ and resets points to 0.
  """
  @spec lock_in_points(PlayerData.t()) :: PlayerData.t()
  def lock_in_points(%PlayerData{} = player_data) do
    %PlayerData{player_data | score: player_data.score + player_data.points, points: 0}
  end

  @doc """
  Resets __points__ to zero.
  """
  @spec reset_points(PlayerData.t()) :: PlayerData.t()
  def reset_points(%PlayerData{} = player_data) do
    %PlayerData{player_data | points: 0}
  end
end
