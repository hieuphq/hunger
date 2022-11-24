defmodule Hunger.Game.Util do
  def gererate_alphabet(num) do
    alphabet = ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)

    alphabet
    |> Enum.take(num)
  end

  def random(min, max) do
    min - 1 + :rand.uniform(max - min + 1)
  end

  def random_value_with_percent(config) when is_map(config) do
    Enum.map(config, fn {k, count} ->
      List.duplicate(k, count)
    end)
    |> Enum.flat_map(fn v -> v end)
    |> Enum.random()
  end

  def random_middle(size) do
    mid = div(size, 4)
    row_start = mid
    row_end = size - mid
    col_start = mid
    col_end = size - mid

    x = random(row_start, row_end)
    y = random(col_start, col_end)

    {x, y}
  end

  def random_location(rows, cols) do
    x = random(1, rows)
    y = random(1, cols)

    {x, y}
  end

  def next_move({row, col}, :up), do: {row - 1, col}
  def next_move({row, col}, :down), do: {row + 1, col}
  def next_move({row, col}, :left), do: {row, col - 1}
  def next_move({row, col}, :right), do: {row, col + 1}
  def next_move({row, col}, _), do: {row, col}

  def parse_action("up"), do: :up
  def parse_action("down"), do: :down
  def parse_action("left"), do: :left
  def parse_action("right"), do: :right
  def parse_action(_), do: :up
end
