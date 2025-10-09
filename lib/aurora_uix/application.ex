defmodule Aurora.Uix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Aurora.UixWeb.Endpoint

  @impl true
  def start(_type, _args) do
    children = [
      Aurora.UixWeb.Telemetry,
      Aurora.Uix.Repo,
      # {DNSCluster, query: Application.get_env(:aurora_uix, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Aurora.Uix.PubSub},
      # Start a worker by calling: Aurora.Uix.Worker.start_link(arg)
      # {Aurora.Uix.Worker, arg},
      # Start to serve requests, typically the last entry
      Aurora.UixWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Aurora.Uix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
