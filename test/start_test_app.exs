## Steps to enable the application dependencies
Logger.configure(level: :error, truncate: :infinity)
Code.require_file("test/env_loader.exs")
Code.require_file("test/app_loader.exs")

{:ok, _} = Application.ensure_all_started(:phoenix)
{:ok, _} = Application.ensure_all_started(:ecto_sql)

# children = [
#   Aurora.Uix.Repo,
#   {Phoenix.PubSub, name: Aurora.Uix.PubSub},
#   Aurora.UixWeb.Endpoint
# ]

# Supervisor.start_link(children, strategy: :one_for_one)

# Ecto.Adapters.SQL.Sandbox.mode(Aurora.Uix.Repo, :auto)
