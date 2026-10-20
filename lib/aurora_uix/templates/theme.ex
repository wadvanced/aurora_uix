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
  alias Aurora.Uix.Templates.Theme.Rule

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
  Callback that should return the theme's rules, in stylesheet order.

  ## Returns

  ([Rule.t()]) - One `Aurora.Uix.Templates.Theme.Rule` per rule name.
  """
  @callback rules() :: [Rule.t()]

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
  Injects `rules/0` and `rule_names/0` into the module before compilation.

  The rule names and their sources come from the `rule/1` clause heads. A clause delegating to
  another theme (`def rule(rule), do: OtherTheme.rule(rule)`) brings in that theme's rules.
  """
  @spec __before_compile__(Macro.Env.t()) :: Macro.t()
  defmacro __before_compile__(env) do
    entries =
      env.module
      |> Module.get_definition({:rule, 1})
      |> elem(3)
      |> Enum.map(&get_rule_names/1)
      |> Enum.flat_map(&rule_entries/1)
      |> Enum.uniq_by(&elem(&1, 0))

    quote do
      @doc false
      @spec rules() :: [Rule.t()]
      def rules, do: Theme.build_rules(__MODULE__, unquote(Macro.escape(entries)))

      @doc false
      @spec rule_names() :: [atom()]
      def rule_names, do: Enum.map(rules(), & &1.name)

      @doc false
      @spec theme_name() :: atom()
      def theme_name, do: @theme_name
    end
  end

  @doc """
  Builds the rules of a theme from its rule names and their sources.

  ## Parameters
  - `module` (module()) - The theme module; its `rule/1` gives each rule's CSS.
  - `entries` ([{atom(), Rule.source()}]) - The rule names, in stylesheet order, with their
    sources.

  ## Returns
  `[Rule.t()]` - The theme's rules.
  """
  @spec build_rules(module(), [{atom(), Rule.source()}]) :: [Rule.t()]
  def build_rules(module, entries) do
    Enum.map(entries, fn {name, source} ->
      %Rule{name: name, css: module.rule(name), source: source}
    end)
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

  # A clause named after a rule is a local rule; a clause delegating to another theme brings in
  # that theme's rules, keeping where each one comes from.
  @spec rule_entries(atom() | nil) :: [{atom(), Rule.source()}]
  defp rule_entries(name) when name in [nil, :_], do: []

  defp rule_entries(name) do
    if theme_module?(name) do
      Enum.map(name.rules(), &{&1.name, delegated_source(&1.source, name)})
    else
      [{name, :local}]
    end
  end

  @spec theme_module?(atom()) :: boolean()
  defp theme_module?(name) do
    match?({:module, _}, Code.ensure_compiled(name)) and function_exported?(name, :rules, 0)
  end

  @spec delegated_source(Rule.source(), module()) :: Rule.source()
  defp delegated_source(:local, module), do: {:theme, module}
  defp delegated_source(source, _module), do: source

  @spec process_option(module(), tuple()) :: any()
  defp process_option(module, {:theme_name, theme_name}),
    do: Module.put_attribute(module, :theme_name, theme_name)

  defp process_option(_module, _option), do: :ok
end
