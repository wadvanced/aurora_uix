defmodule Aurora.Uix.Templates.Basic.Themes.Baseline do
  @moduledoc """
  Tag-selector baseline reset for hosts that don't already ship a CSS
  preflight (Tailwind, Normalize, etc.).

  These rules patch `html, :host`, `body`, `a`, and the form/border
  reset that Tailwind otherwise provides. They are emitted into
  `auix-baseline.css` as a separate file so Tailwind hosts can skip
  them entirely while non-Tailwind hosts opt in with one `@import`.

  Not part of the theme delegation chain — see
  `Aurora.Uix.Templates.Basic.Themes.Base` for component rules and
  `Aurora.Uix.Templates.Basic.Themes.BaseVariables` for `:root`
  declarations.
  """
  use Aurora.Uix.Templates.Theme

  @impl true
  @spec rule(atom()) :: binary()
  def rule(:_auix_html) do
    """
    html, :host {
      line-height: revert;
      background-color: var(--auix-color-bg-default);
      color: var(--auix-color-text-primary);
      -webkit-text-size-adjust: 100%;
      tab-size: 4;
      font-family: var(--auix-font-family-default, ui-sans-serif, system-ui, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji');
      font-feature-settings: var(--auix-default-font-feature-settings, normal);
      font-variation-settings: var(--auix-default-font-variation-settings, normal);
      -webkit-tap-highlight-color: transparent;
    }

    /* Reverts tailwind overall setting */
    *, ::after, ::before, ::backdrop, ::file-selector-button {
      border: revert;
    }
    button, input, select, optgroup, textarea, ::file-selector-button {
      color: var(--auix-color-text-primary);
      border-radius: var(--auix-border-radius-small);
      background-color: transparent;
      opacity: var(--auix-opacity-100);
    }
    """
  end

  def rule(:_auix_tag_body) do
    """
    body {
      margin: var(--auix-margin-medium);
    }
    """
  end

  def rule(:_auix_tag_a) do
    """
    a {
      color: inherit;
      -webkit-text-decoration: inherit;
      text-decoration: inherit;
    }

    a:hover {
      cursor: pointer;
    }
    """
  end

  def rule(_), do: ""
end
