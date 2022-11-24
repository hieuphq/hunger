defmodule HungerWeb.GameView do
  use HungerWeb, :view
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
      players: render_many(Map.values(game.players), PlayerView, "player.json"),
      map: Board.print_matrix(game.board)
    }
  end
end
