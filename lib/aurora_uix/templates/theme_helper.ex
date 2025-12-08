defmodule Aurora.Uix.Templates.ThemeHelper do
  @moduledoc """
  Provides helper functions for embedding theme-based styles within `HEEx` templates.

  Offers a convenient way to include compiled or dynamic themeable stylesheets. Leverages
  the configured theme module to apply consistent styling and manage CSS rule generation.
  """

  use Phoenix.Component

  alias Aurora.Uix.Templates.CssSanitizer

  @template Aurora.Uix.Template.uix_template()
  @default_theme @template.default_theme_module()
  @theme_module Application.compile_env(:aurora_uix, :theme_module, @default_theme)

  @doc """
  Generates a complete stylesheet from all rules in the theme module.

  ## Parameters
  - `theme_module` (module()) - The theme module containing rule definitions.

  ## Returns
  list() - List containing all CSS rules from the theme module.

  ## Examples
  ```elixir
  iex> generate_stylesheet(MyApp.Theme)
  ["<style>.button { color: blue; }</style>", "<style>.card { ... }</style>"]
  ```
  """
  def generate_stylesheet(theme_module) do
    rule_names = theme_module.rule_names()

    rule_names
    |> List.flatten()
    |> style(theme_module)
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
  @spec style(list(), module()) :: list()
  defp style(rules, theme) do
    Enum.map(rules, &"#{read_rule(&1, theme)}\n")
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
