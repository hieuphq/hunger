defmodule Hunger.Mm.MatchMakerLeader do
  use GenServer

  alias Hunger.Mm.MatchMakerSupervisor

  def start_link(_) do
    GenServer.start_link(
      __MODULE__,
      %{
        match_makers: %{}
      },
      name: __MODULE__
    )
  end

  def add_match_maker(users) do
    name = generate_name()
    GenServer.call(__MODULE__, {:add_match_maker, name, users})
    name
  end

  def remove_match_maker(name) do
    GenServer.cast(__MODULE__, {:remove_match_maker, name})
  end

  def generate_name() do
    :crypto.strong_rand_bytes(6) |> Base.url_encode64(padding: false)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:add_match_maker, name, users}, _from, %{match_makers: match_makers} = state) do
    match_pid = MatchMakerSupervisor.start_match_maker(name, users)

    updated_match_makers = Map.put(match_makers, name, match_pid)

    {:reply, :ok, %{state | match_makers: updated_match_makers}}
  end

  def handle_cast({:remove_match_maker, name}, %{match_makers: match_makers} = state) do
    updated_match_makers = Map.delete(match_makers, name)
    {:noreply, %{state | match_makers: updated_match_makers}}
  end
end
