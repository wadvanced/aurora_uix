defmodule Aurora.Uix.Templates.ThemeHelper do
  use Phoenix.Component
  import Phoenix.HTML, only: [raw: 1]

  @template Aurora.Uix.Template.uix_template()
  @default_theme @template.default_theme_module()
  @theme Application.compile_env(:aurora_uix, :theme_module, @default_theme)

  attr(:rules, :list, default: [])

  def css_rules(%{rules: rules} = assigns) do
    assigns =
      rules
      |> Enum.map(&read_rule/1)
      |> Enum.join(" ")
      |> maybe_add_root(rules)
      |> then(&Map.put(assigns, :parsed_css_rules, &1))

    ~H"""
    <style>
      <%= raw(@parsed_css_rules) %>
    </style>
    """
  end

  defp read_rule(rule) do
    rule
    |> convert_dashes()
    |> @theme.rule()
  end

  defp convert_dashes(rule) do
    rule
    |> to_string()
    |> String.replace("-", "_")
    |> String.to_existing_atom()
  end

  defp maybe_add_root(parsed_css_rules, rules) do
    with false <- Enum.any?(rules, &(&1 == :root)),
         true <- String.contains?(parsed_css_rules, "var(--") do
      @theme.rule(:root) <> parsed_css_rules
    else
      _ -> parsed_css_rules
    end
  end
end
