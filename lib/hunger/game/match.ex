defmodule Hunger.Game.Match do
  alias Hunger.Game.Round
  alias Hunger.Game.Board
  alias Hunger.Game.Player
  alias Hunger.Game.Item
  alias Hunger.Game.Action
  alias Hunger.Game.Cell
  alias Hunger.Game.Util
  alias Hunger.Constants

  defstruct [:id, :board, :rounds, :players, :status, :items, :booms]

  @new :new
  @playing :playing
  @done :done

  @max_round Constants.max_rounds()

  def new(name, size \\ 12) do
    players = %{
      "a" => Player.new("a", 1, 1),
      "b" => Player.new("b", 1, size),
      "c" => Player.new("c", size, 1),
      "d" => Player.new("d", size, size)
    }

    %__MODULE__{
      id: name,
      board: Board.new(players, size),
      players: players,
      status: @new,
      rounds: [],
      booms: [],
      items: []
    }
  end

  def join(m = %__MODULE__{players: players}) do
    choosing_player =
      players
      |> Enum.filter(fn
        {_player_id, %Player{status: "new"}} -> true
        _ -> false
      end)
      |> Enum.at(0, nil)

    if choosing_player == nil do
      {:error, "match is full"}
    else
      {player_id, detail} = choosing_player
      updated_player = Player.joined(detail)
      new_players = Map.put(players, player_id, updated_player)
      {:ok, updated_player, %__MODULE__{m | players: new_players}}
    end
  end

  def start_match(m = %__MODULE__{status: @new}) do
    %__MODULE__{m | status: @playing}
  end

  def start_match(m = %__MODULE__{}), do: m

  def run(m = %__MODULE__{players: players, rounds: []}) do
    r = Round.new(players)
    %{m | rounds: [r]}
  end

  def run(
        match = %__MODULE__{
          players: players,
          board: board = %Board{},
          rounds: [r = %Round{} | remains]
        }
      ) do
    with {:end_match, false} <- {:end_match, should_end_match?(match)},
         {:last_second, true} <- {:last_second, Round.is_last_second(r)} do
      player_id_with_location =
        Round.last_players(r)
        |> Enum.map(fn playerid ->
          %Player{id: id, location: loc} = Map.get(players, playerid)
          {id, loc}
        end)

      round_updated =
        Board.suggest_last_player_move(board, player_id_with_location)
        |> Enum.reduce(r, fn {player_id, direction}, acc ->
          Round.submit(acc, player_id, {:move, direction})
        end)

      latest_rounds = [round_updated | remains]

      %__MODULE__{match | rounds: latest_rounds}
      |> update_board(Round.get_player_actions(round_updated))
      |> random_item()
      |> random_boom()
      |> renew_match()
    else
      {:end_match, true} ->
        %__MODULE__{match | status: @done}

      {:last_second, false} ->
        match
    end
  end

  defp should_end_match?(%__MODULE__{rounds: rounds}) do
    length(rounds) >= @max_round
  end

  defp update_board(%__MODULE__{} = match, steps) do
    Enum.reduce(steps, match, fn {player_id, %Action{action: {:move, direction}}},
                                 acc = %__MODULE__{players: players, board: board} ->
      player = %Player{points: player_points} = Map.get(players, player_id)

      case Board.player_move(board, player, direction) do
        {:error, err} ->
          IO.inspect(err)
          will_finish_game(acc, false)

        {:ok, %{board: updated_board, cells: cells, player_location: new_player_location}} ->
          rewards =
            Enum.reduce(cells, 0, fn c, acc ->
              acc + Cell.cell_reward(c)
            end)

          can_end_game? =
            cells
            |> Enum.map(fn c -> Cell.is_destination?(c) end)
            |> Enum.any?()

          new_points = player_points + rewards
          updated_player = %Player{player | location: new_player_location, points: new_points}
          updated_players = Map.put(players, player_id, updated_player)

          acc = will_finish_game(acc, can_end_game?)

          %__MODULE__{acc | board: updated_board, players: updated_players}
      end
    end)
  end

  def will_finish_game(m = %__MODULE__{status: @playing}, true) do
    %__MODULE__{m | status: @done}
  end

  def will_finish_game(m = %__MODULE__{}, _), do: m

  def commit_step(%__MODULE__{rounds: []}, _player_token, _direction) do
    {:error, "empty"}
  end

  def commit_step(m = %__MODULE__{rounds: [r = %Round{} | remains]}, player_token, direction) do
    case Round.is_last_second(r) do
      false ->
        get_user_by_token(m, player_token)
        |> case do
          nil ->
            {:error, "user token invalid"}

          {player_id, _} ->
            updated_round =
              %Round{next_states: next_states} = Round.submit(r, player_id, {:move, direction})

            latest_rounds = [updated_round | remains]

            action = Map.get(next_states, player_id)
            {:ok, action, %__MODULE__{m | rounds: latest_rounds}}
        end

      true ->
        {:error, "round is expired"}
    end
  end

  defp get_user_by_token(%__MODULE__{players: players}, player_token) do
    Enum.filter(players, fn {_player_id, %Player{token: token}} ->
      token == player_token
    end)
    |> List.first()
  end

  def renew_match(m = %__MODULE__{rounds: rounds, players: players, status: @playing}) do
    %__MODULE__{m | rounds: [Round.new(players) | rounds]}
  end

  def renew_match(m = %__MODULE__{}), do: m

  def random_item(m = %__MODULE__{board: board, items: items, status: @playing}) do
    loc = Board.random_loc(board)
    item = Item.random_item(1, 4)

    updated_board = Board.set_item(board, loc, item)
    new_items = [item | items]

    %__MODULE__{m | items: new_items, board: updated_board}
  end

  def random_item(m = %__MODULE__{}), do: m

  def random_boom(m = %__MODULE__{board: board, items: items, status: @playing}) do
    has_boom? = Util.random_value_with_percent(%{true: 1, false: 4})

    case has_boom? do
      true ->
        loc = Board.random_loc(board)
        item = "*"

        updated_board = Board.set_item(board, loc, item)
        new_items = [item | items]

        %__MODULE__{m | items: new_items, board: updated_board}

      false ->
        m
    end
  end

  def random_boom(m = %__MODULE__{}), do: m

  def print_map(%__MODULE__{board: board}) do
    Board.print_matrix(board)
    |> IO.inspect()
  end
end
