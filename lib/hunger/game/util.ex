defmodule Hunger.Game.Util do
  alias Hunger.Constants

  @random_seeds Constants.random_seed()
  @random_bomb_seeds Constants.random_bomb_seed()

  def gererate_alphabet(num) do
    alphabet = ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)

    alphabet
    |> Enum.take(num)
  end

  def random(min, max) do
    min - 1 + :rand.uniform(max - min + 1)
  end

  def random_item() do
    itm =
      @random_seeds
      |> Enum.random()

    "#{itm}"
  end

  def random_has_bomb?(), do: true
  # def random_has_bomb?() do
  #   @random_bomb_seeds
  #   |> Enum.random()
  # end

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

  def set_player_location(:top_left, _size) do
    {2, 2}
  end

  def set_player_location(:top_right, size) do
    {2, size - 1}
  end

  def set_player_location(:bottom_left, size) do
    {size - 1, 2}
  end

  def set_player_location(:bottom_right, size) do
    {size - 1, size - 1}
  end

  def random_player_location(:top_left, size) do
    mid4 = div(size, 4)
    col_start = 1
    col_end = mid4
    row_start = 1
    row_end = mid4

    x = random(row_start, row_end)
    y = random(col_start, col_end)

    {x, y}
  end

  def random_player_location(:top_right, size) do
    mid = div(size, 2)
    mid4 = div(size, 4)
    col_start = mid + mid4
    col_end = size - 1
    row_start = 1
    row_end = mid4

    x = random(row_start, row_end)
    y = random(col_start, col_end)

    {x, y}
  end

  def random_player_location(:bottom_left, size) do
    mid = div(size, 2)
    mid4 = div(size, 4)
    col_start = 1
    col_end = mid4
    row_start = mid + mid4
    row_end = size - 1

    x = random(row_start, row_end)
    y = random(col_start, col_end)

    {x, y}
  end

  def random_player_location(:bottom_right, size) do
    mid = div(size, 2)
    mid4 = div(size, 4)
    col_start = mid + mid4
    col_end = size - 1
    row_start = mid + mid4
    row_end = size - 1

    x = random(row_start, row_end)
    y = random(col_start, col_end)

    {x, y}
  end

  def random_location(rows, _cols) do
    seeds = make_random_set(1, rows)

    x = Enum.random(seeds)
    y = Enum.random(seeds)

    {x, y}
  end

  def make_random_set(min, max) do
    mid = div(max, 2)
    mid4 = div(max, 4)
    rs = Enum.reduce(min..mid4, [], fn idx, acc -> [idx | acc] end)
    Enum.reduce((mid + mid4)..max, rs, fn idx, acc -> [idx | acc] end)
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

  def determine_location({row, col}, {new_row, new_col}) when row == new_row and col == new_col,
    do: :none

  def determine_location({row, col}, _new = {new_row, new_col})
      when row == new_row and col > new_col,
      do: :left

  def determine_location({row, col}, _new = {new_row, new_col})
      when row == new_row and col < new_col,
      do: :right

  def determine_location({row, col}, _new = {new_row, new_col})
      when row < new_row and col == new_col,
      do: :down

  def determine_location({row, col}, _new = {new_row, new_col})
      when row > new_row and col == new_col,
      do: :up
end
