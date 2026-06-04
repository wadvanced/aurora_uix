defmodule Aurora.UixWeb.Test.UploadFieldTest.Consumer do
  @moduledoc false

  @doc false
  @spec consume_image(list(binary())) :: {:ok, binary()}
  def consume_image([binary]), do: {:ok, binary}
end

defmodule Aurora.UixWeb.Test.UploadFieldTest.SocketAwareConsumer do
  @moduledoc false

  @doc false
  @spec consume_with_action(Phoenix.LiveView.Socket.t(), list(binary())) :: {:ok, binary()}
  def consume_with_action(socket, binaries) do
    action = to_string(socket.assigns[:action] || :unknown)
    {:ok, "#{action}:#{List.first(binaries, "")}"}
  end
end

defmodule Aurora.UixWeb.Test.UploadFieldTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Field
  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Repo
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.UixWeb.Test.UploadFieldTest.Consumer

  auix_resource_metadata :product, context: Inventory, schema: Product do
    field(:image,
      data: %{
        upload: %{
          allow: [accept: ~w(.png .jpg), max_entries: 1],
          consume: &Consumer.consume_image/1
        }
      }
    )
  end

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    show_layout :product do
      stacked([:reference, :name, :quantity_initial, :image])
    end

    edit_layout :product, [] do
      stacked([:reference, :name, :quantity_initial, :image])
    end
  end

  describe "form mount — allow_upload registration" do
    test "live file input is present when the form opens", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/upload-field-products/new")
      assert has_element?(view, "input[type='file']")
    end

    test "upload field renders a live_file_input wrapper element", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/upload-field-products/new")
      assert has_element?(view, "[data-phx-upload-ref]")
    end

    test "re-rendering the form does not re-register the upload (double allow_upload guard)",
         %{conn: conn} do
      {:ok, view, _html} = live(conn, "/upload-field-products/new")

      # A validate cycle re-runs the form update path; an unguarded second
      # allow_upload/3 for the same name would raise ArgumentError here.
      view
      |> form("#auix-product-form", product: %{name: "Re-render"})
      |> render_change()

      assert has_element?(view, "input[type='file']")
    end

    test "form renders the live_file_input wrapper but no entries before a file is selected",
         %{conn: conn} do
      {:ok, view, _html} = live(conn, "/upload-field-products/new")

      assert has_element?(view, "[data-phx-upload-ref]")
      refute has_element?(view, ".auix-upload-entry")
    end
  end

  describe "non-upload fields" do
    test "regular text fields still render as inputs when an upload field is present",
         %{conn: conn} do
      {:ok, view, _html} = live(conn, "/upload-field-products/new")
      assert has_element?(view, "input[name$='[name]']")
      assert has_element?(view, "input[name$='[reference]']")
    end
  end

  describe "save with file upload" do
    test "consume callback is invoked and its return value is persisted", %{conn: conn} do
      delete_all_inventory_data()
      reference = "upload-test-#{System.unique_integer([:positive])}"
      {:ok, view, _html} = live(conn, "/upload-field-products/new")

      content = "fake-png-binary-content"

      upload =
        file_input(view, "#auix-product-form", :image, [
          %{
            last_modified: 1_594_171_879_000,
            name: "test.png",
            content: content,
            size: byte_size(content),
            type: "image/png"
          }
        ])

      render_upload(upload, "test.png")

      view
      |> form("#auix-product-form",
        product: %{reference: reference, name: "Upload Test", quantity_initial: 0}
      )
      |> render_submit()

      product = Repo.get_by!(Product, reference: reference)
      assert product.image == content
    end

    test "save with no file selected proceeds and does not overwrite existing image",
         %{conn: conn} do
      delete_all_inventory_data()
      reference = "no-upload-test-#{System.unique_integer([:positive])}"
      {:ok, view, _html} = live(conn, "/upload-field-products/new")

      view
      |> form("#auix-product-form",
        product: %{reference: reference, name: "No Upload", quantity_initial: 0}
      )
      |> render_submit()

      product = Repo.get_by!(Product, reference: reference)
      assert is_nil(product.image)
    end
  end

  describe "auix_cancel_upload" do
    test "cancel button removes the entry from the upload list", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/upload-field-products/new")
      content = "cancel-me"

      upload =
        file_input(view, "#auix-product-form", :image, [
          %{
            last_modified: 1_594_171_879_000,
            name: "cancel.png",
            content: content,
            size: byte_size(content),
            type: "image/png"
          }
        ])

      render_upload(upload, "cancel.png")

      assert has_element?(view, ".auix-upload-entry")

      view
      |> element("button[phx-click='auix_cancel_upload']")
      |> render_click()

      refute has_element?(view, ".auix-upload-entry")
    end
  end

  describe "show mode" do
    test "renders a download button when the entity has a file", %{conn: conn} do
      delete_all_inventory_data()
      content = "fake-image-binary"

      product =
        Repo.insert!(%Product{
          reference: "show-with-file-#{System.unique_integer([:positive])}",
          name: "Show With File",
          quantity_initial: 0,
          image: content
        })

      {:ok, view, _html} = live(conn, "/upload-field-products/#{product.id}/show")

      assert has_element?(view, "button[phx-click='auix_download_upload']")
      refute has_element?(view, "input[type='file']")
    end

    test "renders a 'No file' indicator when the entity has no file", %{conn: conn} do
      delete_all_inventory_data()

      product =
        Repo.insert!(%Product{
          reference: "show-no-file-#{System.unique_integer([:positive])}",
          name: "Show No File",
          quantity_initial: 0
        })

      {:ok, view, _html} = live(conn, "/upload-field-products/#{product.id}/show")

      refute has_element?(view, "button[phx-click='auix_download_upload']")
      assert has_element?(view, "span", "No file")
    end
  end

  describe "edit mode with existing file" do
    test "shows download button alongside file input when entity already has a file",
         %{conn: conn} do
      delete_all_inventory_data()
      content = "existing-image-binary"

      product =
        Repo.insert!(%Product{
          reference: "edit-with-file-#{System.unique_integer([:positive])}",
          name: "Edit With File",
          quantity_initial: 0,
          image: content
        })

      {:ok, view, _html} = live(conn, "/upload-field-products/#{product.id}/edit")

      assert has_element?(view, "button[phx-click='auix_download_upload']")
      assert has_element?(view, "input[type='file']")
    end

    test "does not show download button in edit form when entity has no file", %{conn: conn} do
      delete_all_inventory_data()

      product =
        Repo.insert!(%Product{
          reference: "edit-no-file-#{System.unique_integer([:positive])}",
          name: "Edit No File",
          quantity_initial: 0
        })

      {:ok, view, _html} = live(conn, "/upload-field-products/#{product.id}/edit")

      refute has_element?(view, "button[phx-click='auix_download_upload']")
      assert has_element?(view, "input[type='file']")
    end
  end

  describe "upload_fields/1" do
    test "returns only fields that have a data.upload config" do
      field_with_upload = %Field{key: :image, data: %{upload: %{allow: [], consume: & &1}}}
      field_without = %Field{key: :name, data: %{}}

      auix = %{
        configurations: %{
          product: %{
            resource_config: %{
              fields: %{image: field_with_upload, name: field_without}
            }
          }
        },
        resource_name: :product
      }

      result = BasicHelpers.upload_fields(auix)
      assert length(result) == 1
      assert hd(result).key == :image
    end

    test "returns empty list when no fields have data.upload" do
      field = %Field{key: :name, data: %{}}

      auix = %{
        configurations: %{
          product: %{resource_config: %{fields: %{name: field}}}
        },
        resource_name: :product
      }

      assert BasicHelpers.upload_fields(auix) == []
    end
  end
