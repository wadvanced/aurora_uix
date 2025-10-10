# Mix.Tasks.Uix.Test.Assets.Build.run("")

Logger.configure(level: :debug)
Code.require_file("test/env_loader.exs")
# Tailwind.start(nil, nil)
# Esbuild.start(nil, nil)

Code.require_file("test/start_test_app.exs")

ExUnit.start()
Aurora.Uix.Test.AppLoader.load_modules(["test", "cases_live"])
