defmodule Games.Pig.PlayerData do
  alias __MODULE__

  defstruct [:rolled, rolling: nil]

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
end
