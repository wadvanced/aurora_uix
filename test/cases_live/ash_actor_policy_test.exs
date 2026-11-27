defmodule Aurora.UixWeb.Test.AshActorPolicyTest do
  @moduledoc "Ash actors and policies: the actor assign reaches the Ash resources through the generated UI."
  use Aurora.UixWeb.Test.UICase, :phoenix_case

  @actor %{id: "policy-test-actor"}

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

  test "the generated UI forwards the session actor to create, update and delete", %{conn: conn} do
    # create with the :current_user assign
    {:ok, view, _html} = live(with_actor(conn, @actor), "/ash-actor-policy-items/new")

    view
    |> form("#auix-policy_item-form", policy_item: %{name: "actor-create-test"})
    |> render_submit()

    assert has_element?(view, "div.auix-index-container")

    # create with the non-default :scope assign
    {:ok, scope_view, _html} = live(with_scope(conn, @actor), "/ash-actor-scope-items/new")

    scope_view
    |> form("#auix-policy_item_scope-form", policy_item_scope: %{name: "scope-create-test"})
    |> render_submit()

    assert has_element?(scope_view, "div.auix-index-container")

    # update
    item = seed_policy_item("original-item")

    {:ok, edit_view, _html} =
      live(with_actor(conn, @actor), "/ash-actor-policy-items/#{item.id}/edit")

    edit_view
    |> form("#auix-policy_item-form", policy_item: %{name: "updated-item"})
    |> render_submit()

    assert has_element?(edit_view, "div.auix-index-container")

    # delete
    {:ok, index_view, _html} = live(with_actor(conn, @actor), "/ash-actor-policy-items")
    assert has_element?(index_view, "a[name='auix-delete-policy_item']")

    # embeds-many component
    {:ok, embeds_view, _html} =
      live(with_actor(conn, @actor), "/ash-actor-policy-items/#{item.id}/edit")

    assert has_element?(embeds_view, "#auix-policy_item-form")
    assert has_element?(embeds_view, "[phx-click='toggle-add-embeds']")

    embeds_view
    |> element("[phx-click='toggle-add-embeds']")
    |> render_click()

    assert has_element?(embeds_view, "#auix-policy_item-form")
  end

  test "without an actor the views mount and a policy denies the create and the delete",
       %{conn: conn} do
    {:ok, public_view, _html} = live(conn, "/ash-actor-public-items")
    assert has_element?(public_view, "div.auix-index-container")

    {:ok, public_form, _html} = live(conn, "/ash-actor-public-items/new")
    assert has_element?(public_form, "#auix-public_item-form")

    {:ok, index_view, _html} = live(conn, "/ash-actor-policy-items")
    assert has_element?(index_view, "div.auix-index-container")

    {:ok, view, _html} = live(conn, "/ash-actor-policy-items/new")
    assert has_element?(view, "#auix-policy_item-form")

    view
    |> form("#auix-policy_item-form", policy_item: %{name: "denied-item"})
    |> render_submit()

    assert has_element?(view, "#auix-policy_item-form")

    denied = Ash.read!(AshActorTest.PolicyItem, authorize?: false)
    assert Enum.filter(denied, &(&1.name == "denied-item")) == []

    # a refused delete keeps the index up and shows an error
    item = seed_policy_item("undeletable-item")
    {:ok, delete_view, _html} = live(conn, "/ash-actor-policy-items")

    delete_view
    |> element("tr a[name='auix-delete-policy_item'][phx-click*='#{item.id}']")
    |> render_click()

    assert has_element?(delete_view, "div.auix-index-container")
    assert has_element?(delete_view, "#flash-error", "Item could not be deleted")
    assert Ash.get!(AshActorTest.PolicyItem, item.id, authorize?: false)
  end
end
