defmodule Aurora.UixWeb.ErrorHTML do
  @moduledoc """
  Renders error pages for HTML requests.

  This module is invoked by the endpoint whenever an error occurs during an
  HTML request. It's responsible for rendering the appropriate error page
  (e.g., 404 Not Found, 500 Internal Server Error).

  By default, it renders plain text messages, but you can customize the
  error pages by uncommenting the `embed_templates/1` call and creating
  template files in the `lib/aurora_uix_web/error_html/` directory.
  """
  use Aurora.UixWeb, :html

  # If you want to customize your error pages,
  # uncomment the embed_templates/1 call below
  # and add pages to the error directory:
  #
  #   * lib/aurora_demo_web/controllers/error_html/404.html.heex
  #   * lib/aurora_demo_web/controllers/error_html/500.html.heex
  #
  # embed_templates "error_html/*"

  @doc """
  Renders an error page.

  By default, it renders a plain text page based on the template name.
  For example, a `404.html` template will render the text "Not Found".
  """
  @spec render(binary(), map()) :: binary()
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
