defmodule Aurora.Uix.Templates.Theme do
  alias Aurora.Uix.Templates.Theme
  @callback rule(rule :: atom()) :: binary()

  @callback rule_names() :: list()

  defmacro __using__(_opts) do
    quote do
      @behaviour Theme

      @before_compile Theme
    end
  end

  defmacro __before_compile__(env) do
    module = env.module

    rule_names =
      module
      |> Module.get_definition({:rule, 1})
      |> elem(3)
      |> Enum.map(&get_rule_names/1)
      |> process_alias_modules()
      |> Enum.reject(&(is_nil(&1) or &1 == :_))
      |> Enum.uniq()

    quote do
      def rule_names, do: unquote(rule_names)
    end
  end

  defp get_rule_names(clause) do
    clause
    |> process_clause()
    |> process_contents()
  end

  defp process_clause({_line_column, [{name, _, _}], _guards, contents}) do
    {name, contents}
  end

  defp process_clause({_line_column, [name], _guards, contents}) do
    {name, contents}
  end

  defp process_contents({_name, {{_init, _def_pos, [module, :rule]}, _arg_pos, _rule_metadata}}),
    do: module

  defp process_contents({name, _contents}), do: name

  defp process_alias_modules(clauses) do
    Enum.map(clauses, &module_rules/1)
  end

  defp module_rules(module) when is_atom(module) do
    with {:module, module} <- Code.ensure_compiled(module),
         true <- {:rule_names, 0} in module.__info__(:functions) do
      module.rule_names()
    else
      {:error, _} -> module
      _ -> nil
    end
  end
end
