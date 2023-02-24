defmodule Hunger.Mm.Lobby do
  use GenServer
  alias Hunger.Mm.MatchMakerLeader

  @capacity 2

  def start_link(_) do
    GenServer.start_link(
      __MODULE__,
      %{
        users: %{},
        processing: %{}
      },
      name: __MODULE__
    )
  end

  def init(state) do
    {:ok, state}
  end

  def add_user(user_id) do
    GenServer.cast(__MODULE__, {:add_user, user_id})
  end

  def remove_user(user_id) do
    GenServer.cast(__MODULE__, {:remove_user, user_id})
  end

  def handle_cast(
        {:add_user, user_id},
        %{users: users, processing: processing} = state
      ) do
    IO.inspect("Adding user #{user_id} to lobby")

    case Map.has_key?(processing, user_id) do
      true ->
        IO.inspect("User #{user_id} is already in processing")
        {:noreply, state}

      false ->
        new_user = %{id: user_id, joined_at: DateTime.utc_now()}
        new_users = Map.put(users, user_id, new_user)

        if Enum.count(users) + 1 < @capacity do
          {:noreply, %{state | users: new_users}}
        else
          IO.inspect("Make a match")
          updated_users = Map.values(users) ++ [new_user]
          MatchMakerLeader.add_match_maker(updated_users)

          updated_processing =
            Enum.reduce(updated_users, processing, fn itm, acc ->
              Map.put(acc, itm.id, itm)
            end)

          notify_message(updated_users, "init_match", updated_users)

          {:noreply, %{state | users: %{}, processing: updated_processing}}
        end
    end
  end

  def notify_message(users, message, payload) when is_list(users) do
    HungerWeb.Endpoint.broadcast("match:lobby", message, payload)
  end

  def handle_cast({:remove_user, user_id}, %{users: users, processing: processing} = state) do
    IO.inspect("Removing user #{user_id} from lobby: #{Enum.count(users)}")

    new_users =
      if Map.has_key?(users, user_id) do
        Map.delete(users, user_id)
      else
        users
      end

    # TODO: we should remove user in the processing

    {:noreply, %{state | users: new_users, processing: processing}}
  end
end
