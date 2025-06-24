defmodule Aurora.Uix.Test.AppLoader do
  @moduledoc """
  Utilities for loading application files for testing.

  ## Key Features
  - Loads all modules under test/support/app and test/support/app_web.
  - Recursively loads modules in given paths for test setup.
  """

  @doc """
  Loads all modules under test/support/app and test/support/app_web.

  ## Returns
  :ok - Always returns :ok after loading modules.
  """
  @spec load_app() :: :ok
  def load_app do
    load_modules("app")
    load_modules("app_web")
  end

  @doc """
  Loads modules in test/support plus the given path.

  ## Parameters
  - `path` (binary()) - Path to be appended.

  ## Returns
  :ok - Always returns :ok after loading modules.
  """
  @spec load_modules(binary()) :: :ok
  def load_modules(path) when is_binary(path) do
    load_modules(["test", "support", path])
  end

  @spec load_modules(list(binary())) :: :ok
  def load_modules(paths) when is_list(paths) do
    paths
    |> Path.join()
    |> recursive_list_dir()
    |> Enum.each(fn path ->
      path
      |> Path.join("*.exs")
      |> Path.wildcard()
      |> Enum.each(fn file ->
        IO.puts("Code.require_file(\"#{file}\")")
        Code.require_file(file)
      end)
    end)
  end

  @spec recursive_list_dir(binary()) :: [binary()]
  defp recursive_list_dir(path) do
    path
    |> list_dir()
    |> then(&Enum.reduce(&1, [path | &1], fn file, dirs -> [recursive_list_dir(file) | dirs] end))
    |> List.flatten()
  end

  @spec dir?(binary(), binary()) :: boolean()
  defp dir?(path, file_name) do
    path
    |> Path.join(file_name)
    |> File.dir?()
  end

  @spec list_dir(binary()) :: [binary()]
  defp list_dir(path) do
    case File.ls(path) do
      {:ok, files} ->
        files
        |> Enum.filter(&dir?(path, &1))
        |> Enum.map(&Path.join(path, &1))

      {:error, _} ->
        []
    end
  end
end

Aurora.Uix.Test.AppLoader.load_app()
