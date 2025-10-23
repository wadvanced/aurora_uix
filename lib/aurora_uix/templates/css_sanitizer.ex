defmodule Aurora.Uix.Templates.CssSanitizer do
  @moduledoc """
  CSS sanitization module that parses and filters CSS rules to prevent security vulnerabilities.

  Key features:
  - Enforces allowlist-based CSS property validation using regex patterns
  - Removes dangerous CSS functions and protocols (javascript:, expression, etc.)
  - Sanitizes URL functions to block malicious schemes
  - Supports standard CSS types: elements, media queries, and keyframe animations
  - Maintains CSS custom properties with --auix- prefix
  - Provides detailed debug logging for validation issues

  Constraints:
  - Only processes CSS rule types: elements, media, and keyframe
  - Rejects complex at-rules beyond @media and @keyframes
  - Requires valid CSS syntax; malformed CSS may be partially processed
  - Custom properties must follow --auix-[a-z-]+ naming convention
  """

  alias CssParser
  require Logger

  @property_catch ~r/(?<property>[\w\-*]+)\s*:\s*(?<value>[^;]+)\s*;?/i

  @allowed_properties MapSet.new([
                        # --- Structural/Layout ---
                        "display",
                        "position",
                        "float",
                        "clear",
                        "z-index",
                        "overflow",
                        "visibility",
                        "content-visibility",
                        "(max-|min-|)width",
                        "(max-|min-|)height",
                        # This is deprecated
                        "clip(|-[a-z-]+)",
                        "inset(|-[a-z-]+)",
                        "top",
                        "bottom",
                        "right",
                        "left",
                        "tab-size",
                        # --- Box Model ---
                        "(column-|row-|)gap",
                        "margin(|-[a-z-]+)",
                        "padding(|-[a-z]+)",
                        "border(|-[a-z-]+)",
                        "box-shadow",
                        "outline(|-[a-z-]+)",
                        # --- Typography/Text ---
                        "color(|-[a-z-]+)",
                        "font(|-[a-z-]+)",
                        "line-height",
                        "line-height-step",
                        "text(|-[a-z-]+)",
                        "letter-spacing",
                        "white-space",
                        "word-wrap",
                        "justify(|-[a-z-]+)",
                        "align(|-[a-z-]+)",
                        "vertical-align",
                        # --- Background/Visuals ---
                        "background(|-[a-z-]+)",
                        "fill(|-[a-z-]+)",
                        "opacity",
                        # --- Lists ---
                        "list-style(|-[a-z-]+)",
                        # --- Flex and Grid---
                        "flex(|-[a-z-]+)",
                        "grid(|-[a-z-]+)",
                        # -- Animations and Transitions ---
                        "animation",
                        "transition(|-[a-z-]+)",
                        "transform(|box|origin|style)",
                        "from",
                        "to",
                        "cursor",
                        # --- Properties ---
                        "--auix-[a-z-]+",
                        # --- Browser behavior ---
                        "appearance",
                        "-moz-appearance",
                        "-webkit-appearance",
                        "-webkit-text-size-adjust",
                        "-webkit-tap-highlight-color"
                      ])

  # CssParser uses "elements" for standard selector blocks.
  # We reject other types, like at-rules.
  @allowed_types MapSet.new(["elements", "media", "keyframe"])

  @doc """
  Validates all CSS rules from a theme module by applying sanitization.

  This function configures the logger to debug level and processes each rule
  from the theme module through the CSS sanitization pipeline.

  Parameters:
    - theme_module (module): Theme module implementing rule_names/0 and rule/1 functions

  Returns:
    - :ok (implicitly) - logs validation results and errors

  Example:
  ```elixir
  Aurora.Uix.Templates.CssSanitizer.validate_theme_rules(MyApp.Theme)
  ```
  """
  @spec validate_theme_rules(module()) :: :ok
  def validate_theme_rules(theme_module) do
    Logger.configure(level: :debug)

    rule_names = theme_module.rule_names()

    rule_names
    |> Enum.map(fn rule_name ->
      theme_module.rule(rule_name)
    end)
    |> Enum.each(&sanitize_css/1)
  end

  @doc """
  Sanitizes a raw CSS string by parsing it, enforcing an allowlist, and sanitizing URLs.

  This function:
  - Parses CSS using CssParser
  - Filters out disallowed rule types and properties
  - Removes dangerous tokens and functions
  - Sanitizes URL functions to block malicious protocols
  - Reconstructs valid CSS from sanitized components

  Parameters:
    - css (String.t): Raw CSS string to sanitize

  Returns:
    - String.t: Sanitized CSS string with only allowed properties and safe URLs

  Raises:
    - (Logs) :error level for parsing failures with detailed context

  Example:
  ```elixir
  # Basic sanitization
  safe_css = Aurora.Uix.Templates.CssSanitizer.sanitize_css("color: red; background: url(javascript:alert());")
  # => "color: red;"

  # Media query preservation
  safe_css = Aurora.Uix.Templates.CssSanitizer.sanitize_css("@media (min-width: 768px) { .container { display: flex; } }")
  # => "@media (min-width: 768px) { .container { display: flex; } }"

  # Malicious URL removal
  safe_css = Aurora.Uix.Templates.CssSanitizer.sanitize_css("background: url(javascript:alert('xss'));")
  # => ""
  ```
  """
  @spec sanitize_css(binary()) :: binary()
  def sanitize_css(css) when is_binary(css) do
    parsed_css =
      case parse_css(css) do
        {:ok, parsed_css} ->
          parsed_css

        {:error, error} ->
          Logger.error("""
            \n#{IO.ANSI.red()}Invalid format in rule#{IO.ANSI.reset()}
            error: #{IO.ANSI.red()}#{inspect(error)}#{IO.ANSI.reset()}
            \nCSS:
            #{css}
          """)

          %{type: "error", selectors: "invalid", rules: ""}
      end

    parsed_rules =
      parsed_css
      |> Enum.map(&process_rule_set(&1, css))
      |> Enum.reject(&(&1 == ""))

    result = Enum.join(parsed_rules, "\n")

    if Enum.count(parsed_rules) < Enum.count(parsed_css) do
      Logger.debug("""
        \n#{IO.ANSI.red()}Rules count do not match#{IO.ANSI.reset()}
        \nPARSED:
        #{result}
          \nCSS:
          css
      """)
    end

    result
  end

  ## PRIVATE

  # Processes a single rule set (selectors + rules) from the parser output
  # Returns sanitized CSS rule string or empty string if rule should be removed
  @spec process_rule_set(map(), binary()) :: binary()
  defp process_rule_set(%{type: type, selectors: selectors, rules: rules}, css) do
    if MapSet.member?(@allowed_types, type) do
      sanitized_rules =
        rules
        |> remove_dangerous_tokens()
        |> sanitize_declarations()
        |> String.trim()

      if type != "keyframe" do
        original_properties = scan_properties(rules)

        sanitized_properties = scan_properties(sanitized_rules)

        validate_properties(original_properties, sanitized_properties, css)
      end

      if sanitized_rules != "" do
        "#{selectors} { #{sanitized_rules} }"
      else
        ""
      end
    else
      ""
    end
  end

  # Processes nested rule sets (media queries with children)
  defp process_rule_set(%{selectors: selectors, children: children}, css) do
    sanitized_rules = Enum.map_join(children, " ", &process_rule_set(&1, css))

    if sanitized_rules != "" do
      "#{selectors} { #{sanitized_rules} }"
    else
      ""
    end
  end

  # Catches unexpected formats from the parser
  defp process_rule_set(_other, _css), do: ""

  @spec scan_properties(binary()) :: list()
  defp scan_properties(rules) do
    @property_catch
    |> Regex.scan(rules,
      capture: :all_names
    )
    |> Enum.map(fn [property_name, property_value] ->
      "#{property_name}: #{property_value}"
    end)
  end

  @spec validate_properties(list(), list(), binary()) :: :ok
  defp validate_properties(original_properties, sanitized_properties, css) do
    if Enum.count(original_properties) != Enum.count(sanitized_properties) do
      Logger.debug("""
      ****** counts don't match *****
      CSS:
      #{css}

      CSS PROPERTIES:
      #{Enum.join(original_properties, ", ")}

      CSS SANITIZED PROPERTIES:
      #{Enum.join(sanitized_properties, ", ")}
      """)
    end
    :ok
  end

  # Filters property:value pairs using @allowed_properties allowlist with regex matching
  @spec sanitize_declarations(list() | binary()) :: binary()
  defp sanitize_declarations(rules) when is_list(rules),
    do: Enum.map_join(rules, "\n", &sanitize_declarations/1)

  # Special handling for keyframe animation content
  defp sanitize_declarations(rules) do
    case Regex.named_captures(
           ~r/\{\s*(?<content>from\s*\{\s*transform\:[\w\s\(\)]+;\s*\}\s+to\s*\{\s*transform\:[\w\s\(\)]+;\s*\})\s*\}/,
           rules
         ) do
      %{"content" => content} -> content
      _ -> do_sanitize_declarations(rules)
    end
  end

  # Core declaration sanitization using property allowed list
  @spec do_sanitize_declarations(binary()) :: binary()
  defp do_sanitize_declarations(rules) do
    declarations =
      Regex.scan(@property_catch, rules, capture: :all_names)

    declarations
    |> Enum.map(fn [property_name, property_value] ->
      property = property_name |> String.trim() |> String.downcase()

      if Enum.any?(@allowed_properties, &allowed?(&1, property)) do
        value = sanitize_url_functions(property_value)
        "#{property}: #{String.trim(value)};"
      else
        ""
      end
    end)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" ")
  end

  # Sanitizes URL functions by blocking dangerous protocols
  # Replaces malicious URLs with "url(invalid)" placeholder
  @spec sanitize_url_functions(binary()) :: binary()
  defp sanitize_url_functions(value) do
    Regex.replace(
      ~r/url\(\s*(['"])?\s*([^'")]+?)\1\s*\)/i,
      value,
      fn _full, _quote, url ->
        u = String.trim(url)

        blocked? =
          Regex.match?(~r/^(javascript|vbscript|data|file|about|chrome|moz|ms-widget):/i, u)

        if blocked? do
          "url(invalid)"
        else
          "url(\"#{String.replace(u, "\"", "\\\"")}\")"
        end
      end
    )
  end

  # Removes dangerous CSS functions and browser-specific exploits
  @spec remove_dangerous_tokens(binary() | list()) :: binary()
  defp remove_dangerous_tokens(rules) when is_list(rules) do
    Enum.map_join(rules, " ", &remove_dangerous_tokens/1)
  end

  # Removes expression, behavior, filter, and other dangerous CSS tokens
  defp remove_dangerous_tokens(rules) do
    rules
    |> String.replace(~r/expression\s*\([^)]*\)/i, "")
    |> String.replace(~r/\bbehavior\s*:\s*[^;]+;?/i, "")
    |> String.replace(~r/-moz-binding\s*:\s*[^;]+;?/i, "")
    |> String.replace(~r/\bfilter\s*:\s*[^;]+;?/i, "")
    |> String.replace(~r/-ms-filter\s*:\s*[^;]+;?/i, "")
    |> String.replace(~r/progid:[^;)\s]+/i, "")
    |> String.replace(~r/javascript\s*:/i, "")
    |> String.replace(~r/vbscript\s*:/i, "")
  end

  # Parses CSS with ETS table caching and error handling
  @spec parse_css(binary()) :: {:ok, binary() | map()} | {:error, map()}
  defp parse_css(css) do
    ensure_ets_table()

    try do
      {:ok, CssParser.parse(css)}
    rescue
      e in CaseClauseError -> {:error, e}
    end
  end

  # Ensures ETS table exists for CSS parser caching
  @spec ensure_ets_table() :: :ok
  defp ensure_ets_table do
    case :ets.info(:parsed) do
      :undefined ->
        :ets.new(:parsed, [:named_table, :public, :set, :compressed])

      _ ->
        :ok
    end
  end

  # Helper function for regex-based property allowlist matching
  @spec allowed?(binary(), binary()) :: boolean()
  defp allowed?(matcher, property_name) do
    matcher
    |> Regex.compile!()
    |> Regex.match?(property_name)
  end
end
