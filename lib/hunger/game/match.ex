defmodule Hunger.Game.Match do
  alias Hunger.Game.Round
  alias Hunger.Game.Board
  alias Hunger.Game.Player
  alias Hunger.Game.Item
  alias Hunger.Game.Action
  alias Hunger.Game.Cell
  alias Hunger.Game.Util
  alias Hunger.Game.StepSummary
  alias Hunger.Constants

  defstruct [:id, :board, :rounds, :players, :status, :items, :bombs, :history, :goal]

  @new :new
  @playing :playing
  @done :completed

  @max_round Constants.max_rounds()
  @end_game_reward Constants.destination_marks()

  def new(name, size \\ 12) do
    players = %{
      "a" => Player.new("a", 1, 1),
      "b" => Player.new("b", 1, size),
      "c" => Player.new("c", size, size),
      "d" => Player.new("d", size, 1)
    }

    flag_pos = %{
      "a" => Util.set_player_location(:bottom_right, size),
      "b" => Util.set_player_location(:bottom_left, size),
      "c" => Util.set_player_location(:top_left, size),
      "d" => Util.set_player_location(:top_right, size)
    }

    Util.random_middle(size)

    %__MODULE__{
      id: name,
      board: Board.new(players, size),
      players: players,
      status: @new,
      rounds: [],
      history: [],
      bombs: %{},
      items: %{},
      goal: flag_pos
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

  def run(match = %__MODULE__{status: @done}), do: match

  def run(m = %__MODULE__{players: players, rounds: [], history: []}) do
    r = Round.new(players)

    %__MODULE__{m | rounds: [r], history: [%{}]}
  end

  def run(
        match = %__MODULE__{
          players: players,
          board: board = %Board{},
          status: @playing,
          rounds: [r = %Round{} | remains]
        }
      ) do
    with {:last_second, true} <- {:last_second, Round.is_last_second(r)} do
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
      |> random_bomb()
      |> renew_match()
    else
      {:last_second, false} ->
        match
    end
  end

  defp update_board(%__MODULE__{goal: goals} = match, steps) do
    Enum.reduce(steps, match, fn {player_id, %Action{action: {:move, direction}}},
                                 acc = %__MODULE__{
                                   players: players,
                                   board: board
                                 } ->
      player =
        %Player{points: player_points, location: curr_location} = Map.get(players, player_id)

      case Board.player_move(board, player, direction) do
        {:error, err} ->
          IO.inspect(err)

          step_summary =
            StepSummary.new(
              direction,
              Util.determine_location(curr_location, curr_location),
              []
            )

          update_history_summary(acc, player_id, step_summary)
          |> will_finish_game(false)

        {:ok, %{board: updated_board, cells: cells, player_location: new_player_location}} ->
          rewards =
            Enum.reduce(cells, 0, fn c, acc ->
              acc + Cell.cell_reward(c)
            end)

          can_end_game? = can_endgame?(player_id, new_player_location, goals)

          rewards = if can_end_game?, do: rewards + @end_game_reward, else: rewards

          step_summary =
            StepSummary.new(
              direction,
              Util.determine_location(curr_location, new_player_location),
              cells
            )

          new_points = player_points + rewards
          updated_player = %Player{player | location: new_player_location, points: new_points}
          updated_players = Map.put(players, player_id, updated_player)

          acc =
            update_history_summary(acc, player_id, step_summary)
            |> update_items(new_player_location)
            |> will_finish_game(can_end_game?)

          %__MODULE__{acc | board: updated_board, players: updated_players}
      end
    end)
  end

  defp can_endgame?(player_id, {curr_row, curr_col}, goals) do
    Enum.filter(goals, fn {k, _} -> k == nil || k == player_id end)
    |> Enum.map(fn {_k, {r, c}} ->
      curr_row == r && curr_col == c
    end)
    |> Enum.any?()
  end

  def will_finish_game(m = %__MODULE__{status: @playing}, true) do
    %__MODULE__{m | status: @done}
  end

  def will_finish_game(m = %__MODULE__{}, _), do: m

  def update_history_summary(m = %__MODULE__{history: [h | l]}, player_id, summary) do
    new_h = Map.put(h, player_id, summary)
    %__MODULE__{m | history: [new_h | l]}
  end

  defp update_items(m = %__MODULE__{bombs: bombs, items: items}, new_loc) do
    %__MODULE__{m | bombs: Map.delete(bombs, new_loc), items: Map.delete(items, new_loc)}
  end

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

  def renew_match(
        m = %__MODULE__{rounds: rounds, players: players, history: history, status: @playing}
      ) do
    if length(rounds) < @max_round do
      %__MODULE__{m | rounds: [Round.new(players) | rounds], history: [%{} | history]}
    else
      %__MODULE__{m | status: @done}
    end
  end

  def renew_match(m = %__MODULE__{}), do: m

  def random_item(m = %__MODULE__{board: board, items: items, status: @playing}) do
    loc = Board.random_loc(board)
    item = Item.random_item()

    updated_board = Board.set_item(board, loc, item)
    new_items = Map.put(items, loc, item)

    %__MODULE__{m | items: new_items, board: updated_board}
  end

  def random_item(m = %__MODULE__{}), do: m

  def random_bomb(m = %__MODULE__{board: board, bombs: bombs, status: @playing}) do
    has_bomb? = Util.random_has_bomb?()

    case has_bomb? do
      true ->
        # Util.random(1, 2)
        item = "*"
        num_of_bombs = 1

        bombs_loc =
          Enum.map(1..num_of_bombs, fn _idx ->
            Board.random_loc(board)
          end)

        updated_board =
          Enum.reduce(bombs_loc, board, fn loc, acc ->
            Board.set_item(acc, loc, item)
          end)

        new_bombs =
          Enum.reduce(bombs_loc, bombs, fn loc, acc ->
            Map.put(acc, loc, item)
          end)

        %__MODULE__{m | bombs: new_bombs, board: updated_board}

      _false ->
        m
    end
  end

  def random_bomb(m = %__MODULE__{}), do: m

  def print_map(%__MODULE__{board: board}) do
    Board.print_matrix(board)
    |> IO.inspect()
  end
end
