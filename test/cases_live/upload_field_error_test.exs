defmodule Aurora.UixWeb.Test.UploadFieldErrorTest.ErrorConsumer do
  @moduledoc false

  @doc false
  @spec fail(list(binary())) :: {:error, binary()}
  def fail(_binaries), do: {:error, "bad file"}
end

defmodule Aurora.UixWeb.Test.UploadFieldErrorTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Repo
  alias Aurora.UixWeb.Test.UploadFieldErrorTest.ErrorConsumer

  auix_resource_metadata :product, context: Inventory, schema: Product do
    field(:image,
      data: %{
        upload: %{
          allow: [accept: ~w(.png .jpg), max_entries: 1],
          consume: &ErrorConsumer.fail/1
        }
      }
    )
  end

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    edit_layout :product, [] do
      stacked([:reference, :name, :quantity_initial, :image])
    end
  end

  describe "consume callback returns {:error, reason}" do
    test "save is aborted and the error is shown in the flash", %{conn: conn} do
      delete_all_inventory_data()
      reference = "error-upload-#{System.unique_integer([:positive])}"
      {:ok, view, _html} = live(conn, "/upload-field-error-products/new")

      content = "fake-png-binary-content"

      upload =
        file_input(view, "#auix-product-form", :image, [
          %{
            last_modified: 1_594_171_879_000,
            name: "bad.png",
            content: content,
            size: byte_size(content),
            type: "image/png"
          }
        ])

      render_upload(upload, "bad.png")

      html =
        view
        |> form("#auix-product-form",
          product: %{reference: reference, name: "Error Upload", quantity_initial: 0}
        )
        |> render_submit()

      assert html =~ "bad file"
      assert Repo.get_by(Product, reference: reference) == nil
    end
  end
end
