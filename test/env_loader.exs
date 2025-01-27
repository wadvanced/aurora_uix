# Load file config/test.exs
configuration_file = "config/test.exs"

# Tries to load the test.exs configuration file
if File.exists?(configuration_file) do
  configuration_file
  |> Config.Reader.read!()
  |> Enum.each(fn {app, configs} ->
    configs
    |> Enum.each(fn {key, value} ->
      Application.put_env(app, key, value)
    end)
  end)
end

# Set default environment, if not set in a configuration file.
## Phoenix environment default configuration
if is_nil(Application.get_env(:aurora_uix, AuroraUixTestWeb.Endpoint)),
  do:
    Application.put_env(:aurora_uix, AuroraUixTestWeb.Endpoint,
      http: [port: 4001],
      server: false,
      secret_key_base: "4ur0raU1x"
    )

## Ecto / Postgres environment default configuration
if is_nil(Application.get_env(:aurora_uix, AuroraUixTest.Repo)),
  do:
    Application.put_env(:aurora_uix, AuroraUixTest.Repo,
      username: "postgres",
      password: "postgres",
      database: "aurora_uix_test",
      hostname: "localhost",
      pool: Ecto.Adapters.SQL.Sandbox
    )
