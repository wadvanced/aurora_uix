defmodule Aurora.UixWeb.Test.Mirror.Variants.Uploads do
  @moduledoc """
  The `uploads` views variant: one upload flavour per product field.

  ## Key Features

  - `image` consumes its entries with an arity-1 consumer and offers no download: it sets
    `downloadable?: true` without a `download` producer, so no button shows
  - `thumbnail` consumes with an arity-1 consumer and offers a download
  - `description` consumes with an arity-2, socket-aware consumer
  - `status` consumes with a consumer that returns an error

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.Uploads` and `Aurora.UixWeb.Test.MirrorCtx.Uploads`
  """

  @doc """
  Declares the variant's resources and UI in the caller.

  ## Parameters
  - `opts` (keyword()) - `backend: :ash | :ctx`.

  ## Returns
  Macro.t() - The quoted variant.
  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts) do
    quote do
      use Aurora.UixWeb.Test.Mirror, unquote(opts)

      alias Aurora.UixWeb.Test.Mirror.Handlers

      mirror_resource :product do
        field :image do
          upload(
            allow: [accept: ~w(.png .jpg), max_entries: 1],
            consume: &Handlers.Consumer.consume_image/1,
            downloadable?: true
          )
        end

        field :thumbnail do
          upload(
            allow: [accept: ~w(.png .jpg), max_entries: 1],
            consume: &Handlers.Consumer.consume_image/1,
            downloadable?: &Handlers.Downloader.can_download?/1,
            download: &Handlers.Downloader.fetch/1
          )
        end

        field :description do
          upload(
            allow: [accept: ~w(.png .jpg), max_entries: 1],
            consume: &Handlers.SocketAwareConsumer.consume_with_action/2
          )
        end

        field :status do
          upload(
            allow: [accept: ~w(.png .jpg), max_entries: 1],
            consume: &Handlers.ErrorConsumer.fail/1
          )
        end
      end

      auix_create_ui do
        show_layout :product do
          stacked([
            :reference,
            :name,
            :quantity_initial,
            :image,
            :thumbnail,
            :description,
            :status
          ])
        end

        edit_layout :product, [] do
          stacked([
            :reference,
            :name,
            :quantity_initial,
            :image,
            :thumbnail,
            :description,
            :status
          ])
        end
      end
    end
  end
end
