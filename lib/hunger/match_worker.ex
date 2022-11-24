defmodule Hunger.MatchWorker do
  alias Hunger.MatchManager
  alias Hunger.Constants
  alias Hunger.Game.Match

  use GenServer, restart: :temporary

  # Client

  def start_link(match_name) do
    GenServer.start_link(__MODULE__, Match.new(match_name), name: process_name(match_name))
  end

  def process_name(match_name),
    do: {:via, Registry, {HungerGameRegistry, "hunger_#{match_name}"}}

  def get_match_status(match_name) do
    pid = process_name(match_name)
    GenServer.call(pid, :get_status)
  end

  def join_match(match_name) do
    pid = process_name(match_name)
    GenServer.call(pid, :join)
  end

  def start_match(match_name) do
    pid = process_name(match_name)
    GenServer.call(pid, :start)
  end

  # Server (callbacks)

  @impl true
  def init(match = %Match{}) do
    {:ok, match}
  end

  @impl true
  def handle_continue(:loop, state) do
    Process.send_after(self(), :loop, Constants.round_limit_seconds() * 1000)

    {:noreply, state}
  end

  @impl true
  def handle_call(:join, _from, state) do
    {new_state, response} =
      with {:ok, detail, updated_match} <- Match.join(state) do
        {updated_match, detail}
      else
        {:error, err} ->
          IO.inspect(err)
          {state, nil}
      end

    {:reply, response, new_state}
  end

  @impl true
  def handle_call(:start, _from, state) do
    new_state = Match.start_match(state)

    {:reply, new_state, new_state, {:continue, :loop}}
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    Match.print_map(state)
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:run, state) do
    updated_state = Match.run(state)
    Match.print_map(updated_state)
    {:noreply, updated_state}
  end

  @impl true
  def handle_cast({:submit, token, direction}, state) do
    updated_state = Match.commit_step(state, token, direction)
    updated_state.rounds |> List.first() |> IO.inspect()

    {:noreply, updated_state}
  end

  @impl true
  def handle_info(:loop, state = %{status: :playing}) do
    Process.send_after(self(), :loop, Constants.round_limit_seconds() * 1000)
    GenServer.cast(self(), :run)
    {:noreply, state}
  end

  def handle_info(:loop, state = %Match{name: name, status: :done}) do
    MatchManager.done_match(name)
    {:noreply, state}
  end

  def handle_info(:loop, state) do
    {:noreply, state}
  end
end
