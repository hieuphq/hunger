defmodule Hunger.Game.Board do
  alias Hunger.Game.Util
  alias Hunger.Game.Player
  alias Hunger.Game.Cell
  alias Hunger.Constants

  defstruct [:rows, :cols, :map]

  def new(players, flag_pos, size \\ 12) do
    matrix = init_matrix(size, size)

    matrix =
      Enum.reduce(players, matrix, fn {player_id, %Player{location: loc}}, acc ->
        %{acc | loc => player_id}
      end)

    matrix = %{matrix | flag_pos => "X"}

    %__MODULE__{
      rows: size,
      cols: size,
      map: matrix
    }
  end

  defp init_matrix(rows, cols, val \\ nil) do
    arr =
      for r <- 1..rows,
          c <- 1..cols,
          do: {{r, c}, val}

    Enum.into(arr, %{}, fn v -> v end)
  end

  def print_matrix(%__MODULE__{rows: rows, cols: cols, map: map}) do
    Enum.map(1..rows, fn r ->
      Enum.map(1..cols, fn c ->
        Map.get(map, {r, c})
        |> case do
          nil ->
            " "

          # TRICKY: bomb
          "*" ->
            " "

          "X" ->
            " "

          v ->
            v
        end
      end)
    end)
  end

  def random_loc(b = %__MODULE__{rows: rows, cols: cols, map: map}) do
    loc = Util.random_location(rows, cols)

    case Map.get(map, loc) do
      nil -> loc
      _ -> random_loc(b)
    end
  end

  def set_item(b = %__MODULE__{map: map}, location, item) do
    updated_map =
      case Map.get(map, location, nil) do
        nil ->
          Map.put(map, location, item)

        _ ->
          map
      end

    %__MODULE__{b | map: updated_map}
  end

  def player_move(
        board = %__MODULE__{map: map},
        %Player{id: player_id, location: player_location},
        direction
      ) do
    case can_player_move?(board, player_location, direction) do
      {:ok, new_location} ->
        cell =
          Map.get(map, new_location)
          |> Cell.parse_cell()

        can_move? =
          cell
          |> Cell.can_move?()

        case can_move? do
          :ok ->
            new_map_state =
              map
              |> Map.put(new_location, player_id)
              |> Map.put(player_location, nil)

            final = %{
              board: %__MODULE__{board | map: new_map_state},
              player_location: new_location,
              cells: [cell]
            }

            {:ok, final}

          errs ->
            errs
        end

      errs ->
        errs
    end
  end

  defp can_player_move?(
         %__MODULE__{rows: rows, cols: cols},
         location,
         direction
       ) do
    {nextRow, nextCol} = Util.next_move(location, direction)

    if nextRow <= 0 || nextRow > rows || nextCol <= 0 || nextCol > cols do
      {:error, "invalid move"}
    else
      {:ok, {nextRow, nextCol}}
    end
  end

  def suggest_last_player_move(_g = %__MODULE__{}, []), do: []

  def suggest_last_player_move(g = %__MODULE__{}, player_location)
      when is_list(player_location) do
    Enum.map(player_location, fn {player_id, loc} ->
      next_direction =
        Constants.moves()
        |> Enum.map(fn move ->
          can_move? =
            case can_player_move?(g, loc, move) do
              {:ok, _} -> true
              _ -> false
            end

          {move, can_move?}
        end)
        |> Enum.filter(fn {_, can_move?} -> can_move? end)
        |> Enum.map(fn {direction, _} -> direction end)
        |> Enum.random()

      {player_id, next_direction}
    end)
  end
end
