defmodule Hunger.Game.Round do
  alias Hunger.Game.Action
  alias Hunger.Constants

  defstruct [:players, :next_states, :expired_at]

  def new(players) do
    player_keys = Map.keys(players)

    init_states =
      player_keys
      |> Enum.map(fn k -> {k, nil} end)
      |> Enum.into(%{}, fn v -> v end)

    expired_at =
      DateTime.utc_now()
      |> DateTime.add(Constants.round_limit_seconds(), :second)

    %__MODULE__{
      players: players,
      next_states: init_states,
      expired_at: expired_at
    }
  end

  def get_player_actions(%__MODULE__{next_states: states}) do
    Enum.map(states, fn {player_id, action} ->
      {player_id, action}
    end)
  end

  def submit(%__MODULE__{next_states: states} = round, player_id, action) do
    case parse_action(action) do
      {:ok, move_action} ->
        new_states = Map.put(states, player_id, move_action)

        %__MODULE__{
          round
          | next_states: new_states
        }

      {:error, _} ->
        round
    end
  end

  def is_last_second(%__MODULE__{expired_at: expired_at}) do
    DateTime.utc_now()
    |> DateTime.compare(expired_at)
    |> case do
      :gt -> true
      _ -> false
    end
  end

  def last_players(%__MODULE__{next_states: states}) do
    Enum.filter(states, fn
      {_k, nil} -> true
      {_k, _} -> false
    end)
    |> Enum.map(fn {k, _} -> k end)
  end

  defp parse_action({:move, _direction} = move_action) do
    {:ok, Action.new(move_action)}
  end

  defp parse_action(_) do
    {:error, "invalid action"}
  end
end
