defmodule AuroraUix.RepoHelper do
  @moduledoc """
  Helper module for common repository operations like preloading associations.
  """

  @doc """
  Applies a list of repository options to a struct or list of structs.

  ## Parameters
    - `structs_or_struct` (list | struct | nil): The data to process
    - `repo` (module): The repository module
    - `options` (keyword): List of options to apply. Supports {:preload, associations}

  ## Returns
    - `list | struct | nil`: The processed data with options applied
  """
  @spec options(list | struct | nil, module, keyword) :: list | struct | nil
  def options(structs_or_struct, repo, options \\ [])

  def options(nil, _repo, _options), do: nil

  def options(structs_or_struct, repo, options) do
    Enum.reduce(options, structs_or_struct, &option(&2, repo, &1))
  end

  @spec option(list | struct, module, tuple) :: list | struct
  defp option(structs_or_struct, repo, {:preload, preload}),
    do: repo.preload(structs_or_struct, preload)

  defp option(structs_or_struct, _repo, _option), do: structs_or_struct
end
