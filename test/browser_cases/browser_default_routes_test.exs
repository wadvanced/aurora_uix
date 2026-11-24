defmodule Aurora.UixWeb.Test.BrowserDefaultRoutesTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  import Aurora.Uix.Test.Mirror.Seeds
  import Aurora.UixWeb.Test.Scenario

  alias Wallaby.Query

  # Own reference prefix: see BrowserUploadTest.
  # Wallaby is needed because each route is loaded with a full page load, not a LiveView patch.
  feature "the default routes open their modal on a full page load", %{session: session} do
    each_backend(fn backend ->
      product = create_sample_products(1, :routes)["id_routes-1"]
      base = mirror_path(backend, "default", "products")

      for {suffix, modal} <- [
            {"/new", "new"},
            {"/#{product.id}/show", "show"},
            {"/#{product.id}/show-edit", "show_edit"},
            {"/#{product.id}/edit", "edit"}
          ] do
        session
        |> visit(base <> suffix)
        |> assert_has(Query.css("#auix-product-#{modal}-modal"))
        |> assert_has(Query.css("a[name='auix-new-product']", visible: :any))
        |> click(Query.css("#auix-product-#{modal}-modal .auix-modal-close-button"))
        |> assert_has(Query.css("#auix-product-#{modal}-modal", count: 0))

        assert current_path(session) == base
      end
    end)
  end
end
