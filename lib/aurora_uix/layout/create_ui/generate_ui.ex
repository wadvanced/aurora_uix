defmodule Aurora.Uix.Layout.CreateUI.GenerateUI do
  @moduledoc """
  Spark transformer that generates the UI declared with `auix_create_ui`.

  ## Key Features
  - Collects the layouts of `auix_create_ui` and `auix_create_layout`, validates them against
    the resources resolved by `Aurora.Uix.Layout.ResourceMetadata.ResolveResources`, and
    evaluates the generated code in the declaring module.

  ## Key Constraints
  - Generates nothing in a module without `auix_create_ui`.
  - A module holds at most one `auix_create_ui`.
  """

  use Spark.Dsl.Transformer

  alias Aurora.Uix.Layout.CreateUI
  alias Aurora.Uix.Layout.ResourceMetadata.ResolveResources
  alias Spark.Dsl.Transformer
  alias Spark.Error.DslError

  @doc false
  @spec after?(module()) :: boolean()
  def after?(ResolveResources), do: true
  def after?(_transformer), do: false

  @doc false
  @spec transform(map()) :: {:ok, map()}
  def transform(dsl_state) do
    calls = Transformer.get_entities(dsl_state, [:auix_ui])
    module = Transformer.get_persisted(dsl_state, :module)

    case Enum.filter(calls, &(&1.kind == :auix_create_ui)) do
      [] ->
        {:ok, dsl_state}

      [ui] ->
        resources = resources(dsl_state, module)
        layouts = CreateUI.collect_layouts(calls, module)
        :ok = CreateUI.validate_layouts(layouts, resources, module)

        module
        |> CreateUI.ui_code(layouts, resources, CreateUI.ui_opts(ui))
        |> then(&{:ok, Transformer.eval(dsl_state, [], &1)})

      _several ->
        raise DslError,
          module: module,
          path: [:auix_create_ui],
          message: "a module holds one auix_create_ui"
    end
  end

  # The declared resources, plus any a module writes to `@auix_resource_metadata` by hand.
  @spec resources(map(), module()) :: map()
  defp resources(dsl_state, module) do
    module
    |> Module.get_attribute(:auix_resource_metadata, [])
    |> Enum.reduce(%{}, &Map.merge(&2, &1))
    |> Map.merge(Transformer.get_persisted(dsl_state, :auix_resources, %{}))
  end
end
