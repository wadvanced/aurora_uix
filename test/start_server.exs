Logger.configure(level: :debug)
Code.require_file("test/env_loader.exs")
Tailwind.start(nil, nil)
Esbuild.start(nil, nil)

Code.require_file("test/start_dependencies.exs")
ExUnit.start()
AuroraUixTest.AppLoader.load_modules(["test", "cases_live"])
