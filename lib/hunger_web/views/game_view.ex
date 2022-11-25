defmodule HungerWeb.GameView do
  use HungerWeb, :view
  alias Hunger.Game.Round
  alias Hunger.Game.Cell
  alias Hunger.Game.Match
  alias Hunger.Game.Board
  alias HungerWeb.GameView
  alias HungerWeb.PlayerView

  def render("index.json", %{game: game}) do
    %{data: render_many(game, GameView, "game.json")}
  end

  def render("show.json", %{game: game}) do
    %{data: render_one(game, GameView, "game.json")}
  end

  def render("game.json", %{game: game}) do
    %{
      id: game.id,
      status: game.status,
      no_items: Map.values(game.items) |> length(),
      no_bombs: Map.values(game.bombs) |> length(),
      round_expire_at: render_round_expire_at(game),
      players: render_many(Map.values(game.players), PlayerView, "player.json"),
      prev_round: render_prev_history(game),
      map: Board.print_matrix(game.board),
      history: render_history(game)
    }
  end

  defp render_round_expire_at(%Match{rounds: []}), do: nil

  defp render_round_expire_at(%Match{
         rounds: [%Round{expired_at: expired_at} | _]
       }) do
    expired_at
  end

  defp render_prev_history(%Match{history: []}), do: %{}
  defp render_prev_history(%Match{history: [%{}]}), do: %{}

  defp render_prev_history(%Match{history: history, status: :playing}) do
    [_first | [second | _]] = history

    Enum.into(second, %{}, fn {k, val} ->
      {k,
       %{
         action: val.action,
         action_request: val.action_request,
         action_result: val.action_result,
         item: render_item(val.item),
         got_bomb: val.got_bomb
       }}
    end)
  end

  defp render_prev_history(%Match{history: history, status: :completed}) do
    [first | _] = history

    Enum.into(first, %{}, fn {k, val} ->
      {k,
       %{
         action: val.action,
         action_request: val.action_request,
         action_result: val.action_result,
         item: render_item(val.item),
         got_bomb: val.got_bomb
       }}
    end)
  end

  defp render_history(%Match{history: []}), do: []

  defp render_history(%Match{history: history, status: :playing}) do
    [_first | remains] = history

    Enum.map(remains, fn h ->
      Enum.into(h, %{}, fn {k, val} ->
        {k,
         %{
           action: val.action,
           action_request: val.action_request,
           action_result: val.action_result,
           item: render_item(val.item),
           got_bomb: val.got_bomb
         }}
      end)
    end)
  end

  defp render_history(%Match{history: history, status: :completed}) do
    Enum.map(history, fn h ->
      Enum.into(h, %{}, fn {k, val} ->
        {k,
         %{
           action: val.action,
           action_request: val.action_request,
           action_result: val.action_result,
           item: render_item(val.item),
           got_bomb: val.got_bomb
         }}
      end)
    end)
  end

  defp render_item(nil), do: nil

  defp render_item(%Cell{type: type, metadata: val}),
    do: %{
      type: type,
      value: val
    }
end
