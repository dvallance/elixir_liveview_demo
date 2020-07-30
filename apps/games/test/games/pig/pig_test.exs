defmodule Games.PigTest do
  use ExUnit.Case, async: true
  alias Games.Pig

  test("tmp") do
    player = Games.User.new("Player")
    opponent = Games.User.new("Opponent")

    pig =
      Pig.new(player)
      |> Pig.assign_opponent(opponent)
      |> IO.inspect(label: "VALUE")
      |> Pig.rolled(opponent, 5)
      |> IO.inspect(label: "Rolled")
  end
end
