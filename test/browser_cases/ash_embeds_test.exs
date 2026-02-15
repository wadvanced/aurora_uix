defmodule Aurora.UixWeb.Test.BrowserAshEmbedsTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test
  use Wallaby.Feature

  alias Aurora.Uix.Guides.Blog.Post

  alias Wallaby.Query
  alias Wallaby.Session

  @new_button Query.css("a[name='auix-new-post']")
  @save_button Query.css("button[name='auix-save-post']")
  @expand_details_button Query.css("details[name^='auix-details-auix-field-post-tags-']")
  @add_embed_button Query.css(
                      "div[name='auix-embeds_many-header_actions'] > button[phx-click='toggle-add-embeds']"
                    )
  @do_add_button Query.css(
                   "div[name='auix-embeds_many-new_entry_actions'] > button[form^='auix-embeds-many-']"
                 )
  @close_add Query.css(
               "div[id*='auix-embeds-many-add-auix-field-post-tags-'][id$='-wrapper'] button.auix-modal-close-button"
             )

  auix_resource_metadata :post, schema: Post do
    field :content, html_type: :textarea
  end

  auix_create_ui do
    index_columns(:post, [:title, :published_at, :status])

    edit_layout :post,
      new_title: "Embeds many" do
      stacked do
        inline([:status])
        stacked([:title, :content])
        stacked([:comment, :tags])
      end
    end
  end

  feature "Create a new entry without embeds many ", %{session: session} do
    delete_all_blog_data()

    test_title = "My First post"
    test_content = "This is my first post in testing.\nShould be allright."

    # Checks if it is well shown
    page = visit(session, "/browser-ash-embeds-posts")

    page
    |> assert_text("Listing Posts")
    |> click_and_wait(@new_button, @save_button)

    session
    |> fill_field(&main_form/1, :title, test_title)
    |> fill_field(&main_form/1, :content, test_content)
    |> click_and_wait(@save_button, Query.text("Listing Posts"))

    post = Ash.read!(Post)

    post
    |> List.first()
    |> Kernel.tap(&assert(&1.title == test_title))
    |> Kernel.tap(&assert(&1.content == test_content))
    |> Kernel.tap(&assert(&1.comment.description == nil))
    |> Kernel.tap(&assert(&1.tags == nil))
  end

  feature "Create a new entry with embeds many ", %{session: session} do
    delete_all_blog_data()
    test_title = "My Second post"
    test_content = "This is my second post in testing.\nShould be allright."
    test_comment__description = "Commenting in"

    tags = [
      %{name: "Tag one"},
      %{name: "Tag two"}
    ]

    # Checks if it is well shown
    session
    |> visit("/browser-ash-embeds-posts")
    |> assert_text("Listing Posts")
    |> click_and_wait(@new_button, @save_button)

    # Main section
    session
    |> fill_field(&main_form/1, :title, test_title)
    |> fill_field(&main_form/1, :content, test_content)
    |> fill_field(&comment_form/1, :description, test_comment__description)
    |> click_and_wait(@expand_details_button, @add_embed_button)
    |> click_and_wait(@add_embed_button, @do_add_button)

    # Tags
    tags
    |> Enum.reduce(session, fn tag_entry, acc ->
      acc
      |> pause()
      |> fill_field(&new_embed_form/1, :name, tag_entry.name)
      |> click_and_wait(@do_add_button, Query.css("Success!"))
    end)
    |> click_and_wait(@close_add, @add_embed_button)

    # Validate tags
    Enum.with_index(tags, fn tag_entry, index ->
      validate_field(session, :name, index, tag_entry.name)
    end)

    click_and_wait(session, @save_button, Query.text("Listing Posts"))

    posts = Ash.read!(Post)

    posts
    |> List.first()
    |> Kernel.tap(&assert(&1.title == test_title))
    |> Kernel.tap(&assert(&1.content == test_content))
    |> Kernel.tap(&assert(&1.comment.description == test_comment__description))
    |> Kernel.tap(&assert_tags(&1, tags))
  end

  @spec main_form(atom()) :: Query.t()
  defp main_form(field) do
    Query.css("form#auix-post-form [id^='auix-field-post-#{field}-'][id$='--form']")
  end

  @spec comment_form(atom()) :: Query.t()
  defp comment_form(field) do
    Query.css("form#auix-post-form [id^='auix-field-post__comment-#{field}-'][id$='--form']")
  end

  @spec new_embed_form(atom()) :: Query.t()
  defp new_embed_form(field) do
    Query.css(
      "form[id^='auix-embeds-many-auix-field-post-tags-'][id$='-add-form'] [id^='auix-field-post__tags-#{field}-'][id$='--form']"
    )
  end

  @spec tags_form(atom(), integer()) :: Query.t()
  defp tags_form(field, index) do
    Query.css("[name='post[tags][#{index}][#{field}]'")
  end

  @spec validate_field(Session.t(), atom(), integer(), binary()) :: Session.t()
  defp validate_field(session, field, index, value) do
    assert field
           |> tags_form(index)
           |> then(&attr(session, &1, "value")) == value

    session
  end

  @spec fill_field(Session.t(), function(), atom(), term()) :: Session.t()
  defp fill_field(session, query, field, value) do
    field_query =
      query.(field)

    field_query
    |> Kernel.tap(&click(session, &1))
    |> then(&fill_in(session, &1, with: value))
    |> wait_for_value(field_query, value)
  end

  @spec click_and_wait(Session.t(), Query.t(), Query.t(), boolean(), integer()) :: Session.t()
  defp click_and_wait(session, clickable, expected, state \\ true, retries \\ 5)
  defp click_and_wait(session, clickable, _expected, _state, 0), do: click(session, clickable)

  defp click_and_wait(session, clickable, expected, state, retries) do
    page = click(session, clickable)

    if has?(page, expected) == state do
      page
    else
      click_and_wait(session, clickable, expected, state, retries - 1)
    end
  end

  @spec wait_for_value(Session.t(), Query.t(), term(), integer()) :: Session.t()
  defp wait_for_value(session, field, value, retries \\ 5)
  defp wait_for_value(session, _field, _value, 0), do: session

  defp wait_for_value(session, field, value, retries) do
    if has_value?(session, field, value) do
      session
    else
      session
      |> pause()
      |> wait_for_value(field, value, retries - 1)
    end
  end

  @spec assert_tags(map(), list()) :: :boolean
  defp assert_tags(%{tags: tags}, expected) do
    assert expected
           |> Enum.with_index(fn expect, index ->
             tag_equals?(Enum.at(tags, index), expect)
           end)
           |> Enum.all?()
  end

  @spec tag_equals?(map(), map()) :: boolean()
  defp tag_equals?(%{name: name}, %{name: name}), do: true
  defp tag_equals?(_tag, _expected_tag), do: false

  @spec pause(Session.t()) :: Session.t()
  defp pause(session) do
    Process.sleep(100)
    session
  end
end
