defmodule Aurora.UixWeb.Test.BrowserUploadTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  import Aurora.Uix.Test.Mirror.Seeds
  import Aurora.UixWeb.Test.Scenario

  alias Aurora.Uix.Repo
  alias Aurora.Uix.Test.MirrorCtx.Product
  alias Wallaby.Query

  @save_button Query.css("button[name='auix-save-product']")
  @gone_form Query.css("#auix-product-form", count: 0)

  # The mirror keeps one unique reference per product, and a browser feature holds its rows
  # uncommitted for seconds: a prefix of its own keeps the other async modules from waiting on it.
  # Wallaby is needed because a file is sent through the browser's live upload channel, which
  # Phoenix.LiveViewTest replaces with its own client.
  feature "a file chosen in the browser uploads and is consumed on save", %{session: session} do
    path =
      Path.join(System.tmp_dir!(), "browser-upload-#{System.unique_integer([:positive])}.png")

    File.write!(path, "browser-png-bytes")
    on_exit(fn -> File.rm(path) end)

    each_backend(fn backend ->
      id = create_sample_products(1, :upload, %{quantity_initial: 1})["id_upload-1"].id
      edit_path = mirror_path(backend, "uploads", "products", "/#{id}/edit")

      session
      |> visit(edit_path)
      |> click(@save_button)
      |> assert_has(@gone_form)

      assert is_nil(Repo.get!(Product, id).image)

      session
      |> visit(edit_path)
      # A file attached before the LiveView connects raises no upload entry.
      |> assert_has(Query.css("[data-phx-main].phx-connected", visible: :any))
      |> attach_file(Query.css("input[type='file'][name='image']", visible: :any), path: path)
      |> assert_has(Query.css(".auix-upload-entry", visible: :any))
      |> click(@save_button)
      |> assert_has(@gone_form)

      assert Repo.get!(Product, id).image == "browser-png-bytes"
    end)
  end
end
