defmodule Aurora.Uix.Templates.ThemeHelper do
  @moduledoc """
  Provides helper functions for embedding theme-based styles within `HEEx` templates.

  Offers a convenient way to include compiled or dynamic themeable stylesheets. Leverages
  the configured theme module to apply consistent styling and manage CSS rule generation.

  The stylesheet is split across three files:

    * `auix-variables.css` — `:root` variable declarations and palette colors.
    * `auix-rules.css` — `.auix-*` component rules.
    * `auix-baseline.css` — tag-selector reset for hosts **without** a CSS preflight.
      Tailwind hosts should ignore this file; non-Tailwind hosts `@import` it before
      `auix-variables.css`.
  """

  use Phoenix.Component

  alias Aurora.Uix.BehaviourHelper
  alias Aurora.Uix.Helpers.Common, as: CommonHelper
  alias Aurora.Uix.Templates.Basic.Themes.Baseline
  alias Aurora.Uix.Templates.CssSanitizer
  alias Aurora.Uix.Templates.Theme

  @template Aurora.Uix.Template.uix_template()
  @default_theme_name @template.default_theme_name()
  @theme_name Application.compile_env(:aurora_uix, :theme_name, @default_theme_name)

  @doc """
  Generates a complete stylesheet from all rules in the theme module.

  ## Returns
  binary() - All the :root_colors from all the registered themes plus 
    the CSS rules from the configured theme module.

  ## Examples
  ```elixir
  iex> generate_stylesheet(MyApp.Theme)
  ["<style>.button { color: blue; }</style>", "<style>.card { ... }</style>"]
  ```
  """
  @spec generate_stylesheet() :: binary()
  def generate_stylesheet do
    generate_variables_stylesheet() <> "\n" <> generate_rules_stylesheet()
  end

  @doc """
  Generates the variables half of the stylesheet.

  Emits the `:root` declarations from the configured theme (sizes, typography,
  shadows) followed by every registered palette's `:root_colors`, then the
  shared `:root_color_aliases` block. Host applications can `@import` this
  file, override individual `--auix-*` vars, and then `@import` the rules file.

  ## Returns
  `binary()` - The combined CSS variable declarations.
  """
  @spec generate_variables_stylesheet() :: binary()
  def generate_variables_stylesheet do
    palettes =
      registered_themes()
      |> Enum.map(fn {_name, module} -> style([:root_colors], module) end)
      |> Enum.reverse()

    root_block = style([:root], theme_module())
    alias_block = style([:root_color_aliases], theme_module())

    [[root_block | palettes], alias_block]
    |> List.flatten()
    |> Enum.join(" ")
  end

  @doc """
  Generates the rules half of the stylesheet.

  Emits every theme rule except `:root` and `:root_colors`, which are
  handled by `generate_variables_stylesheet/0`.

  ## Returns
  `binary()` - The component CSS rules.
  """
  @spec generate_rules_stylesheet() :: binary()
  def generate_rules_stylesheet do
    theme_module = theme_module()

    theme_module.rule_names()
    |> Enum.reject(&(&1 in [:root, :root_colors, :root_color_aliases]))
    |> style(theme_module)
    |> Enum.join(" ")
  end

  @doc """
  Generates the baseline tag-selector stylesheet for non-Tailwind hosts.

  Hosts on Tailwind v4 (or any other CSS reset) should NOT import this — it
  patches `html`, `body`, and `a` selectors that Tailwind's preflight
  already normalises. Hosts without a reset import `auix-baseline.css`
  BEFORE `auix-variables.css` so the `@layer auix.baseline` placement is
  honoured.

  ## Returns
  `binary()` - The combined baseline CSS rules.
  """
  @spec generate_baseline_stylesheet() :: binary()
  def generate_baseline_stylesheet do
    Baseline.rule_names()
    |> style(Baseline)
    |> Enum.join(" ")
  end

  @doc """
  Returns the configured theme module.

  ## Returns

  `module() | nil` - The theme module configured at compile time, nil if the configured module name
    is not registered. This might provoke an error in calling modules.

  ## Examples

      iex> theme_module()
      Aurora.Uix.Templates.Basic.Themes.WhiteCharcoal
  """
  @spec theme_module() :: module()
  def theme_module do
    Map.get(registered_themes(), @theme_name)
  end

  @doc """
  Returns the name of the configured theme.
  ## Returns
  `atom()` - The name of the configured theme.
  ## Examples
      iex> theme_name()
      :white_charcoal
  """
  @spec theme_name() :: atom()
  def theme_name do
    @theme_name
  end

  @doc """
  Registers and retrieves all available themes.
  """
  @spec registered_themes() :: map()
  def registered_themes do
    case :persistent_term.get(:auix_registered_themes, :undefined) do
      :undefined ->
        registered_themes = find_registered_themes()
        :persistent_term.put(:auix_registered_themes, registered_themes)

        registered_themes

      registered_themes ->
        registered_themes
    end
  end

  @doc """
  Copies another rule of the same theme into a rule's CSS, renaming its selector.

  Used inside a `rule` of a theme. The copy is made when the theme compiles, from the theme's own
  or included rules.

  ## Parameters
  - `rule_source` (`atom()`) - rule name to import from.
  - `target_name` (`binary()` | `atom()`) - rule to create.

  ## Returns
  - `binary()` - A marker that the theme replaces with the renamed CSS of `rule_source`.

  """
  @spec import_rule(atom(), binary() | atom()) :: binary()
  def import_rule(rule_source, target_name), do: "<<auix_import:#{rule_source}:#{target_name}>>"

  @doc """
  Replaces the `import_rule/2` markers of a rule's CSS.

  ## Parameters
  - `css` (`binary()`) - The rule's CSS.
  - `css_by_name` (`map()`) - The theme's rules CSS, by rule name as a string.
  - `module` (`module()`) - The theme, for error reporting.

  ## Returns
  - `binary()` - The CSS with each marker replaced by the imported rule's CSS, renamed.

  """
  @spec resolve_imports(binary(), map(), module()) :: binary()
  def resolve_imports(css, css_by_name, module), do: resolve_imports(css, css_by_name, module, [])

  ## PRIVATE

  @spec resolve_imports(binary(), map(), module(), [binary()]) :: binary()
  defp resolve_imports(css, css_by_name, module, seen) do
    Regex.replace(~r/<<auix_import:(\w+):(\w+)>>/, css, fn _marker, source, target ->
      if source in seen or not Map.has_key?(css_by_name, source) do
        raise Spark.Error.DslError,
          module: module,
          path: [:rule, String.to_existing_atom(target)],
          message: "import_rule cannot import #{source}"
      end

      css_by_name
      |> Map.fetch!(source)
      |> resolve_imports(css_by_name, module, [source | seen])
      |> rename_rule(source, target)
    end)
  end

  # Mirrors the class names: `_auix_flash` and `auix_flash__info` become `auix-flash` and
  # `auix-flash--info`.
  @spec rename_rule(binary(), binary(), binary()) :: binary()
  defp rename_rule(css, source, target) do
    source = source |> String.replace("_", "-") |> String.replace_leading("-", "")
    target = String.replace(target, "_", "-")
    Regex.replace(~r"\.#{source}\b", css, ".#{target}")
  end

  # Emits the CSS of the named rules of a theme, in the given order. A name the theme does not
  # list emits nothing.
  @spec style([atom()], module()) :: [binary()]
  defp style(rule_names, theme) do
    css_by_name = Map.new(theme.rules(), &{&1.name, &1.css})

    Enum.map(rule_names, fn rule_name ->
      css_by_name
      |> Map.get(rule_name, "")
      |> trim_rule()
      |> CssSanitizer.sanitize_css()
      |> then(&"#{&1}\n")
    end)
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

  @spec find_registered_themes() :: map()
  defp find_registered_themes do
    available = :code.all_available()

    available
    |> Enum.map(&(&1 |> elem(0) |> to_string()))
    |> Enum.filter(&String.starts_with?(&1, "Elixir."))
    |> Enum.map(fn module_name ->
      module = CommonHelper.safe_atom(module_name)

      if Code.ensure_loaded?(module) and BehaviourHelper.behaviour_implemented?(module, Theme) do
        {module.theme_name(), module}
      else
        {nil, module}
      end
    end)
    |> Enum.reject(&(elem(&1, 0) == nil))
    |> Map.new()
  end
end
