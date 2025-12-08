defmodule Aurora.UixWeb.ErrorView do
  @moduledoc """
  Renders error views for the Aurora.UixWeb application.

  ## Key Features
  - Provides fallback rendering for error templates and associated data.
  - Formats and displays error information for test support.
  """

  @doc """
  Renders an error template with the given assigns.

  ## Parameters
  - `template` (binary()) - The error template to be rendered.
  - `assigns` (map()) - A map containing the error details, such as `:reason`.

  ## Returns
  binary() - A string representation of the error template and its associated data.
  """
  @spec render(binary(), map()) :: binary()
  def render(template, assigns) do
    "#{inspect(template)}: #{inspect(assigns[:reason])}#{inspect(assigns)}"
  end
end
