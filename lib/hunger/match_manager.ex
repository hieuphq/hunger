defmodule Hunger.MatchManager do
  alias Hunger.MatchWorker
  alias Hunger.MatchSupervisor

  use GenServer

  defmodule State do
    defstruct [:processing, :done]
  end

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    {:ok,
     %State{
       processing: %{},
       done: %{}
     }}
  end

  def new_match(match_name) do
    MatchSupervisor.new_child(match_name)
    add_processing(match_name, MatchWorker.process_name(match_name))
    match_status(match_name)
  end

  def match_status(match_name) do
    MatchWorker.get_match_status(match_name)
  end

  def join_match(match_name) do
    MatchWorker.join_match(match_name)
  end

  def run_match(match_name) do
    MatchWorker.start_match(match_name)
  end

  def add_processing(match_name, match_id) do
    GenServer.cast(__MODULE__, {:add, {match_name, match_id}})
  end

  def match_list() do
    GenServer.call(__MODULE__, :list)
  end

  def done_match(match_name) do
    GenServer.cast(__MODULE__, {:done, match_name})
  end

  @impl true
  def handle_cast({:add, {name, id}}, state = %State{processing: processing}) do
    processing = Map.put(processing, name, id)
    state = Map.put(state, :processing, processing)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:done, match_name}, state = %State{processing: processing, done: done}) do
    case Map.get(processing, match_name) do
      nil ->
        {:noreply, state}

      match_id ->
        GenServer.stop(match_id)
        match_status = MatchWorker.get_match_status(match_name)
        processing = Map.delete(processing, match_name)
        done = Map.put(done, match_name, match_status)

        {:noreply, %State{state | done: done, processing: processing}}
    end
  end

  @impl true
  def handle_call(:list, _from, state = %State{processing: processing}) do
    names = Map.keys(processing)
    {:reply, names, state}
  end
end
