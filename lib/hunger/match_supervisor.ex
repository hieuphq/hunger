defmodule Hunger.MatchSupervisor do
  alias Hunger.MatchWorker

  use DynamicSupervisor

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    IO.inspect("start #{__MODULE__}")
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def new_child(match_name) do
    spec = %{id: MatchWorker, start: {MatchWorker, :start_link, [match_name]}}

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} ->
        pid

      {:error, {:already_started, pid}} ->
        pid
    end
  end
end
