defmodule Aurora.Uix.Templates.ThemeHelper do
  @moduledoc """
  Provides the `~AH` sigil to embed theme-based compiled time styles within `HEEx` templates.

  This module offers a convenient way to include compiled or dynamic themeable stylesheets.
  It allows you to apply CSS rules per component, per tag or the entire stylesheets from the configured theme module.

  ## Key Features

  - **Themed Styles**: Leverages the configured theme module to apply consistent styling.
  - **Inline CSS Rules**: Define component-specific styles directly in the template.
  - **Scanneable CSS Rules by Markers**: Use `!expression!` syntax automatically include `expression` css rule.

  ## Compile Time Style Generation Usage

  With the `~AH`, first, add `import Aurora.Uix.Templates.ThemeHelper` to the module where you want to use it,
  then use the `~AH` sigil instead of `~H` sigil.

  ### Example
  #### Defining style for the component
    ```elixir
    def my_component(assigns) do
      ~AH""
        :css_rules: my-component, button
        <div class="my-component">
          <.button class="button">Click me</.button>
        </div>
      ""
    end
    ```
    Will be transformed into HEEX equivalent:
    ```elixir
    def my_component(assigns) do
      ~H""
        <style>
          .my-component {
            /* css rules for my-component */
          }
          .my-component:hover {
            /* css rules for my-component when hovering */
          }
          .button{
            /* css rules for button'
          }
        </style>
        <div class="my-component">
          <.button class="button">Click me</.button>
        </div>
      ""
    end
    ```

  #### Defining the style by marking the css_rules

    ```elixir
    def my_component(assigns) do
      ~AH""
        <div class="!my-component!">
          <.button class="!button!">Click me</.button>
        </div>
      ""
    end
    ```

    Will pick the needed rules by scanning !expression!. The above example will produce the following HEEX:

    ```elixir
    def my_component(assigns) do
      ~H""
        <style>
          .my-component {
            /* css rules for my-component */
          }
          .my-component:hover {
            /* css rules for my-component when hovering */
          }
          .button{
            /* css rules for button'
          }
        </style>
        <div class="my-component">
          <.button class="button">Click me</.button>
        </div>
      ""
    end
    ```

  """

  use Phoenix.Component

  @css_rule_marker "css_rules:"
  @template Aurora.Uix.Template.uix_template()
  @default_theme @template.default_theme_module()
  @theme Application.compile_env(:aurora_uix, :theme_module, @default_theme)

  @doc """
  A sigil to embed theme-based styles within `HEEx` templates.

  It processes the content inside the sigil to extract CSS rule definitions,
  scans for dynamic expressions, and generates a `<style>` tag with the
  corresponding themed CSS rules. See `Phoenix.Component.sigil_H/2` for details on the parameters.

  ## Returns

  An `EEx` compiled string containing the generated `<style>` tag and the processed `HEEx` content.

  ## Raises

  - `RuntimeError` - If the `assigns` variable is not available in the calling context.

  """
  @spec sigil_AH(tuple(), list()) :: Macro.t()
  defmacro sigil_AH({:<<>>, meta, [expr]}, modifiers)
           when modifiers == [] or modifiers == ~c"noformat" do
    if not Macro.Env.has_var?(__CALLER__, {:assigns, nil}) do
      raise "~H requires a variable named \"assigns\" to exist and be set to a map"
    end

    scanned_rules = scan_rules(expr)

    styles = generate_style(scanned_rules)

    expr =
      expr
      |> remove_scanned_rules(scanned_rules)
      |> add_styles(styles)

    options = [
      engine: Phoenix.LiveView.TagEngine,
      file: __CALLER__.file,
      line: __CALLER__.line + 1,
      caller: __CALLER__,
      indentation: meta[:indentation] || 0,
      source: expr,
      tag_handler: Phoenix.LiveView.HTMLEngine
    ]

    EEx.compile_string(expr, options)
  end

  # PRIVATE

  # Scans the expression for CSS rule markers, dynamic expressions, and stylesheets.
  @spec scan_rules(binary()) :: list()
  defp scan_rules(expr) do
    expr
    |> String.split("\n")
    |> Enum.filter(&Regex.match?(~r/^[ \t]*#{@css_rule_marker}/, &1))
    |> Enum.map(&rule_names_from_line/1)
    |> scan_expressions(expr)
    |> detect_stylesheet(expr)
  end

  # Extracts rule names from a line containing the CSS rule marker.
  @spec rule_names_from_line(binary()) :: {binary(), list(), binary()}
  defp rule_names_from_line(line) do
    line
    |> String.replace("#{@css_rule_marker} ", "")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> then(&{"#{line}\n", &1, ""})
  end

  # Scans for dynamic expressions in the form of `!expression!`.
  @spec scan_expressions(list(), binary()) :: list()
  defp scan_expressions(scanned_rules, expr) do
    ~r/![a-z][0-9a-z-]*!/
    |> Regex.scan(expr)
    |> List.flatten()
    |> Enum.map(&String.slice(&1, 1..-2//1))
    |> Enum.reduce(scanned_rules, &[{"!#{&1}!", &1, &1} | &2])
    |> List.flatten()
  end

  # Detects the presence of a stylesheet marker and returns all rule names from the theme.
  @spec detect_stylesheet(list(), binary()) :: list()
  defp detect_stylesheet(scanned_rules, expr) do
    stylesheet =
      ~r/^[ \t]*:stylesheet:[ \t]*/
      |> Regex.scan(expr)
      |> List.flatten()

    if stylesheet == [] do
      scanned_rules
    else
      Enum.reduce(stylesheet, [], &[{&1, @theme.rule_names(), ""} | &2])
    end
  end

  # Generates the final CSS string from the list of rule lines.
  @spec generate_style(list()) :: binary()
  defp generate_style(rule_lines) do
    rule_lines
    |> List.flatten()
    |> Enum.reduce([], fn {_rule_line, rule_name, _replacement}, acc -> [rule_name | acc] end)
    |> List.flatten()
    |> style()
  end

  # Removes the scanned rule lines from the expression.
  @spec remove_scanned_rules(binary(), list()) :: binary()
  defp remove_scanned_rules(expr, scanned_rules) do
    Enum.reduce(scanned_rules, expr, fn {rule_line, _rule_name, replacement}, acc ->
      String.replace(acc, rule_line, replacement)
    end)
  end

  # Adds the generated styles to the expression.
  @spec add_styles(binary(), binary()) :: binary()
  defp add_styles(expr, styles) do
    "#{styles}\n#{expr}"
  end

  # Generates the `<style>` tag with the CSS rules.
  @spec style(list(binary())) :: binary()
  defp style(rules) do
    css_rules =
      rules
      |> Enum.map_join(" ", &read_rule/1)
      |> maybe_add_root(rules)

    """
    <style>
      #{css_rules}
    </style>
    """
  end

  # Reads a single CSS rule from the theme.
  @spec read_rule(binary()) :: binary()
  defp read_rule(rule) do
    rule
    |> convert_dashes()
    |> @theme.rule()
  end

  # Converts a string with dashes to a snake_case atom.
  @spec convert_dashes(binary()) :: atom()
  defp convert_dashes(rule) do
    rule
    |> to_string()
    |> String.replace("-", "_")
    |> String.to_atom()
  end

  # Adds the `:root` rule if CSS variables are used and the `:root` rule is not already present.
  @spec maybe_add_root(binary(), list()) :: binary()
  defp maybe_add_root(parsed_css_rules, rule_names) do
    with false <- Enum.any?(rule_names, &(&1 == :root)),
         true <- String.contains?(parsed_css_rules, "var(--") do
      @theme.rule(:root) <> parsed_css_rules
    else
      _ -> parsed_css_rules
    end
  end
end
