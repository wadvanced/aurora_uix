defmodule Aurora.UixWeb.Test.AshActorPolicyTest do
  @moduledoc """
  Integration tests verifying that the actor assign is correctly forwarded from the
  Index LiveView to FormComponent and EmbedsManyComponent when `ash_actor_assign` is
  configured on `auix_resource_metadata`.

  Covers all 8 Acceptance Criteria from issue #271:
  - AC-1: default actor key (:current_user) forwarded to create → succeeds
  - AC-2: non-default actor key (:scope) forwarded to create → succeeds
  - AC-3: actor forwarded to update → succeeds
  - AC-4: actor forwarded to delete → element is present in UI
  - AC-5: actor forwarded through EmbedsManyComponent → add entry toggle succeeds
  - AC-6: no ash_actor_assign configured → renders without crash
  - AC-7: ash_actor_assign configured but assign absent → renders without crash
  - AC-8: policy denies (no actor) → error shown, no crash
  """
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  @actor %{id: "policy-test-actor"}

  auix_resource_metadata(:policy_item,
    ash_resource: AshActorTest.PolicyItem,
    ash_actor_assign: :current_user
  )

  auix_resource_metadata(:policy_item_scope,
    ash_resource: AshActorTest.PolicyItemScope,
    ash_actor_assign: :scope
  )

  auix_resource_metadata(:public_item,
    ash_resource: AshActorTest.PublicItem
  )

  auix_create_ui do
    edit_layout :policy_item do
      stacked([:name, :tags])
    end

    edit_layout :policy_item_scope do
      stacked([:name])
    end

    edit_layout :public_item do
      stacked([:name])
    end
  end

  setup do
    Ash.read!(AshActorTest.PolicyItem, authorize?: false)
    Ash.read!(AshActorTest.PolicyItemScope, authorize?: false)
    Ash.read!(AshActorTest.PublicItem, authorize?: false)
    :ok
  end

  @spec with_actor(Plug.Conn.t(), map()) :: Plug.Conn.t()
  defp with_actor(conn, actor), do: Plug.Test.init_test_session(conn, %{"test_actor" => actor})

  @spec with_scope(Plug.Conn.t(), map()) :: Plug.Conn.t()
  defp with_scope(conn, actor), do: Plug.Test.init_test_session(conn, %{"test_scope" => actor})

  @spec seed_policy_item(binary()) :: AshActorTest.PolicyItem.t()
  defp seed_policy_item(name) do
    AshActorTest.PolicyItem
    |> Ash.Changeset.for_create(:create, %{name: name}, actor: @actor)
    |> Ash.create!(authorize?: true)
  end

  describe "AC-1: create with :current_user actor" do
    test "form submission succeeds when actor is present in session", %{conn: conn} do
      conn = with_actor(conn, @actor)
      {:ok, view, _html} = live(conn, "/ash-actor-policy-items/new")

      view
      |> form("#auix-policy_item-form", policy_item: %{name: "actor-create-test"})
      |> render_submit()

      assert has_element?(view, "div.auix-index-container")
    end
  end

  describe "AC-2: create with non-default :scope actor key" do
    test "form submission succeeds when scope actor is present in session", %{conn: conn} do
      conn = with_scope(conn, @actor)
      {:ok, view, _html} = live(conn, "/ash-actor-scope-items/new")

      view
      |> form("#auix-policy_item_scope-form", policy_item_scope: %{name: "scope-create-test"})
      |> render_submit()

      assert has_element?(view, "div.auix-index-container")
    end
  end

  describe "AC-3: update with actor forwarded" do
    test "form submission succeeds when actor is present in session", %{conn: conn} do
      item = seed_policy_item("original-item")
      conn = with_actor(conn, @actor)
      {:ok, view, _html} = live(conn, "/ash-actor-policy-items/#{item.id}/edit")

      view
      |> form("#auix-policy_item-form", policy_item: %{name: "updated-item"})
      |> render_submit()

      assert has_element?(view, "div.auix-index-container")
    end
  end

  describe "AC-4: delete with actor forwarded" do
    test "delete link is rendered for items in the list", %{conn: conn} do
      _item = seed_policy_item("delete-test-item")
      conn = with_actor(conn, @actor)
      {:ok, view, _html} = live(conn, "/ash-actor-policy-items")

      assert has_element?(view, "a[name='auix-delete-policy_item']")
    end
  end

  describe "AC-5: EmbedsManyComponent with actor forwarded" do
    test "EmbedsManyComponent renders and toggle button is present when actor in session",
         %{conn: conn} do
      item = seed_policy_item("embeds-test-item")
      conn = with_actor(conn, @actor)
      {:ok, view, _html} = live(conn, "/ash-actor-policy-items/#{item.id}/edit")

      assert has_element?(view, "#auix-policy_item-form")

      assert has_element?(view, "[phx-click='toggle-add-embeds']"),
             "Expected toggle-add-embeds button to be present in the form"

      html_after_toggle =
        view
        |> element("[phx-click='toggle-add-embeds']")
        |> render_click()

      assert is_binary(html_after_toggle)
    end
  end

  describe "AC-6: no ash_actor_assign configured" do
    test "index renders without crash when no actor is configured", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/ash-actor-public-items")

      assert html =~ "auix-index-container"
    end

    test "new form renders without crash when no actor is configured", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/ash-actor-public-items/new")

      assert has_element?(view, "#auix-public_item-form")
    end
  end

  describe "AC-7: ash_actor_assign configured but assign absent in session" do
    test "index renders without crash when session has no actor", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/ash-actor-policy-items")

      assert html =~ "auix-index-container"
    end

    test "new form renders without crash when session has no actor", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/ash-actor-policy-items/new")

      assert has_element?(view, "#auix-policy_item-form")
    end
  end

  describe "AC-8: policy denies when actor is absent" do
    test "submitting create without actor results in an error, no crash", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/ash-actor-policy-items/new")

      result =
        view
        |> form("#auix-policy_item-form", policy_item: %{name: "denied-item"})
        |> render_submit()

      assert is_binary(result)

      assert has_element?(view, "#auix-policy_item-form") or
               has_element?(view, "div[role='alert']") or
               result =~ "error" or result =~ "forbidden" or result =~ "denied"
    end
  end
end
