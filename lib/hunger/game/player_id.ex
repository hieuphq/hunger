defmodule Hunger.Game.PlayerId do
  @cyrillic_alphabet "123456789абвгґдеєжзиіїйклмнопрстуфцчшщьюяАБВГҐДЕЄЖЗИІЇЙКЛМНОПРСТУФЦЧШЩЬЮЯ"
  @coder Hashids.new(alphabet: @cyrillic_alphabet)

  def generate() do
    unix =
      DateTime.utc_now()
      |> DateTime.to_unix()

    Hashids.encode(@coder, [unix])
  end
end
