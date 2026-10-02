# What's New in 0.1.6

This page walks through the changes of this release that you are most likely to use, with
examples you can paste into your own project. It is rewritten for every release; the
[CHANGELOG](../../CHANGELOG.md) keeps the complete history, including every fix.

- [Upgrading from 0.1.5](#upgrading-from-0-1-5)
- [Live updates across sessions](#live-updates-across-sessions)
- [Click-to-sort column headers](#click-to-sort-column-headers)
- [Unsaved-changes guard](#unsaved-changes-guard)
- [Predefined field renderers](#predefined-field-renderers)
- [Renderers by HTML type](#renderers-by-html-type)
- [Multi-value selects](#multi-value-selects)
- [The `contains` filter](#the-contains-filter)
- [Custom action labels and name functions](#custom-action-labels-and-name-functions)

## Upgrading from 0.1.5

Most of this release is additive. These are the points that can require a change in your
application.

**1. Re-generate the stylesheet.** Several widgets and dialogs bring new theme classes, and
the generated `auix-*.css` files are not rebuilt by a dependency update:

```shell
mix auix.gen.stylesheet
```

**2. Rename `Aurora.Uix.Gettext`.** The old name shadowed the `Gettext` library module:

```elixir
# before
use Aurora.Uix.Gettext

# after
use Aurora.Uix.GettextResolver
```

**3. `:in` conditions take a list.** A comma-separated string is no longer split:

```elixir
# before — now an invalid query on Ash, ArgumentError on Ecto
where: [{:status, :in, "draft,published"}]

# after
where: [{:status, :in, ["draft", "published"]}]
```

**4. Ash 3.33+ needs a string-length mode.** Ash demands it at compile time for resources
with string constraints:

```elixir
# config/config.exs
config :ash, default_string_length_count: :codepoints
```

**5. Groups are flat by default.** A group no longer paints a card inside its container. To
keep the previous look, restore the two variables in your own stylesheet:

```css
:root {
  --auix-color-group-container-bg: var(--auix-color-bg-light);
  --auix-color-group-container-border: var(--auix-color-border-primary);
}
```

**6. Multi-value selects need a host-side blank filter.** See
[Multi-value selects](#multi-value-selects).

## Live updates across sessions

Name a `Phoenix.PubSub` server your application already supervises and every save or delete
made through a generated UI shows up in the other open sessions, on Ash and Ecto resources
alike:

```elixir
# config/config.exs
config :aurora_uix, pubsub_server: MyApp.PubSub
```

What each session sees:

| On screen | Reaction |
|---|---|
| An index over the same schema | Re-reads its current page, keeping the viewer's own filters, sort and page |
| A show of the changed record | Follows an update; closes on a delete |
| A form on the changed record | Keeps what the user typed and shows a notice |

Without the key nothing is subscribed or broadcast, and only the session that made the change
refreshes, exactly as before.

Changes that do not go through a generated UI (a background job, an import, a custom action)
publish through `Aurora.Uix.Events`:

```elixir
alias Aurora.Uix.Events

Events.created(product)                                # schema taken from the record
Events.updated(product)
Events.deleted(MyApp.Inventory.Product, [product.id])
Events.changed(MyApp.Inventory.Product)                # bulk change, not listed record by record
```

A host LiveView can listen too:

```elixir
def mount(_params, _session, socket) do
  if connected?(socket), do: Aurora.Uix.Events.subscribe(MyApp.Inventory.Product)
  {:ok, socket}
end
```

See [Reacting to Data Changes](../core/liveview.md#reacting-to-data-changes).

## Click-to-sort column headers

Index column headers are now clickable: click to sort by that column, click again to reverse.
The chosen sort replaces the layout's `order_by` until the page is reloaded, on both backends.

```elixir
index_columns :product, [:reference, :name, :price],
  order_by: [asc: :name]            # the initial order, until a header is clicked
```

Columns that cannot be ordered (associations, embeds, arrays, maps, uploads) are skipped
automatically. Opt any other column out with `sortable?: false`:

```elixir
auix_resource_metadata :product, context: Inventory, schema: Product do
  field :description, sortable?: false
end
```

## Unsaved-changes guard

Closing the new/edit form modal with unsaved changes — the × button, `Esc` or a click outside
it — now opens a confirmation dialog ("Keep editing" / "Discard changes") instead of silently
throwing the input away. A form without changes closes as before.

To turn it off for a resource, use the form layout option:

```elixir
edit_layout :product, unsaved_changes_guard_disabled?: true do
  stacked [:reference, :name, :description]
end
```

If you override `modal/1` in your own components, honour its new `hide_on_cancel?` attribute
(default `true`); otherwise the modal hides before the dialog can appear.

## Predefined field renderers

A field's renderer slots (`renderer`, `index_renderer`, `edit_renderer`, `show_renderer`)
now accept an atom that names a ready-made widget:

```elixir
auix_resource_metadata :product, context: Inventory, schema: Product do
  field :active, renderer: :toggle_switch
  field :brand_color, renderer: :color
  field :status, index_renderer: :badge, show_renderer: :badge
  field :stock_level, renderer: :progress_bar, data: %{max: 100}
  field :homepage, renderer: :url
  field :score, renderer: :rating, data: %{max: 5}
end
```

| Atom | For | Index | Show | Form |
|------|-----|:-----:|:----:|:----:|
| `:toggle_switch` | boolean | switch | switch | toggle switch |
| `:color` | hex / rgb / named color | swatch | swatch | color picker |
| `:badge` | enum / status | pill | pill | default input |
| `:progress_bar` | number | bar | bar | default input |
| `:url` | string | text | link | default input |
| `:rating` | number | stars | stars | interactive stars |

`renderer:` covers show and form only. To render the widget in the index as well, set
`index_renderer:` too.

Add your own atoms, or replace a built-in, through a registrar:

```elixir
# config/config.exs
config :aurora_uix, :renderers, MyApp.Renderers

defmodule MyApp.Renderers do
  @behaviour Aurora.Uix.RendererRegistrar

  @impl true
  def renderers, do: %{uppercase: &MyApp.Renderers.Uppercase.render/1}
end

# then, like any built-in
field :sku, renderer: :uppercase
```

See [Predefined Renderers](../customization/predefined_renderers.md).

## Renderers by HTML type

Instead of setting a renderer on every field, map an HTML type to a renderer once and every
field of that type gets it. The `renderers:` option is accepted at every level:

```elixir
# config/config.exs — the whole application
config :aurora_uix, :html_type_renderers, %{checkbox: :toggle_switch}

defmodule MyAppWeb.ProductUi do
  # every resource of this module
  use Aurora.Uix, renderers: %{checkbox: :toggle_switch}

  # one resource
  auix_resource_metadata :product,
    context: Inventory,
    schema: Product,
    renderers: %{checkbox: :badge}

  # every layout this auix_create_ui generates, and one layout of it
  auix_create_ui renderers: %{checkbox: :default_checkbox} do
    index_columns :product, [:name, :active], renderers: %{checkbox: :toggle_switch}
  end
end
```

The most specific declaration wins, highest first:

1. the field's own renderer slot
2. the layout macro (`index_columns`, `edit_layout`, `show_layout`)
3. `auix_create_ui`
4. `auix_resource_metadata`
5. `use Aurora.Uix`
6. the application config
7. the default rendering

To undo a broader entry for one HTML type, point it at a named default:
`:default_checkbox`, `:default_date`, `:default_datetime_local`, `:default_number`,
`:default_select`, `:default_text`, `:default_textarea` or `:default_time`.

Association, embed, upload and hidden fields ignore these tables and keep their own rendering.
Works the same on Ash and Ecto resources.

## Multi-value selects

A multi-value attribute with a fixed option set is now a multi-select on both backends, and it
renders as a checkbox group instead of a `<select multiple>`:

- **Form**: one checkbox per option, with a tri-state toggle-all checkbox beside the label.
- **Show**: the selected options as a read-only list.
- **Index**: the selected labels, joined.

The attribute declarations that trigger it:

```elixir
# Ash
attribute :labels, {:array, :atom} do
  constraints nil_items?: true,
              items: [one_of: [:featured, :sponsored, :opinion, :full_review]]

  public? true
end

# Ecto
field :labels, {:array, Ecto.Enum}, values: [:fragile, :perishable, :hazardous]
```

Also detected as selects now: an attribute typed by a `use Ash.Type.Enum` module, and an
`Ash.Type.NewType` over `Ash.Type.Atom` or over an enum module. A scalar array with **no**
option set renders as a read-only list.

> #### Host contract {: .warning}
> The checkbox group always submits one blank value, so that unchecking the last box clears
> the field. Your changeset or action must drop that blank. The demo
> schemas `lib/aurora_uix/guides/blog/post.ex` (`reject_blank_labels/2`, Ash) and
> `lib/aurora_uix/guides/inventory/product.ex` (Ecto) are the reference implementations.

A minimal Ecto version:

```elixir
defp reject_blank_labels(%{"labels" => labels} = attrs) when is_list(labels),
  do: %{attrs | "labels" => Enum.reject(labels, &(&1 in ["", nil]))}

defp reject_blank_labels(attrs), do: attrs
```

The toggle-all control is the `:default_toggle_all` action, registered under the new
`:multi_select` action group, so you can add, replace or remove it from the field options.
See [Custom Actions](../customization/custom_actions.md).

## The `contains` filter

The index filter bar offers a new condition on text fields, `contains (~)`: a case-insensitive
substring search on both backends. Backslash, `%` and `_` in the typed value match literally,
and a blank value applies no filter.

If you filter programmatically, `:like` and `:ilike` conditions on Ash now match by pattern
instead of silently behaving as `:eq` (both need AshPostgres):

```elixir
index_columns :product, [:name],
  where: [{:name, :ilike, "%desk%"}]
```

## Custom action labels and name functions

The labels of the standard buttons are layout options:

```elixir
index_columns :product, [:name], new_action_label: "Add product"
edit_layout :product, save_action_label: "Store product" do
  stacked [:reference, :name]
end
show_layout :product, edit_action_label: "Change", back_action_label: "Back to list" do
  stacked [:reference, :name]
end
```

A resource's `:name` and `:title` can also be a captured 0-arity function returning a binary,
called wherever the name or title appears in a default title, subtitle or label — handy for
translating at render time:

```elixir
auix_resource_metadata :product,
  context: Inventory,
  schema: Product,
  name: &MyApp.Labels.product_name/0,
  title: &MyApp.Labels.product_title/0
```

## Where to go next

- The full list of fixes and changes: [CHANGELOG](../../CHANGELOG.md)
- Everything about layouts and their options: [Layouts](../core/layouts.md)
- Writing your own widgets: [Predefined Renderers](../customization/predefined_renderers.md)
