Code.require_file("test/support/aurora_uix_test_web.exs")
Code.require_file("test/support/app_web/router.exs")

defmodule AuroraUixTestWeb.Layout do
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
