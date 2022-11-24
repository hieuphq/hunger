defmodule HungerWeb.GameController do
  use HungerWeb, :controller

  alias Hunger.Hungers

  action_fallback HungerWeb.FallbackController

  def index(conn, _params) do
    game = Hungers.list_game()
    render(conn, "index.json", game: game)
  end

  def create(conn, %{"game" => game_params}) do
    game = Hungers.create_game(game_params)

    conn
    |> put_status(:created)
    |> put_resp_header("location", Routes.game_path(conn, :show, game))
    |> render("show.json", game: game)
  end

  def show(conn, %{"id" => game_id}) do
    game = Hungers.get_game!(game_id)

    case game do
      %{id: _} ->
        render(conn, "show.json", game: game)

      errs ->
        errs
    end
  end

  def start(conn, %{"game_id" => id}) do
    game = Hungers.start_game(id)
    render(conn, "show.json", game: game)
  end

  # def update(conn, %{"id" => id, "game" => game_params}) do
  #   game = Hungers.get_game!(id)

  #   with {:ok, %Game{} = game} <- Hungers.update_game(game, game_params) do
  #     render(conn, "show.json", game: game)
  #   end
  # end

  # def delete(conn, %{"id" => id}) do
  #   game = Hungers.get_game!(id)

  #   with {:ok, %Game{}} <- Hungers.delete_game(game) do
  #     send_resp(conn, :no_content, "")
  #   end
  # end
end
