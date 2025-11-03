defmodule Aurora.Uix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    endpoint = Application.get_env(:aurora_uix, :endpoint)
    opts = [strategy: :one_for_one, name: Aurora.Uix.Supervisor]

    if endpoint do
      children =
        [
          Aurora.UixWeb.Telemetry,
          Aurora.Uix.Repo,
          # {DNSCluster, query: Application.get_env(:aurora_uix, :dns_cluster_query) || :ignore},
          {Phoenix.PubSub, name: Aurora.Uix.PubSub},
          # Start a worker by calling: Aurora.Uix.Worker.start_link(arg)
          # {Aurora.Uix.Worker, arg},
          # Start to serve requests, typically the last entry
          endpoint
        ]

      # See https://hexdocs.pm/elixir/Supervisor.html
      # for other strategies and supported options
      Supervisor.start_link(children, opts)
    else
      Supervisor.start_link([], opts)
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    endpoint_module = Application.get_env(:aurora_uix, :endpoint)

    if endpoint_module do
      endpoint_module.config_change(changed, removed)
    end

    :ok
  end
end
