# Reusable Components

`auix_create_ui` generates three LiveComponents for each resource, and one LiveView that hosts them:

| Module | Kind | Role |
|---|---|---|
| `.IndexComponent` | LiveComponent | The list: streams, filters, sort, pagination and selection |
| `.FormComponent` | LiveComponent | The create and edit form |
| `.ShowComponent` | LiveComponent | The read-only detail view |
| `.Index` | LiveView | Hosts the three components, owns the routes and wraps form and show in a modal |

This guide shows how to embed the components in a LiveView you write.

## Embedding a component

```elixir
defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view

  on_mount Aurora.Uix.Live.ComponentHooks

  def render(assigns) do
    ~H"""
    <.live_component
      module={MyAppWeb.ProductViews.Product.IndexComponent}
      id="low-stock"
      where={[{:quantity_at_hand, :lt, 10}]}
    />
    """
  end

  def handle_info({Aurora.Uix, "low-stock", {:open, :show, id}}, socket) do
    {:noreply, assign(socket, :selected_id, id)}
  end

  def handle_info({Aurora.Uix, _component_id, _intent}, socket), do: {:noreply, socket}
end
```

## Inputs

| Input | Applies to | Meaning |
|---|---|---|
| `id` | all | Required. DOM ids, stream names, form ids and event targets derive from it |
| `resource` | all | The resource name, an atom. Defaults to the resource the module was generated for |
| `entity` | form, show | The record to render |
| `entity_id` | form, show | The id of the record; the component loads it. Use it instead of `entity` |
| `action` | form, show | `:new`, `:edit`, `:show` or `:show_edit` |
| `where`, `order_by` | index | The scope of the list |
| `page` | index | The page to display. Defaults to the first |
| `parent` | index | The owner key and its value, for a list of children |
| `notify` | all | Who receives the outputs: a pid or `{module, id}`. Defaults to `self()` |
| actor assign | all | The assign named by `ash_actor_assign`, as in the generated LiveView |

An index instance may also override the index layout options (pagination, filters, selection, sort). An
option it leaves out takes the value the layout declares.

## Outputs

A component reports to its parent with a message `{Aurora.Uix, component_id, intent}`:

| Intent | Sent when |
|---|---|
| `{:saved, entity}` | The form saved a record |
| `{:closed}` | The form or the show view closed |
| `{:open, action, id}` | The user asked to open a record; `action` is `:show`, `:edit` or `:new` |
| `{:page, page}` | The index moved to another page |
| `{:deleted, ids}` | The index deleted records |

A component sends these in every host. It never patches, navigates or reads the URL.

## Events

Every event of a component carries `phx-target`, so it never reaches the host LiveView. `@auix._myself` holds
the target in the index, the form and the show view. A custom action sends its event to the component with it:

```elixir
<.auix_link phx-click="archive" phx-target={@auix._myself}>Archive</.auix_link>
```

`auix_link`, `auix_link_back` and `auix_back` pass `phx-target` through; without it they behave as before.

## Navigation

A component does not know how it is used. It reports what the user asked for, and its parent decides what
that means: render a form, assign a selected record, change the URL, or nothing.

The generated `.Index` LiveView is one such parent. It answers `{:open, action, id}`, `{:closed}` and
`{:page, page}` with `Aurora.Uix.Navigation`: a patch or a navigate under its routes, with the routing stack
in `?routing_stack=`. Its URLs are the ones it always had.

In the generated LiveView, `@auix.navigation` holds the `%Aurora.Uix.Navigation{}`: the base path, the
current path and the routing stack. `@auix.uri_path`, `@auix.uri_path_id`, `@auix.routing_stack` and
`@auix[:index_new_link]` remain readable there. They mirror `@auix.navigation`; change navigation through
`Aurora.Uix.Navigation`, `auix_route_forward/2` and `auix_route_back/1`, not by assigning those keys.

## Live updates

A component takes data changes through its own `update/2`:

```elixir
send_update(MyAppWeb.ProductViews.Product.IndexComponent, id: "low-stock", auix_event: event)
```

`on_mount Aurora.Uix.Live.ComponentHooks` does this for a whole LiveView: it subscribes to the topics of the
resources its components display and forwards each `%Aurora.Uix.Event{}` to every component instance.
Without the hook the components work, and update only when the host calls `send_update/2` itself.

## Several instances on one page

Components of the same resource can share a page, each with its own `id`, scope and options. Selection,
filters, sort, pagination and the open record are per instance. A data change reaches every instance, and
each one re-reads with its own scope.

## Generating the components alone

```elixir
auix_create_ui generate: [:index_component, :form_component, :show_component] do
  index_columns :product, [:reference, :name]
end
```

`generate:` lists the modules to generate. It defaults to
`[:live_view, :index_component, :form_component, :show_component]`.

## One-to-many lists

A one-to-many field renders an `IndexComponent` scoped to the parent record. In the generated LiveView it
looks and acts as before: its new, show and edit actions navigate to the child resource's routes, and
filters, selection, sort and paging stay off unless the field turns them on.

The list takes its columns from the resource the field names. Several resources can describe one schema, so
a child list can have its own columns:

```elixir
auix_resource_metadata :product, schema: Product, context: Inventory
auix_resource_metadata :product_compact, schema: Product, context: Inventory

auix_resource_metadata :product_location, schema: ProductLocation, context: Inventory do
  field :products, resource: :product_compact
end

auix_create_ui do
  index_columns :product_compact, [:reference, :name]
end
```

## Design decisions

1. **Compatibility.** The generated `.Index` LiveView keeps the full `IndexImpl` contract: its callbacks, the
   delivery of `send(self(), msg)` to `auix_handle_info/2`, and the `@auix` keys. A separate
   `IndexComponentImpl` behaviour covers the component.
2. **Presentation.** The form and the show view render without modal chrome. The generated `.Index` LiveView
   wraps them in a modal.
3. **Components report, parents decide.** A component has no navigation mode. It sends the same intents in
   every host; the generated `.Index` LiveView turns them into patches and navigations.
4. **One-to-many keeps its behaviour.** The child list is an embedded `IndexComponent` with the same
   columns, actions and `name` attributes. Editing children in place is opt-in and comes later.
5. **Live updates go through `update/2`.** The `on_mount` hook is wiring, not contract.
6. **The LiveView owns the URL.** No component reads or writes it, so any number of instances share a page.
