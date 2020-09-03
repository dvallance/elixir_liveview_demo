defmodule Games.ComputerOpponent do
  @moduledoc """
  A struct to represent a computer opponent. 
  """

  # opptionally add things like skill level.
  defstruct [:name]

  # maybe add a name generator but for this demo i'll hard code a name.
  @spec new() :: %Games.ComputerOpponent{}
  def new(), do: %Games.ComputerOpponent{name: "Robo (computer)"}

  def is_computer?(%Games.ComputerOpponent{}), do: true
  def is_computer?(_), do: false
end
