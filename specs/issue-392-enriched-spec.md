<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** high

### Overview
Every data change made through a generated UI is published as an `%Aurora.Uix.Event{}` on the host's Phoenix PubSub (`config :aurora_uix, pubsub_server:`). The generated Index LiveView subscribes to its schema's topic, re-reads its page, and reacts in an open show or form. Host code publishes through the new public `Aurora.Uix.Events` module and drives an index with the `refresh` and `reset_selection` commands. The publishers and the subscriber live in the shared handlers, so Ash (`blog`) and Ecto (`inventory`) behave the same, and each UI section tests both.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | `CHANGELOG.md`; `guides/core/liveview.md` § Index Handler Hook (LiveView), § Adding Custom Events, new § Reacting to Data Changes; `guides/customization/custom_actions.md` new § Refreshing the Index from a Custom Action; `guides/introduction/getting_started.md` new § Live Updates (optional) | none | federico/392-doc-1-events-guides | docs: document data-change events and index commands (#392 · DOC-1) |
| UI-1 | UI | `Aurora.Uix.Event`, `Aurora.Uix.Events`, `pubsub_server` key in `config/config.exs` | DOC-1 | federico/392-ui-1-events-api | feat: add the Aurora.Uix.Events publish/subscribe API (#392 · UI-1) |
| UI-2 | UI | handler · index subscriber, built-in publishers, index commands, "Delete selected" ids | UI-1 | federico/392-ui-2-index-subscriber | feat: publish data changes and re-read subscribed indexes (#392 · UI-2) |
| UI-3 | UI | handler + generator · open show and form reactions, form state kept across a parent re-render | UI-2 | federico/392-ui-3-open-record-reactions | feat: react to data changes in an open show or form (#392 · UI-3) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
- `guides/core/liveview.md` § Index Handler Hook (LiveView) — example "Override `auix_handle_event/3`"
- `guides/core/liveview.md` § Adding Custom Events — "In Index Handler" example
- `guides/core/liveview.md` § Callback Reference (the new section goes immediately before it)
- `guides/customization/custom_actions.md` § Association Actions (the new section goes immediately before it)
- `guides/introduction/getting_started.md` § Installation, § CSS Configuration (the new section goes between them)

#### Implementation details

##### CHANGELOG.md
1. § `## [0.1.6]` — replace every line from the `### Fixes` heading through the line directly above the `## [0.1.5] - 2026-07-28` heading with the text below, verbatim, followed by one blank line. The lines above `### Fixes` (the `## [0.1.6]` heading, the release summary, the `Requires:` list) stay unchanged.
   ~~~~
   ### Fixes

   - **A layout `where` was lost as soon as the filter bar was submitted**
     - A layout `where` now stays in force when the filter bar is submitted, on both backends, and
       submitted filters survive closing a modal.

   - **The filter bar's "in list" condition was ignored on Ecto resources**
     - The comma-separated values typed into the filter bar now filter Ecto resources too. On Ecto,
       an unsupported condition now raises `ArgumentError` instead of matching every row.

   - **Ash rejected the direction-first `order_by`**
     - `order_by: [desc: :published_at]` now works on Ash, including the `*_nulls_first` and
       `*_nulls_last` directions, as does a single-tuple `where`.

   - **Ash one-to-many tables rendered no rows**
     - A one-to-many table over an Ash resource now lists its rows.

   - **Ash silently collapsed `:like` and `:ilike` where-clauses into `:eq`**
     - A `:like` or `:ilike` condition on an Ash resource now matches by pattern instead of returning
       only exact matches.
     - Both operators need AshPostgres: on another Ash data layer the filter raises.

   - **Ash aggregates of kind `:first`, `:list` and `:custom` had no type, and `sum`/`max`/`min` were always `:float`**
     - Every Ash aggregate kind now gets a type, so the field renders and can be placed in
       `index_columns`. `sum`, `max` and `min` take the type of the aggregated attribute, and a
       `:list` aggregate renders read-only, like any other scalar array.
     - A `custom` aggregate that declares its type by short name (`custom :joined, :rel, :string`) no
       longer raises `ArgumentError`, and an aggregate over an Ash enum attribute takes the type the
       enum stores.

   - **Aggregate, calculation and association columns rendered an empty cell in the index**
     - The index now loads the aggregates, calculations and associations its columns show, as show
       and form already did.

   - **The multi-select toggle-all checkbox stayed clickable on a disabled or read-only field**
     - The toggle-all checkbox now follows its field's disabled and read-only state.

   - **Every `--auix-opacity-*` variable was undeclared, so nothing dimmed**
     - The modal close button renders at 20% opacity (40% on hover) instead of fully opaque, and
       loading and disabled states dim again.

   - **Multi-word checkbox-group and selected-list labels broke mid-word**
     - An option label and a read-only selected-list item now stay on one line; a long label scrolls
       horizontally instead of breaking the row.

   - **Title and subtitle layout options are plain strings**
     - A binary `edit_title`, `edit_subtitle`, `new_title`, `new_subtitle`, `page_title` or
       `page_subtitle` is used as written, like any other string option, instead of being evaluated
       as a template.
     - The index renders no blank subtitle line when `page_subtitle` is not set.
     - The default form subtitles quote the resource name
       (`"Creates a new 'Product' record in your database"`) instead of wrapping it in `<strong>`,
       and the `edit_subtitle` default is now translated through Gettext.

   - **Multi-value atom and enum attributes not detected as multiple selects**
     - An Ash `{:array, :atom}` with an `items: [one_of: ...]` constraint and an Ecto
       `{:array, Ecto.Enum}` now render as multi-value selects.
     - Multi-value selects are excluded from filtering.
     - An index cell shows the selected option labels joined, instead of raising.

   ### Added

   - **Live updates across sessions through Phoenix PubSub**
     - With `config :aurora_uix, pubsub_server: MyApp.PubSub`, a save or delete made in one session
       updates every open index over the same data, on Ash and Ecto alike. An open show follows the
       change, and an open form keeps what the user typed and shows a notice.
     - Host code publishes its own changes and refreshes an index through the new
       `Aurora.Uix.Events` module.

   - **Sortable index column headers**
     - Click a column header to sort the index by it; click again to reverse. The sort replaces the
       layout `order_by` on both backends. Unorderable columns (associations, embeds, arrays, maps,
       uploads) are skipped; opt any other out with `sortable?: false`. New class `auix-items-table-header-sort`.

   - **Unsaved-changes guard on the form modal**
     - Closing the new/edit form modal (the × button, `Esc`, a click outside it) with unsaved changes
       now opens a confirmation dialog ("Keep editing" / "Discard changes") instead of discarding
       them. A form without changes closes as before, and the show modal is unchanged. Ash and Ecto
       resources behave the same.
     - Opt out per resource with the new `edit_layout` option
       `unsaved_changes_guard_disabled?: true`.
     - `modal/1` gains a `hide_on_cancel?` attribute (default `true`). A host override of `modal/1`
       must honour it, otherwise the modal hides before the dialog appears.
     - New theme classes `auix-discard-confirm`, `auix-discard-confirm-message` and
       `auix-discard-confirm-actions`: re-run `mix auix.gen.stylesheet` after upgrading.

   - **`contains` filter condition for text fields**
     - The index filter bar offers a new condition, `contains (~)`, on text fields: a
       case-insensitive substring search on both backends.
     - Backslash, `%` and `_` in the typed value match literally, and a blank value applies no filter.

   - **Separate font-size variables for group titles and index empty states**
     - `--auix-font-size-group-title` and `--auix-font-size-empty-state` now size group headings and
       the index empty-state message, which `--auix-font-size-title` used to size together with the
       page title. Both default to `1.125rem`, so default rendering is unchanged, and an override of
       `--auix-font-size-title` no longer changes them.

   - **Multi-value selects render as a checkbox group**
     - A form renders one checkbox per option instead of a `<select multiple>`, and a show renders
       the selected options as a read-only list with a `No options to show` empty state. Index cells
       are unchanged.
     - The `:default_toggle_all` action, a tri-state checkbox beside the label, selects or clears
       every option. Label, header and footer actions are registered under the new `:multi_select`
       action group, so hosts add, replace or remove them from the layout DSL field options.
     - **Host contract:** the group submits a blank value so that unchecking the last box clears the
       field. The host must reject that blank — see `Blog.Post.reject_blank_labels/2` (Ash, which
       also needs `constraints: [nil_items?: true]` on the attribute) and `Inventory.Product` (Ecto)
       for the two reference implementations.

   - **Read-only rendering for scalar arrays**
     - A scalar array attribute with no option set (no `one_of`, no enum) renders as a read-only list
       on both backends, and an index cell shows its values joined.

   - **Ash enum modules and `NewType`-wrapped constraints detected as selects**
     - An attribute typed by a `use Ash.Type.Enum` module renders as a select.
     - A `NewType` over `Ash.Type.Atom` or over an `Ash.Type.Enum` module renders as a select with
       the subtype's options, instead of a text input.

   - **New action-label layout options and arity-0 name/title functions**
     - `:new_action_label` (`:index`), `:save_action_label` (`:form`), and `:edit_action_label` /
       `:back_action_label` (`:show`) set the labels of the corresponding action buttons.
     - A resource's `:name` and `:title` (set via `auix_resource_metadata/3`) can be a captured
       0-arity function returning a binary. It is called wherever the name or title appears in a
       default title, subtitle or action label.

   ### Changed

   - **A save or delete updates every open index over the same schema** (behaviour change)
     - With `pubsub_server` configured, every connected index over that schema re-reads its current
       page; before, only the session that made the change refreshed. Without the key nothing
       changes.

   - **`:in` conditions take a list of values only**
     - A comma-separated string is no longer split: `{:status, :in, "a,b"}` now yields an invalid
       query on Ash and raises `ArgumentError` on Ecto. Write `{:status, :in, ["a", "b"]}`.

   - **`Aurora.Uix.Gettext` renamed to `Aurora.Uix.GettextResolver`**
     - The old name shadowed the `Gettext` library module. Host apps that `use Aurora.Uix.Gettext`
       must update to the new name.
     - The helper the macro injects is now the private `gettext_backend/0`, no longer the public
       `backend/0`.

   - **Group containers are now flat by default** (visual change)
     - A group no longer paints a card inside the card of its container:
       `--auix-color-group-container-bg` and `--auix-color-group-container-border` now default to
       `transparent`. Spacing is unchanged.
     - To keep the previous look, restore the two variables in your own stylesheet:
       ```css
       :root {
         --auix-color-group-container-bg: var(--auix-color-bg-light);
         --auix-color-group-container-border: var(--auix-color-border-primary);
       }
       ```

   - **`Templates.Basic.Helpers.many_to_many_candidate_ids/2` renamed to `select_candidate_ids/2`**
     - It now serves any multi-value select, not only a many-to-many membership. Its behaviour is
       unchanged.

   - **Ash 3.33 requires an explicit string-length counting mode**
     - Host applications on Ash 3.33+ must set
       `config :ash, default_string_length_count: :codepoints`, which Ash demands at compile time for
       resources with string constraints.

   - **Updated Dependencies**
     - ash: 3.30.1 -> 3.33.11
     - ash_phoenix: 2.3.24 -> 2.3.25
     - ash_postgres: 2.11.0 -> 2.13.1
     - aurora_ctx: 0.1.10 -> 0.1.11
     - bandit: 1.12.4 -> 1.12.5
     - dialyxir: 1.4.7 -> 1.4.8
     - ex_doc: 0.40.3 -> 0.40.4
     - lazy_html: 0.1.12 -> 0.1.13
     - phoenix: 1.8.9 -> 1.8.15
     - phoenix_live_dashboard: 0.8.7 -> 0.9.1
     - phoenix_live_reload: 1.6.2 -> 1.7.0
     - phoenix_live_view: 1.2.8 -> 1.2.12
     - postgrex: 0.22.3 -> 0.22.4
     - telemetry_metrics: 1.1.0 -> 1.2.0
   ~~~~

##### guides/core/liveview.md
1. § Index Handler Hook (LiveView) — in the example under `**Example - Override `auix_handle_event/3`:**`, replace this block verbatim:
   ~~~
     def auix_handle_event("bulk_publish", %{"ids" => ids}, socket) do
       # Custom bulk operation
       Enum.each(ids, &publish_product/1)
       
       {:noreply, 
        socket
        |> put_flash(:info, "Products published")
        |> refresh_current_page()}
     end
   ~~~
   with:
   ~~~
     def auix_handle_event("bulk_publish", %{"ids" => ids}, socket) do
       # Custom bulk operation
       Enum.each(ids, &publish_product/1)
       Aurora.Uix.Events.changed(MyApp.Inventory.Product)

       {:noreply, put_flash(socket, :info, "Products published")}
     end
   ~~~
2. § Adding Custom Events — in the `**In Index Handler:**` example, replace this block verbatim:
   ~~~
     def auix_handle_event("publish", %{"id" => id}, socket) do
       product = socket.assigns.auix.modules.context.get_product(id)
       {:ok, _} = socket.assigns.auix.modules.context.publish_product(product)
       
       {:noreply, 
        socket
        |> put_flash(:info, "Product published")
        |> refresh_current_page()}
     end
   ~~~
   with:
   ~~~
     def auix_handle_event("publish", %{"id" => id}, socket) do
       product = socket.assigns.auix.modules.context.get_product(id)
       {:ok, published} = socket.assigns.auix.modules.context.publish_product(product)
       Aurora.Uix.Events.updated(published)

       {:noreply, put_flash(socket, :info, "Product published")}
     end
   ~~~
3. Insert this new section verbatim immediately before the `## Callback Reference` heading:
   ~~~~
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
   ```

   ### Index commands

   Two requests are not data changes, so they are messages to one index LiveView process, never
   broadcasts:

   | Function | Effect |
   |---|---|
   | `Aurora.Uix.Events.refresh(pid \\ self())` | re-reads the current page |
   | `Aurora.Uix.Events.reset_selection(pid \\ self())` | clears the selection, then re-reads the current page |

   A handler running inside the index calls them with no argument. A task or job that holds the
   index LiveView's pid passes it. Both work whether or not `pubsub_server` is configured.
   ~~~~

##### guides/customization/custom_actions.md
1. Insert this new section verbatim immediately before the `## Association Actions` heading:
   ~~~~
   ## Refreshing the Index from a Custom Action

   A custom action that changes data tells the index through `Aurora.Uix.Events`. Handle the
   action's event in an index handler module (see
   [LiveView Integration › Index Handler Hook](../core/liveview.md#index-handler-hook-liveview)):

   ```elixir
   defmodule MyApp.ProductIndexHandler do
     use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

     alias Aurora.Uix.Events
     alias MyApp.Inventory.Product

     @impl IndexImpl
     def auix_handle_event("archive_selected", _params, socket) do
       Enum.each(socket.assigns.auix.selection.selected, &MyApp.Inventory.archive_product/1)

       Events.changed(Product)
       Events.reset_selection()

       {:noreply, put_flash(socket, :info, "Products archived")}
     end

     def auix_handle_event(event, params, socket), do: super(event, params, socket)
   end
   ```

   - `Events.changed(Product)` makes every open index over `Product` re-read its current page,
     this one included. Publish `Events.created/1`, `Events.updated/1` or `Events.deleted/2`
     instead when the action knows which records it wrote.
   - `Events.reset_selection()` clears this view's selection only; other users keep theirs.
   - With `pubsub_server` unset, publishing does nothing. Call `Events.refresh()` to re-read this
     view's page.
   - `refresh/1` and `reset_selection/1` take the index LiveView's pid. A handler running inside
     the view calls them with no argument; a task or job that holds the pid passes it.

   See [LiveView Integration › Reacting to Data Changes](../core/liveview.md#reacting-to-data-changes)
   for the event shape and how an open index reacts.
   ~~~~

##### guides/introduction/getting_started.md
1. Insert this new section verbatim immediately before the `## CSS Configuration` heading:
   ~~~~
   ## Live Updates (optional)

   Name your application's PubSub server so every generated index updates when data changes in
   another session:

   ```elixir
   # config/config.exs
   config :aurora_uix, pubsub_server: MyApp.PubSub
   ```

   Use the server your Phoenix application already starts (`{Phoenix.PubSub, name: MyApp.PubSub}`
   in `application.ex`). Without this key the generated views work as before, and only the
   session that made a change refreshes. See
   [LiveView Integration › Reacting to Data Changes](../core/liveview.md#reacting-to-data-changes).
   ~~~~

##### Acceptance criteria
- [x] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no
      issue-link suffix (mechanical — no red test; verified by
      `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [x] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-392-enriched-spec.md`)
- [x] AC-3: `guides/core/liveview.md` no longer calls `refresh_current_page`, both examples call
      `Aurora.Uix.Events`, and § Reacting to Data Changes precedes § Callback Reference
      (mechanical — no red test; verified by `grep -c refresh_current_page guides/core/liveview.md`
      printing `0`, `grep -c 'Aurora.Uix.Events.changed(MyApp.Inventory.Product)\|Aurora.Uix.Events.updated(published)' guides/core/liveview.md`
      printing `2`, and `grep -n '^## Reacting to Data Changes\|^## Callback Reference' guides/core/liveview.md`
      listing the first heading on the lower line number)
- [x] AC-4: `guides/customization/custom_actions.md` § Refreshing the Index from a Custom Action
      precedes § Association Actions (mechanical — no red test; verified by
      `grep -n '^## Refreshing the Index from a Custom Action\|^## Association Actions' guides/customization/custom_actions.md`
      listing the first heading on the lower line number)
- [x] AC-5: `guides/introduction/getting_started.md` § Live Updates (optional) sits between
      § Installation and § CSS Configuration and names the `pubsub_server` key (mechanical — no
      red test; verified by `grep -n '^## Installation\|^## Live Updates (optional)\|^## CSS Configuration' guides/introduction/getting_started.md`
      listing the three headings in that order, and
      `grep -c 'config :aurora_uix, pubsub_server: MyApp.PubSub' guides/introduction/getting_started.md`
      printing `1`)
- [x] AC-6: `CHANGELOG.md` § `## [0.1.6]` reads as prescribed: 28 entries, 195 lines, and none of
      the removed implementation names (mechanical — no red test; verified by
      `awk '/^## \[0\.1\.6\]/{f=1} /^## \[0\.1\.5\]/{f=0} f' CHANGELOG.md | grep -c '^- \*\*'` printing `28`,
      `awk '/^## \[0\.1\.6\]/{f=1} /^## \[0\.1\.5\]/{f=0} f' CHANGELOG.md | wc -l` printing `195`, and
      `awk '/^## \[0\.1\.6\]/{f=1} /^## \[0\.1\.5\]/{f=0} f' CHANGELOG.md | grep -c 'translate_operation\|prepare_query_options\|render_binary\|parse_value\|auix_request_close\|refresh_current_page\|auix_handle_async\|Aurora\.Uix\.Event{'` printing `0`)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->

<!-- section:UI-1:start -->
### UI-1 — UI · `Aurora.Uix.Events` API
Depends on: DOC-1

#### Documentation references
- `guides/core/liveview.md` § Reacting to Data Changes (written by DOC-1) — topic, event fields, publisher and command contracts
- `guides/introduction/getting_started.md` § Live Updates (optional) — the `pubsub_server` key

#### Implementation details
Layout types: none. This section adds two backend-agnostic modules and one config key; no
renderer, generator or handler changes. Nothing calls the new API until UI-2.

##### Acceptance criteria
- [x] AC-1: Given `pubsub_server: Aurora.Uix.PubSub`, `Aurora.Uix.Events.topic(Aurora.Uix.Guides.Inventory.Product)`
      returns `"auix:Aurora.Uix.Guides.Inventory.Product"`, and the same holds for the Ash resource
      `Aurora.Uix.Guides.Blog.Author`.
- [x] AC-2: Given a process subscribed with `Events.subscribe(Product)`, `Events.created(%Product{id: "p-1"})`
      delivers `%Aurora.Uix.Event{schema: Product, action: :created, ids: ["p-1"], entities: [%Product{id: "p-1"}]}`;
      `Events.updated/1` delivers the same shape with `action: :updated`; the same holds for an
      `%Author{}` record (Ash).
- [x] AC-3: `Events.deleted(Product, ["p-1", "p-2"])` delivers `%Event{schema: Product, action: :deleted, ids: ["p-1", "p-2"], entities: []}`;
      `Events.changed(Product)` delivers `%Event{schema: Product, action: :changed, ids: [], entities: []}`.
- [x] AC-4: A publisher called with `from: pid` does not deliver to `pid` and does deliver to
      every other subscriber.
- [x] AC-5: After `Events.unsubscribe(Product)`, the process receives no further event on that topic.
- [x] AC-6: `Events.refresh()` sends `{Aurora.Uix.Events, :refresh}` to the caller and
      `Events.reset_selection(pid)` sends `{Aurora.Uix.Events, :reset_selection}` to `pid`; both
      return `:ok`.
- [x] AC-7 (empty path): With `:pubsub_server` unset, `subscribe/1` returns `:ok` and registers
      nothing on the topic, and every publisher returns `:ok` and broadcasts nothing.
- [x] AC-8 (error path): With `:pubsub_server` set to a server that is not started,
      `Events.subscribe(Product)` raises `ArgumentError` (host misconfiguration surfaces loudly).

##### Test ports
- `Aurora.Uix.Events` public functions, called directly from a test process · no route · no
  layout type · observable: `assert_receive` / `refute_receive` on the test process mailbox, and
  `Registry.lookup(Aurora.Uix.PubSub, topic)` for the subscriber set (`Phoenix.PubSub.subscribe/3`
  registers the caller in the `Registry` named after the PubSub server —
  `deps/phoenix_pubsub/lib/phoenix/pubsub.ex` `subscribe/3`).
- `Aurora.Uix.PubSub` is already started in the test app: `lib/aurora_uix/application.ex`
  `start/2` lists `{Phoenix.PubSub, name: Aurora.Uix.PubSub}` whenever `:endpoint` is configured,
  and `test/config/test.exs` configures it.

##### Red tests
New file `test/cases/events_test.exs` (search: `ls test/cases/events_test.exs` and
`rg -l "Aurora.Uix.Events" test/` return nothing). Module
`Aurora.Uix.Test.EventsTest`, `use ExUnit.Case, async: false` (the tests change application
env). Aliases: `Aurora.Uix.Event`, `Aurora.Uix.Events`, `Aurora.Uix.Guides.Blog.Author`,
`Aurora.Uix.Guides.Inventory.Product`. A `setup` block stores
`Application.get_env(:aurora_uix, :pubsub_server)` and registers
`on_exit(fn -> Application.put_env(:aurora_uix, :pubsub_server, previous) end)`. No database, no
`Process.sleep/1`.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file | none | test/cases/events_test.exs | "topic/1 names one topic per schema on both backends" | `assert Events.topic(Product) == "auix:Aurora.Uix.Guides.Inventory.Product"`; `assert Events.topic(Author) == "auix:Aurora.Uix.Guides.Blog.Author"` |
| AC-2 | new file | `:ok = Events.subscribe(Product)`; `:ok = Events.subscribe(Author)` | test/cases/events_test.exs | "created/1 and updated/1 take the schema and id from the record" | `Events.created(%Product{id: "p-1"})` → `assert_receive %Event{schema: Product, action: :created, ids: ["p-1"], entities: [%Product{id: "p-1"}]}`; `Events.updated(%Author{id: "a-1"})` → `assert_receive %Event{schema: Author, action: :updated, ids: ["a-1"], entities: [%Author{id: "a-1"}]}` |
| AC-3 | new file | `:ok = Events.subscribe(Product)` | test/cases/events_test.exs | "deleted/2 and changed/1 carry no entities" | `assert_receive %Event{action: :deleted, ids: ["p-1", "p-2"], entities: []}`; `assert_receive %Event{action: :changed, ids: [], entities: []}` |
| AC-4 | new file | `:ok = Events.subscribe(Product)`; spawn a second subscriber with `Task.async/1` that subscribes, sends `:subscribed` to the test pid, then `receive`s one `%Event{}` and returns it | test/cases/events_test.exs | "from: excludes the sender only" | after `assert_receive :subscribed`, `Events.changed(Product, from: self())`; `refute_receive %Event{}, 100`; `assert %Event{action: :changed} = Task.await(task)` |
| AC-5 | new file | `:ok = Events.subscribe(Product)`; `:ok = Events.unsubscribe(Product)` | test/cases/events_test.exs | "unsubscribe/1 stops delivery" | `Events.changed(Product)`; `refute_receive %Event{}, 100` |
| AC-6 | new file | none | test/cases/events_test.exs | "refresh/1 and reset_selection/1 message one process" | `assert Events.refresh() == :ok`; `assert_received {Events, :refresh}`; `assert Events.reset_selection(self()) == :ok`; `assert_received {Events, :reset_selection}` |
| AC-7 | new file | `Application.delete_env(:aurora_uix, :pubsub_server)` | test/cases/events_test.exs | "an unset pubsub_server subscribes and broadcasts nothing" | `assert Events.subscribe(Product) == :ok`; `assert Registry.lookup(Aurora.Uix.PubSub, Events.topic(Product)) == []`; then subscribe directly with `:ok = Phoenix.PubSub.subscribe(Aurora.Uix.PubSub, Events.topic(Product))`; `assert Events.created(%Product{id: "p-1"}) == :ok`; `assert Events.changed(Product) == :ok`; `refute_receive %Event{}, 100` |
| AC-8 | new file | `Application.put_env(:aurora_uix, :pubsub_server, Aurora.Uix.Test.MissingPubSub)` | test/cases/events_test.exs | "a pubsub_server that is not started raises on subscribe" | `assert_raise ArgumentError, fn -> Events.subscribe(Product) end` |

##### Modules & components
1. `Aurora.Uix.Event` at `lib/aurora_uix/event.ex` — new (search: `ls lib/aurora_uix/event.ex` and
   `rg -n "defmodule Aurora.Uix.Event\b" lib/` return nothing). Write:
   ```elixir
   defmodule Aurora.Uix.Event do
     @moduledoc """
     A data change published on a schema's topic by `Aurora.Uix.Events`.

     ## Key Features

     - One struct for every data change: created, updated, deleted, or changed in bulk.
     - Carries the primary keys of the affected records, and the records themselves when the
       publisher has them.

     ## Key Constraints

     - `ids` is `[]` for `:changed`.
     - Generated views never render `entities`; they re-read the data with the viewer's own
       actor, filters, sort and page.
     """

     defstruct schema: nil, action: nil, ids: [], entities: []

     @type action() :: :created | :updated | :deleted | :changed

     @type t() :: %__MODULE__{
             schema: module() | nil,
             action: action() | nil,
             ids: list(),
             entities: list(struct())
           }
   end
   ```
2. `Aurora.Uix.Events` at `lib/aurora_uix/events.ex` — new (search: `ls lib/aurora_uix/events.ex`
   and `rg -n "Aurora.Uix.Events" lib/` return nothing). It is the only module that reads
   `:pubsub_server`, builds a topic or builds a command message. It starts no process. Write:
   ```elixir
   defmodule Aurora.Uix.Events do
     @moduledoc """
     Publish and subscribe to data changes, and send commands to an index LiveView.

     ## Key Features

     - One topic per schema or Ash resource: `"auix:" <> inspect(schema)`.
     - Publishers for host code: `created/2`, `updated/2`, `deleted/3`, `changed/2`.
     - Index commands `refresh/1` and `reset_selection/1`, sent to one LiveView process.

     ## Key Constraints

     - The PubSub server is read at call time from `config :aurora_uix, pubsub_server:`. The host
       supervises it; this module starts no process.
     - With `:pubsub_server` unset, subscribing and publishing do nothing and return `:ok`.
     - The primary key is read with `schema.__schema__(:primary_key)`, which Ecto schemas and Ash
       resources both define.
     """

     alias Aurora.Uix.Event

     @doc """
     Returns the topic for a schema or Ash resource.

     ## Parameters
     - `schema` (module()) - The schema or Ash resource module.

     ## Returns
     binary() - `"auix:" <> inspect(schema)`.
     """
     @spec topic(module()) :: binary()
     def topic(schema) when is_atom(schema), do: "auix:" <> inspect(schema)

     @doc """
     Subscribes the calling process to the schema's topic.

     ## Parameters
     - `schema` (module()) - The schema or Ash resource module.

     ## Returns
     `:ok | {:error, term()}` - `:ok` without subscribing when `:pubsub_server` is not configured.
     """
     @spec subscribe(module()) :: :ok | {:error, term()}
     def subscribe(schema) do
       case pubsub_server() do
         nil -> :ok
         server -> Phoenix.PubSub.subscribe(server, topic(schema))
       end
     end

     @doc """
     Unsubscribes the calling process from the schema's topic.

     ## Parameters
     - `schema` (module()) - The schema or Ash resource module.

     ## Returns
     `:ok`
     """
     @spec unsubscribe(module()) :: :ok
     def unsubscribe(schema) do
       case pubsub_server() do
         nil -> :ok
         server -> Phoenix.PubSub.unsubscribe(server, topic(schema))
       end
     end

     @doc """
     Publishes a `:created` event for a record; the schema is the record's struct module.

     ## Parameters
     - `entity` (struct()) - The created record.
     - `opts` (keyword()) - `from: pid` skips delivery to that process.

     ## Returns
     `:ok | {:error, term()}`
     """
     @spec created(struct(), keyword()) :: :ok | {:error, term()}
     def created(%schema{} = entity, opts \\ []),
       do: publish(%Event{schema: schema, action: :created, ids: [entity_id(entity)], entities: [entity]}, opts)

     @doc """
     Publishes an `:updated` event for a record; the schema is the record's struct module.

     ## Parameters
     - `entity` (struct()) - The updated record.
     - `opts` (keyword()) - `from: pid` skips delivery to that process.

     ## Returns
     `:ok | {:error, term()}`
     """
     @spec updated(struct(), keyword()) :: :ok | {:error, term()}
     def updated(%schema{} = entity, opts \\ []),
       do: publish(%Event{schema: schema, action: :updated, ids: [entity_id(entity)], entities: [entity]}, opts)

     @doc """
     Publishes a `:deleted` event listing the primary keys of the deleted records.

     ## Parameters
     - `schema` (module()) - The schema or Ash resource module.
     - `ids` (list()) - Primary-key values of the deleted records.
     - `opts` (keyword()) - `from: pid` skips delivery to that process.

     ## Returns
     `:ok | {:error, term()}`
     """
     @spec deleted(module(), list(), keyword()) :: :ok | {:error, term()}
     def deleted(schema, ids, opts \\ []) when is_list(ids),
       do: publish(%Event{schema: schema, action: :deleted, ids: ids}, opts)

     @doc """
     Publishes a `:changed` event: the schema's data changed in a way that is not listed record by record.

     ## Parameters
     - `schema` (module()) - The schema or Ash resource module.
     - `opts` (keyword()) - `from: pid` skips delivery to that process.

     ## Returns
     `:ok | {:error, term()}`
     """
     @spec changed(module(), keyword()) :: :ok | {:error, term()}
     def changed(schema, opts \\ []), do: publish(%Event{schema: schema, action: :changed}, opts)

     @doc """
     Asks an index LiveView to re-read its current page.

     ## Parameters
     - `pid` (pid()) - The index LiveView process. Defaults to the caller.

     ## Returns
     `:ok`
     """
     @spec refresh(pid()) :: :ok
     def refresh(pid \\ self()) do
       send(pid, {__MODULE__, :refresh})
       :ok
     end

     @doc """
     Asks an index LiveView to clear its selection and re-read its current page.

     ## Parameters
     - `pid` (pid()) - The index LiveView process. Defaults to the caller.

     ## Returns
     `:ok`
     """
     @spec reset_selection(pid()) :: :ok
     def reset_selection(pid \\ self()) do
       send(pid, {__MODULE__, :reset_selection})
       :ok
     end

     ## PRIVATE

     @spec publish(Event.t(), keyword()) :: :ok | {:error, term()}
     defp publish(%Event{} = event, opts) do
       case pubsub_server() do
         nil -> :ok
         server -> broadcast(server, event, Keyword.get(opts, :from))
       end
     end

     @spec broadcast(atom(), Event.t(), pid() | nil) :: :ok | {:error, term()}
     defp broadcast(server, event, nil),
       do: Phoenix.PubSub.broadcast(server, topic(event.schema), event)

     defp broadcast(server, event, from),
       do: Phoenix.PubSub.broadcast_from(server, from, topic(event.schema), event)

     # Same shape as `Aurora.Uix.Templates.Basic.Helpers.primary_key_value/2`: a single key yields
     # its value, a composite key a list of values.
     @spec entity_id(struct()) :: term()
     defp entity_id(%schema{} = entity) do
       case schema.__schema__(:primary_key) do
         [key] -> Map.get(entity, key)
         keys -> Enum.map(keys, &Map.get(entity, &1))
       end
     end

     @spec pubsub_server() :: atom() | nil
     defp pubsub_server, do: Application.get_env(:aurora_uix, :pubsub_server)
   end
   ```
   Run `mix format` after writing; it reflows the long `do:` lines.
3. `config/config.exs` — modified. In the `# Configure modules` entry, replace
   ```elixir
   config :aurora_uix,
     endpoint: Aurora.UixWeb.Endpoint
   ```
   with
   ```elixir
   config :aurora_uix,
     endpoint: Aurora.UixWeb.Endpoint,
     pubsub_server: Aurora.Uix.PubSub
   ```
   `test/config/test.exs` overrides only `endpoint` and `sandbox` in its `# Configure modules`
   entry, so the key reaches the test app unchanged. `Aurora.Uix.PubSub` is the server
   `Aurora.Uix.Application.start/2` already starts.
4. `mix.exs` — unchanged. `phoenix_pubsub` arrives through `phoenix`; a transitive dependency
   already compiles clean under `--warnings-as-errors` (precedent: `import Plug.Conn` in
   `lib/aurora_uix_web.ex` `router/0`, used by `lib/aurora_uix_web/router.ex`, `plug` being
   transitive).
5. Primary key: `schema.__schema__(:primary_key)` is the call `Aurora.Uix.Parsers.Common`
   `option_value/4` (`:primary_key` clause) already makes for every resource, Ecto and Ash, so it
   crosses no backend boundary.
6. Components: none. Theme: none. `dt/1` strings: none.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-1:end -->

<!-- section:UI-2:start -->
### UI-2 — UI · handler · index subscriber, built-in publishers, index commands
Depends on: UI-1

#### Documentation references
- `guides/core/liveview.md` § Reacting to Data Changes (written by DOC-1) — publisher table, list reaction, index commands
- `guides/customization/custom_actions.md` § Refreshing the Index from a Custom Action (written by DOC-1)

#### Implementation details
Layout types: `:index` (the Index LiveView, `IndexImpl`) and `:form` (the `"save"` wrapper in
`FormImpl.__using__/1`). `:show` is untouched here. No renderer, theme or markup changes.

##### Acceptance criteria
- [x] AC-1: Given the Ecto `EventsTest` product UI, a connected index at `/events-products` is
      subscribed to `Events.topic(Product)`, and an index at `/events-product-locations` is not.
- [x] AC-2: A form save (edit) in one view re-reads a second connected index over the same
      schema: the renamed row appears there.
- [x] AC-3: A form save of a new record publishes `:created` with the new record's id.
- [x] AC-4: A row delete in one view removes the row from a second connected index.
- [x] AC-5: The view that made a built-in change does not receive its own event; the second view does.
- [x] AC-6: A one-to-many child row delete publishes `:deleted` on the child's schema
      (`ProductTransaction`) with the child's id.
- [x] AC-7: "Delete selected" publishes one `:deleted` listing exactly the records it deleted; a
      selected record already deleted elsewhere is not listed; the second view loses the deleted rows.
- [x] AC-8 (empty path): "Delete selected" over records that were all already deleted publishes nothing.
- [x] AC-9: A `:deleted` event drops the deleted ids from the receiving view's selection.
- [x] AC-10: An event published from a non-LiveView process re-reads a subscribed index.
- [x] AC-11: `Events.reset_selection(pid)` clears only that view's selection; `Events.refresh(pid)`
      re-reads that view's page; `Events.refresh()` called from a host `auix_handle_event/3`
      re-reads the calling view.
- [x] AC-12 (degraded path): With `:pubsub_server` unset, a connected index is not subscribed, a
      row delete broadcasts nothing, and the row still leaves the originating view.
- [x] AC-13: AC-1, AC-2, AC-4, AC-7 and AC-9 hold on the Ash `blog` `Author` UI.

##### Test ports
- Route `"/events-products"` and `"/events-product-locations"` registered in `routes.ex` via
  `RoutesHelper.register_crud(EventsTest.Product, "events-products")` and
  `RoutesHelper.register_crud(EventsTest.ProductLocation, "events-product-locations")` · layout
  types `:index`, `:form` · observable: `has_element?/2` on `#products-<id>` (stream dom id:
  stream name `auix.source_key` = `:products`, row id = the entry's `:id`), on
  `#auix-delete-all-button-product>button span.auix-button-badge` (the selection count,
  `actions/index.ex` `selected_delete_all_action/1`), and `assert_receive` of `%Event{}` on a
  test process subscribed with `Events.subscribe/1`.
- Route `"/ash-events-authors"` registered via
  `RoutesHelper.register_crud(AshEventsTest.Author, "ash-events-authors")` · same observables
  with `#authors-<id>` and `#auix-delete-all-button-author>button span.auix-button-badge`.
- Drives, all existing events: row select —
  `render_change(view, "index-layout-change", %{"_target" => ["selected_check__#{id}"]})`
  (`index_impl.ex` `auix_handle_event/3` clause `%{"_target" => ["selected_check__" <> id]}`);
  row delete — `render_click(view, "delete", %{"id" => id})`; "Delete selected" —
  `render_click(view, "selected-delete_all", %{})` then `render_async(view)`; form save —
  `view |> form("#auix-product-form", product: %{...}) |> render_submit()`.
- Probe handler `Aurora.UixWeb.EventsProbeIndexHandler` (new, defined at the bottom of
  `test/cases_live/events_test.exs`, following `Aurora.UixWeb.IndexHandlerHook` in
  `test/cases_live/handler_hooks_index_test.exs`):
  ```elixir
  defmodule Aurora.UixWeb.EventsProbeIndexHandler do
    use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

    alias Aurora.Uix.Event
    alias Aurora.Uix.Events
    alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl

    @impl IndexImpl
    def auix_handle_event("events-test-refresh", _params, socket) do
      Events.refresh()
      {:noreply, socket}
    end

    def auix_handle_event(event, params, socket), do: super(event, params, socket)

    @impl IndexImpl
    def auix_handle_info(%Event{} = event, socket) do
      case Process.whereis(:auix_events_probe) do
        nil -> :ok
        probe -> send(probe, {:auix_event_seen, self(), event})
      end

      super(event, socket)
    end

    def auix_handle_info(message, socket), do: super(message, socket)
  end
  ```
  A test that uses the probe calls `Process.register(self(), :auix_events_probe)`; the name is
  released when the test process exits. Tests in `test/cases_live/` run with `async: false`
  (`ConnCase` default), so the name never collides.

##### Red tests
Ecto: new file `test/cases_live/events_test.exs` (search: `ls test/cases_live/events_test.exs`
returns nothing), module `Aurora.UixWeb.Test.EventsTest`,
`use Aurora.UixWeb.Test.UICase, :phoenix_case` and `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`.
Aliases: `Aurora.Uix.Event`, `Aurora.Uix.Events`, `Aurora.Uix.Guides.Inventory`,
`Aurora.Uix.Guides.Inventory.Product`, `Aurora.Uix.Guides.Inventory.ProductLocation`,
`Aurora.Uix.Guides.Inventory.ProductTransaction`. Declarations:
```elixir
auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)
auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)
auix_resource_metadata(:product, context: Inventory, schema: Product)

auix_create_ui do
  index_columns(:product, [:reference, :name],
    handler_module: Aurora.UixWeb.EventsProbeIndexHandler
  )

  edit_layout :product do
    stacked([:reference, :name, :quantity_initial, :product_transactions])
  end

  show_layout :product do
    stacked([:reference, :name])
  end
end
```
Every test starts with `delete_all_inventory_data()` and seeds with
`create_sample_products(n, :test)` (keys `"id_test-1"`…, names `"Item test-1"`…), binding
records by key: `%{"id_test-1" => first, "id_test-2" => second} = create_sample_products(2, :test)`;
with one record, `product`/`id` name `"id_test-1"` and its `:id`. Saves submit
`quantity_initial: "5"`: `Product.changeset/2` requires it and `create_sample_products/3` leaves
it `nil`.

Ash: new file `test/cases_live/ash_events_test.exs` (search: `ls test/cases_live/ash_events_test.exs`
returns nothing), module `Aurora.UixWeb.Test.AshEventsTest`, same two `use` lines. Aliases:
`Aurora.Uix.Event`, `Aurora.Uix.Events`, `Aurora.Uix.Guides.Blog.Author`. Declarations:
```elixir
auix_resource_metadata(:author, ash_resource: Author)

auix_create_ui do
  index_columns(:author, [:name, :email])

  edit_layout :author do
    stacked([:name, :email, :bio])
  end

  show_layout :author do
    stacked([:name, :email])
  end
end
```
Every test starts with `delete_all_blog_data()` and seeds with `create_sample_authors(n)` (it
returns the list of authors).

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file | `{:ok, products, _} = live(conn, "/events-products")`; `{:ok, locations, _} = live(conn, "/events-product-locations")` | test/cases_live/events_test.exs | "an index subscribes to its own schema's topic only" | `pids = Aurora.Uix.PubSub \|> Registry.lookup(Events.topic(Product)) \|> Enum.map(&elem(&1, 0))`; `assert products.pid in pids`; `refute locations.pid in pids` |
| AC-2 | new file | seed 1; `view_b` on `/events-products`; `view_a` on `/events-products/#{id}/edit` | test/cases_live/events_test.exs | "a save in one view re-reads another index" | `view_a \|> form("#auix-product-form", product: %{name: "Renamed item", quantity_initial: "5"}) \|> render_submit()`; `assert has_element?(view_b, "#products-#{id}", "Renamed item")` |
| AC-3 | new file | `Events.subscribe(Product)`; `view_a` on `/events-products/new` | test/cases_live/events_test.exs | "a new-record save publishes :created" | submit `product: %{reference: "item_new-1", name: "New item", quantity_initial: "5"}`; `assert_receive %Event{action: :created, ids: [id], entities: [%Product{name: "New item"}]}`; `assert id` |
| AC-4 | new file | seed 2; `view_a`, `view_b` both on `/events-products` | test/cases_live/events_test.exs | "a row delete removes the row from another index" | `render_click(view_a, "delete", %{"id" => id})`; `refute has_element?(view_b, "#products-#{id}")` |
| AC-5 | new file | `Process.register(self(), :auix_events_probe)`; seed 2; `view_a`, `view_b` on `/events-products` | test/cases_live/events_test.exs | "the originating view does not receive its own event" | `render_click(view_a, "delete", %{"id" => id})`; `pid_b = view_b.pid`; `assert_receive {:auix_event_seen, ^pid_b, %Event{action: :deleted}}`; `pid_a = view_a.pid`; `refute_receive {:auix_event_seen, ^pid_a, _}, 100` |
| AC-6 | new file | `create_sample_products_with_transactions(1, 2, :test)`; `product = List.first(Inventory.list_products())`; `transaction = product.id \|> Inventory.get_product!(preload: [:product_transactions]) \|> Map.get(:product_transactions) \|> List.first()`; `Events.subscribe(ProductTransaction)`; view on `/events-products/#{product.id}/edit` | test/cases_live/events_test.exs | "a one-to-many child delete publishes on the child's schema" | `view \|> element("a[name^='auix-delete-product__product_transaction-'][phx-click*='#{transaction.id}']") \|> render_click()`; `assert_receive %Event{schema: ProductTransaction, action: :deleted, ids: [id]}`; `assert id == transaction.id` |
| AC-7 | new file | seed 3; `Events.subscribe(Product)`; `view_a`, `view_b` on `/events-products`; select all three in `view_a`; `Inventory.delete_product(third)` | test/cases_live/events_test.exs | "Delete selected publishes only the records it deleted" | `render_click(view_a, "selected-delete_all", %{})`; `render_async(view_a)`; `assert_receive %Event{action: :deleted, ids: ids}`; `assert Enum.sort(ids) == Enum.sort([first.id, second.id])`; `refute has_element?(view_b, "#products-#{first.id}")` |
| AC-8 | new file | seed 1; `Events.subscribe(Product)`; view on `/events-products`; select it; `Inventory.delete_product(product)` | test/cases_live/events_test.exs | "Delete selected publishes nothing when nothing was deleted" | `render_click(view, "selected-delete_all", %{})`; `render_async(view)`; `refute_receive %Event{}, 100` |
| AC-9 | new file | seed 2; `view_b` on `/events-products`, select both rows; `view_a` on `/events-products` | test/cases_live/events_test.exs | "a deleted id leaves another view's selection" | `assert has_element?(view_b, "#auix-delete-all-button-product>button span.auix-button-badge", "2")`; `render_click(view_a, "delete", %{"id" => first.id})`; `assert has_element?(view_b, "#auix-delete-all-button-product>button span.auix-button-badge", "1")` |
| AC-10 | new file | seed 1; view on `/events-products`; `extra = 1 \|> create_sample_products(:extra) \|> Map.fetch!("id_extra-1")` (a direct insert, no event) | test/cases_live/events_test.exs | "an event from a non-LiveView process re-reads the index" | `refute has_element?(view, "#products-#{extra.id}")`; `fn -> Events.created(extra) end \|> Task.async() \|> Task.await()`; `assert has_element?(view, "#products-#{extra.id}", "Item extra-1")` |
| AC-11 | new file | seed 2; `view_a`, `view_b` on `/events-products`; select row 1 in both | test/cases_live/events_test.exs | "index commands target one view" | `Events.reset_selection(view_a.pid)`; `refute has_element?(view_a, "#auix-delete-all-button-product")`; `assert has_element?(view_b, "#auix-delete-all-button-product>button span.auix-button-badge", "1")`; then `extra` inserted as in AC-10, `Events.refresh(view_b.pid)` → `assert has_element?(view_b, "#products-#{extra.id}")`; a second `extra2` (`create_sample_products(1, :more)`, key `"id_more-1"`), `render_click(view_a, "events-test-refresh", %{})` → `assert has_element?(view_a, "#products-#{extra2.id}")` |
| AC-12 | new file | `previous = Application.get_env(:aurora_uix, :pubsub_server)`; `on_exit(fn -> Application.put_env(:aurora_uix, :pubsub_server, previous) end)`; `Application.delete_env(:aurora_uix, :pubsub_server)`; seed 1; view on `/events-products`; `Phoenix.PubSub.subscribe(Aurora.Uix.PubSub, Events.topic(Product))` (direct) | test/cases_live/events_test.exs | "an unset pubsub_server keeps today's behaviour" | `refute view.pid in Enum.map(Registry.lookup(Aurora.Uix.PubSub, Events.topic(Product)), &elem(&1, 0))`; `render_click(view, "delete", %{"id" => id})`; `refute_receive %Event{}, 100`; `refute has_element?(view, "#products-#{id}")` |
| AC-13 | new file | `create_sample_authors(3)`; route `/ash-events-authors`; `Events.subscribe(Author)` where an event is asserted | test/cases_live/ash_events_test.exs | "an index subscribes to its resource's topic", "a save in one view re-reads another index", "a row delete removes the row from another index", "Delete selected publishes only the records it deleted", "a deleted id leaves another view's selection" | the Ecto sketches with `Author`, `#authors-<id>`, `#auix-author-form`, `author: %{name: "Renamed author"}`, `#auix-delete-all-button-author>button span.auix-button-badge`, and `Ash.destroy!(author)` for the direct delete |

##### Modules & components
1. `Aurora.Uix.Templates.Basic.Handlers.IndexImpl` at
   `lib/aurora_uix/templates/basic/handlers/index_impl.ex` — modified. Aliases: add
   `alias Aurora.Uix.Event` and `alias Aurora.Uix.Events` between `alias Aurora.Ctx.Pagination`
   and `alias Aurora.Uix.Filter`.
   1. New private functions, in `## PRIVATE`:
      ```elixir
      @spec resource_schema(map()) :: module()
      defp resource_schema(%{configurations: configurations, resource_name: resource_name}) do
        get_in(configurations, [
          Access.key!(resource_name),
          Access.key!(:resource_config),
          Access.key!(:schema)
        ])
      end

      @spec subscribe_to_changes(Socket.t()) :: Socket.t()
      defp subscribe_to_changes(%{assigns: %{auix: auix}} = socket) do
        if connected?(socket), do: :ok = Events.subscribe(resource_schema(auix))
        socket
      end

      @spec publish_deleted(map(), list()) :: :ok | {:error, term()}
      defp publish_deleted(_auix, []), do: :ok
      defp publish_deleted(auix, ids), do: Events.deleted(resource_schema(auix), ids, from: self())

      @spec publish_child_deleted(struct()) :: :ok | {:error, term()}
      defp publish_child_deleted(%schema{} = entity) do
        ids = [BasicHelpers.primary_key_value(entity, schema.__schema__(:primary_key))]
        Events.deleted(schema, ids, from: self())
      end

      # A row checkbox stores its id as the DOM string (`"selected_check__" <> id`); "select
      # all" stores the native value. Integer keys are dropped in both forms.
      @spec unselect_deleted(Socket.t(), Event.t()) :: Socket.t()
      defp unselect_deleted(
             %{assigns: %{auix: %{selection: selection}}} = socket,
             %Event{action: :deleted, ids: ids}
           ) do
        dom_ids = for id <- ids, is_integer(id), do: Integer.to_string(id)
        assign_auix(socket, :selection, Selection.unselect(selection, ids ++ dom_ids))
      end

      defp unselect_deleted(socket, _event), do: socket

      @spec delete_selected(struct() | nil, Aurora.Uix.Integration.Connector.t(), keyword(), list()) ::
              list()
      defp delete_selected(nil, _delete_function, _delete_opts, _primary_key), do: []

      defp delete_selected(entity, delete_function, delete_opts, primary_key) do
        case apply_delete_function(delete_function, entity, delete_opts) do
          {:ok, _} -> [BasicHelpers.primary_key_value(entity, primary_key)]
          _error -> []
        end
      end
      ```
      `:ok = Events.subscribe(...)` is deliberate: a `{:error, _}` from the PubSub server fails
      the mount loudly.
   2. `assign_index_fields/1` — replace the inline `resource_schema = get_in(configurations, [...])`
      binding with `resource_schema = resource_schema(auix)`. The pattern already binds `auix`.
   3. `auix_mount/3` — insert `|> subscribe_to_changes()` as the first step of the pipe,
      directly after `socket`, before `|> assign_auix(:form_component, form_component)`.
   4. `auix_handle_event/3` clause `"delete", %{"id" => id}, %{assigns: %{auix: auix, streams: _streams}} = socket`
      — after `{:ok, _} = apply_delete_function(auix.delete_function, entity, delete_opts)` insert
      `publish_deleted(auix, [BasicHelpers.primary_key_value(entity, auix.primary_key)])`.
   5. `auix_handle_event/3` clause `"delete", %{"id" => id, "get_function" => get_function_string, "delete_function" => delete_function_string}, socket`
      (the one-to-many child delete) — in the `with` success body, insert
      `publish_child_deleted(entity)` as the first statement, before the existing
      `socket |> put_flash(...) |> push_patch(...)` pipe.
   6. `assign_async_delete_all/1` — replace the `function` binding with:
      ```elixir
      get_function = auix.get_function
      delete_function = auix.delete_function
      primary_key = auix.primary_key

      function =
        fn ->
          selection.selected
          |> Enum.map(&apply_get_function(get_function, &1, get_opts))
          |> Enum.flat_map(&delete_selected(&1, delete_function, delete_opts, primary_key))
        end
      ```
      The task now returns the list of deleted primary keys. A missing record (`get` returns
      `nil` on both backends: `Aurora.Uix.Integration.Ash.Crud.get/3` maps `{:error, _}` to `nil`;
      the ctx default `get_<module>/2` is `Repo.get/3`) and a failed delete are left out.
   7. `auix_handle_async/3` clause `:auix_selection_delete_all` — change the head's socket
      pattern to `%{assigns: %{auix: %{selection: current_selection} = auix}} = socket` and the
      `{:ok, _}` branch of the `case` to:
      ```elixir
      {:ok, deleted_ids} ->
        publish_deleted(auix, deleted_ids)
        Selection.new()
      ```
      Contract change: the async result changes from `{:ok, :ok}` to `{:ok, [id]}`. Callers:
      `rg -n "auix_selection_delete_all" lib test guides` lists only `index_impl.ex`.
   8. `auix_handle_info/2` — insert three clauses after the `{_component, {:saved, _entity}}`
      clause and before the catch-all `auix_handle_info(_input, socket)`:
      ```elixir
      def auix_handle_info(%Event{} = event, socket) do
        {:noreply,
         socket
         |> unselect_deleted(event)
         |> assign_selected_states()
         |> refresh_current_page()}
      end

      def auix_handle_info({Events, :refresh}, socket), do: {:noreply, refresh_current_page(socket)}

      def auix_handle_info({Events, :reset_selection}, socket) do
        {:noreply,
         socket
         |> assign_auix(:selection, Selection.new())
         |> assign_selected_states()
         |> refresh_current_page()}
      end
      ```
      `Selection.new/0` already has `toggle_all_mode: :none`.
   9. Docs: the `auix_handle_info/2` `@doc` (on the first clause) becomes: "Handles info
      messages for the LiveView. Re-reads the current page after a save notification, an
      `%Aurora.Uix.Event{}` on the schema's topic (dropping deleted ids from the selection first),
      or the `refresh` command; the `reset_selection` command clears the selection, then re-reads.
      Other messages are ignored." with the existing `## Parameters` / `## Returns` blocks, the
      `event_info` description changed to "Info message: `{component, {:saved, entity}}`, an
      `%Aurora.Uix.Event{}`, or an `Aurora.Uix.Events` command". Add to the `@moduledoc`
      `## Key Features` list: "- Subscribes to its schema's `Aurora.Uix.Events` topic when
      connected, publishes its own deletes, and answers the `refresh` and `reset_selection`
      commands". Add to `## Key Constraints`: "- Built-in publishers use `broadcast_from`, so the
      view that made a change refreshes locally and never receives its own event".
2. `Aurora.Uix.Templates.Basic.Handlers.FormImpl` at
   `lib/aurora_uix/templates/basic/handlers/form_impl.ex` — modified.
   1. Alias `alias Aurora.Uix.Events` before `alias Aurora.Uix.Layout.Options, as: LayoutOptions`.
   2. New public function, placed after `notify_parent/1`:
      ```elixir
      @doc """
      Publishes the saved record on its schema's topic, skipping the calling LiveView.

      ## Parameters
      - `action` (atom()) - The form action: `:new`, `:edit` or `:show_edit`.
      - `entity` (struct()) - The record returned by `save_entity/2`.

      ## Returns
      `:ok | {:error, term()}`
      """
      @spec publish_saved(atom(), struct()) :: :ok | {:error, term()}
      def publish_saved(:new, entity), do: Events.created(entity, from: self())
      def publish_saved(_action, entity), do: Events.updated(entity, from: self())
      ```
      The form component runs inside the Index LiveView process, so `self()` is that view.
   3. `__using__/1`, `handle_event("save", params, %{assigns: %{action: action, auix: auix}} = socket)`
      — directly after `FormImpl.notify_parent({:saved, entity})` insert
      `FormImpl.publish_saved(action, entity)`. It runs after `save_entity/2`, so a host override
      of `save_entity/2` still publishes.
3. `Aurora.Uix.Selection` at `lib/aurora_uix/selection.ex` — modified. New public function,
   placed after `set_selected/4` (search: `rg -n "def unselect" lib/` returns nothing):
   ```elixir
   @doc """
   Removes the given item ids from the selection, on every page.

   ## Parameters

   - `selection` (`t()`) - The selection struct.
   - `item_ids` (`list()`) - The ids to remove.

   ## Returns

   `t()` - The selection without those ids. Call `update_states/2` to refresh the counts.
   """
   @spec unselect(__MODULE__.t(), list()) :: __MODULE__.t()
   def unselect(%__MODULE__{} = selection, item_ids) do
     removed = MapSet.new(item_ids)

     selected_in_page =
       Map.new(selection.selected_in_page, fn {page, ids} -> {page, MapSet.difference(ids, removed)} end)

     struct(selection, %{
       selected: MapSet.difference(selection.selected, removed),
       selected_in_page: selected_in_page
     })
   end
   ```
   Test: new file `test/cases/selection_test.exs` (search: `ls test/cases/selection_test.exs` and
   `rg -l "Selection" test/` return nothing), module `Aurora.Uix.Test.SelectionTest`,
   `use ExUnit.Case, async: true`, one test "unselect/2 removes ids from every page": build with
   `Selection.set_selected/4` (`"a"` on page 1, `"b"` on page 2, `"c"` on page 2), call
   `Selection.unselect(selection, ["a", "b"])`, assert `selected == MapSet.new(["c"])` and
   `selected_in_page == %{1 => MapSet.new(), 2 => MapSet.new(["c"])}`.
4. `test/support/app_web/routes.ex` — modified. Inside the `routes` quote, after the
   `AshSortableColumnsTest.Author` registration, add:
   ```elixir
   RoutesHelper.register_crud(EventsTest.Product, "events-products")
   RoutesHelper.register_crud(EventsTest.ProductLocation, "events-product-locations")
   RoutesHelper.register_crud(AshEventsTest.Author, "ash-events-authors")
   ```
5. Components: none. Theme: none. `dt/1` strings: none new.
6. Backend boundary: every new line consumes the CRUD dispatcher (`apply_get_function/3`,
   `apply_delete_function/3`), `BasicHelpers.primary_key_value/2` and `%Event{}`; no
   `Ecto.*` / `Ash.*` struct appears. `schema.__schema__(:primary_key)` is the reflection
   `Aurora.Uix.Parsers.Common` already uses for both backends.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-2:end -->

<!-- section:UI-3:start -->
### UI-3 — UI · handler + generator · open show and form reactions
Depends on: UI-2

#### Documentation references
- `guides/core/liveview.md` § Reacting to Data Changes › How an open index reacts (written by DOC-1)

#### Implementation details
Layout types: `:show` (the show modal of the Index LiveView) and `:form` (the edit and
show-edit modals, and the generated FormComponent's `update/2`). `:index` list behaviour is
UI-2's and stays unchanged. The ShowComponent generator is untouched.

##### Acceptance criteria
- [ ] AC-1: Given an open show of record X, an `:updated` event for X re-reads X: the show
      displays the new value.
- [ ] AC-2: Given an open show of record X, a `:deleted` event for X closes the show (patch to
      the index path) with the flash "Item deleted successfully".
- [ ] AC-3: Given an open edit form of record X with typed, unsaved input, an `:updated` event for
      X keeps the typed input, keeps the form dirty (closing it opens the discard dialog), and
      shows the flash "Product updated successfully".
- [ ] AC-4: Given an open edit form of record X, a `:deleted` event for X keeps the form open and
      shows the flash "Item deleted successfully".
- [ ] AC-5: Given an open edit form of record X with typed input, reopening the form for record Y
      starts clean: Y's stored values, and closing it opens no discard dialog.
- [ ] AC-6 (empty path): An event for a different record leaves the open show and form untouched
      and shows no flash.
- [ ] AC-7 (degraded path): An `:updated` event for X after X is gone (the re-read returns
      `nil`) keeps the show open with the values it already displays.
- [ ] AC-8: AC-1, AC-2 and AC-3 hold on the Ash `blog` `Author` UI, with the flash
      "Author updated successfully".

##### Test ports
- Routes registered by UI-2: `"/events-products"` (`EventsTest.Product`) and
  `"/ash-events-authors"` (`AshEventsTest.Author`) · layout types `:show`, `:form` · observable:
  `has_element?/2` on `#auix-product-show-modal input[value='<value>']` (show fields render a
  valued input — precedent `test/cases_live/record_navigation_test.exs`), on
  `#auix-product-edit-modal input[name='product[name]'][value='<value>']`, on `#flash-info`
  (`core_components.ex` `flash/1` default id `"flash-#{kind}"`, rendered by `index_renderer.ex`),
  on `#auix-product-discard-confirm-modal`; `assert_patch(view, "/events-products")`.
- Drives: events are published from the test process with the public API (`Events.updated/1`,
  `Events.deleted/2`) — plain `broadcast`, so the view receives them. Typing —
  `view |> form("#auix-product-form", product: %{name: "Typed name"}) |> render_change()`.
  Close request — `view |> with_target("#auix-product-edit-modal [data-phx-component]") |> render_click("auix_request_close", %{})`
  (precedent `test/cases_live/form_discard_guard_test.exs` `request_close/2`). Reopen on another
  record — `render_patch(view, "/events-products/#{other.id}/edit")`.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | add to test/cases_live/events_test.exs (created by UI-2), new `describe "an open show"` | seed 1; view on `/events-products/#{id}/show`; `{:ok, renamed} = Inventory.update_product(product, %{name: "Renamed item"})` | test/cases_live/events_test.exs | "re-reads its record on :updated" | `Events.updated(renamed)`; `assert has_element?(view, "#auix-product-show-modal input[value='Renamed item']")` |
| AC-2 | add to test/cases_live/events_test.exs, `describe "an open show"` | seed 1; view on `/events-products/#{id}/show`; `Inventory.delete_product(product)` | test/cases_live/events_test.exs | "closes on :deleted" | `Events.deleted(Product, [product.id])`; `assert_patch(view, "/events-products")`; `refute has_element?(view, "#auix-product-show-modal")`; `assert has_element?(view, "#flash-info", "Item deleted successfully")` |
| AC-7 | add to test/cases_live/events_test.exs, `describe "an open show"` | seed 1; view on `/events-products/#{id}/show`; `Inventory.delete_product(product)` | test/cases_live/events_test.exs | "keeps its record when the re-read finds nothing" | `Events.updated(product)`; `assert has_element?(view, "#auix-product-show-modal input[value='Item test-1']")` |
| AC-3 | add to test/cases_live/events_test.exs, new `describe "an open form"` | seed 1; view on `/events-products/#{id}/edit`; type `"Typed name"` | test/cases_live/events_test.exs | "keeps typed input and reports an update" | `Events.updated(product)`; `assert has_element?(view, "#auix-product-edit-modal input[name='product[name]'][value='Typed name']")`; `assert has_element?(view, "#flash-info", "Product updated successfully")`; request close → `assert has_element?(view, "#auix-product-discard-confirm-modal")` |
| AC-4 | add to test/cases_live/events_test.exs, `describe "an open form"` | seed 1; view on `/events-products/#{id}/edit` | test/cases_live/events_test.exs | "stays open and reports a delete" | `Events.deleted(Product, [product.id])`; `assert has_element?(view, "#auix-product-edit-modal")`; `assert has_element?(view, "#flash-info", "Item deleted successfully")` |
| AC-5 | add to test/cases_live/events_test.exs, `describe "an open form"` | seed 2; view on `/events-products/#{first.id}/edit`; type `"Typed name"` | test/cases_live/events_test.exs | "reopened on another record starts clean" | `render_patch(view, "/events-products/#{second.id}/edit")`; `assert has_element?(view, "#auix-product-edit-modal input[name='product[name]'][value='Item test-2']")`; `refute has_element?(view, "input[name='product[name]'][value='Typed name']")`; request close → `refute has_element?(view, "#auix-product-discard-confirm-modal")`. Guard row: it passes before and after this section and pins that the merge in step 2 below never carries state to another record. |
| AC-6 | add to test/cases_live/events_test.exs, `describe "an open form"` | seed 2; view on `/events-products/#{first.id}/edit`; type `"Typed name"` | test/cases_live/events_test.exs | "ignores an event for another record" | `Events.updated(second)`; `refute has_element?(view, "#flash-info")`; `assert has_element?(view, "input[name='product[name]'][value='Typed name']")` |
| AC-8 | add to test/cases_live/ash_events_test.exs (created by UI-2), `describe "an open show"` and `describe "an open form"` | `create_sample_authors(1)`; routes `/ash-events-authors/#{id}/show` and `/edit`; rename with `author \|> Ash.Changeset.for_update(:update, %{name: "Renamed author"}) \|> Ash.update!()`; delete with `Ash.destroy!(author)` | test/cases_live/ash_events_test.exs | "re-reads its record on :updated", "closes on :deleted", "keeps typed input and reports an update" | the AC-1, AC-2, AC-3 sketches with `#auix-author-show-modal`, `#auix-author-edit-modal`, `#auix-author-form`, `input[name='author[name]']`, `#auix-author-discard-confirm-modal`, `assert_patch(view, "/ash-events-authors")` and the flash "Author updated successfully" |

AC-3 is red before step 2 below: an event re-reads the list, the Index re-renders the form's
`live_component` with a new `pagination`, and today's generated `update/2` replaces the whole
`auix` assign, so `FormImpl.auix_update/2`'s `assign_auix_new(:form, …)` rebuilds the form from
the stored record.

##### Modules & components
1. `Aurora.Uix.Templates.Basic.Handlers.IndexImpl` at
   `lib/aurora_uix/templates/basic/handlers/index_impl.ex` — modified.
   1. The `auix_handle_info(%Event{} = event, socket)` clause UI-2 added gains a last pipe step:
      ```elixir
      def auix_handle_info(%Event{} = event, socket) do
        {:noreply,
         socket
         |> unselect_deleted(event)
         |> assign_selected_states()
         |> refresh_current_page()
         |> react_to_open_entity(event)}
      end
      ```
   2. New private functions, in `## PRIVATE`:
      ```elixir
      @spec react_to_open_entity(Socket.t(), Event.t()) :: Socket.t()
      defp react_to_open_entity(
             %{assigns: %{live_action: live_action, auix: auix}} = socket,
             %Event{action: action, ids: ids}
           )
           when live_action in [:show, :edit, :show_edit] and action in [:updated, :deleted] do
        entity_id = BasicHelpers.primary_key_value(auix.entity, auix.primary_key)

        if not is_nil(entity_id) and entity_id in ids,
          do: react_to_change(socket, live_action, action, entity_id),
          else: socket
      end

      defp react_to_open_entity(socket, _event), do: socket

      @spec react_to_change(Socket.t(), atom(), Event.action(), term()) :: Socket.t()
      defp react_to_change(%{assigns: %{auix: auix}} = socket, :show, :updated, entity_id) do
        get_opts =
          socket
          |> backend_socket_opts(auix.get_function)
          |> Keyword.put(:preload, auix.preload)

        case apply_get_function(auix.get_function, entity_id, get_opts) do
          nil -> socket
          entity -> assign_auix(socket, :entity, entity)
        end
      end

      defp react_to_change(%{assigns: %{auix: auix}} = socket, :show, :deleted, _entity_id) do
        socket
        |> put_flash(:info, dt("Item deleted successfully"))
        |> push_patch(to: "/#{auix.uri_path}")
      end

      defp react_to_change(%{assigns: %{auix: auix}} = socket, _form_action, :updated, _entity_id),
        do: put_flash(socket, :info, "#{auix.name} updated successfully")

      defp react_to_change(socket, _form_action, :deleted, _entity_id),
        do: put_flash(socket, :info, dt("Item deleted successfully"))
      ```
      The re-read uses the same `get_opts` as `apply_action/2`'s `:show` clause (actor plus
      `auix.preload`). `"/#{auix.uri_path}"` is the index path the pagination events already
      patch to (`auix_handle_event("pagination_to_page", …)`). The form is never modified here:
      only a flash is set.
   3. Docs: extend the `auix_handle_info/2` `@doc` sentence about `%Aurora.Uix.Event{}` with "; an
      open show of an affected record re-reads it on `:updated` and closes on `:deleted`, and an
      open form on an affected record shows a flash".
2. Generated FormComponent at `lib/aurora_uix/templates/basic/generators/form_generator.ex`
   `generate_module/1` — modified. In the quoted `def update(...)`, replace
   ```elixir
   def update(%{auix: %{entity: entity, routing_stack: routing_stack}} = assigns, socket) do
     socket
     |> assign(assigns)
   ```
   with
   ```elixir
   def update(
         %{auix: %{entity: _entity, routing_stack: _routing_stack} = incoming_auix} = assigns,
         socket
       ) do
     merged_auix = socket.assigns |> Map.get(:auix, %{}) |> Map.merge(incoming_auix)

     socket
     |> assign(Map.put(assigns, :auix, merged_auix))
   ```
   The rest of the pipe (`assign_parsed_opts/2`, `assign_actor_to_auix/1`, the handler's
   `update/2`) is unchanged. The `assign_auix_new/3` keys of `FormImpl.auix_update/2` — `:form`,
   `:_sections`, `:_form_dirty?`, `:_discard_confirm_open?` — now survive a parent re-render; the
   keys the Index passes (`entity`, `routing_stack`, `uri_path`, `_close_path`,
   `one_to_many_related_key`, `pagination`, `item_index` — `index_renderer.ex` `render/1`
   `.live_component` `auix={...}`) still overwrite. Another record starts clean because the Index
   renders the component with `id={entity_id(@auix) || @live_action}`: a new record id mounts a
   new component whose `socket.assigns` holds no `:auix`.
3. Components: none. Theme: none. `dt/1` strings: reused `"Item deleted successfully"`
   (`priv/gettext/default.pot`); the update flash reuses `FormImpl`'s
   `"#{auix.name} updated successfully"` expression verbatim, unlocalised as it is today.
4. Markup: no selector, id, input name or label changes.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-3:end -->

---

### Out of Scope
- Tenant or user scoping of topics. A change in another tenant costs a subscriber one extra re-read; it leaks nothing, because payload entities are never rendered.
- Patching rows into the stream instead of re-reading the page.
- Debouncing bursts of events. Bulk publishers send one event with many ids, or `:changed`.
- Live refresh of a one-to-many child list inside a parent's open form.
- Reloading or merging an open form when its record changes elsewhere.
- No Parser or Schema section: the publishers and the subscriber live in the shared handlers and consume only the CRUD dispatcher, `%Aurora.Uix.Event{}` and `backend_socket_opts/2`; UI-1, UI-2 and UI-3 each test an Ecto (`inventory`) and an Ash (`blog`) resource.
- Keeping the ShowComponent's `_sections` tab state across a parent re-render; only the FormComponent's `update/2` merges.
- Adding `phoenix_pubsub` to `mix.exs`; it arrives through `phoenix`.
<!-- enriched-spec:end -->
