# Load file config/test.exs
configuration_files = ["test/config/test.exs", "config/test.exs"]

# Tries to load the test.exs configuration file
Enum.each(configuration_files, fn configuration_file ->
  if File.exists?(configuration_file) do
    configuration_file
    |> Config.Reader.read!()
    |> Enum.each(fn {app, configs} ->
      Enum.each(configs, fn {key, value} ->
        Application.put_env(app, key, value)
      end)
    end)
  end
end)
