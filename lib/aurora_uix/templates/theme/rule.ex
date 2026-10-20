defmodule Aurora.Uix.Templates.Theme.Rule do
  @moduledoc """
  One CSS rule of a theme, as listed by the theme's `rules/0`.

  ## Key Features
  - `name` is the rule name, such as `:auix_button` or `:root_colors`.
  - `css` is the rule's CSS, as the stylesheet emits it before trimming and sanitizing.
  - `source` says where the CSS comes from: `:local` when the theme defines it, or
    `{:theme, module}` when it comes from a theme the rule delegates to.

  ## Key Constraints
  - A theme lists each rule name once; a local rule replaces a delegated rule of the same name.
  """

  defstruct name: nil, css: "", source: :local

  @type source() :: :local | {:theme, module()}

  @type t() :: %__MODULE__{
          name: atom(),
          css: binary(),
          source: source()
        }
end
