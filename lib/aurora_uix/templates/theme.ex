defmodule Aurora.Uix.Templates.Theme do
  @moduledoc ~S/
  Defines the behaviour for a theme module in `Aurora.Uix`.

  A theme module provides the CSS rules that style the components. `use Aurora.Uix.Templates.Theme`
  brings in the theme DSL: `rule name, css` declares a rule, `include Theme` takes every rule of
  another theme that the module does not declare, and `import_rule(source, target)` copies another rule of the
  theme inside a rule's CSS.

  ## Example

  ```elixir
  defmodule MyApp.Theme do
    use Aurora.Uix.Templates.Theme, theme_name: :my_theme

    rule :root, """
    :root {
      --primary-color: #3b82f6;
      --secondary-color: #6b7280;
    }
    """

    rule :button, """
    .button {
      background-color: var(--primary-color);
      color: white;
      padding: 0.5rem 1rem;
      border-radius: 0.25rem;
    }
    """

    include Aurora.Uix.Templates.Basic.Themes.ThemeBase
  end
  ```

  ## Key Constraints
  - Rule CSS is built when the theme compiles, so it cannot call the theme's own functions.
  - A theme declares each rule name once and has at most one `include`.
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
  Brings in the theme DSL (`rule` and `include`) and the `Theme` behaviour.

  ## Options
  - `:theme_name` (atom()) - The theme's name, also available as `@theme_name` in the rules.
  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts \\ []) do
    quote do
      use Aurora.Uix.Templates.Theme.Definition

      import Aurora.Uix.Templates.ThemeHelper, only: [import_rule: 2]

      Module.register_attribute(__MODULE__, :theme_name, accumulate: false)
      Theme.__process_options(__MODULE__, unquote(opts))
      @behaviour Theme

      @doc false
      @spec theme_name() :: atom()
      def theme_name, do: @theme_name
    end
  end

  @doc """
  Returns the code defining a theme's `rules/0`, `rule_names/0` and `rule/1`.

  ## Parameters
  - `rules` ([Rule.t()]) - The theme's rules, in stylesheet order.

  ## Returns
  `Macro.t()` - The function definitions. `rule/1` gives `""` for a name the theme does not have.
  """
  @spec rules_code([Rule.t()]) :: Macro.t()
  def rules_code(rules) do
    css_by_name = Map.new(rules, &{&1.name, &1.css})

    quote do
      @doc false
      @spec rules() :: [Rule.t()]
      def rules do
        unquote(Macro.escape(rules))
      end

      @doc false
      @spec rule_names() :: [atom()]
      def rule_names do
        unquote(Enum.map(rules, & &1.name))
      end

      @doc false
      @spec rule(atom()) :: binary()
      def rule(name) do
        Map.get(unquote(Macro.escape(css_by_name)), name, "")
      end
    end
  end

  @doc false
  @spec __process_options(module(), keyword()) :: :ok
  def __process_options(module, options) do
    Enum.each(options, &process_option(module, &1))
  end

  ## PRIVATE

  @spec process_option(module(), tuple()) :: any()
  defp process_option(module, {:theme_name, theme_name}),
    do: Module.put_attribute(module, :theme_name, theme_name)

  defp process_option(_module, _option), do: :ok
end
