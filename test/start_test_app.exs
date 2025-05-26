## Steps to enable the application dependencies
Logger.configure(level: :error, truncate: :infinity)
Code.require_file("test/env_loader.exs")
Code.require_file("test/app_loader.exs")

{:ok, _} = Application.ensure_all_started(:phoenix)
{:ok, _} = Application.ensure_all_started(:ecto_sql)

Aurora.Uix.Test.Repo.start_link()
Aurora.Uix.Test.Web.Endpoint.start_link()

Ecto.Adapters.SQL.Sandbox.mode(Aurora.Uix.Test.Repo, :auto)
