defmodule Hunger.Game.Item do
  def random_item(min, max) do
    base =
      Enum.map(min..max, fn v ->
        no_value = max - v + 1
        Enum.map(1..no_value, fn _l -> v end)
      end)
      |> Enum.flat_map(fn v -> v end)

    val = Enum.random(base)

    "#{val}"
  end
end
