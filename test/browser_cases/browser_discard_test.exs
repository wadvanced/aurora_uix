defmodule Aurora.UixWeb.Test.BrowserDiscardTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  import Aurora.Uix.Test.Mirror.Seeds
  import Aurora.UixWeb.Test.Scenario

  alias Aurora.Uix.Repo
  alias Aurora.Uix.Test.MirrorCtx.Product
  alias Wallaby.Query

  @form Query.css("#auix-product-form")
  @gone_form Query.css("#auix-product-form", count: 0)
  @connected Query.css("[data-phx-main].phx-connected", visible: :any)
  @confirm Query.css("#auix-product-discard-confirm-modal")
  @gone_confirm Query.css("#auix-product-discard-confirm-modal", count: 0)

  # Own reference prefix: see BrowserUploadTest.
  # Wallaby is needed because the modal's client-side close (Escape) cannot be pressed with
  # Phoenix.LiveViewTest.
  feature "the edit modal closes through the discard dialog", %{session: session} do
    each_backend(fn backend ->
      product = create_sample_products(1, :discard, %{quantity_initial: 1})["id_discard-1"]

      session
      |> visit(mirror_path(backend, "form", "products", "/#{product.id}/edit"))
      # An edit made before the LiveView connects never marks the form as changed.
      |> assert_has(@connected)
      |> fill_in(Query.css("input[name='product[name]']"), with: "Changed")
      |> send_keys([:escape])
      |> assert_has(@confirm)
      |> click(Query.css("button[name='auix-keep-editing']"))
      # Escape while the dialog is still open counts as "keep editing" again and reopens nothing.
      |> assert_has(@gone_confirm)
      |> assert_has(@form)
      |> send_keys([:escape])
      |> assert_has(@confirm)
      |> click(Query.css("button[name='auix-discard-changes']"))
      |> assert_has(@gone_form)

      assert Repo.get!(Product, product.id).name == product.name
    end)
  end
end
