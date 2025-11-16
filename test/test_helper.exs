ExUnit.start()

Code.require_file("test/start_test_app.exs")

{:ok, _} = Application.ensure_all_started(:wallaby)
