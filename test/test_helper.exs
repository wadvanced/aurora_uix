# Loads configuration and required modules
Code.require_file("test/app_loader.exs")
Code.require_file("test/env_loader.exs")

ExUnit.start()
{:ok, _} = Application.ensure_all_started(:phoenix)
{:ok, _} = Application.ensure_all_started(:ecto_sql)

AuroraUixTest.Repo.start_link()
AuroraUixTestWeb.Endpoint.start_link()

Ecto.Adapters.SQL.Sandbox.mode(AuroraUixTest.Repo, :manual)
