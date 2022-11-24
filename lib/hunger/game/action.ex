defmodule Hunger.Game.Action do
  defstruct [:action, :created_at]

  def new(action) do
    %__MODULE__{
      action: action,
      created_at: DateTime.utc_now()
    }
  end
end
