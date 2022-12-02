defmodule Hunger.Constants do
  def max_rounds(), do: 48

  def destination_marks(), do: 4

  def round_limit_seconds(), do: 10

  def actually_round_seconds(), do: round_limit_seconds()

  def moves(), do: [:up, :down, :left, :right]

  def random_seed(),
    do: [2, 2, 2, 2, 2, 2, 2, 2, 2, 2] ++ [4, 4, 4, 4, 4, 4, 4] ++ [6, 6] ++ [8]

  def random_bomb_seed(), do: [false, false, false] ++ [true]
end
