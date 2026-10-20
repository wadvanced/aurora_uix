defmodule Aurora.Uix.Templates.Theme.Extension.BuildRules do
  @moduledoc """
  Spark transformer that builds a theme's rule list and defines `rules/0`, `rule_names/0` and
  `rule/1`.

  ## Key Features
  - Rules come in the order they are written. An `include` puts the included theme's rules where
    it is written, and a local rule replaces an included rule of the same name.
  - Resolves the `import_rule/2` markers in local CSS against the theme's rules.

  ## Key Constraints
  - A theme declares each rule name once and has at most one `include`, of a theme module.
  - A theme defining `rule/1` itself fails compilation.
  """

  use Spark.Dsl.Transformer

  alias Aurora.Uix.Templates.Theme
  alias Aurora.Uix.Templates.Theme.Include
  alias Aurora.Uix.Templates.Theme.Rule
  alias Aurora.Uix.Templates.ThemeHelper
  alias Spark.Dsl.Entity
  alias Spark.Dsl.Transformer
  alias Spark.Error.DslError

  @doc false
  @spec transform(map()) :: {:ok, map()}
  def transform(dsl_state) do
    module = Transformer.get_persisted(dsl_state, :module)
    entities = Transformer.get_entities(dsl_state, [:auix_theme])
    includes = for %Include{} = include <- entities, do: include
    local_rules = for %Rule{} = rule <- entities, do: rule
    local_names = Enum.map(local_rules, & &1.name)

    :ok = reject_rule_clauses(module)
    :ok = validate_names(local_rules, module)
    :ok = validate_includes(includes, module)

    rules =
      entities
      |> Enum.flat_map(&entity_rules(&1, local_names))
      |> resolve_imports(module)

    # The included theme is read at compile time, so the theme recompiles with it.
    requires = Enum.map(includes, &quote(do: require(unquote(&1.theme))))

    {:ok, Transformer.eval(dsl_state, [], [requires, Theme.rules_code(rules)])}
  end

  ## PRIVATE

  @spec entity_rules(Rule.t() | Include.t(), [atom()]) :: [Rule.t()]
  defp entity_rules(%Rule{} = rule, _local_names), do: [%{rule | __spark_metadata__: nil}]

  defp entity_rules(%Include{theme: theme}, local_names) do
    for rule <- theme.rules(), rule.name not in local_names do
      %{rule | source: delegated_source(rule.source, theme)}
    end
  end

  @spec delegated_source(Rule.source(), module()) :: Rule.source()
  defp delegated_source(:local, theme), do: {:theme, theme}
  defp delegated_source(source, _theme), do: source

  @spec resolve_imports([Rule.t()], module()) :: [Rule.t()]
  defp resolve_imports(rules, module) do
    css_by_name = Map.new(rules, &{Atom.to_string(&1.name), &1.css})

    Enum.map(rules, fn
      %Rule{source: :local} = rule ->
        %{rule | css: ThemeHelper.resolve_imports(rule.css, css_by_name, module)}

      rule ->
        rule
    end)
  end

  # A 0.1.x theme written with `def rule(...)` clauses would otherwise compile with no rules.
  @spec reject_rule_clauses(module()) :: :ok
  defp reject_rule_clauses(module) do
    if Module.defines?(module, {:rule, 1}),
      do:
        raise(DslError,
          module: module,
          path: [:rule],
          message:
            "def rule/1 clauses are no longer read; declare each rule with `rule :name, css` " <>
              "and the parent theme with `include`"
        ),
      else: :ok
  end

  @spec validate_names([Rule.t()], module()) :: :ok
  defp validate_names(rules, module) do
    case rules -- Enum.uniq_by(rules, & &1.name) do
      [] ->
        :ok

      [rule | _rest] ->
        raise DslError,
          module: module,
          path: [:rule, rule.name],
          location: Entity.anno(rule),
          message: "rule #{inspect(rule.name)} is declared more than once"
    end
  end

  @spec validate_includes([Include.t()], module()) :: :ok
  defp validate_includes([], _module), do: :ok

  defp validate_includes([%Include{theme: theme} = include], module) do
    if match?({:module, _}, Code.ensure_compiled(theme)) and function_exported?(theme, :rules, 0),
      do: :ok,
      else:
        raise(DslError,
          module: module,
          path: [:include, theme],
          location: Entity.anno(include),
          message: "#{inspect(theme)} is not a theme"
        )
  end

  defp validate_includes([_first, second | _rest], module) do
    raise DslError,
      module: module,
      path: [:include],
      location: Entity.anno(second),
      message: "a theme has at most one include"
  end
end
