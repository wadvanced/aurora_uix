# Live Updates

## Reacting to Data Changes

When the host names a PubSub server, every data change made through a generated UI is
published, and every open index over the same schema re-reads its current page. Other browser
sessions see a save or a delete without reloading.

### Enabling

```elixir
# config/config.exs
config :aurora_uix, pubsub_server: MyApp.PubSub
```

Name a `Phoenix.PubSub` server your application already supervises; Aurora UIX starts no
process. With the key unset, nothing is subscribed or broadcast, and every view behaves as
before: only the session that made a change refreshes.

### Topics and events

Each schema (or Ash resource) has one topic, `"auix:" <> inspect(schema)` — for example
`auix:MyApp.Inventory.Product`. `Aurora.Uix.Events.topic/1` builds it.

Every message on a topic is an `%Aurora.Uix.Event{}`:

| Field | Content |
|---|---|
| `schema` | the schema or Ash resource module |
| `action` | `:created`, `:updated`, `:deleted` or `:changed` |
| `ids` | primary-key values of the affected records; `[]` for `:changed` |
| `entities` | the written records when the publisher has them, else `[]` |

`:changed` means the data changed in a way that cannot be listed record by record (a bulk
update, an import).

The generated UI publishes:

| Action | Event |
|---|---|
| Form save of a new record | `:created` |
| Form save of an existing record (edit, show-edit) | `:updated` |
| Row delete | `:deleted` |
| One-to-many child row delete | `:deleted`, on the child's schema |
| "Delete selected" | one `:deleted` listing only the records actually deleted |

Embeds and many-to-many changes are saved through the parent form, so they publish the
parent's `:updated`. The view that made a change does not receive its own event: it refreshes
locally, as it always has.

### How an open index reacts

| On screen | Reaction |
|---|---|
| The list | Deleted ids leave the selection, then the current page is re-read with the viewer's own filters, sort, page and actor. |
| Show of an affected record | `:updated` re-reads the record; `:deleted` closes the view with the flash "Item deleted successfully". |
| Form on an affected record | The form keeps what the user typed; a flash reports the change. |

The list is always re-read, never patched from the event's `entities`, so Ash policies and
layout `where` conditions still apply to what each viewer sees.

The reactions are `auix_handle_info/2` clauses. An override of `auix_handle_info/2` must pass
every message it does not handle to `super`, as the `auix_handle_info/2` example under
[Index Handler Hook](#index-handler-hook-liveview) does.

### Publishing from host code

Any process can publish: a custom action, a background job, another LiveView.

```elixir
alias Aurora.Uix.Events

Events.created(product)                               # schema taken from the record
Events.updated(product)
Events.deleted(MyApp.Inventory.Product, [product.id])
Events.changed(MyApp.Inventory.Product)
```

A publisher returns what `Phoenix.PubSub.broadcast/3` returns, and `:ok` without broadcasting
when `pubsub_server` is not configured.

### Subscribing from host code

```elixir
def mount(_params, _session, socket) do
  if connected?(socket), do: Aurora.Uix.Events.subscribe(MyApp.Inventory.Product)
  {:ok, socket}
end

def handle_info(%Aurora.Uix.Event{action: :created}, socket) do
  {:noreply, put_flash(socket, :info, "A product was added")}
end

# The topic also carries :updated, :deleted and :changed
def handle_info(%Aurora.Uix.Event{}, socket), do: {:noreply, socket}
```

Subscribe once per schema: each call to `subscribe/1` adds a subscription, and each subscription
delivers the event again. `Aurora.Uix.Events.unsubscribe(MyApp.Inventory.Product)` stops the
messages, for example when a LiveView changes the schema it watches. With `pubsub_server` not
configured, both calls do nothing and return `:ok`.

### Index commands

Two requests are not data changes, so they are messages to one index LiveView process, never
broadcasts:

| Function | Effect |
|---|---|
| `Aurora.Uix.Events.refresh(pid \\ self())` | re-reads the current page |
| `Aurora.Uix.Events.reset_selection(pid \\ self())` | clears the selection, then re-reads the current page |

A handler running inside the index calls them with no argument. A task or job that holds the
index LiveView's pid passes it. Both work whether or not `pubsub_server` is configured.
