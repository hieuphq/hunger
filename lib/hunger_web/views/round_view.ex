defmodule HungerWeb.RoundView do
  use HungerWeb, :view

  alias HungerWeb.RoundView

  def render("index.json", %{round: round}) do
    %{data: render_many(round, RoundView, "round.json")}
  end

  def render("show.json", %{round: round}) do
    %{data: render_one(round, RoundView, "round.json")}
  end

  def render("round.json", %{round: round}) do
    %{
      action: parse_action(round.action),
      created_at: round.created_at
    }
  end

  defp parse_action({action, value}) do
    %{
      action: action,
      value: value
    }
  end
end
