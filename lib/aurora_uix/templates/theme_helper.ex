defmodule Aurora.Uix.Templates.ThemeHelper do
  @moduledoc """
  Provides helper functions for embedding theme-based styles within `HEEx` templates.

  Offers a convenient way to include compiled or dynamic themeable stylesheets, allowing
  CSS rules to be applied per component, per tag, or as entire stylesheets from the
  configured theme module.

  ## Key Features

  - **Themed Styles**: Leverages the configured theme module to apply consistent styling
  - **Runtime CSS Generation**: Components for dynamically generating CSS at runtime
  - **Theme Module Management**: Access and generate complete stylesheets from themes
  - **Compile-Time or Dynamic Themes**: Choose between static injection for performance
    or runtime theme swapping for flexibility

  ## Usage

  Import `Aurora.Uix.Templates.ThemeHelper` to access the CSS helper components.

  ### Using `css_rules` Component

  Generate style tags with specific CSS rules:

  ```elixir
  def my_component(assigns) do
    ~H\"\"\"
    <.css_rules rules={[:my_component, :button]} />
    <div class="my-component">
      <button class="button">Click me</button>
    </div>
    \"\"\"
  end
  ```

  ### Using `stylesheet` Component

  Include complete stylesheet content:

  ```elixir
  def my_component(assigns) do
    ~H\"\"\"
    <.stylesheet stylesheet={@theme_styles} />
    <div class="my-component">
      <button class="button">Click me</button>
    </div>
    \"\"\"
  end
  ```

  ## Style Duplication

  When using `css_rules` within reusable components, the same CSS rules might be
  duplicated if the component is used multiple times on the same page. To avoid this,
  generate and include all necessary styles once at the top-level LiveView.

  ## Dynamic vs. Compile-Time Themes

  By default, Aurora.Uix operates in **compile-time theme** mode. The theme module is
  determined at compile time, and CSS rules are injected into HEEx templates as static
  text. This is the most performant option as it avoids runtime computation for styles.

  Enable **dynamic themes** by setting `config :aurora_uix, :dynamic_themes, true`. When
  enabled, the theme can be swapped at runtime. The `css_rules/1` component will fetch
  the appropriate CSS rules from the currently active theme at runtime.

  The main consequence of enabling dynamic themes is a performance trade-off. While it
  offers flexibility, it introduces runtime overhead for generating styles on every
  render.
  """

  use Phoenix.Component

  import Phoenix.HTML, only: [raw: 1]

  alias Aurora.Uix.Templates.CssSanitizer
  alias Phoenix.LiveView.Rendered

  @template Aurora.Uix.Template.uix_template()
  @default_theme @template.default_theme_module()
  @theme_module Application.compile_env(:aurora_uix, :theme_module, @default_theme)
  @dynamic_themes Application.compile_env(:aurora_uix, :dynamic_themes, false)

  @doc """
  Generates `<style>` tags with named themed CSS rules at runtime.

  Accepts either a specific theme module or uses the configured default theme module.
  When no theme module is provided, respects the dynamic themes configuration.

  ## Parameters

  - `assigns` (`map()`) - Map containing the CSS rules to be included:
    - `:rules` - List of CSS rule names to fetch from the theme module
    - `:theme_module` (optional) - Atom representing the theme module to use

  ## Returns

  `Phoenix.LiveView.Rendered.t()` - Struct containing the `<style>` tag with the
  requested CSS rules.

  ## Examples

      iex> css_rules(%{rules: [:button, :card]})
      %Phoenix.LiveView.Rendered{static: ["<style>\\n  ", "\\n</style>\\n"]}

      iex> css_rules(%{rules: [:button], theme_module: MyApp.CustomTheme})
      %Phoenix.LiveView.Rendered{static: ["<style>\\n  ", "\\n</style>\\n"]}
  """
  attr(:rules, :list, default: [])
  attr(:theme_module, :atom, default: nil)
  @spec css_rules(map()) :: Rendered.t()
  def css_rules(%{rules: rule_names, theme_module: theme_module}) when is_nil(theme_module) do
    theme_module =
      if @dynamic_themes,
        do: Application.get_env(:aurora_uix, :theme_module, @theme_module),
        else: @theme_module

    generate_css_rules(theme_module, rule_names)
  end

  def css_rules(%{rules: rule_names, theme_module: theme_module}) do
    generate_css_rules(theme_module, rule_names)
  end

  @doc """
  Generates `<style>` tags with the full stylesheet content.

  ## Parameters

  - `assigns` (`map()`) - Map with the stylesheet content:
    - `:stylesheet` - String containing the complete stylesheet CSS

  ## Returns

  `Phoenix.LiveView.Rendered.t()` - Struct containing the stylesheet wrapped in raw HTML.

  ## Examples

      iex> stylesheet(%{stylesheet: ".button { color: blue; }"})
      %Phoenix.LiveView.Rendered{static: ["\\n  ", "\\n"]}
  """
  attr(:stylesheet, :string, default: "")
  @spec stylesheet(map()) :: Rendered.t()
  def stylesheet(assigns) do
    ~H"""
      <%= raw(@stylesheet) %>
    """
  end

  @doc """
  Generates a complete stylesheet from all rules in the theme module.

  ## Parameters

  - `theme_module` (`module()`) - The theme module containing rule definitions

  ## Returns

  `binary()` - String containing all CSS rules from the theme module.

  ## Examples

      iex> generate_stylesheet(MyApp.Theme)
      "<style>.button { color: blue; }</style>\\n<style>.card { ... }</style>\\n"
  """
  @spec generate_stylesheet(module()) :: binary()
  def generate_stylesheet(theme_module) do
    rule_names = theme_module.rule_names()

    rule_names
    |> List.flatten()
    |> style(theme_module, false)
  end

  @doc """
  Generates CSS rules from a theme module and wraps them in a `<style>` tag.

  Reads the specified CSS rules from the theme module, processes them, and returns
  a rendered component with the styles ready for inclusion in a template.

  ## Parameters

  - `theme_module` (`module()`) - The theme module containing CSS rule definitions
  - `rule_names` (`list()`) - List of CSS rule names (atoms or strings) to include

  ## Returns

  `Phoenix.LiveView.Rendered.t()` - Struct containing the `<style>` tag with the
  processed CSS rules.

  ## Examples

      iex> generate_css_rules(MyApp.Theme, [:button, :card])
      %Phoenix.LiveView.Rendered{static: ["<style>\\n  ", "\\n</style>\\n"]}
  """
  @spec generate_css_rules(module(), list()) :: Rendered.t()
  def generate_css_rules(theme_module, rule_names) do
    assigns =
      rule_names
      |> Enum.map_join(" ", &read_rule(&1, theme_module))
      |> then(&%{css_rules: &1})

    ~H"""
    <style>
      <%= raw(@css_rules) %>
    </style>
    """
  end

  @doc """
  Returns the configured theme module.

  ## Returns

  `module()` - The theme module configured at compile time.

  ## Examples

      iex> theme_module()
      Aurora.Uix.Themes.Default
  """
  @spec theme_module() :: module()
  def theme_module do
    @theme_module
  end

  @doc """
  Extracts the rule contents and replace and create a new rule using the target_name.

  ## Parameters
  - `rule_source` (`atom()`) - rule name to import from.
  - `target_name` (`binary()` | `atom()`) - rule to create.

  ## Returns
  - `binary()` - The new css rule.

  """
  @spec import_rule(atom(), binary() | atom()) :: Macro.t()
  defmacro import_rule(rule_source, target_name) do
    parsed_rule_source =
      rule_source
      |> to_string()
      |> String.replace("_", "-")

    parsed_target_name =
      target_name
      |> to_string()
      |> String.replace("_", "-")

    quote do
      unquote(rule_source)
      |> rule()
      |> then(
        &Regex.replace(
          ~r"\.#{unquote(parsed_rule_source)}\b",
          &1,
          ".#{unquote(parsed_target_name)}"
        )
      )
    end
  end

  ## PRIVATE

  # Generates the `<style>` tag with the CSS rules.
  # For dynamic themes, generates a component call. For static themes, embeds CSS directly.
  @spec style(list(), module(), boolean()) :: binary()
  defp style(rules, theme, dynamic_themes?) do
    if dynamic_themes? do
      css_rules = Enum.map_join(rules, ", ", &":#{&1}")

      """
      <.css_rules rules={[#{css_rules}]} />
      """
    else
      Enum.map(rules, &"<style>#{read_rule(&1, theme)}</style>\n")
    end
  end

  # Reads a single CSS rule from the theme.
  # Converts dashed names to snake_case atoms and fetches the rule from the theme module.
  @spec read_rule(binary() | atom(), module()) :: binary()
  defp read_rule(rule, theme) do
    rule
    |> convert_dashes()
    |> theme.rule()
    |> trim_rule()
    |> CssSanitizer.sanitize_css()
  end

  # Trims unnecessary whitespace and comments from a CSS rule.
  # Removes CSS comments and excessive whitespace while preserving structure.
  @spec trim_rule(binary()) :: binary()
  defp trim_rule(rule) do
    rule
    |> String.replace(~r"/\*.+\*/", "")
    |> String.trim()
    |> replace_conditionally(~r/[ \t\n]+\n/, "\n")
  end

  # Recursively replaces matches of a regex pattern until no more matches are found.
  # Used to normalize whitespace in CSS rules.
  @spec replace_conditionally(binary(), Regex.t(), binary()) :: binary()
  defp replace_conditionally(rule, finder, replacement) do
    if Regex.scan(finder, rule) != [] do
      rule
      |> String.replace(finder, replacement)
      |> replace_conditionally(finder, replacement)
    else
      rule
    end
  end

  # Converts a string with dashes to a snake_case atom.
  # Used to convert CSS class names (kebab-case) to Elixir function names (snake_case).
  @spec convert_dashes(binary() | atom()) :: atom()
  defp convert_dashes(rule) do
    rule
    |> to_string()
    |> String.replace("-", "_")
    |> String.to_atom()
  end
end
