defmodule Aurora.Uix.Test.Cases.FormatterExportsTest do
  use ExUnit.Case, async: true

  alias Spark.Dsl.Entity

  @extensions [
    Aurora.Uix.Layout.ResourceMetadata,
    Aurora.Uix.Layout.CreateUI,
    Aurora.Uix.Templates.Theme.Extension,
    Aurora.Uix.Layout.Options.Extension
  ]

  test ".formatter.exs exports every call of the DSL without parentheses" do
    {formatter, _bindings} = Code.eval_file(".formatter.exs")
    exported = Keyword.fetch!(formatter[:export], :locals_without_parens)

    assert Enum.sort(exported) == dsl_calls()
  end

  # Same rule as `mix spark.formatter`: an entity at its required and optional
  # argument counts (plus one for the keyword list), and every option as `name/1`.
  @spec dsl_calls() :: [{atom(), non_neg_integer()}]
  defp dsl_calls do
    @extensions
    |> Enum.flat_map(fn extension -> Enum.flat_map(extension.sections(), &section_calls/1) end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec section_calls(struct()) :: [{atom(), non_neg_integer()}]
  defp section_calls(section) do
    Enum.flat_map(section.entities, &entity_calls/1) ++
      Enum.map(section.schema, fn {key, _config} -> {key, 1} end) ++
      Enum.flat_map(section.sections, &section_calls/1)
  end

  @spec entity_calls(struct()) :: [{atom(), non_neg_integer()}]
  defp entity_calls(entity) do
    required = Enum.count(entity.args, &is_atom/1)

    builders =
      Enum.flat_map(required..length(entity.args), &[{entity.name, &1}, {entity.name, &1 + 1}])

    options =
      entity.schema
      |> Keyword.drop(Entity.required_arg_names(entity))
      |> Enum.map(fn {key, _config} -> {key, 1} end)

    nested =
      Enum.flat_map(entity.entities, fn {_key, entities} ->
        entities |> List.wrap() |> Enum.flat_map(&entity_calls/1)
      end)

    builders ++ options ++ nested
  end
end
