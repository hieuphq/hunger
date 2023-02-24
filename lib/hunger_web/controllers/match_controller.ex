defmodule HungerWeb.MatchController do
  use HungerWeb, :controller
  alias Hunger.Mm.GuestPool

  action_fallback HungerWeb.FallbackController

  def init(conn, %{"name" => name}) do
    public_ip = conn.remote_ip

    guest = GuestPool.add_guest(name, public_ip)

    conn
    |> put_status(:created)
    |> render("pre-match.json", guest: guest)
  end
end
