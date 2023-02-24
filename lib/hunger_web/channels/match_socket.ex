defmodule HungerWeb.MatchSocket do
  use Phoenix.Socket

  channel "match:*", HungerWeb.MatchChannel

  # A Socket handler
  #
  # It's possible to control the websocket connection and
  # assign values that can be accessed by your channel topics.

  ## Channels
  # Uncomment the following line to define a "room:*" topic
  # pointing to the `HungerWeb.RoomChannel`:
  #
  # channel "room:*", HungerWeb.RoomChannel
  #
  # To create a channel file, use the mix task:
  #
  #     mix phx.gen.channel Room
  #
  # See the [`Channels guide`](https://hexdocs.pm/phoenix/channels.html)
  # for further details.

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(%{"match_token" => token}, socket, _connect_info)
      when is_binary(token) do
    case validate_token(token) do
      {:ok, user} ->
        updated_socket =
          socket
          |> assign(:user_id, user.id)
          |> assign(:user_token, token)

        {:ok, updated_socket}

      {:error, reason} ->
        {:error, %{reason: reason}}
    end
  end

  def connect(params, _socket, _connect_info) do
    IO.inspect(params)
    {:error, %{reason: "Missing token"}}
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Elixir.HungerWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(socket), do: "user:#{socket.assigns.user_id}"

  defp validate_token(token) do
    case String.starts_with?(token, "mm_") do
      true ->
        case Hunger.Mm.GuestPool.find_guest_by_token(token) do
          nil ->
            {:error, "Invalid token"}

          user ->
            {:ok, user}
        end

      false ->
        {:error, "Invalid token prefix"}
    end
  end
end
