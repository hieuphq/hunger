defmodule Hunger.Mm.MatchMakerSupervisor do
  use DynamicSupervisor
  alias Hunger.Mm.MatchMaker

  def start_link(_opts \\ []) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    IO.inspect("start #{__MODULE__}")
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_match_maker(name, users) do
    spec = %{id: MatchMaker, start: {MatchMaker, :start_link, [%{users: users, name: name}]}}

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} ->
        pid

      {:error, {:already_started, pid}} ->
        pid
    end
  end

  def stop_match_maker(match_maker_pid) do
    DynamicSupervisor.terminate_child(__MODULE__, match_maker_pid)
  end
end
