defmodule Aurora.UixWeb.Test.GuidesCapture.UploadStore do
  @moduledoc false

  @doc false
  @spec consume([binary()]) :: {:ok, binary()}
  def consume([binary]), do: {:ok, binary}

  @doc false
  @spec download(binary()) :: {:ok, %{name: binary(), content: binary()}}
  def download(value), do: {:ok, %{name: "desk-lamp.png", content: value}}

  @doc false
  @spec info(binary()) :: %{name: binary(), size: non_neg_integer(), content_type: binary()}
  def info(_value), do: %{name: "desk-lamp.png", size: 48_213, content_type: "image/png"}
end

defmodule Aurora.UixWeb.Test.GuidesCapture.UploadsLayout do
  @moduledoc false
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.UixWeb.Test.GuidesCapture.UploadStore

  auix_resource_metadata :product do
    context Inventory
    schema(Product)

    field :thumbnail do
      label("Photo")

      upload(
        allow: [accept: ~w(.png .jpg), max_entries: 1],
        consume: &UploadStore.consume/1,
        downloadable?: true,
        download: &UploadStore.download/1,
        file_info: &UploadStore.info/1
      )
    end

    field :image do
      label("Data sheet")
      upload(allow: [accept: ~w(.pdf), max_entries: 1], consume: &UploadStore.consume/1)
    end
  end

  auix_create_ui do
    index_columns(:product, [:reference, :name], order_by: :reference)

    edit_layout :product do
      stacked([:name, :thumbnail, :image])
    end
  end
end
