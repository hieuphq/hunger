defmodule HungerWeb.PlayerView do
  use HungerWeb, :view
  alias HungerWeb.PlayerView

  def render("index.json", %{player: player}) do
    %{data: render_many(player, PlayerView, "player.json")}
  end

  def render("show.json", %{player: player}) do
    %{data: render_one(player, PlayerView, "player.json")}
  end

  def render("player.json", %{player: player}) do
    %{
      id: player.id,
      token: player.token,
      location: render_location(player.location),
      points: player.points,
      status: player.status
    }
  end

  defp render_location({row, col}) do
    %{
      row: row,
      col: col
    }
  end
end
