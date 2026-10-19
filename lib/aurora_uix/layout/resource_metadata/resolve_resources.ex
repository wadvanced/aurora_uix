defmodule Aurora.Uix.Layout.ResourceMetadata.ResolveResources do
  @moduledoc """
  Spark transformer that resolves the resources declared with `auix_resource_metadata` and
  defines `auix_resources/0` and `auix_resource/1` in the declaring module.

  ## Key Features
  - Runs the resolution in `Aurora.Uix.Layout.ResourceMetadata` once all declarations are read.

  ## Key Constraints
  - Defines nothing in a module without resource declarations.
  """

  use Spark.Dsl.Transformer

  alias Aurora.Uix.Counter
  alias Aurora.Uix.Layout.ResourceMetadata
  alias Spark.Dsl.Transformer

  @doc false
  @spec transform(map()) :: {:ok, map()}
  def transform(dsl_state) do
    case Transformer.get_entities(dsl_state, [:auix_resources]) do
      [] ->
        {:ok, dsl_state}

      declared ->
        module = Transformer.get_persisted(dsl_state, :module)
        Counter.start_counter(:auix_fields)

        # Resolution expects the latest declaration first.
        declared
        |> Enum.map(&ResourceMetadata.prepare_resource(&1, module))
        |> Enum.reverse()
        |> ResourceMetadata.resolve_resources()
        |> ResourceMetadata.resource_functions_code()
        |> then(&{:ok, Transformer.eval(dsl_state, [], &1)})
    end
  end
end
