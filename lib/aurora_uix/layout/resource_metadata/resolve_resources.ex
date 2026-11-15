defmodule Aurora.Uix.Layout.ResourceMetadata.ResolveResources do
  @moduledoc """
  Spark transformer that resolves the resources declared with `auix_resource_metadata` and
  defines `auix_resources/0` and `auix_resource/1` in the declaring module.

  ## Key Features
  - Runs the resolution in `Aurora.Uix.Layout.ResourceMetadata` once all declarations are read.
  - Links the associations of the declared resources to the resources the module imports with `@auix_resource_metadata`, after the declared ones.
  - Persists the resolved resources as `:auix_resources` for the UI generation
    (`Aurora.Uix.Layout.CreateUI.GenerateUI`).

  ## Key Constraints
  - Defines nothing in a module without resource declarations.
  """

  use Spark.Dsl.Transformer

  alias Aurora.Uix.Counter
  alias Aurora.Uix.Layout.ResourceMetadata
  alias Aurora.Uix.Resource
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
        resources =
          declared
          |> Enum.map(&ResourceMetadata.prepare_resource(&1, module))
          |> Enum.reverse()
          |> ResourceMetadata.resolve_resources(imported_resources(module))

        dsl_state
        |> Transformer.persist(:auix_resources, resources)
        |> Transformer.eval([], ResourceMetadata.resource_functions_code(resources))
        |> then(&{:ok, &1})
    end
  end

  # The resources a module imports by writing `@auix_resource_metadata` by hand.
  @spec imported_resources(module()) :: [{atom(), Resource.t()}]
  defp imported_resources(module) do
    module
    |> Module.get_attribute(:auix_resource_metadata, [])
    |> Enum.flat_map(&Map.to_list/1)
    |> Enum.filter(&match?({_name, %Resource{}}, &1))
    |> Enum.sort_by(&elem(&1, 0))
  end
end
