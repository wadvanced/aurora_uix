defmodule Aurora.Uix.Templates.Theme.Include do
  @moduledoc """
  An `include` of a theme DSL: the theme whose rules this theme takes.

  ## Key Features
  - Brings in every rule of `theme`, except the ones the including theme declares itself.

  ## Key Constraints
  - `theme` must be a compiled theme module, one that exposes `rules/0`.
  """

  defstruct theme: nil, __spark_metadata__: nil

  @type t() :: %__MODULE__{theme: module(), __spark_metadata__: term()}
end
