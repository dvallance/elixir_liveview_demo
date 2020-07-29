defmodule Games.Pig.PlayerData do
  alias __MODULE__

  defstruct [:rolled, rolling: nil, points: 0, score: 0]

  @spec new() :: %Games.Pig.PlayerData{}
  def new() do
    %Games.Pig.PlayerData{}
  end

  def assign_rolling(%PlayerData{} = player_data, roll) do
    %PlayerData{player_data | rolling: roll}
  end

  def assign_rolled(%PlayerData{} = player_data, rolled) do
    %PlayerData{player_data | rolled: rolled, rolling: nil}
  end

  def assign_points(%PlayerData{} = player_data) do
    %PlayerData{player_data | points: player_data.points + player_data.rolled}
  end

  def has_won?(%PlayerData{} = player_data, points_to_reach) when is_integer(points_to_reach) do
    player_data.points + player_data.score >= points_to_reach
  end

  def lock_in_points(%PlayerData{} = player_data) do
    %PlayerData{player_data | score: player_data.score + player_data.points, points: 0}
  end

  def reset_points(%PlayerData{} = player_data) do
    %PlayerData{player_data | points: 0}
  end
end
