defmodule Hunger.MatchManager do
  alias Hunger.Game.Util
  alias Hunger.MatchWorker
  alias Hunger.MatchSupervisor
  alias Hunger.MatchStore

  use GenServer

  defmodule State do
    defstruct [:processing]
  end

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    {:ok,
     %State{
       processing: %{}
     }}
  end

  def new_match(match_name) do
    GenServer.call(__MODULE__, {:add, match_name})
    |> case do
      {:ok, _} ->
        match_status(match_name)

      errs ->
        errs
    end
  end

  def match_status(match_name) do
    with match = %{} <- MatchWorker.get_match_status(match_name) do
      match
    else
      _errs ->
        MatchStore.get_match(match_name)
    end
  end

  def join_match(match_name) do
    MatchWorker.join_match(match_name)
  end

  def start_match(match_name) do
    MatchWorker.start_match(match_name)
  end

  def match_list() do
    GenServer.call(__MODULE__, :list)
  end

  def done_match(match_name) do
    GenServer.cast(__MODULE__, {:done, match_name})
  end

  def submit_round(match_name, player_token, action) do
    MatchWorker.submit(match_name, player_token, Util.parse_action(action))
  end

  @impl true
  def handle_cast({:done, match_name}, state = %State{processing: processing}) do
    case Map.get(processing, match_name) do
      nil ->
        {:noreply, state}

      match_id ->
        match_status = MatchWorker.get_match_status(match_name)
        processing = Map.delete(processing, match_name)
        MatchStore.add_match(match_name, match_status)
        GenServer.stop(match_id)

        {:noreply, %State{state | processing: processing}}
    end
  end

  @impl true
  def handle_call(
        {:add, match_name},
        _from,
        state = %State{processing: processing}
      ) do
    existed_processing? = Map.has_key?(processing, match_name)
    existed_match = MatchStore.get_match(match_name)

    existed_done? =
      case existed_match do
        {:error, :not_found} -> false
        _ -> true
      end

    case !existed_done? && !existed_processing? do
      true ->
        MatchSupervisor.new_child(match_name)
        match_process_name = MatchWorker.process_name(match_name)
        updated_processing = Map.put(processing, match_name, match_process_name)

        {:reply, {:ok, match_process_name}, %State{state | processing: updated_processing}}

      _else ->
        {:reply, {:error, "duplicated name"}, state}
    end
  end

  @impl true
  def handle_call(:list, _from, state = %State{processing: processing}) do
    names = Map.keys(processing)

    list = Enum.map(names, fn n -> match_status(n) end)
    {:reply, list, state}
  end
end
