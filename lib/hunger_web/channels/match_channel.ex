defmodule HungerWeb.MatchChannel do
  use Phoenix.Channel
  alias Hunger.Mm.Lobby

  @impl true
  def join("match:lobby", _message, socket) do
    Lobby.add_user(socket.assigns.user_id)
    {:ok, socket}
  end

  @impl true
  def join("match:" <> _private_match_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  @impl true
  def handle_in("accept", %{"group_id" => group_id}, socket) do
    match_maker_pid = GenServer.whereis(MyApp.MatchMaker)
    GenServer.call(match_maker_pid, {:accept, socket.assigns.user_id, group_id})
    {:noreply, socket}
  end

  def handle_in("decline", %{"group_id" => group_id}, socket) do
    match_maker_pid = GenServer.whereis(MyApp.MatchMaker)
    GenServer.call(match_maker_pid, {:decline, socket.assigns.user_id, group_id})
    {:noreply, socket}
  end

  def handle_info({:match_status, status}, socket) do
    # socket = socket |> push_event("match_status", %{status: status})

    # if status == :success do
    #   socket = socket |> leave()
    # end

    {:noreply, socket}
  end

  def handle_info({:match_group, group_id, users}, socket) do
    if List.keymember?(users, socket.assigns.user_id, 0) do
      socket =
        socket
        |> assign(:group_id, group_id)

      # |> push_event("match_group", %{group_id: group_id, users: users})
    end

    {:noreply, socket}
  end

  @impl true
  def terminate({:shutdown, _}, socket) do
    Lobby.remove_user(socket.assigns.user_id)
    {:stop, :shutdown, socket}
  end
end
