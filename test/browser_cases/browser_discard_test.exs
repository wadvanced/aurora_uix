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

  # Own reference prefix: see BrowserUploadTest.
  # Wallaby is needed because the modal's client-side close (Escape) cannot be pressed with
  # Phoenix.LiveViewTest.
  feature "the edit modal closes through the discard dialog", %{session: session} do
    each_backend(fn backend ->
      product = create_sample_products(1, :discard, %{quantity_initial: 1})["id_discard-1"]

      session
      |> visit(mirror_path(backend, "form", "products", "/#{product.id}/edit"))
      |> fill_in(Query.css("input[name='product[name]']"), with: "Changed")
      |> send_keys([:escape])
      |> assert_has(Query.css("#auix-product-discard-confirm-modal"))
      |> click(Query.css("button[name='auix-keep-editing']"))
      |> assert_has(@form)
      |> send_keys([:escape])
      |> click(Query.css("button[name='auix-discard-changes']"))
      |> assert_has(@gone_form)

      assert Repo.get!(Product, product.id).name == product.name
    end)
  end
end
