defmodule Hunger.Mm.MatchMaker do
  use GenServer, restart: :temporary

  @timeout 30_000

  def start_link(%{name: name, users: users}) do
    GenServer.start_link(
      __MODULE__,
      %{
        users: users,
        state: :processing,
        timeout_ref: nil
      },
      name: {:global, "mm:#{name}"}
    )
  end

  def init(state) do
    {:ok, state}
  end

  def create_match(users) do
    GenServer.cast(__MODULE__, {:create_match, users})
  end

  def handle_cast({:create_match, users}, state) do
    IO.inspect("Creating match with users #{inspect(users)}")

    timeout_ref = Process.send_after(self(), :timeout, @timeout)
    {:noreply, %{state | users: users, timeout_ref: timeout_ref}}
  end

  def handle_info(:timeout, %{users: users, state: :processing} = state) do
    IO.inspect("Matchmaking timed out")
    notify_users(users, %{state: :failed})
    {:stop, :timeout, %{state | state: :failed}}
  end

  def handle_cast({:accept, user_id}, %{users: users, state: :processing} = state) do
    IO.inspect("User #{user_id} accepted the match")

    new_users =
      for user = %{id: id, socket: socket, accepted: false} <- users, id != user_id, do: user

    accepted_user = List.keyfind(users, :id, user_id)

    if accepted_user do
      updated_user = Map.put(accepted_user, :accepted, true)
      new_users = new_users ++ [updated_user]
    end

    if Enum.all?(new_users, fn user -> user.accepted end) do
      Process.cancel_timer(state.timeout_ref)
      notify_users(new_users, %{state: :success})
      {:stop, :normal, %{state | users: [], state: :success}}
    else
      {:noreply, %{state | users: new_users}}
    end
  end

  def handle_cast({:decline, user_id}, %{state: :processing} = state) do
    IO.inspect("User #{user_id} declined the match")
    notify_users(state.users, %{state: :failed})
    {:stop, :normal, %{state | users: [], state: :failed}}
  end

  defp notify_users(users, message) do
    Enum.each(users, fn user ->
      send(user.socket, message)
    end)
  end
end
