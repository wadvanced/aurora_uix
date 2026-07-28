defmodule Aurora.UixWeb.Test.AshOne2OneTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Blog.Author
  alias Aurora.Uix.Guides.Blog.AuthorProfile

  # Routes for both resources are registered in test/support/app_web/routes.ex as
  # "ash-one2one-authors" and "ash-one2one-author-profiles".
  auix_resource_metadata(:author, schema: Author)
  auix_resource_metadata(:author_profile, schema: AuthorProfile)

  auix_create_ui do
    edit_layout :author do
      stacked([:name, :email, :bio, :author_profile])
    end

    edit_layout :author_profile do
      stacked([:website, :twitter_handle, :years_active])
    end

    show_layout :author do
      stacked([:name, :email, :author_profile])
    end

    show_layout :author_profile do
      stacked([:website, :twitter_handle, :years_active])
    end
  end

  describe "form rendering" do
    test "renders blank nested inputs on new, with no child record", %{conn: conn} do
      delete_all_blog_data()

      {:ok, view, _html} = live(conn, "/ash-one2one-authors/new")

      assert has_element?(view, "#auix-one-to-one-author_profile-form")

      for field <- ~w(website twitter_handle years_active) do
        assert has_element?(view, "input[name='author[author_profile][#{field}]']")
      end
    end

    test "pre-fills nested inputs on edit and keeps the child's foreign key hidden", %{conn: conn} do
      delete_all_blog_data()
      [author] = create_sample_authors_with_profiles(1)

      {:ok, view, _html} = live(conn, "/ash-one2one-authors/#{author.id}/edit")

      assert has_element?(
               view,
               "input[name='author[author_profile][website]'][value='https://author-1.test']"
             )

      refute has_element?(view, "select[name='author[author_profile][author_id]']")
    end
  end

  describe "writing through the parent form" do
    test "creates the author and its profile in one submit", %{conn: conn} do
      delete_all_blog_data()

      {:ok, view, _html} = live(conn, "/ash-one2one-authors/new")

      view
      |> form("#auix-author-form", %{
        "author" => %{
          "name" => "Nested Author",
          "email" => "nested@test.com",
          "bio" => "Created with a profile",
          "author_profile" => %{
            "website" => "https://nested.test",
            "twitter_handle" => "@nested",
            "years_active" => "7"
          }
        }
      })
      |> render_submit()

      author =
        Author
        |> Ash.read!()
        |> List.first()
        |> Ash.load!(:author_profile)

      assert author.name == "Nested Author"
      assert author.author_profile.website == "https://nested.test"
      assert author.author_profile.years_active == 7
      assert author.author_profile.author_id == author.id
    end

    test "updates the existing profile in place rather than adding a second", %{conn: conn} do
      delete_all_blog_data()
      [author] = create_sample_authors_with_profiles(1)

      {:ok, view, _html} = live(conn, "/ash-one2one-authors/#{author.id}/edit")

      view
      |> form("#auix-author-form", %{
        "author" => %{
          "name" => author.name,
          "email" => author.email,
          "bio" => author.bio,
          "author_profile" => %{
            "website" => "https://updated.test",
            "twitter_handle" => "@updated",
            "years_active" => "9"
          }
        }
      })
      |> render_submit()

      profiles = Ash.read!(AuthorProfile)

      assert Enum.count(profiles) == 1
      assert List.first(profiles).website == "https://updated.test"
      assert List.first(profiles).author_id == author.id
    end
  end

  describe "show rendering" do
    test "renders the child read-only", %{conn: conn} do
      delete_all_blog_data()
      [author] = create_sample_authors_with_profiles(1)

      {:ok, view, _html} = live(conn, "/ash-one2one-authors/#{author.id}/show")

      assert has_element?(view, "#auix-one-to-one-author_profile-show")

      assert view
             |> element("#auix-one-to-one-author_profile-show")
             |> render() =~ "https://author-1.test"

      # `:show` displays fields as disabled inputs, so read-only means every input is disabled.
      refute has_element?(view, "#auix-one-to-one-author_profile-show input:not([disabled])")
    end

    test "renders the empty message when there is no child", %{conn: conn} do
      delete_all_blog_data()

      author =
        Author
        |> Ash.Changeset.for_create(:create, %{
          name: "No Profile",
          email: "noprofile@test.com",
          bio: "Has no profile"
        })
        |> Ash.create!()

      {:ok, view, _html} = live(conn, "/ash-one2one-authors/#{author.id}/show")

      assert has_element?(view, "#auix-one-to-one-author_profile-show .auix-one-to-one-empty-msg")
    end
  end

  describe "index" do
    test "never renders the association as a column", %{conn: conn} do
      delete_all_blog_data()
      create_sample_authors_with_profiles(2)

      {:ok, view, _html} = live(conn, "/ash-one2one-authors")

      refute view
             |> element("table.auix-items-table thead")
             |> render() =~ "Author Profile"
    end
  end
end
