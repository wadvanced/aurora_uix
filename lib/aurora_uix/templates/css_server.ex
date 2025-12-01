defmodule Aurora.Uix.Templates.CssServer do
  @moduledoc """
  Serves dynamically generated CSS for Aurora UIX themes.

  This controller generates CSS stylesheets based on the current theme module.
  It is intended for internal use within the Aurora UIX system to provide
  up-to-date theme styles to clients.

  ## Usage

      GET /path/to/css
      # Returns CSS generated for the current theme.

  """

  use Phoenix.Controller, formats: [:html]

  alias Aurora.Uix.Templates.ThemeHelper

  @doc """
  Generates and sends a CSS response for the current theme.

  ## Parameters

    - conn: The Plug.Conn struct.
    - _params: Request parameters (not used).

  ## Returns

    - The connection with a CSS response body containing the generated stylesheet.
  """
  @spec generate(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def generate(conn, _params) do
    theme_module = ThemeHelper.theme_module()

    stylesheet =
      theme_module
      |> ThemeHelper.generate_stylesheet()
      |> Enum.join(" ")

    conn
    |> put_resp_content_type("text/css; charset=utf-8")
    |> put_resp_header("cache-control", "no-cache, must-revalidate, max-age=0")
    |> text("#{stylesheet}\n")
  end
end
