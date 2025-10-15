defmodule Aurora.Uix.Templates.ThemeHelper do
  use Phoenix.Component

  @css_rule_marker "css_rules:"
  @template Aurora.Uix.Template.uix_template()
  @default_theme @template.default_theme_module()
  @theme Application.compile_env(:aurora_uix, :theme_module, @default_theme)

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

  defp scan_rules(expr) do
    expr
    |> String.split("\n")
    |> Enum.filter(&Regex.match?(~r/^[ \t]*#{@css_rule_marker}/, &1))
    |> Enum.map(&rule_names_from_line/1)
    |> scan_expressions(expr)
    |> detect_stylesheet(expr)
  end

  defp rule_names_from_line(rule) do
    rule
    |> String.replace("#{@css_rule_marker} ", "")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> then(&{"#{rule}\n", &1, ""})
  end

  defp scan_expressions(scanned_rules, expr) do
    ~r/![a-z][0-9a-z-]*!/
    |> Regex.scan(expr)
    |> List.flatten()
    |> Enum.map(&(&1 |> String.slice(1..-2//1)))
    |> Enum.reduce(scanned_rules, &[{"!#{&1}!", &1, &1} | &2])
    |> List.flatten()
  end

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

  defp generate_style(rule_lines) do
    rule_lines
    |> List.flatten()
    |> Enum.reduce([], fn {_rule_line, rule_name, _replacement}, acc -> [rule_name | acc] end)
    |> List.flatten()
    |> style()
  end

  defp remove_scanned_rules(expr, scanned_rules) do
    Enum.reduce(scanned_rules, expr, fn {rule_line, _rule_name, replacement}, acc ->
      String.replace(acc, rule_line, replacement)
    end)
  end

  defp add_styles(expr, styles) do
    "#{styles}\n#{expr}"
  end

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

  defp read_rule(rule) do
    rule
    |> convert_dashes()
    |> @theme.rule()
  end

  defp convert_dashes(rule) do
    rule
    |> to_string()
    |> String.replace("-", "_")
    |> String.to_atom()
  end

  defp maybe_add_root(parsed_css_rules, rule_names) do
    with false <- Enum.any?(rule_names, &(&1 == :root)),
         true <- String.contains?(parsed_css_rules, "var(--") do
      @theme.rule(:root) <> parsed_css_rules
    else
      _ -> parsed_css_rules
    end
  end
end
