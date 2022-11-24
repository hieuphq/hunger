defmodule HungerWeb.PlayerController do
  use HungerWeb, :controller

  alias Hunger.Hungers

  action_fallback HungerWeb.FallbackController

  def create(conn, %{"game_id" => game_id}) do
    with player = %{id: _} <- Hungers.join_game(game_id) do
      conn
      |> put_status(:created)
      |> render("show.json", player: player)
    else
      errs -> errs
    end
  end
end
