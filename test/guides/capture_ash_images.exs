Code.require_file("test/guides/image_helper.exs")

defmodule Aurora.UixWeb.Test.Guides.CaptureAshImages do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test
  use Wallaby.Feature

  import Aurora.UixWeb.Test.Guides.ImageHelper
  alias Wallaby.Query
  alias Wallaby.Session

  feature "create_images", %{session: session} do
    create_guides_sample_data()

    session
    |> create_overview_images(:desktop)
    |> create_overview_images(:mobile)
  end

  @spec create_overview_images(Session.t(), atom()) :: Session.t()
  defp create_overview_images(session, screen_size) do
    url = "/guides-overview/posts"
    target = "guides/core/images/ash"

    post_id =
      Aurora.Uix.Guides.Blog.Post
      |> Ash.read!()
      |> List.first()
      |> Map.get(:id)

    session
    |> reset_window_size(screen_size)

    # index
    |> visit(url)
    |> capture(:index, screen_size, target, %{
      desktop: [center_crop_width: 896, center_crop_height: 960],
      mobile: [crop_height: 1_024]
    })

    # show
    |> visit("#{url}/#{post_id}/show")
    |> capture(:show, screen_size, target, %{
      all: [
        click: "input[id^='auix-field-post-title-'][id$='#{post_id}--show']"
      ],
      desktop: [zoom: 0.80, center_crop_width: 672],
      mobile: [center_crop_width: 640, crop_height: 1_440]
    })

    # edit
    |> visit("#{url}/#{post_id}/edit")
    |> capture(:edit, screen_size, target, %{
      all: [
        click: "input[id^='auix-field-post-title-'][id$='#{post_id}--form']"
      ],
      desktop: [zoom: 0.75, center_crop_width: 768],
      mobile: [zoom: 0.90]
    })
  end
end
