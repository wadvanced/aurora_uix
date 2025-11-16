## Steps to enable the application dependencies
Logger.configure(level: :error, truncate: :infinity)
Code.require_file("test/app_loader.exs")
