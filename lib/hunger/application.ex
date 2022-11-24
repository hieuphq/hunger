defmodule Hunger.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Hunger.Repo,
      # Start the Telemetry supervisor
      HungerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Hunger.PubSub},
      # Start the Endpoint (http/https)
      HungerWeb.Endpoint,
      # Start a worker by calling: Hunger.Worker.start_link(arg)
      # {Hunger.Worker, arg}
      {Registry, keys: :unique, name: HungerGameRegistry},
      %{
        id: Hunger.MatchManager,
        start: {Hunger.MatchManager, :start_link, [[]]}
      },
      %{
        id: Hunger.MatchSupervisor,
        start: {Hunger.MatchSupervisor, :start_link, [[]]}
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hunger.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HungerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