end

defmodule Aurora.UixWeb.Test.SocketAwareUploadFieldTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Repo
  alias Aurora.UixWeb.Test.UploadFieldTest.SocketAwareConsumer

  auix_resource_metadata :product, context: Inventory, schema: Product do
    field(:image,
      data: %{
        upload: %{
          allow: [accept: ~w(.png .jpg), max_entries: 1],
          consume: &SocketAwareConsumer.consume_with_action/2
        }
      }
    )
  end

  # Route registered as "socket-aware-upload-products" in test/support/app_web/routes.ex
  auix_create_ui do
    edit_layout :product, [] do
      stacked([:reference, :name, :quantity_initial, :image])
    end
  end

  describe "arity-2 socket-aware consume callback" do
    test "consume receives socket and embeds assign-derived data in persisted value",
         %{conn: conn} do
      delete_all_inventory_data()
      reference = "socket-aware-upload-#{System.unique_integer([:positive])}"
      {:ok, view, _html} = live(conn, "/socket-aware-upload-products/new")

      content = "fake-png-binary-content"

      upload =
        file_input(view, "#auix-product-form", :image, [
          %{
            last_modified: 1_594_171_879_000,
            name: "test.png",
            content: content,
            size: byte_size(content),
            type: "image/png"
          }
        ])

      render_upload(upload, "test.png")

      view
      |> form("#auix-product-form",
        product: %{reference: reference, name: "Socket Aware Upload", quantity_initial: 0}
      )
      |> render_submit()

      product = Repo.get_by!(Product, reference: reference)
      # The arity-2 consumer prefixes the binary with the live_action assign value.
      assert product.image == "new:#{content}"
    end
  end
end
