defmodule Aurora.Uix.Dsl do
  @moduledoc """
  The Spark DSL behind `use Aurora.Uix`.

  ## Key Features
  - Brings in the resource metadata DSL (`Aurora.Uix.Layout.ResourceMetadata`) and the UI and
    layout DSL (`Aurora.Uix.Layout.CreateUI`).
  - Starts every module from a clean Spark builder state, so a DSL error in an earlier module
    compiled by the same process does not break the next one.

  ## Key Constraints
  - Used through `use Aurora.Uix`.
  """

  use Spark.Dsl,
    default_extensions: [
      extensions: [Aurora.Uix.Layout.ResourceMetadata, Aurora.Uix.Layout.CreateUI]
    ]

  # Spark builds nested entities in the process dictionary and restores it only when the
  # entity finishes; a DSL error raised inside a nested entity leaves the state behind, and the
  # next module compiled in the process fails with an unrelated error.
  @builder_keys [:recursive_builder_path, :parent_recursive_as]
  @builder_path_keys [:builder_opts, :builder_opts_anno, :builder_anno]

  @impl Spark.Dsl
  def handle_opts(_opts) do
    quote do
      Aurora.Uix.Dsl.reset_builder_state()
    end
  end

  @doc """
  Removes the entity builder state Spark keeps in the process dictionary.

  Called at the top of every module that uses `Aurora.Uix`, before any DSL entity is read.
  A module starts no entity of its own before this point, so whatever state exists belongs to
  an earlier compilation that failed.
  """
  @spec reset_builder_state() :: :ok
  def reset_builder_state do
    Enum.each(Process.get_keys(), &delete_builder_key/1)
  end

  @spec delete_builder_key(term()) :: term()
  defp delete_builder_key(key) when key in @builder_keys, do: Process.delete(key)

  defp delete_builder_key({kind, _path} = key) when kind in @builder_path_keys,
    do: Process.delete(key)

  defp delete_builder_key(_key), do: nil
end
