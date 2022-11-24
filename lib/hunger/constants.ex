defmodule Hunger.Constants do
  def max_rounds(), do: 4

  def destination_marks(), do: 8

  def round_limit_seconds(), do: 2

  def moves(), do: [:up, :down, :left, :right]
end
