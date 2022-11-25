defmodule Hunger.Constants do
  def max_rounds(), do: 48

  def destination_marks(), do: 8

  def round_limit_seconds(), do: 10

  def moves(), do: [:up, :down, :left, :right]

  def random_seed(), do: [2, 2, 2, 2, 2, 2, 2, 2] ++ [4, 4, 4, 4, 4, 4] ++ [8, 8] ++ [16]
  def random_boom_seed(), do: [false, false, false, false] ++ [true]
end
