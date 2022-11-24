defmodule Hunger.Game.StepSummary do
  alias Hunger.Game.Cell

  defstruct [:action, :action_request, :action_result, :item, :got_boom]

  def new(action_request, action_result, cells) do
    got_bomb? =
      cells
      |> Enum.map(fn c -> Cell.is_bomb?(c) end)
      |> Enum.any?()

    %__MODULE__{
      action: "move",
      action_request: action_request,
      action_result: action_result,
      item: parse_item(cells),
      got_boom: got_bomb?
    }
  end

  defp parse_item(cells) do
    Enum.filter(cells, fn c -> Cell.contain_item?(c) end)
    |> List.first()
  end
end
