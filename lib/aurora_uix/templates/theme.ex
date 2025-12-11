defmodule Aurora.Uix.Templates.Theme do
  @moduledoc ~S/
  Defines the behaviour for a theme module in `Aurora.Uix`.

  A theme module is responsible for providing the CSS rules that are used to style the components.
  This module provides the `__using__` macro to inject the necessary behaviour and callbacks into your theme module.

  ## Example

  ```elixir
  defmodule MyApp.Theme do
    use Aurora.Uix.Templates.Theme

    def rule(:root) do
      """
      :root {
        --primary-color: #3b82f6;
        --secondary-color: #6b7280;
      }
      """
    end

    def rule(:button) do
      """
      .button {
        background-color: var(--primary-color);
        color: white;
        padding: 0.5rem 1rem;
        border-radius: 0.25rem;
      }
      """
    end
  end
  ```
  /

  alias Aurora.Uix.Templates.Theme

  @doc """
  Callback that should return the CSS rule for a given rule name.

  ## Parameters

  - `rule` (atom()) - The name of the rule.

  ## Returns

  (binary()) - The CSS rule as a string.
  """
  @callback rule(rule :: atom()) :: binary()

  @doc """
  Callback that should return a list of all available rule names in the theme.

  ## Returns

  (list(atom())) - A list of rule names.
  """
  @callback rule_names() :: list()

  @doc """
  Injects the `Theme` behaviour and callbacks into the calling module.
  """
  @spec __using__(any()) :: Macro.t()
  defmacro __using__(opts \\ []) do
    quote do
      Module.register_attribute(__MODULE__, :theme_name, accumulate: false)
      Theme.__process_options(__MODULE__, unquote(opts))
      @behaviour Theme

      @before_compile Theme
    end
  end

  @doc """
  Injects the `rule_names/0` function into the module before compilation.

  This function is generated based on the `rule/1` function definitions in the module.
  """
  @spec __before_compile__(Macro.Env.t()) :: Macro.t()
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
      @doc false
      @spec rule_names() :: list()
      def rule_names, do: List.flatten(unquote(rule_names))

      @doc false
      @spec theme_name() :: atom()
      def theme_name, do: @theme_name
    end
  end

  @doc false
  @spec __process_options(module(), keyword()) :: :ok
  def __process_options(module, options) do
    Enum.each(options, &process_option(module, &1))
  end

  ## PRIVATE

  @spec get_rule_names(tuple()) :: atom() | nil
  defp get_rule_names(clause) do
    clause
    |> process_clause()
    |> process_contents()
  end

  @spec process_clause(tuple()) :: {atom() | tuple(), any()}
  defp process_clause({_line_column, [{name, _, _}], _guards, contents}) do
    {name, contents}
  end

  defp process_clause({_line_column, [name], _guards, contents}) do
    {name, contents}
  end

  @spec process_contents({atom() | tuple(), any()}) :: atom() | nil
  defp process_contents({_name, {{_init, _def_pos, [module, :rule]}, _arg_pos, _rule_metadata}}),
    do: module

  defp process_contents({name, _contents}), do: name

  @spec process_alias_modules(list(atom() | nil)) :: list(atom() | nil)
  defp process_alias_modules(clauses) do
    Enum.map(clauses, &module_rules/1)
  end

  @spec module_rules(atom() | nil) :: atom() | nil
  defp module_rules(module) when is_atom(module) do
    with {:module, module} <- Code.ensure_compiled(module),
         true <- {:rule_names, 0} in module.__info__(:functions) do
      module.rule_names()
    else
      {:error, _} -> module
      _ -> nil
    end
  end

  @spec process_option(module(), tuple()) :: any()
  defp process_option(module, {:theme_name, theme_name}),
    do: Module.put_attribute(module, :theme_name, theme_name)

  defp process_option(_module, _option), do: :ok
end
