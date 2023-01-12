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
    match_id = process_name(match_name)

    case Registry.lookup(HungerGameRegistry, "hunger_#{match_name}") do
      [] ->
        {:error, :not_found}

      _val ->
        GenServer.call(match_id, :get_status)
    end
  end

  def join_match(match_name, team_name) do
    match_id = process_name(match_name)

    case Registry.lookup(HungerGameRegistry, "hunger_#{match_name}") do
      [] ->
        {:error, :not_found}

      _val ->
        GenServer.call(match_id, {:join, team_name})
    end
  end

  def start_match(match_name, token) do
    pid = process_name(match_name)

    case Registry.lookup(HungerGameRegistry, "hunger_#{match_name}") do
      [] ->
        {:error, :not_found}

      _ ->
        GenServer.call(pid, {:start, token})
    end
  end

  def submit(match_name, player_token, action) do
    pid = process_name(match_name)

    case Registry.lookup(HungerGameRegistry, "hunger_#{match_name}") do
      [] ->
        {:error, :not_found}

      _ ->
        GenServer.call(pid, {:submit, player_token, action})
    end
  end

  # Server (callbacks)

  @impl true
  def init(match = %Match{}) do
    {:ok, match}
  end

  @impl true
  def handle_continue(:loop, state) do
    Process.send(self(), :loop, [])

    {:noreply, state}
  end

  @impl true
  def handle_call({:join, team_name}, _from, state) do
    {new_state, response} =
      with {:ok, detail, updated_match} <- Match.join(state, team_name) do
        {updated_match, detail}
      else
        errs = {:error, err} ->
          IO.inspect(err)
          {state, errs}
      end

    {:reply, response, new_state}
  end

  @impl true
  def handle_call({:start, token}, _from, state) do
    with {:ok, updated_state} <- Match.start_match(state, token) do
      {:reply, updated_state, updated_state, {:continue, :loop}}
    else
      errs = {:error, _err} ->
        {:reply, errs, state}
    end
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:submit, token, direction}, _from, state) do
    with {:ok, action, updated_state} <- Match.commit_step(state, token, direction) do
      {:reply, action, updated_state}
    else
      errs = {:error, _err} ->
        {:reply, errs, state}
    end
  end

  @impl true
  def handle_cast(:run, state) do
    updated_state = Match.run(state)
    Match.print_map(updated_state)
    {:noreply, updated_state}
  end

  @impl true
  def handle_info(:loop, state = %{status: :playing}) do
    GenServer.cast(self(), :run)
    Process.send_after(self(), :loop, Constants.actually_round_seconds() * 1000)
    {:noreply, state}
  end

  def handle_info(:loop, state = %Match{id: game_id, status: :completed}) do
    MatchManager.done_match(game_id)
    {:noreply, state}
  end

  def handle_info(:loop, state) do
    {:noreply, state}
  end
end
