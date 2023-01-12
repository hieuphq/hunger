defmodule Hunger.Game.Player do
  alias Hunger.Game.PlayerId

  defstruct [:id, :token, :location, :points, :status, :name]

  @new "new"
  @joined "joined"

  def status_new(), do: @new
  def status_joined(), do: @joined

  def new(player_id, x, y) do
    %__MODULE__{
      id: player_id,
      token: PlayerId.generate(),
      location: {x, y},
      points: 0,
      status: @new,
      name: player_id
    }
  end

  def joined(%__MODULE__{} = p, nil) do
    %__MODULE__{p | status: @joined, token: PlayerId.generate()}
  end

  def joined(%__MODULE__{} = p, team_name) do
    %__MODULE__{p | status: @joined, token: PlayerId.generate(), name: team_name}
  end
end
