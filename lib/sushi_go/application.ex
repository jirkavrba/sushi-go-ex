defmodule SushiGo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      SushiGoWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: SushiGo.PubSub},
      # Start a key-value storage for linking games
      {Registry, keys: :unique, name: SushiGo.GameRegistry},
      # Start the dynamic supervisor that's managing game servers
      SushiGo.GameSupervisor,
      # Start the Endpoint (http/https)
      SushiGoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SushiGo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SushiGoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
