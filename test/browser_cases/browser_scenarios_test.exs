defmodule Aurora.UixWeb.Test.BrowserScenariosTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  import Aurora.UixWeb.Test.Scenario

  alias Aurora.Uix.Repo
  alias Aurora.Uix.Test.MirrorCtx.Product
  alias Wallaby.Query
  alias Wallaby.Session

  @new_button Query.css("a[name='auix-new-product']")
  @save_button Query.css("button[name='auix-save-product']")
  @gone_form Query.css("#auix-product-form", count: 0)
  @expand_details Query.css("details[name^='auix-details-auix-field-product-contacts-']")
  @add_embed Query.css(
               "div[name='auix-embeds_many-header_actions'] > button[phx-click='toggle-add-embeds']"
             )
  @do_add Query.css(
            "div[name='auix-embeds_many-new_entry_actions'] > button[form^='auix-embeds-many-']"
          )
  # The add form rejects a submit that arrives before its validation round trip ends.
  @add_form_settled Query.css("form[id$='-add-form']:not(.phx-change-loading)")
  @close_add Query.css(
               "div[id*='auix-embeds-many-add-auix-field-product-contacts-'][id$='-wrapper'] button.auix-modal-close-button"
             )

  # Wallaby is needed because the embeds-many add-entry modal and its entry list live in a
  # client-managed portal that Phoenix.LiveViewTest does not run.
  feature "a product is created without embeds-many entries", %{session: session} do
    each_backend(fn backend ->
      session
      |> visit(mirror_path(backend, "embeds", "products"))
      |> click_and_wait(@new_button, @save_button)
      |> fill_field("product[reference]", "browser-1")
      |> fill_field("product[name]", "Browser one")
      |> fill_field("product[quantity_initial]", "3")
      |> click_and_wait(@save_button, @gone_form)

      product = Repo.get_by!(Product, reference: "browser-1")
      assert product.name == "Browser one"
      assert product.contacts == []
    end)
  end

  # Wallaby is needed because the embeds-many add-entry modal and its entry list live in a
  # client-managed portal that Phoenix.LiveViewTest does not run.
  feature "embeds-many entries are added and removed in the browser", %{session: session} do
    each_backend(fn backend ->
      session
      |> visit(mirror_path(backend, "embeds", "products"))
      |> click_and_wait(@new_button, @save_button)
      |> fill_field("product[reference]", "browser-2")
      |> fill_field("product[name]", "Browser two")
      |> fill_field("product[quantity_initial]", "3")
      |> click_and_wait(@expand_details, @add_embed)
      |> click_and_wait(@add_embed, @do_add)
      |> add_remove_and_save_contacts()
    end)
  end

  @spec add_remove_and_save_contacts(Session.t()) :: Session.t()
  defp add_remove_and_save_contacts(session) do
    contacts = [
      %{email: "is_paul@test.com", name: "Home"},
      %{email: "is_tony@test.com", name: "Work"}
    ]

    contacts
    |> Enum.with_index()
    |> Enum.reduce(session, fn {contact, index}, acc ->
      acc
      |> fill_field(new_entry_input(:email), contact.email)
      |> fill_field(new_entry_input(:name), contact.name)
      |> assert_has(@add_form_settled)
      |> click(@do_add)
      |> assert_has(entry_input(:email, index))
    end)
    |> click_and_wait(@close_add, @add_embed)

    session
    |> assert_has(entry_input(:email, 1))
    |> click(Query.css("#auix-remove-button-0 button"))
    |> click(
      Query.css("#auix-remove-button-0 .auix-confirm-button--actions button:first-of-type")
    )
    |> assert_has(entry_input(:email, 1, count: 0))
    |> click_and_wait(@save_button, @gone_form)

    product = Repo.get_by!(Product, reference: "browser-2")
    assert Enum.map(product.contacts, &{&1.email, &1.name}) == [{"is_tony@test.com", "Work"}]
    session
  end

  @spec new_entry_input(atom()) :: Query.t()
  defp new_entry_input(field) do
    Query.css(
      "form[id^='auix-embeds-many-auix-field-product-contacts-'][id$='-add-form'] [id^='auix-field-product__contacts-#{field}-'][id$='--form']"
    )
  end

  @spec entry_input(atom(), integer(), keyword()) :: Query.t()
  defp entry_input(field, index, opts \\ []) do
    Query.css("[name='product[contacts][#{index}][#{field}]']", [visible: :any] ++ opts)
  end

  @spec fill_field(Session.t(), binary() | Query.t(), binary()) :: Session.t()
  defp fill_field(session, name, value) when is_binary(name),
    do: fill_field(session, Query.css("form#auix-product-form [name='#{name}']"), value)

  defp fill_field(session, %Query{} = query, value) do
    session
    |> assert_has(query)
    |> Kernel.tap(&click(&1, query))
    |> fill_in(query, with: value)
  end

  # Re-clicks until the expected element is present: the first click can land before the
  # LiveView has patched in the element that makes the click act.
  @spec click_and_wait(Session.t(), Query.t(), Query.t(), integer()) :: Session.t()
  defp click_and_wait(session, clickable, expected, retries \\ 5)
  defp click_and_wait(session, clickable, _expected, 0), do: click(session, clickable)

  defp click_and_wait(session, clickable, expected, retries) do
    session = click(session, clickable)

    if has?(session, expected) do
      session
    else
      click_and_wait(session, clickable, expected, retries - 1)
    end
  end
end
