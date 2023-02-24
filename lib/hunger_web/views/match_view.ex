defmodule HungerWeb.MatchView do
  use HungerWeb, :view

  def render("pre-match.json", %{guest: guest}) do
    %{
      id: guest.id,
      name: guest.name,
      token: guest.token
    }
  end
end
