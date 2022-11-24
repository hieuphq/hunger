defmodule HungerWeb.RoundController do
  use HungerWeb, :controller

  alias Hunger.Hungers

  action_fallback HungerWeb.FallbackController

  def create(conn, %{"game_id" => game_id, "token" => token, "action" => action}) do
    with round = %{} <- Hungers.submit(game_id, token, action) do
      conn
      |> render("show.json", round: round)
    else
      errs -> errs
    end
  end
end
