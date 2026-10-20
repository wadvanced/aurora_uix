defmodule Aurora.Uix.Templates.Basic.Themes.Breakpoints do
  @moduledoc """
  The responsive breakpoints of the Basic template's themes.

  ## Key Features
  - `breakpoint/1` gives the pixel width of a breakpoint, for use inside theme rules.

  ## Key Constraints
  - Theme rules are built when the theme compiles, so the breakpoints live outside any theme.
  """

  @doc """
  Returns the CSS breakpoint value in pixels for the given size atom.

  ## Parameters
  - `size` (atom()) - The breakpoint size. Supported values: `:sm`, `:md`, `:lg`, `:xl`, `:xxl`.

  ## Returns
  binary() - The CSS pixel value string for the breakpoint.

  ## Examples

  ```elixir
  iex> Aurora.Uix.Templates.Basic.Themes.Breakpoints.breakpoint(:md)
  "768px"
  ```
  """
  @spec breakpoint(atom()) :: binary()
  def breakpoint(:sm), do: "640px"
  def breakpoint(:md), do: "768px"
  def breakpoint(:lg), do: "1024px"
  def breakpoint(:xl), do: "1280px"
  def breakpoint(:xxl), do: "1536px"
end
