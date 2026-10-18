defmodule Aurora.UixWeb.Test.RenderedPagesTest do
  # Synchronous on purpose: ExUnit starts synchronous modules only after every test file is
  # loaded, and the routed view modules are defined by those files.
  use Aurora.UixWeb.Test.UICase, :phoenix_case

  alias Aurora.UixWeb.Test.RenderedPages

  @moduletag :rendered_pages

  # AURORA_UIX_RENDERED_PAGES=update mix test --only rendered_pages
  @update? System.get_env("AURORA_UIX_RENDERED_PAGES") == "update"

  @tag timeout: :infinity
  test "every test-app page renders as committed", %{conn: conn} do
    RenderedPages.seed()
    rendered = RenderedPages.render_all(conn)

    if @update? do
      RenderedPages.write_all(rendered)
    else
      differences = RenderedPages.differences(rendered)

      assert differences == [], """
      #{length(differences)} rendered page(s) differ from #{RenderedPages.root_dir()}.
      If the change is intended, regenerate them with
        AURORA_UIX_RENDERED_PAGES=update mix test --only rendered_pages

      #{Enum.join(differences, "\n\n")}
      """
    end
  end
end
