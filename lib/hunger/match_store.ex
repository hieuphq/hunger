defmodule Hunger.MatchStore do
  alias Hunger.Game.Match
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    {:ok, %{}}
  end

  def add_match(match_name, match) do
    GenServer.cast(__MODULE__, {:add, match_name, match})
  end

  def get_match(match_name) do
    GenServer.call(__MODULE__, {:get, match_name})
  end

  @impl true
  def handle_call({:get, match_name}, _from, state) do
    case Map.has_key?(state, match_name) do
      true ->
        {:reply, Map.get(state, match_name), state}

      false ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_cast({:add, match_name, match}, state) do
    {:noreply, Map.put(state, match_name, match)}
  end
end
