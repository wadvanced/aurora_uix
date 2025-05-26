defmodule Aurora.Uix.Web.TestLayouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use AuroraUixTestWeb, :controller` and
  `use AuroraUixTestWeb, :live_view`.
  """
  use AuroraUixTestWeb, :html

  embed_templates("layouts/*")
end
