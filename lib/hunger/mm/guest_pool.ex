defmodule Hunger.Mm.GuestPool do
  use GenServer

  @guests_table :guests_table

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(state) do
    :ets.new(@guests_table, [:set, :public, :named_table])
    g1 = %{id: "127.0.0.1-a", token: "mm_1", name: "a", public_ip: "127.0.0.1"}
    g2 = %{id: "127.0.0.1-b", token: "mm_2", name: "b", public_ip: "127.0.0.1"}
    :ets.insert(@guests_table, {g1.id, g1.token, g1})
    :ets.insert(@guests_table, {g2.id, g2.token, g2})
    {:ok, state}
  end

  def add_guest(name, public_ip) do
    guest = generate_user(name, public_ip)
    :ets.insert(@guests_table, {guest.id, guest.token, guest})
    guest
  end

  defp generate_user(name, public_ip) do
    guest_id = parse_user_id(name, public_ip)
    guest_token = "mm_#{:crypto.strong_rand_bytes(12) |> Base.url_encode64()}"
    %{id: guest_id, name: name, token: guest_token, public_ip: public_ip}
  end

  defp parse_user_id(name, public_ip) do
    public_ip = public_ip |> Tuple.to_list() |> Enum.join(".")
    "#{public_ip}-#{name}"
  end

  def find_guest_by_token(token) do
    case :ets.match_object(@guests_table, {:_, token, :"$1"}) do
      [] -> nil
      [g | _] -> elem(g, 2)
    end
  end

  def find_guest_by_id(guest_id) do
    :ets.lookup(@guests_table, guest_id) |> List.first()
  end

  def remove_guest(guest_id) do
    case :ets.lookup(@guests_table, guest_id) do
      [] ->
        {:error, "guest not found"}

      [g | _] ->
        :ets.delete(@guests_table, g)
    end
  end
end
