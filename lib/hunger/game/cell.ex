defmodule Hunger.Game.Cell do
  alias Hunger.Constants

  defstruct [:type, :metadata]

  @item "item"
  @empty "empty"
  @destination "dest"
  @bomb "bomb"
  @player "player"

  @dest_marks Constants.destination_marks()

  def parse_cell(nil) do
    %__MODULE__{
      type: @empty,
      metadata: 0
    }
  end

  def parse_cell(val) do
    case val do
      "X" ->
        %__MODULE__{
          type: @destination,
          metadata: @dest_marks
        }

      "*" ->
        %__MODULE__{
          type: @bomb,
          metadata: 0
        }

      val ->
        is_number = Regex.match?(~r/^\d+$/, val)

        if is_number do
          {number_val, _} = Integer.parse(val)

          %__MODULE__{
            type: @item,
            metadata: number_val
          }
        else
          %__MODULE__{
            type: @player,
            metadata: val
          }
        end
    end
  end

  def can_move?(%__MODULE__{type: @player, metadata: player_id}),
    do: {:error, "cell is occupied by #{player_id}"}

  def can_move?(_), do: :ok

  def is_destination?(%__MODULE__{type: @destination}),
    do: true

  def is_destination?(_), do: false

  def cell_reward(%__MODULE__{type: @destination, metadata: marks}), do: marks
  def cell_reward(%__MODULE__{type: @item, metadata: marks}), do: marks
  def cell_reward(%__MODULE__{}), do: 0

  def is_bomb?(%__MODULE__{type: @bomb}), do: true
  def is_bomb?(%__MODULE__{}), do: false

  def contain_item?(%__MODULE__{type: @item}), do: true
  def contain_item?(%__MODULE__{}), do: false
end
