defmodule AuroraUixTestWeb.ErrorView do
  @moduledoc """
  This module is responsible for rendering error views in the AuroraUixTestWeb application.

  It provides a fallback mechanism for rendering error templates and associated data
  when an error occurs in the application. The `render/2` function is used to format
  and display error information.
  """

  @doc """
  Renders an error template with the given assigns.

  ## Parameters
  - `template`: The error template to be rendered (as an atom or string).
  - `assigns`: A keyword list or map containing the error details, such as `:reason`.

  ## Returns
  A string representation of the error template and its associated data.
  """
  @spec render(binary, map) :: binary
  def render(template, assigns) do
    "#{inspect(template)}: #{inspect(assigns[:reason])}#{inspect(assigns)}"
  end
end
