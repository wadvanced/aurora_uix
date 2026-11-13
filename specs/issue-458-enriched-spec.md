<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** high

### Overview
This spec covers steps 1–3 of the epic: the documented component contract, a test suite that locks today's navigation and handler-hook behaviour, and the extraction of `Aurora.Uix.Navigation`. Nothing here changes generated behaviour: every URL, event and `@auix` key a host reads stays as it is. The documented contract departs from the issue body's design decisions 3 and 6 by a decision taken during enrichment: a component has no navigation mode. It always reports intents to its parent, and the parent (the generated `.Index` LiveView, or a hand-written host) decides what they mean. All sections are backend-agnostic UI work; the navigation suite runs on both backends (Ecto `inventory`, Ash `blog`).

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | `CHANGELOG.md` § `[0.2.1]`, `guides/core/components.md` (new), `guides/core/liveview.md` § Module Generation, § Generated Module Structure, § Targeting the Component, § Navigation, § Related guides, `guides/whats_new/0.2.1.md` (new) | none | federico/458-doc-1-components-contract | docs: component contract and navigation spec (#458 · DOC-1) |
| UI-1 | UI | handlers · navigation characterization tests, Ecto and Ash (no library change) | DOC-1 | federico/458-ui-1-navigation-characterization | test: lock current navigation behaviour (#458 · UI-1) |
| UI-2 | UI | handlers · handler-hook tests for the documented callbacks, in the existing `handler_hooks_*` test files (no library change) | DOC-1 | federico/458-ui-2-compatibility-suite | test: cover the documented handler hooks (#458 · UI-2) |
| UI-3 | UI | handlers · extract `Aurora.Uix.Navigation` (`base_path`) as a pure data module; socket layer in `Aurora.Uix.Templates.Basic.Helpers` | UI-1, UI-2 | federico/458-ui-3-navigation-module | refactor: extract Aurora.Uix.Navigation (#458 · UI-3) |
| DOC-2 | Documentation | `guides/core/components.md` § Navigation, `guides/core/liveview.md` § Navigation, `guides/whats_new/0.2.1.md` § Upgrading from 0.2.0 (the pure `Aurora.Uix.Navigation` API of UI-3) | UI-3 | federico/458-doc-2-navigation-guides | docs: navigation guides match the pure Aurora.Uix.Navigation (#458 · DOC-2) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
- `CHANGELOG.md § [0.2.1]`
- `guides/core/liveview.md § Module Generation with auix_create_ui`, `§ Generated Module Structure`, `§ Targeting the Component`, `§ Navigation`, `§ Related guides`
- `guides/whats_new/0.2.0.md` (shape of a What's New page)

#### Implementation details

##### CHANGELOG.md
1. § `## [0.2.1]` — insert a new `### Added` subsection directly above `### Build`, verbatim:
   ```
   ### Added

   - **Reusable components**
     - `auix_create_ui` generates an `IndexComponent` next to `FormComponent` and `ShowComponent`. The three
       components can be embedded in any LiveView; the generated `Index` LiveView hosts them and keeps its
       routes, handler hooks and behaviour.
     - A component never navigates: it reports what the user asked for to its parent, and the parent decides.
       `Aurora.Uix.Navigation` holds the navigation state of the generated LiveView (`@auix.navigation`),
       which patches and navigates as before.
     - `auix_create_ui generate:` chooses which modules are generated; leaving out `:live_view` generates the
       components alone.
     - `Aurora.Uix.Live.ComponentHooks` forwards `Aurora.Uix.Events` to the components of a hand-written LiveView.
     - A one-to-many list is an embedded `IndexComponent`; its columns come from the resource the field names
       with `resource:`.
     - New guide: Reusable Components.
   ```

##### guides/core/components.md
1. Create the file with this content, verbatim:
   ````markdown
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
   ````

##### guides/core/liveview.md
1. § Module Generation with `auix_create_ui` — replace the fenced module tree with, verbatim:
   ```
   Overview.Product                      # Parent module (generated)
   ├── Overview.Product.Index            # LiveView - Hosts the components, owns the routes
   ├── Overview.Product.IndexComponent   # LiveComponent - Handles the list
   ├── Overview.Product.FormComponent    # LiveComponent - Handles create/edit forms
   └── Overview.Product.ShowComponent    # LiveComponent - Handles detail view display
   ```
2. § Generated Module Structure — insert this paragraph directly above the line that starts `**FormComponent Module**`, followed by one blank line, verbatim:
   ```
   **IndexComponent Module** (`Overview.Product.IndexComponent`) - LiveComponent:
   - Holds the list state the Index LiveView delegates to it: streams, filters, sort, pagination and selection
   - Can be embedded in any LiveView; see [Reusable Components](components.md)
   ```
3. § Targeting the Component — replace the sentence that starts `` `@auix._myself` exists in the form and the show view only `` with, verbatim:
   ```
   `@auix._myself` exists in the index, the form and the show view. An untargeted event in the generated index
   still reaches the Index LiveView and its `auix_handle_event/3`.
   ```
4. § Navigation — replace the whole section body (from the line `Aurora UIX handles navigation through:` to the closing fence of the `push_navigate` / `push_patch` example) with, verbatim:
   ````markdown
   `Aurora.Uix.Navigation` owns the navigation of the generated LiveView. Its state is `@auix.navigation`, an
   `%Aurora.Uix.Navigation{}` with the base path, the current path and the routing stack.

   | Function | Does |
   |---|---|
   | `Navigation.path(nav, action, id)` | Builds the path of `:index`, `:new`, `:show`, `:edit` or `:show_edit` |
   | `Navigation.forward(socket, nav, target)` | Pushes the current path on the routing stack and goes to `target` (`patch: path` or `to: path`) |
   | `Navigation.back(socket, nav)` | Pops the routing stack and goes back |

   `auix_route_forward/2` and `auix_route_back/1` call them with the socket's own navigation, and remain the
   helpers to use in a handler:

   ```elixir
   def auix_handle_event("archive", _params, socket) do
     {:noreply, auix_route_back(socket)}
   end
   ```

   The generated LiveView navigates with a patch for a change within the view, a navigate for another view,
   and the routing stack in `?routing_stack=` so that back returns to where the user came from. The components
   never navigate: they report to the LiveView that hosts them; see [Reusable Components](components.md).

   `@auix.uri_path`, `@auix.uri_path_id`, `@auix.routing_stack` and `@auix[:index_new_link]` mirror the
   navigation state and stay readable from custom actions.
   ````
5. § Related guides — insert as the first list item, verbatim:
   ```
   - [Reusable Components](components.md) — embedding the index, form and show components in your own LiveView
   ```

##### guides/whats_new/0.2.1.md
1. Create the file with this content, verbatim:
   ````markdown
   # What's New in 0.2.1

   0.2.1 has no breaking change. Coming from a version earlier than 0.2.0? Follow
   [Upgrading from 0.1.7](0.2.0.md#upgrading-from-0-1-7) first. The [CHANGELOG](../../CHANGELOG.md) keeps the
   complete history.

   - [Reusable components](#reusable-components)
   - [Upgrading from 0.2.0](#upgrading-from-0-2-0)

   ## Reusable components

   `auix_create_ui` now generates an `IndexComponent` next to `FormComponent` and `ShowComponent`, and the three
   can be embedded in a LiveView you write:

   ```elixir
   <.live_component
     module={MyAppWeb.ProductViews.Product.IndexComponent}
     id="low-stock"
     where={[{:quantity_at_hand, :lt, 10}]}
   />
   ```

   - The generated `Index` LiveView hosts the components and keeps its routes, handler hooks and modal.
   - `generate:` on `auix_create_ui` chooses the modules; leave out `:live_view` to get the components alone.
   - A component never navigates. It tells its parent what the user asked for, and the parent decides.
     `Aurora.Uix.Navigation` holds the navigation state of the generated LiveView.
   - `on_mount Aurora.Uix.Live.ComponentHooks` keeps embedded components up to date with `Aurora.Uix.Events`.
   - A one-to-many list is an embedded `IndexComponent`.

   The [Reusable Components](../core/components.md) guide has the contract and the examples.

   ## Upgrading from 0.2.0

   No change is required. `@auix.uri_path`, `@auix.uri_path_id`, `@auix.routing_stack` and
   `@auix[:index_new_link]` stay readable; a handler that assigned one of them directly now changes navigation
   through `auix_route_forward/2`, `auix_route_back/1` and `Aurora.Uix.Navigation`.

   Coming from a version earlier than 0.2.0? Follow [Upgrading from 0.1.7](0.2.0.md#upgrading-from-0-1-7) first.
   ````

##### Acceptance criteria
- [x] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no
      issue-link suffix (mechanical — no red test; verified by
      `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [x] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-458-enriched-spec.md`)
- [x] AC-3: `guides/core/components.md` exists with the sections Embedding a component, Inputs, Outputs, Events, Navigation, Live updates, Several instances on one page, Generating the components alone, One-to-many lists and Design decisions (mechanical — no red test; verified by `grep -c '^## ' guides/core/components.md` returning `10`)
- [x] AC-4: `guides/core/liveview.md § Navigation` documents `Aurora.Uix.Navigation` and no longer carries the `~p"/products/#{product.id}/edit"` example (mechanical — no red test; verified by `grep -c 'Navigation.path(nav, action, id)' guides/core/liveview.md` returning `1` and `grep -c 'push_patch(socket, to: ~p' guides/core/liveview.md` returning `0`)
- [x] AC-5: `guides/core/liveview.md` lists `IndexComponent` in the module tree and in § Generated Module Structure, states that `@auix._myself` exists in the index, and links the new guide from § Related guides (mechanical — no red test; verified by `grep -c 'IndexComponent' guides/core/liveview.md` returning `3` and `grep -c '(components.md)' guides/core/liveview.md` returning `3`)
- [x] AC-6: `guides/whats_new/0.2.1.md` exists and links the Reusable Components guide (mechanical — no red test; verified by `grep -c '(../core/components.md)' guides/whats_new/0.2.1.md` returning `1`)
- [x] AC-7: the introduction of `guides/core/components.md` describes the guide without comparing it to earlier versions (mechanical — no red test; verified by `grep -c 'behaves as it always did' guides/core/components.md` returning `0` and `grep -c '^This guide shows how to embed the components in a LiveView you write\.$' guides/core/components.md` returning `1`)
- [x] AC-8: `guides/whats_new/0.2.1.md` sends readers coming from a version earlier than 0.2.0 to the 0.2.0 upgrade steps, in the introduction and in § Upgrading from 0.2.0 (mechanical — no red test; verified by `grep -c '(0.2.0.md#upgrading-from-0-1-7)' guides/whats_new/0.2.1.md` returning `2`)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->
<!-- section:UI-1:start -->
### UI-1 — UI · handlers · navigation characterization tests
Depends on: DOC-1

#### Documentation references
- `guides/core/liveview.md § Using Generated Modules with Routes`, `§ Navigation`, `§ Built-in Events`
- `guides/core/components.md § Navigation`

#### Implementation details

This section adds tests and test support only. It changes no file under `lib/`. Every test passes on its first run, because it records what the library does today. A test that fails on its first run means this spec states a wrong value: report a spec defect with the observed value; never change library code to satisfy it.

Layout types covered: `:index`, `:form`, `:show`. All navigation is observed on the generated LiveView.

Notation used below: `P` is the parent index path, `C` the child index path, `<id>` a parent id, `<cid>` a child id. A stack is written top first, as the decoded `routing_stack` values, each entry `{type, path}`.

##### Acceptance criteria
- [x] AC-1: Given the index at `P`, clicking a row's show link patches to `P/<id>/show` with stack `[{patch, P}, {patch, P}]`; clicking a row's edit link patches to `P/<id>/edit` with the same stack; clicking the new link patches to `P/new` with the same stack
- [x] AC-2: Given the show modal opened from the index, clicking its edit link patches to `P/<id>/show-edit` with stack `[{patch, P/<id>/show}, {patch, P}, {patch, P}]`; a close request on the form patches to `P/<id>/show` with stack `[{patch, P}, {patch, P}]`; `auix_route_back` then patches to `P` with stack `[{patch, P}]`
- [x] AC-3: Given the new form opened from the index, a close request patches to `P` with stack `[{patch, P}]`; given the edit form opened from the index, a valid save patches to `P` with stack `[{patch, P}]`
- [x] AC-4: Given a direct load of `P/<id>/edit`, a close request patches to `P` with an empty stack; a valid save patches to `P` with an empty stack; given a direct load of `P/<id>/show`, `auix_route_back` patches to `P` with an empty stack
- [x] AC-5: Given a direct load of `P/<id>/edit` and a changed field, a close request sends no patch and opens the discard dialog; clicking discard patches to `P` with an empty stack
- [x] AC-6: Given a direct load of `P/<id>/edit` with a one-to-many list, clicking the list's new link live-redirects to `C/new` with query `related_key=<key>&parent_id=<id>` and stack `[{navigate, P/<id>/edit}, {patch, P}]`; saving the child live-redirects to `P/<id>/edit` with stack `[{patch, P}]`; a close request on the child form live-redirects to the same path with the same stack
- [x] AC-7: Given a direct load of `P/<id>/show`, clicking a child row's show link live-redirects to `C/<cid>/show` with stack `[{navigate, P/<id>/show}, {patch, P}]`, and `auix_route_back` on the child view live-redirects to `P/<id>/show` with stack `[{patch, P}]`; given a direct load of `P/<id>/edit`, clicking a child row's edit link live-redirects to `C/<cid>/edit` with query `related_key=<key>&parent_id=<id>` and stack `[{navigate, P/<id>/edit}, {patch, P}]`
- [x] AC-8: Given the new form opened from the index of a resource whose form renders a one-to-many list, a valid save live-redirects to `P/<new id>/edit` with stack `[{patch, P}]`
- [x] AC-9: Given the show modal opened from the index, `read_indexed_entry` with a page and an index in that page patches to `P/<that record's id>/show` with no `routing_stack` parameter; with the next page and index `0` it patches to the first record of the next page; `auix_route_back` then patches to `P` with an empty stack
- [x] AC-10: Given the index at `P`, `pagination_next` patches to `P?page=2` with stack `[{patch, P}, {patch, P}]`; `pagination_to_page` with page `3` then patches to `P?page=3` with three `{patch, P}` entries; opening new then patches to `P/new` with four entries, and a close request patches to `P` with three entries and no `page` parameter
- [x] AC-11: Given routes declared with `auix_live_resources/3` and `only: [:index, :show]`, `P` and `P/<id>/show` mount, and the router has no route for `P/new`, `P/<id>/edit` and `P/<id>/show-edit`; given `except: [:new, :edit]`, `P/<id>/show-edit` mounts, and the router has no route for `P/new` and `P/<id>/edit`
- [x] AC-12: A path that carries `?routing_stack=` built by `NavigationHelper.encode_stack/1` from two entries mounts, and `auix_route_back` goes to the top entry's path with the second entry as the remaining stack
- [x] AC-13: Given the index at `P`, a row's show link and edit link are anchors with `href="#"`, `phx-click="auix_route_forward"`, `phx-value-route_type="patch"` and `phx-value-route_path` equal to `P/<id>/show` and `P/<id>/edit`; the new link is an anchor with the same `phx-click` and `phx-value-route_type`, `phx-value-route_path="P/new"` and no `href` attribute

##### Test ports
- Ecto routes, registered in `test/support/app_web/routes.ex` inside `load_test_routes/0` via `RoutesHelper.register_crud/2`:
  `register_crud(NavigationTest.Product, "navigation-products")` and
  `register_crud(NavigationTest.ProductTransaction, "navigation-product_transactions")`.
  `P = "/navigation-products"`, `C = "/navigation-product_transactions"`, `<key> = product_id`.
- Ash routes, same place: `register_crud(AshNavigationTest.Author, "ash-navigation-authors")` and
  `register_crud(AshNavigationTest.Post, "ash-navigation-posts")`.
  `P = "/ash-navigation-authors"`, `C = "/ash-navigation-posts"`, `<key> = author_id`.
- Route subsets, same place, directly below the four lines above:
  `auix_live_resources("/navigation-only-products", NavigationTest.Product, only: [:index, :show])` and
  `auix_live_resources("/navigation-except-products", NavigationTest.Product, except: [:new, :edit])`.
  `Aurora.Uix.RouteHelper` is already imported by `test/support/app_web/router.ex`; inside the quote of `load_test_routes/0` call it as `Aurora.Uix.RouteHelper.auix_live_resources(...)` after `require Aurora.Uix.RouteHelper`.
- Observables: `assert_patch/1` (returns the patched path), the `{:error, {:live_redirect, %{to: path}}}` return of `render_click/1` and `render_submit/1`, `has_element?/2`, `Phoenix.Router.route_info/4` on `Aurora.UixWeb.Test.Router`.

##### Red tests
Every row passes on first run (characterization). Setup for every Ecto row: `delete_all_inventory_data()` then the helper named in the row. Setup for every Ash row: `delete_all_blog_data()`, `[author | _] = create_sample_authors(2)`, `create_sample_posts(3, %{author_id: author.id})`.

`remount` in a sketch means `{:ok, view, _html} = live(conn, P)`; the drives after it run on the new view.

Once `P/new` has been opened on a view, the index of that view renders no rows, while the form is open and after it closes. `assign_auix_uri_path/1` (`lib/aurora_uix/templates/basic/helpers.ex`) keeps `new` in `uri_path` for `live_action: :new`, so the stream container id `auix-table-<uri_path_id>-index` (`lib/aurora_uix/templates/basic/renderers/index_renderer.ex`, `render/1`) changes to `auix-table-navigation-products--new-index`, and the handler does not stream the rows again when the id returns. Every drive that clicks a row link after a new form remounts first. No test in this section asserts on the missing rows.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file (`ls test/cases_live \| grep -i navig` returns only `record_navigation_*`) | `create_sample_products(3, :test)`; `live(conn, P)` | `test/cases_live/navigation_test.exs` | `"index opens show, edit and new with the index pushed twice"` | click `tr[id^='products-<id>'] td:nth-child(2) a[name='auix-show-product']`; `NavigationHelper.decode_route(assert_patch(view)) == {"P/<id>/show", %{}, [{:patch, P}, {:patch, P}]}`; remount; click `tr[id^='products-<id>'] a[name='auix-edit-product']`; remount; click `a[name='auix-new-product']` |
| AC-1 | new file (same search) | Ash setup; `live(conn, P)` | `test/cases_live/ash_navigation_test.exs` | `"index opens show, edit and new with the index pushed twice"` | same drives with `tr[id='authors-<id>'] td:nth-child(2) a[name='auix-show-author']`, `tr[id='authors-<id>'] a[name='auix-edit-author']`, `a[name='auix-new-author']` |
| AC-2 | add to `navigation_test.exs` | as AC-1 | `test/cases_live/navigation_test.exs` | `"show to show-edit and back unwinds the stack"` | open show; click `#auix-product-show-modal a[name='auix-edit-product']`; decode; `view \|> with_target("#auix-product-show_edit-modal [data-phx-component]") \|> render_click("auix_request_close", %{})`; decode; `render_click(view, "auix_route_back", %{})`; decode |
| AC-2 | add to `ash_navigation_test.exs` | Ash setup | `test/cases_live/ash_navigation_test.exs` | `"show to show-edit and back unwinds the stack"` | same drives with `author` in the selectors |
| AC-3 | add to `navigation_test.exs` | as AC-1 | `test/cases_live/navigation_test.exs` | `"closing and saving a form opened from the index returns to the index"` | click `a[name='auix-new-product']`; `assert_patch(view)`; close request on `#auix-product-new-modal [data-phx-component]`; decode → `{P, %{}, [{:patch, P}]}`; remount; click `tr[id^='products-<id>'] a[name='auix-edit-product']`; `assert_patch(view)`; `form("#auix-product-form", product: %{name: "Changed", description: "d", quantity_initial: 2.0}) \|> render_submit()`; decode → `{P, %{}, [{:patch, P}]}` |
| AC-4 | add to `navigation_test.exs` | as AC-1; `live(conn, "P/<id>/edit")` | `test/cases_live/navigation_test.exs` | `"a directly loaded form or show returns to the index with an empty stack"` | close request on `#auix-product-edit-modal [data-phx-component]` → `{P, %{}, []}`; remount; valid submit → `{P, %{}, []}`; `live(conn, "P/<id>/show")`; `render_click(view, "auix_route_back", %{})` → `{P, %{}, []}` |
| AC-4 | add to `ash_navigation_test.exs` | Ash setup; `live(conn, "P/<id>/edit")` | `test/cases_live/ash_navigation_test.exs` | `"a directly loaded form or show returns to the index with an empty stack"` | close request on `#auix-author-edit-modal [data-phx-component]` → `{P, %{}, []}`; `live(conn, "P/<id>/show")`; `auix_route_back` → `{P, %{}, []}` |
| AC-5 | add to `navigation_test.exs` | as AC-4 | `test/cases_live/navigation_test.exs` | `"the discard guard holds navigation until the change is discarded"` | `form("#auix-product-form", product: %{name: "Dirty"}) \|> render_change()`; close request; `assert has_element?(view, "#auix-product-discard-confirm-modal")`; `assert has_element?(view, "#auix-product-edit-modal")`; click `button[name='auix-discard-changes']`; decode → `{P, %{}, []}` |
| AC-6 | add to `navigation_test.exs` | `create_sample_products_with_transactions(1, 2, :test)`; `live(conn, "P/<id>/edit")` | `test/cases_live/navigation_test.exs` | `"a new child navigates to the child route and back to the parent form"` | `{:error, {:live_redirect, %{to: to}}} = view \|> element("a[name='auix-new-product__product_transactions-form']") \|> render_click()`; `decode_route(to) == {"C/new", %{"related_key" => "product_id", "parent_id" => id}, [{:navigate, "P/<id>/edit"}, {:patch, P}]}`; `{:ok, child, _} = live(conn, to)`; submit `form("#auix-product_transaction-form", product_transaction: %{quantity: "3", type: "in", cost: 1.5})` → redirect decodes to `{"P/<id>/edit", %{}, [{:patch, P}]}`; remount child at `to`; close request on `#auix-product_transaction-new-modal [data-phx-component]` → same |
| AC-6 | add to `ash_navigation_test.exs` | Ash setup; `live(conn, "P/<id>/edit")` | `test/cases_live/ash_navigation_test.exs` | `"a new child navigates to the child route and back to the parent form"` | click `a[name='auix-new-author__posts-form']`; decode → `{"C/new", %{"related_key" => "author_id", "parent_id" => id}, [{:navigate, "P/<id>/edit"}, {:patch, P}]}`; `live(conn, to)`; close request on `#auix-post-new-modal [data-phx-component]` → `{"P/<id>/edit", %{}, [{:patch, P}]}` |
| AC-7 | add to `navigation_test.exs` | as AC-6 | `test/cases_live/navigation_test.exs` | `"child show and edit links navigate with the parent on the stack"` | `live(conn, "P/<id>/show")`; click `table a[name='auix-show-product__product_transaction-<cid>']`; decode; `live(conn, to)`; `render_click(child, "auix_route_back", %{})` → redirect decodes to `{"P/<id>/show", %{}, [{:patch, P}]}`; `live(conn, "P/<id>/edit")`; click `table a[name='auix-edit-product__product_transaction-<cid>']`; decode |
| AC-8 | add to `navigation_test.exs` | `delete_all_inventory_data()`; `live(conn, P)` | `test/cases_live/navigation_test.exs` | `"a new parent with a child list continues on its edit form"` | click `a[name='auix-new-product']`; `assert_patch(view)`; submit `product: %{reference: ref, name: "n", description: "d", quantity_initial: 1.0}` with a unique `ref`; redirect decodes to `{"P/" <> new_id <> "/edit", %{}, [{:patch, P}]}` where `new_id` is the id of `Inventory.list_products(where: [reference: ref])`'s only entry |
| AC-9 | add to `navigation_test.exs` | `create_sample_products(100, :test)`; `live(conn, P)` | `test/cases_live/navigation_test.exs` | `"record navigation patches without a routing stack"` | click `table tbody tr:nth-of-type(5) td:nth-of-type(2) a`; `assert_patch(view)`; `render_click(view, "read_indexed_entry", %{"page" => "1", "index" => "5"})` → `{"P/<id of id_test-006>/show", %{}, :none}`; `render_click(view, "read_indexed_entry", %{"page" => "2", "index" => "0"})` → `{"P/<id of id_test-041>/show", %{}, :none}`; `auix_route_back` → `{P, %{}, []}` |
| AC-10 | add to `navigation_test.exs` | as AC-9 | `test/cases_live/navigation_test.exs` | `"pagination pushes the index and closing a form drops the page"` | `render_click(view, "pagination_next", %{})` → `{P, %{"page" => "2"}, [2 entries]}`; `render_click(view, "pagination_to_page", %{"page" => "3"})` → `{P, %{"page" => "3"}, [3 entries]}`; click `a[name='auix-new-product']` → `{"P/new", %{}, [4 entries]}`; close request → `{P, %{}, [3 entries]}`; every entry is `{:patch, P}` |
| AC-11 | add to `navigation_test.exs` | `create_sample_products(1, :test)` | `test/cases_live/navigation_test.exs` | `"only and except limit the mounted routes"` | `assert {:ok, _, _} = live(conn, "/navigation-only-products")`; same for `/<id>/show`; `Phoenix.Router.route_info(Aurora.UixWeb.Test.Router, "GET", "/navigation-only-products/new", "localhost") == :error`; same for `/<id>/edit` and `/<id>/show-edit`; `live(conn, "/navigation-except-products/<id>/show-edit")` mounts; `route_info` returns `:error` for `/navigation-except-products/new` and `/<id>/edit` |
| AC-12 | add to `navigation_test.exs` | `create_sample_products(1, :test)` | `test/cases_live/navigation_test.exs` | `"a forwarded routing stack is honoured on back"` | `stack = NavigationHelper.encode_stack([{:navigate, "/navigation-product_transactions"}, {:patch, P}])`; `live(conn, "P/<id>/show?routing_stack=" <> stack)`; `{:error, {:live_redirect, %{to: to}}} = render_click(view, "auix_route_back", %{})`; `decode_route(to) == {"/navigation-product_transactions", %{}, [{:patch, P}]}` |
| AC-13 | add to `navigation_test.exs` | `create_sample_products(1, :test)`; `live(conn, P)` | `test/cases_live/navigation_test.exs` | `"index links keep their anchor attributes"` | `fwd = "[phx-click='auix_route_forward'][phx-value-route_type='patch']"`; `has_element?(view, "tr[id^='products-<id>'] a[name='auix-show-product'][href='#']#{fwd}[phx-value-route_path='P/<id>/show']")`; `has_element?(view, "tr[id^='products-<id>'] a[name='auix-edit-product'][href='#']#{fwd}[phx-value-route_path='P/<id>/edit']")`; `has_element?(view, "a[name='auix-new-product']#{fwd}[phx-value-route_path='P/new']")`; `refute has_element?(view, "a[name='auix-new-product'][href]")` |

##### Modules & components
1. `Aurora.UixWeb.Test.NavigationHelper` at `test/support/navigation_helper.ex` — new (search: `grep -rn "NavigationHelper" lib test` returns nothing). `test/support/` is compiled in the test environment (`mix.exs` `elixirc_paths(:test)`). The module is self-contained: it calls no function of `Aurora.Uix.Templates.Basic.Helpers` and none of `Aurora.Uix.Navigation`, so the suite keeps its meaning when UI-3 moves the library code. It carries `@moduledoc` with `## Key Features` and `## Key Constraints`, and `@doc` + `@spec` on both functions:
   - `decode_route(path :: binary()) :: {binary(), map(), list({atom(), binary()}) | :none}` — parses `path` with `URI.parse/1`; decodes the query with `URI.decode_query/1`; removes `"routing_stack"` from the query map; when the parameter is absent the third element is `:none`; otherwise it is `param |> Base.decode64!() |> :zlib.uncompress() |> Jason.decode!() |> Map.fetch!("values")` mapped to `{String.to_existing_atom(type), path}`.
   - `encode_stack(entries :: list({atom(), binary()})) :: binary()` — `%{values: Enum.map(entries, fn {type, path} -> %{type: type, path: path} end)} |> Jason.encode!() |> :zlib.compress() |> Base.encode64() |> URI.encode_www_form()`.
2. `Aurora.UixWeb.Test.NavigationTest` at `test/cases_live/navigation_test.exs` — new. Header copied from `test/cases_live/association_one2many_ui_layout_test.exs`: `use Aurora.UixWeb.Test.UICase, :phoenix_case`, `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`, plus `alias Aurora.UixWeb.Test.NavigationHelper`. Metadata and layout:
   ```elixir
   auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)
   auix_resource_metadata(:product, context: Inventory, schema: Product)

   auix_create_ui do
     index_columns(:product, [:reference, :name, :quantity_initial], order_by: :reference)

     edit_layout :product do
       stacked([:reference, :name, :description, :quantity_initial, :product_transactions])
     end
   end
   ```
3. `Aurora.UixWeb.Test.AshNavigationTest` at `test/cases_live/ash_navigation_test.exs` — new. Header copied from `test/cases_live/ash_where_one2many_test.exs`. Metadata and layout:
   ```elixir
   auix_resource_metadata(:author, ash_resource: Author)
   auix_resource_metadata(:post, ash_resource: Post)

   auix_create_ui do
     index_columns(:post, [:title, :content])

     edit_layout :author do
       stacked([:name, :email, :posts])
     end
   end
   ```
4. `mix.exs` `docs/0` › `extras:` — insert `"guides/whats_new/0.2.1.md",` directly above `"guides/whats_new/0.2.0.md",`, and `"guides/core/components.md",` directly below `"guides/core/liveview.md",`. DOC-1 creates both files; this is the only non-test file the section edits.
5. Components: none. Theme: none. `dt/1` strings: none.

##### Green tests
1. The tests above pass, unmodified (code-issue runs these, targeted: `mix test test/cases_live/navigation_test.exs test/cases_live/ash_navigation_test.exs`)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
4. `git diff --name-only origin/main...HEAD -- lib` prints nothing
<!-- section:UI-1:end -->
<!-- section:UI-2:start -->
### UI-2 — UI · handlers · handler-hook tests for the documented callbacks
Depends on: DOC-1

#### Documentation references
- `guides/core/liveview.md § Index Handler Hook (LiveView)`, `§ Form/Edit Handler Hook (LiveComponent)`, `§ Show Handler Hook (LiveComponent)`, `§ Advanced: Overriding Phoenix Callbacks`, `§ Adding Custom Events`, `§ Targeting the Component`, `§ Hiding Fields at Runtime`

#### Implementation details

This section extends three existing test files and the handler module each one already defines. It adds no test file, no support module and no route, and it changes no file under `lib/`. Every new test passes on its first run. A test that fails on its first run is a spec defect to report, never a reason to change library code. The tests these files already hold stay unmodified.

Layout types covered: `:index`, `:form`, `:show`. The tests run on the Ecto backend only: the handler behaviours and the event and message delivery they exercise reach neither a parser nor a CRUD module.

Notation: `I = "/handler-hooks-index-products"`, `F = "/handler-hooks-form-products"`, `S = "/handler-hooks-show-products"`, `<id>` a product id.

Coverage of the documented extension points. A row marked "existing" gets no new test:

| `guides/core/liveview.md` section | Extension point | Covered by |
|---|---|---|
| § Advanced: Overriding Phoenix Callbacks › `mount/3` | override with `super` | existing: `test/cases_live/handler_hooks_index_test.exs` `"Test index hooks"` |
| § Index Handler Hook › `apply_action/2` | override with `super` | existing: same test |
| § Index Handler Hook › `auix_mount/3`, `auix_handle_params/3` | override with `super` | AC-1 |
| § Index Handler Hook › `auix_handle_event/3`, § Adding Custom Events (index) | custom untargeted event, fallback to `super` | existing: `test/cases_live/selected_bulk_action_test.exs` `"the control deactivates the ticked rows and clears the selection"` |
| § Index Handler Hook › `auix_handle_async/3` | custom task, fallback to `super` | AC-2 |
| § Index Handler Hook › `auix_handle_info/2` | custom clause, fallback to `super` | existing for a PubSub message: `test/cases_live/events_test.exs` (`Aurora.UixWeb.EventsProbeIndexHandler`); AC-3 for a message a form sends with `send(self(), …)` |
| § Form/Edit Handler Hook › `save_entity/2` | override with `super` | existing: `test/cases_live/handler_hooks_form_test.exs` `"Test main edit link"` |
| § Form/Edit Handler Hook › `auix_update/2`, § Hiding Fields at Runtime | override with `super`, `assign_auix(socket, :fields_to_reject, keys)` | AC-4 |
| § Advanced: Overriding Phoenix Callbacks › `update/2` | override with `super` | AC-4 |
| § Form/Edit Handler Hook › `auix_handle_event/3`, § Adding Custom Events (form), § Targeting the Component | custom event through `phx-target={@auix._myself}`, fallback to `super` | AC-5, AC-6 |
| § Show Handler Hook › `auix_update/2`, § Hiding Fields at Runtime | override with `super` | AC-7 |
| § Show Handler Hook › `auix_handle_event/3`, § Adding Custom Events (show) | custom targeted event, `auix_route_back/1` | AC-8 |

##### Acceptance criteria
- [x] AC-1: Given an index handler that overrides `auix_mount/3` and `auix_handle_params/3`, each assigning a custom `@auix` key and calling `super`, visiting `I?filter=abc` and sending the untargeted `hooks_report` event shows `mount=mounted filter=abc` in the info flash
- [x] AC-2: Given the same handler, the untargeted `hooks_async` event starts a task with `start_async/3`, and the task's result reaches `auix_handle_async/3`, which shows `async done` in the info flash
- [x] AC-3: Given a direct load of `I/<id>/edit`, a valid save reaches the index handler's `auix_handle_info/2` as `{component, {:saved, entity}}`; the `hooks_report` event then shows `saved=Renamed` in the info flash
- [x] AC-4: Given a form handler that overrides `Phoenix.LiveComponent` `update/2` and `auix_update/2`, each calling `super` and then adding a key to `:fields_to_reject` with `assign_auix/3`, the edit form renders no input for `rrp`, none for `list_price`, and the input for `description`
- [x] AC-5: Given a form footer action whose button carries `phx-target={@auix._myself}`, clicking it reaches the form handler's `auix_handle_event/3`; the form then renders no input for `description`, and still none for `rrp` and `list_price`
- [x] AC-6: Given the same form handler, the built-in `auix_request_close` event, which no clause of the handler names, reaches the default implementation through `super` and patches to `F`
- [x] AC-7: Given a show handler whose `auix_update/2` calls `super` and then assigns `:fields_to_reject`, the show view renders its one-to-many list and the `reference` input, and renders no input for `name`
- [x] AC-8: Given the same show handler, a `hooks_back` event targeted at the show component reaches its `auix_handle_event/3`, and the `auix_route_back/1` it calls patches to `S`

##### Test ports
- Routes: the three registrations already in `test/support/app_web/routes.ex` inside `load_test_routes/0` — `RoutesHelper.register_product_crud(HandlerHooksIndexTest, "handler-hooks-index-")`, `RoutesHelper.register_product_crud(HandlerHooksShowTest, "handler-hooks-show-")`, `RoutesHelper.register_product_crud(HandlerHooksFormTest, "handler-hooks-form-")`. Each one expands to `RoutesHelper.register_crud/2` for `products` (`test/support/app_web/routes_helper.ex`, `register_product_crud/2`). No registration is added and none is changed.
- Observables: `has_element?/2` on `#flash-info` with a text filter (the selector `test/cases_live/selected_bulk_action_test.exs` asserts on), `has_element?/2` on `[name='product[<field>]']` and on `#auix-product-show-modal input[value='…']`, `assert_patch/1`.
- A targeted event with no button: `view |> with_target("#auix-product-<live_action>-modal [data-phx-component]") |> render_click(event, %{})`, as `request_close/2` in `test/cases_live/form_discard_guard_test.exs` does.

##### Red tests
Every row passes on first run (characterization). Every row is a new `test` appended after the last existing `test` of the named file; none of the three files has a `describe` block.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | add to `test/cases_live/handler_hooks_index_test.exs` | `{:ok, view, _html} = live(conn, "/handler-hooks-index-products?filter=abc")` | `test/cases_live/handler_hooks_index_test.exs` | `"auix_mount and auix_handle_params overrides keep their auix keys"` | `render_click(view, "hooks_report", %{})`; `assert has_element?(view, "#flash-info", "mount=mounted filter=abc")` |
| AC-2 | add to `test/cases_live/handler_hooks_index_test.exs` | `{:ok, view, _html} = live(conn, "/handler-hooks-index-products")` | `test/cases_live/handler_hooks_index_test.exs` | `"an async task started by a custom event reaches auix_handle_async"` | `render_click(view, "hooks_async", %{})`; `render_async(view)`; `assert has_element?(view, "#flash-info", "async done")` |
| AC-3 | add to `test/cases_live/handler_hooks_index_test.exs` | `delete_all_inventory_data()`; `%{"id_test-1" => product} = create_sample_products(1, :test)`; `{:ok, view, _html} = live(conn, "/handler-hooks-index-products/#{product.id}/edit")` | `test/cases_live/handler_hooks_index_test.exs` | `"a form save reaches auix_handle_info in the index"` | `view \|> form("#auix-product-form", product: %{name: "Renamed", quantity_initial: 11}) \|> render_submit()`; `render_click(view, "hooks_report", %{})`; `assert has_element?(view, "#flash-info", "saved=Renamed")` |
| AC-4 | add to `test/cases_live/handler_hooks_form_test.exs` | `delete_all_inventory_data()`; `%{"id_test-1" => product} = create_sample_products(1, :test)`; `{:ok, view, _html} = live(conn, "/handler-hooks-form-products/#{product.id}/edit")` | `test/cases_live/handler_hooks_form_test.exs` | `"update and auix_update overrides hide their fields"` | `refute has_element?(view, "[name='product[rrp]']")`; `refute has_element?(view, "[name='product[list_price]']")`; `assert has_element?(view, "[name='product[description]']")` |
| AC-5 | add to `test/cases_live/handler_hooks_form_test.exs` | as AC-4 | `test/cases_live/handler_hooks_form_test.exs` | `"a targeted custom event reaches the form handler"` | `view \|> element("button[name='hooks-hide-description']") \|> render_click()`; `refute has_element?(view, "[name='product[description]']")`; `refute has_element?(view, "[name='product[rrp]']")`; `refute has_element?(view, "[name='product[list_price]']")`; `assert has_element?(view, "[name='product[name]']")` |
| AC-6 | add to `test/cases_live/handler_hooks_form_test.exs` | as AC-4 | `test/cases_live/handler_hooks_form_test.exs` | `"a built-in form event falls through to super"` | `view \|> with_target("#auix-product-edit-modal [data-phx-component]") \|> render_click("auix_request_close", %{})`; `assert URI.parse(assert_patch(view)).path == "/handler-hooks-form-products"` |
| AC-7 | add to `test/cases_live/handler_hooks_show_test.exs` | `delete_all_inventory_data()`; `%{"id_test-1" => product} = create_sample_products(1, :test)`; `{:ok, view, _html} = live(conn, "/handler-hooks-show-products/#{product.id}/show")` | `test/cases_live/handler_hooks_show_test.exs` | `"auix_update override hides a field in the show view"` | `assert has_element?(view, "#auix-one_to_many-product__product_transactions-show")`; `assert has_element?(view, "#auix-product-show-modal input[value='#{product.reference}']")`; `refute has_element?(view, "#auix-product-show-modal input[value='#{product.name}']")` |
| AC-8 | add to `test/cases_live/handler_hooks_show_test.exs` | as AC-7 | `test/cases_live/handler_hooks_show_test.exs` | `"a targeted custom event routes back from the show handler"` | `view \|> with_target("#auix-product-show-modal [data-phx-component]") \|> render_click("hooks_back", %{})`; `assert URI.parse(assert_patch(view)).path == "/handler-hooks-show-products"` |

In `handler_hooks_show_test.exs` the two new tests go directly after `test "Test one-to-many relationship UI workflow new Product"`, above the private helpers.

##### Modules & components
1. Earlier implementation on the section branch `federico/458-ui-2-compatibility-suite`. Delete `test/cases_live/compatibility_test.exs`. Delete the directory `test/support/compatibility/` (`probe.ex`, `index_handler.ex`, `form_handler.ex`, `show_handler.ex`). In `test/support/app_web/routes.ex` delete the line `RoutesHelper.register_crud(CompatibilityTest.Product, "compatibility-products")`. After this step `git diff --name-only origin/main...HEAD -- test/support` prints nothing.
2. `Aurora.UixWeb.IndexHandlerHook` in `test/cases_live/handler_hooks_index_test.exs` — modified. `mount/3` and `apply_action/2` stay as they are. Append below `apply_action/2`:
   ```elixir
   @impl IndexImpl
   def auix_mount(params, session, socket) do
     super(params, session, assign_auix(socket, :hooks_mount, "mounted"))
   end

   @impl IndexImpl
   def auix_handle_params(params, url, socket) do
     super(params, url, assign_auix(socket, :hooks_filter, Map.get(params, "filter")))
   end

   @impl IndexImpl
   def auix_handle_event("hooks_report", _params, %{assigns: %{auix: auix}} = socket) do
     saved = Map.get(auix, :hooks_saved)
     report = "mount=#{auix.hooks_mount} filter=#{auix.hooks_filter} saved=#{saved}"

     {:noreply, put_flash(socket, :info, report)}
   end

   def auix_handle_event("hooks_async", _params, socket) do
     {:noreply, start_async(socket, :hooks_async, fn -> "async done" end)}
   end

   def auix_handle_event(event, params, socket), do: super(event, params, socket)

   @impl IndexImpl
   def auix_handle_async(:hooks_async, {:ok, message}, socket) do
     {:noreply, put_flash(socket, :info, message)}
   end

   def auix_handle_async(task, result, socket), do: super(task, result, socket)

   @impl IndexImpl
   def auix_handle_info({_component, {:saved, entity}} = message, socket) do
     super(message, assign_auix(socket, :hooks_saved, entity.name))
   end

   def auix_handle_info(message, socket), do: super(message, socket)
   ```
   `assign_auix/3`, `put_flash/3` and `start_async/3` come from the imports `IndexImpl.__using__/1` injects (`Aurora.Uix.Templates.Basic.Helpers`, `Phoenix.LiveView`). The module adds no import and no alias. The names `hooks_report`, `hooks_async`, `:hooks_mount`, `:hooks_filter` and `:hooks_saved` are new (search: `grep -rn "hooks_report\|hooks_async\|hooks_mount\|hooks_filter\|hooks_saved" lib test` returns nothing).
3. `Aurora.UixWeb.Test.HandlerHooksIndexTest` in the same file — modified. The `auix_create_ui` block and `test "Test index hooks"` stay as they are. Add the three tests of AC-1, AC-2 and AC-3.
4. `Aurora.UixWeb.FormHandlerHook` in `test/cases_live/handler_hooks_form_test.exs` — modified. `FormImpl.__using__/1` injects no import, so add `import Aurora.Uix.Templates.Basic.Helpers, only: [assign_auix: 3]` between the `use` line and the first `alias`. `save_entity/2` stays as it is. Append below `save_entity/2`:
   ```elixir
   @impl Phoenix.LiveComponent
   def update(assigns, socket) do
     {:ok, socket} = super(assigns, socket)
     rejected = [:list_price | socket.assigns.auix.fields_to_reject]

     {:ok, assign_auix(socket, :fields_to_reject, rejected)}
   end

   @impl FormImpl
   def auix_update(assigns, socket) do
     {:ok, socket} = super(assigns, socket)

     {:ok, assign_auix(socket, :fields_to_reject, [:rrp])}
   end

   @impl FormImpl
   def auix_handle_event("hooks_hide_description", _params, %{assigns: %{auix: auix}} = socket) do
     {:noreply, assign_auix(socket, :fields_to_reject, [:description | auix.fields_to_reject])}
   end

   def auix_handle_event(event, params, socket), do: super(event, params, socket)
   ```
   The event name `hooks_hide_description` is new (search: `grep -rn "hooks_hide_description" lib test` returns nothing).
5. `Aurora.UixWeb.Test.HandlerHooksFormTest` in the same file — modified.
   - Add `import Phoenix.Component, only: [sigil_H: 2]` directly below `use Aurora.Uix.CoreComponentsImporter`.
   - Add one public function component above `auix_resource_metadata(:product, …)`, with the `@spec` form `custom_back_footer_action/1` has in `test/cases_live/create_ui_actions_show_test.exs`:
     ```elixir
     @spec hooks_footer_action(map()) :: Rendered.t()
     def hooks_footer_action(assigns) do
       ~H"""
       <button type="button" name="hooks-hide-description" phx-click="hooks_hide_description" phx-target={@auix._myself}>
         Hide description
       </button>
       """
     end
     ```
     Contract: it reads `@auix._myself`, which `FormImpl.auix_update/2` assigns; the tests select it as `button[name='hooks-hide-description']`. The form renderer calls it as `action.(%{auix: @auix})` (`lib/aurora_uix/templates/basic/renderers/form_renderer.ex`, the `@auix.form_footer_actions` loop).
   - Change the `edit_layout` head to:
     ```elixir
     edit_layout :product,
       edit_handler_module: Aurora.UixWeb.FormHandlerHook,
       add_footer_action: {:hooks_hide_description, &__MODULE__.hooks_footer_action/1} do
     ```
     The three `inline/1` lines and the `show_layout` block stay as they are.
   - The two existing tests stay as they are. They submit `reference`, `name` and `quantity_initial` only, and none of the three is rejected.
   - Add the three tests of AC-4, AC-5 and AC-6.
6. `Aurora.UixWeb.ShowHandlerHook` in `test/cases_live/handler_hooks_show_test.exs` — modified. `ShowComponentImpl.__using__/1` injects no import and no alias. Add `import Aurora.Uix.Templates.Basic.Helpers, only: [assign_auix: 3, auix_route_back: 1]` above the existing `import Phoenix.LiveView, …` line, and `alias Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl` above `alias Phoenix.LiveView.Socket`. The two `handle_event/3` clauses stay as they are. Append below them:
   ```elixir
   @impl ShowComponentImpl
   def auix_update(assigns, socket) do
     {:ok, socket} = super(assigns, socket)

     {:ok, assign_auix(socket, :fields_to_reject, [:name])}
   end

   @impl ShowComponentImpl
   def auix_handle_event("hooks_back", _params, socket) do
     {:noreply, auix_route_back(socket)}
   end

   def auix_handle_event(event, params, socket), do: super(event, params, socket)
   ```
   The event name `hooks_back` is new (search: `grep -rn "hooks_back" lib test` returns nothing). The module's second `handle_event/3` clause passes `hooks_back` to `super`, which calls `auix_handle_event/3`.
7. `Aurora.UixWeb.Test.HandlerHooksShowTest` in the same file — modified. The `auix_create_ui` block, the two existing tests and every private helper stay as they are. The file declares no `show_layout`, so the show view reuses the `edit_layout` and its `show_handler_module` (`lib/aurora_uix/layout/create_ui.ex`, `put_missing_show/1`). Add the two tests of AC-7 and AC-8.
8. Load guarantees.
   - AC-3: the generated `handle_event("save", …)` in `FormImpl.__using__/1` calls `FormImpl.notify_parent({:saved, entity})`, which is `send(self(), {FormImpl, {:saved, entity}})`. The form component runs in the LiveView process, so the message reaches `handle_info/2` of the generated index module and, through `IndexImpl.__using__/1`, `auix_handle_info/2`.
   - AC-4, AC-5, AC-7: `Aurora.Uix.Templates.Basic.Renderer.render_inner_elements/1` skips every `%Node.Field{}` whose key is in `auix.fields_to_reject` (`lib/aurora_uix/templates/basic/renderer.ex`, private `inner_path/1`, first clause).
   - AC-5: the generated form `update/2` (`lib/aurora_uix/templates/basic/generators/form_generator.ex`) merges the incoming `auix` into the socket's `auix`, so `:fields_to_reject` stays between events. A component event does not call `update/2` again.
9. Components: none added to the library. Theme: none. `dt/1` strings: none.

##### Green tests
1. The tests above pass, unmodified, together with the tests the three files already hold (code-issue runs these, targeted: `mix test test/cases_live/handler_hooks_index_test.exs test/cases_live/handler_hooks_form_test.exs test/cases_live/handler_hooks_show_test.exs`)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
4. `git diff --name-only origin/main...HEAD -- lib test/support` prints nothing
5. `git diff --name-only origin/main...HEAD -- test` prints exactly `test/cases_live/handler_hooks_form_test.exs`, `test/cases_live/handler_hooks_index_test.exs` and `test/cases_live/handler_hooks_show_test.exs`
<!-- section:UI-2:end -->
<!-- section:UI-3:start -->
### UI-3 — UI · handlers · extract `Aurora.Uix.Navigation`
Depends on: UI-1, UI-2

#### Documentation references
- `guides/core/liveview.md § Navigation`
- `guides/core/components.md § Navigation`, `§ Events`

#### Implementation details

The section splits navigation into two layers. `Aurora.Uix.Navigation` is a pure data module: a struct, and functions that take the struct and return it. `Aurora.Uix.Templates.Basic.Helpers` is the socket layer: the only module that reads and writes `auix.navigation`, mirrors the legacy `auix` keys, and calls `push_patch/2` and `push_navigate/2`. Handlers call the helpers and `Navigation.path/3`. Generated URLs, events and markup do not change. Layout types covered: `:index`, `:form`, `:show`. Both modules are backend-agnostic: they reference no `Ecto.*` and no `Ash.*` module.

A **route** is the map `%{type: :patch | :navigate, path: binary()}`.

##### Acceptance criteria
- [x] AC-1: `Navigation.path/3` returns `"/<uri_path>"` for `:index`, `"/<uri_path>/new"` for `:new`, and `"/<uri_path>/<id>/show"`, `"/<uri_path>/<id>/edit"`, `"/<uri_path>/<id>/show-edit"` for `:show`, `:edit`, `:show_edit`
- [x] AC-2: `Navigation.resolve_uri_path/2` without a `base_path` derives `uri_path` from `current_path` exactly as `assign_auix_uri_path/1` does today, for the paths `"/a/products"`, `"/a/products/7/edit"`, `"/a/products/7/show"`, `"/a/products/7/show-edit"` and `"/a/products/new"` (the last keeps today's result, `"a/products/new"`); `uri_path_id` replaces every `/` with `--`
- [x] AC-3: `Navigation.resolve_uri_path/2` with `base_path: "/shop/products"` sets `uri_path` to `"shop/products"` for every `current_path` and every live action
- [x] AC-4: `Navigation.encode_stack/1` of an empty stack returns `"eJyrVipLzClNLVayio6tBQAhgwS%2F"`, and `decode_stack/1` of the URI-decoded form of an encoded stack returns a stack with the same entries in the same order
- [x] AC-5: the helpers `assign_auix_current_path/2`, `assign_auix_uri_path/1` and `assign_auix_routing_stack/3` store the struct at `auix.navigation` and mirror it: `auix.routing_stack` always; `auix.uri_path`, `auix.uri_path_id`, `auix._current_path` and `auix._last_route_path` when the struct field is not `nil`
- [x] AC-6: the navigation struct has no mode: `Navigation.new(mode: :local)` raises `KeyError`
- [x] AC-7: `auix_link`, `auix_link_back` and `auix_back` render a `phx-target` attribute they are given, and render none when they are given none
- [x] AC-8: `Aurora.Uix.Templates.Basic.Helpers` exports `assign_auix_current_path/2`, `assign_auix_uri_path/1`, `assign_auix_index_new_link/1`, `assign_auix_routing_stack/2`, `assign_auix_routing_stack/3`, `auix_route_forward/2`, `auix_route_back/1`, `assign_auix_navigation/2`, `auix_route_back_from/2` and `auix_route_back_to_edit/2`
- [x] AC-9: the tests of UI-1 and UI-2 pass with their files unchanged (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- test/cases_live/navigation_test.exs test/cases_live/ash_navigation_test.exs test/support/navigation_helper.ex test/cases_live/handler_hooks_index_test.exs test/cases_live/handler_hooks_form_test.exs test/cases_live/handler_hooks_show_test.exs` printing nothing, and `mix test` green)
- [x] AC-10: `Navigation.forward/2` returns `{nav, route}` and touches no socket. The returned `nav` has the old `current_path` pushed on its stack as `%{type: <type of the target>, path: <current_path>}` and `last_route_path` set to the old `current_path`. The `route` has the type of the target (`patch: path` gives `:patch`, `to: path` gives `:navigate`) and the target path followed by `routing_stack=<encoded new stack>`, joined with `?` when the target path has no `?`, and with `&` when it has one
- [x] AC-11: `Navigation.back/1` returns `{nav, route}` and touches no socket. With a stack whose top differs from `current_path`, the route is the top entry and the returned stack has it popped. With an empty stack, and with a stack whose top path equals `current_path`, the route is `%{type: :navigate, path: <index fallback>}`: `current_path` without its last two segments when it ends in one of `/show`, `/edit`, `/show-edit`, and without its last segment when it ends in `/new`. Every route path carries `routing_stack=<encoded returned stack>`
- [x] AC-12: `Navigation.back_to_edit/2` pops the origin entry of the stack and returns `{nav, route}` with `route == %{type: :navigate, path: "<origin path without its query>/<id>/edit?routing_stack=<encoded returned stack>"}`; the returned stack is the stack without the origin entry
- [x] AC-13: `Navigation.put_current_path/2` sets `current_path` to the path component of a URL (`"http://localhost:4001/a/products/7/edit?x=1"` gives `"/a/products/7/edit"`), and `Navigation.put_stack/2` replaces the stack
- [x] AC-14: error paths. `Navigation.forward/2` on a struct whose `current_path` is `nil` raises `FunctionClauseError`; `Navigation.back_to_edit/2` on a struct with an empty stack raises `Aurora.Uix.Stack.EmptyStackError`
- [x] AC-15: `Aurora.Uix.Navigation` is pure (mechanical — no red test; verified by `grep -nE 'Phoenix|Templates|import ' lib/aurora_uix/navigation.ex` printing nothing)
- [x] AC-16: outside `helpers.ex`, the template layer calls no function of `Aurora.Uix.Navigation` except `path/3` (mechanical — no red test; verified by `grep -rnE 'Navigation\.[a-z_]+' lib/aurora_uix/templates | grep -v 'templates/basic/helpers.ex' | grep -v 'Navigation\.path('` printing nothing, and `grep -rn '%{nav |' lib/aurora_uix/templates` printing nothing)
- [x] AC-17: one function writes the navigation keys of `auix` (mechanical — no red test; verified by `grep -rnE "assign_auix(_new)?\(([a-z_0-9&]+, )?:(navigation|routing_stack|uri_path|uri_path_id|_current_path|_last_route_path)," lib` printing exactly six lines, all of them inside `put_navigation/2` of `lib/aurora_uix/templates/basic/helpers.ex`)
- [x] AC-18: `assign_auix_navigation/2` starts the navigation of a component from `auix.uri_path` and the stack it is given: with `auix.uri_path == "a/b"` and a `nil` stack, `auix.navigation == Navigation.new(uri_path: "a/b")`, `auix.routing_stack == Stack.new()` and `auix` has no `_current_path` key; with a stack, `auix.navigation.stack` and `auix.routing_stack` are that stack

##### Test ports
- No new route. The LiveView behaviour is observed through the routes of UI-1 and the `handler-hooks-*` routes the tests of UI-2 visit.
- Pure functions of `Aurora.Uix.Navigation`, called directly, in `test/cases/navigation_test.exs`. That file builds no socket and aliases no module under `Aurora.Uix.Templates`.
- The socket helpers, called directly on a bare socket, in `test/cases/templates/basic/helpers_navigation_test.exs`: `%Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, auix: %{}}}`.
- Directly rendered components for AC-7: `Phoenix.LiveViewTest.render_component/2`, as `test/cases/core_components_input_test.exs` does.

##### Red tests
`Navigation` is `Aurora.Uix.Navigation`, `Stack` is `Aurora.Uix.Stack`, `Helpers` is `Aurora.Uix.Templates.Basic.Helpers`. `@empty` stands for the literal `"eJyrVipLzClNLVayio6tBQAhgwS%2F"`.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | on the branch, kept unchanged | `nav = Navigation.new(uri_path: "a/products")` | `test/cases/navigation_test.exs` | `"path/3 builds the five paths"` | `Navigation.path(nav, :index) == "/a/products"`; `Navigation.path(nav, :new) == "/a/products/new"`; `Navigation.path(nav, :show, 7) == "/a/products/7/show"`; `:edit`, `:show_edit` alike |
| AC-2 | on the branch, kept unchanged | `Navigation.new(current_path: path)` | same | `"resolve_uri_path/2 parses the current path as before"` | for `{path, live_action, expected}` in `{"/a/products", :index, "a/products"}`, `{"/a/products/7/edit", :edit, "a/products"}`, `{"/a/products/7/show", :show, "a/products"}`, `{"/a/products/7/show-edit", :show_edit, "a/products"}`, `{"/a/products/new", :new, "a/products/new"}`: `Navigation.resolve_uri_path(nav, live_action).uri_path == expected`; `.uri_path_id == String.replace(expected, "/", "--")` |
| AC-3 | on the branch, kept unchanged | `Navigation.new(base_path: "/shop/products", current_path: "/elsewhere/9/edit")` | same | `"resolve_uri_path/2 prefers base_path"` | `.uri_path == "shop/products"` for `:edit` and for `:index` |
| AC-4 | on the branch, kept unchanged | `Stack.new()`; a stack of two entries | same | `"encode_stack/1 and decode_stack/1 round-trip"` | `Navigation.encode_stack(Stack.new()) == @empty`; `stack \|> Navigation.encode_stack() \|> URI.decode_www_form() \|> Navigation.decode_stack() == stack` |
| AC-5 | new file (`ls test/cases/templates/basic` lists only `helpers_actor_test.exs`). Module `Aurora.Uix.Templates.Basic.HelpersNavigationTest`, `use ExUnit.Case, async: true`, aliases `Aurora.Uix.Navigation`, `Aurora.Uix.Stack`, `Aurora.Uix.Templates.Basic.Helpers` | bare socket; `auix = socket \|> Helpers.assign_auix_current_path("/a/b?x=1") \|> Helpers.assign_auix_uri_path() \|> Helpers.assign_auix_routing_stack(%{}) \|> then(& &1.assigns.auix)` | `test/cases/templates/basic/helpers_navigation_test.exs` | `"the helpers store the struct and mirror the legacy keys"` | `auix.navigation == Navigation.new(current_path: "/a/b", uri_path: "a/b", uri_path_id: "a--b")`; `auix._current_path == "/a/b"`; `auix.uri_path == "a/b"`; `auix.uri_path_id == "a--b"`; `auix.routing_stack == Stack.new()`; `refute Map.has_key?(auix, :_last_route_path)` |
| AC-6 | on the branch, kept unchanged | none | `test/cases/navigation_test.exs` | `"new/1 rejects a key the struct does not have"` | `assert_raise KeyError, fn -> Navigation.new(mode: :local) end` |
| AC-7 | on the branch, kept unchanged | the four function components of the file | `test/cases/routing_components_test.exs` | `"routing links pass phx-target through"` | one node for `a[phx-click='auix_route_forward'][phx-target='#c']` from `targeted_link/1`; one node for `a[phx-click='auix_route_back'][phx-target='#c']` from `targeted_link_back/1` and from `targeted_back/1`; no node for `a[phx-target]` from `plain_link/1` |
| AC-8 | add to `test/cases/templates/basic/helpers_navigation_test.exs` | `Code.ensure_loaded!(Helpers)` | same | `"the Basic helpers keep their navigation functions"` | `function_exported?(Helpers, name, arity)` for the ten name/arity pairs of AC-8 |
| AC-10 | add to `test/cases/navigation_test.exs` | `nav = Navigation.new(current_path: "/a/products", uri_path: "a/products")` | `test/cases/navigation_test.exs` | `"forward/2 pushes the current path and returns the route"` | `{nav2, route} = Navigation.forward(nav, patch: "/a/products/7/show")`: `nav2.stack == Stack.new([%{type: :patch, path: "/a/products"}])`; `nav2.last_route_path == "/a/products"`; `route == %{type: :patch, path: "/a/products/7/show?routing_stack=" <> Navigation.encode_stack(nav2.stack)}`. `{nav3, route3} = Navigation.forward(nav, to: "/a/products?page=2")`: `nav3.stack == Stack.new([%{type: :navigate, path: "/a/products"}])`; `route3 == %{type: :navigate, path: "/a/products?page=2&routing_stack=" <> Navigation.encode_stack(nav3.stack)}` |
| AC-11 | add to same | three structs, built with `Navigation.new/1` | same | `"back/1 pops the stack and falls back to the index path"` | `Navigation.new(current_path: "/a/products/7/show", stack: Stack.new([%{type: :patch, path: "/a/products"}]))` gives `{nav2, %{type: :patch, path: "/a/products?routing_stack=" <> @empty}}` with `nav2.stack == Stack.new()`; `Navigation.new(current_path: "/a/products/7/edit")` gives the route `%{type: :navigate, path: "/a/products?routing_stack=" <> @empty}`; `Navigation.new(current_path: "/a/products/new", stack: Stack.new([%{type: :patch, path: "/a/products/new"}]))` gives the route `%{type: :navigate, path: "/a/products?routing_stack=" <> @empty}` and an empty stack |
| AC-12 | add to same | `nav = Navigation.new(stack: Stack.new([%{type: :patch, path: "/a/products?page=2"}]))` | same | `"back_to_edit/2 returns to the edit path of the origin"` | `{nav2, route} = Navigation.back_to_edit(nav, 7)`: `route == %{type: :navigate, path: "/a/products/7/edit?routing_stack=" <> @empty}`; `nav2.stack == Stack.new()` |
| AC-13 | add to same | `Navigation.new()` | same | `"put_current_path/2 and put_stack/2 set their field"` | `Navigation.put_current_path(Navigation.new(), "http://localhost:4001/a/products/7/edit?x=1").current_path == "/a/products/7/edit"`; with `stack = Stack.new([%{type: :patch, path: "/a"}])`, `Navigation.put_stack(Navigation.new(), stack).stack == stack` |
| AC-14 | add to same | none | same | `"forward/2 needs a current path and back_to_edit/2 an origin"` | `assert_raise FunctionClauseError, fn -> Navigation.forward(Navigation.new(), patch: "/x") end`; `assert_raise Aurora.Uix.Stack.EmptyStackError, fn -> Navigation.back_to_edit(Navigation.new(), 7) end` |
| AC-18 | add to `test/cases/templates/basic/helpers_navigation_test.exs` | `socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, auix: %{uri_path: "a/b"}}}`; `stack = Stack.new([%{type: :patch, path: "/a/b"}])` | same | `"assign_auix_navigation/2 starts the navigation of a component"` | `auix = Helpers.assign_auix_navigation(socket, nil).assigns.auix`: `auix.navigation == Navigation.new(uri_path: "a/b")`; `auix.routing_stack == Stack.new()`; `refute Map.has_key?(auix, :_current_path)`. `auix2 = Helpers.assign_auix_navigation(socket, stack).assigns.auix`: `auix2.navigation.stack == stack`; `auix2.routing_stack == stack` |

##### Modules & components
1. Starting point. Work on the head of `federico/458-ui-3-navigation-module` (commit `d3fd717`), which already holds a first implementation of this section. Every "replace" and "delete" below quotes that branch's code, not `main`. On that branch `lib/aurora_uix/navigation.ex` exists and mixes the struct, pure functions and socket functions; `helpers.ex` delegates to it; `index_impl.ex`, `form_impl.ex`, `show_component_impl.ex` and `renderers/fields/one_to_many.ex` call it. Steps 2 to 8 give each file's end state.
2. `Aurora.Uix.Navigation` at `lib/aurora_uix/navigation.ex` — modified into a pure data module, in the style of `lib/aurora_uix/stack.ex`.
   - Delete `import Phoenix.LiveView, only: [push_navigate: 2, push_patch: 2]`, `alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers` and `alias Phoenix.LiveView.Socket`. The only alias left is `alias Aurora.Uix.Stack`.
   - Delete the public functions `get/1`, `put/2`, `assign_current_path/2`, `assign_uri_path/1`, `assign_stack/3`, `forward/3`, `back/2`, `record/4`, `related_uri_path/3`, with their `@doc` and `@spec`.
   - Delete the private functions `maybe_assign/3`, `route_to/3` and `route_type/1`, with their `@spec` and comments.
   - Keep unchanged: `defstruct` (the six fields `base_path`, `current_path`, `uri_path`, `uri_path_id`, `stack`, `last_route_path`), `@type t()`, `new/1`, `resolve_uri_path/2`, `path/3`, `encode_stack/1`, `decode_stack/1`, and the private `put_uri_path/2`, `route_path_with_stack/2`, `determine_fallback_path/1`, `remove_trailing_paths/2`.
   - Add, after `@type t()`: `@type route() :: %{type: :patch | :navigate, path: binary()}`. Change the `@spec` of `determine_fallback_path/1` to `determine_fallback_path(binary()) :: route()`.
   - Add the public functions below (new: `grep -rnE 'put_current_path|put_stack|back_to_edit' lib test guides` returns nothing; `forward/2` and `back/1` replace `forward/3` and `back/2`). Each gets a `@doc` with `## Parameters` and `## Returns`, in the form the file already uses. Place them in this order after `resolve_uri_path/2`: `put_current_path/2`, `put_stack/2`, `path/3` (existing), `forward/2`, `back/1`, `back_to_edit/2`.
     ```elixir
     @spec put_current_path(t(), binary() | URI.t() | nil) :: t()
     def put_current_path(%__MODULE__{} = nav, url),
       do: %{nav | current_path: url |> URI.parse() |> Map.get(:path)}

     @spec put_stack(t(), Stack.t()) :: t()
     def put_stack(%__MODULE__{} = nav, %Stack{} = stack), do: %{nav | stack: stack}

     @spec forward(t(), keyword()) :: {t(), route()}
     def forward(%__MODULE__{current_path: current_path} = nav, target)
         when is_binary(current_path) do
       %{type: type, path: path} = target_route(target)
       stack = Stack.push(nav.stack, %{type: type, path: current_path})

       {%{nav | stack: stack, last_route_path: current_path},
        %{type: type, path: route_path_with_stack(path, stack)}}
     end

     @spec back(t()) :: {t(), route()}
     def back(%__MODULE__{} = nav) do
       current_path = nav.current_path || ""
       fallback_route = determine_fallback_path(current_path)
       {stack, popped_route} = Stack.pop(nav.stack, fallback_route)

       %{type: type, path: path} =
         if current_path == popped_route.path, do: fallback_route, else: popped_route

       {%{nav | stack: stack}, %{type: type, path: route_path_with_stack(path, stack)}}
     end

     @spec back_to_edit(t(), term()) :: {t(), route()}
     def back_to_edit(%__MODULE__{} = nav, id) do
       {stack, origin} = Stack.pop!(nav.stack)

       edit_path =
         origin
         |> Map.get(:path)
         |> URI.parse()
         |> Map.get(:path)
         |> then(&"#{&1}/#{id}/edit")

       back(%{nav | stack: Stack.push(stack, %{type: :navigate, path: edit_path})})
     end
     ```
   - Add the private function (new: `grep -rn 'target_route' lib test` returns nothing):
     ```elixir
     @spec target_route(keyword()) :: route()
     defp target_route(to: path), do: %{type: :navigate, path: path}
     defp target_route(patch: path), do: %{type: :patch, path: path}
     ```
   - `@moduledoc`: rewrite it. First paragraph: `Navigation state of a generated Aurora UIX view, as plain data.` `## Key Features`: the struct with its six fields; `uri_path` resolution from `base_path` and from `current_path`; the five resource paths; `forward/2`, `back/1` and `back_to_edit/2` return the new struct and the route to follow; routing stack encoding and decoding. `## Key Constraints`: every function takes the struct and returns data, and none takes a socket; backend-agnostic, it references no Ecto and no Ash module; the struct has no navigation mode, an unknown key given to `new/1` raises `KeyError`; `forward/2` requires a binary `current_path`. The text contains none of the words `Phoenix`, `Templates` and `import` (AC-15).
3. `lib/aurora_uix/templates/basic/helpers.ex` — modified. It is the socket layer.
   - Add `alias Aurora.Uix.Stack` on the line after `alias Aurora.Uix.Navigation`.
   - In the `@doc` of `assign_auix_current_path/2`, `assign_auix_uri_path/1`, `assign_auix_routing_stack/3`, `auix_route_forward/2` and `auix_route_back/1`, delete the line ``Delegates to `Aurora.Uix.Navigation`.`` and the blank line before it. Their `@spec` lines stay.
   - Replace the bodies of the five functions, and add three public functions. `assign_auix_navigation/2` goes directly after `assign_auix_routing_stack/3`; `auix_route_back_from/2` and `auix_route_back_to_edit/2` go directly after `auix_route_back/1`. The three are new (`grep -rnE 'assign_auix_navigation|auix_route_back_from|auix_route_back_to_edit' lib test guides` returns nothing); each gets a `@doc` with `## Parameters` and `## Returns`.
     ```elixir
     def assign_auix_current_path(socket, url),
       do: update_navigation(socket, &Navigation.put_current_path(&1, url))

     def assign_auix_uri_path(socket) do
       update_navigation(socket, &Navigation.resolve_uri_path(&1, socket.assigns[:live_action]))
     end

     def assign_auix_routing_stack(socket, params, default_route \\ nil)

     def assign_auix_routing_stack(
           socket,
           %{"routing_stack" => encoded_routing_stack},
           _default_route
         ) do
       encoded_routing_stack
       |> Navigation.decode_stack()
       |> then(fn stack -> update_navigation(socket, &Navigation.put_stack(&1, stack)) end)
     end

     def assign_auix_routing_stack(socket, _params, nil),
       do: update_navigation(socket, &Navigation.put_stack(&1, Stack.new()))

     def assign_auix_routing_stack(socket, _params, default_route) do
       default_route
       |> Stack.new()
       |> then(fn stack -> update_navigation(socket, &Navigation.put_stack(&1, stack)) end)
     end

     @spec assign_auix_navigation(Socket.t(), Stack.t() | nil) :: Socket.t()
     def assign_auix_navigation(socket, stack) do
       put_navigation(
         socket,
         Navigation.new(uri_path: socket.assigns.auix[:uri_path], stack: stack || Stack.new())
       )
     end

     def auix_route_forward(socket, navigation),
       do: navigate_with(socket, &Navigation.forward(&1, navigation))

     def auix_route_back(socket), do: navigate_with(socket, &Navigation.back/1)

     @spec auix_route_back_from(Socket.t(), binary()) :: Socket.t()
     def auix_route_back_from(socket, current_path) do
       navigate_with(socket, fn nav ->
         nav
         |> Navigation.put_current_path(current_path)
         |> Navigation.back()
       end)
     end

     @spec auix_route_back_to_edit(Socket.t(), term()) :: Socket.t()
     def auix_route_back_to_edit(socket, id),
       do: navigate_with(socket, &Navigation.back_to_edit(&1, id))
     ```
     `@doc` first lines: `assign_auix_navigation/2` — `Starts the navigation of a component from its auix uri_path and the routing stack it received.`; `auix_route_back_from/2` — `Navigates back as if the socket were at the given path.`; `auix_route_back_to_edit/2` — `Navigates back to the edit path of a record, under the path the user came from.`
   - Add the private functions below, directly before the first clause of `get_many_to_one_select_option/2` (new: `grep -rnE 'update_navigation|navigate_with|put_navigation|push_route|maybe_assign_auix|defp navigation\(' lib test` returns nothing). `push_navigate/2` and `push_patch/2` are already imported by `use Phoenix.LiveComponent`.
     ```elixir
     @spec navigation(Socket.t()) :: Navigation.t()
     defp navigation(socket) do
       case socket.assigns.auix[:navigation] do
         %Navigation{} = nav -> nav
         nil -> Navigation.new()
       end
     end

     # The single writer of `auix.navigation` and of the legacy keys that mirror it.
     @spec put_navigation(Socket.t(), Navigation.t()) :: Socket.t()
     defp put_navigation(socket, %Navigation{} = nav) do
       socket
       |> assign_auix(:navigation, nav)
       |> assign_auix(:routing_stack, nav.stack)
       |> maybe_assign_auix(:uri_path, nav.uri_path)
       |> maybe_assign_auix(:uri_path_id, nav.uri_path_id)
       |> maybe_assign_auix(:_current_path, nav.current_path)
       |> maybe_assign_auix(:_last_route_path, nav.last_route_path)
     end

     @spec maybe_assign_auix(Socket.t(), atom(), term()) :: Socket.t()
     defp maybe_assign_auix(socket, _key, nil), do: socket
     defp maybe_assign_auix(socket, key, value), do: assign_auix(socket, key, value)

     @spec update_navigation(Socket.t(), (Navigation.t() -> Navigation.t())) :: Socket.t()
     defp update_navigation(socket, fun) do
       socket
       |> navigation()
       |> fun.()
       |> then(&put_navigation(socket, &1))
     end

     @spec navigate_with(Socket.t(), (Navigation.t() -> {Navigation.t(), Navigation.route()})) ::
             Socket.t()
     defp navigate_with(socket, fun) do
       {nav, route} =
         socket
         |> navigation()
         |> fun.()

       socket
       |> put_navigation(nav)
       |> push_route(route)
     end

     @spec push_route(Socket.t(), Navigation.route()) :: Socket.t()
     defp push_route(socket, %{type: :navigate, path: path}), do: push_navigate(socket, to: path)
     defp push_route(socket, %{type: :patch, path: path}), do: push_patch(socket, to: path)
     ```
   - `assign_auix_index_new_link/1`: unchanged.
4. `lib/aurora_uix/templates/basic/handlers/index_impl.ex` — modified. `alias Aurora.Uix.Navigation` stays. The handler reads `navigation: nav` from `auix` in a pattern and calls `Navigation.path/3`; it calls no other function of the module.
   - `auix_handle_params/3`: replace the whole `|> then(&assign_auix_routing_stack(&1, params, %{type: :patch, path: &1 |> Navigation.get() |> Navigation.path(:index)}))` step with `|> assign_index_routing_stack(params)`. Add the private function (new: `grep -rn 'assign_index_routing_stack' lib test` returns nothing):
     ```elixir
     @spec assign_index_routing_stack(Socket.t(), map()) :: Socket.t()
     defp assign_index_routing_stack(%{assigns: %{auix: %{navigation: nav}}} = socket, params) do
       assign_auix_routing_stack(socket, params, %{type: :patch, path: Navigation.path(nav, :index)})
     end
     ```
   - `auix_handle_event("delete", %{"id" => id, "get_function" => get_function_string, "delete_function" => delete_function_string}, socket)`: the third argument becomes `%{assigns: %{auix: %{navigation: nav}}} = socket`; replace `Navigation.get(socket).current_path` with `nav.current_path`.
   - `auix_handle_event("pagination_to_page", %{"page" => page}, …)`: the `auix` pattern becomes `%{pagination: %Pagination{}, navigation: nav}`; the patch becomes `"#{Navigation.path(nav, :index)}?page=#{page}"`.
   - `auix_handle_event("pagination_previous", …)` and `("pagination_next", …)`, first clause of each: add `navigation: nav` to the `auix` pattern, after `layout_options: %{pagination_disabled?: pagination_disabled?}`; replace `Navigation.path(Navigation.get(socket), :index)` with `Navigation.path(nav, :index)`, keeping the page expression.
   - `auix_handle_event("read_indexed_entry", …)`: the match on `load_page/2` becomes `%{assigns: %{auix: %{primary_keys: primary_keys, navigation: nav}}} = new_socket = load_page(socket, int_new_page)`; replace the `Navigation.record(new_socket, Navigation.get(new_socket), found_id, record_action(socket))` call with `push_patch(new_socket, to: Navigation.path(nav, record_action(socket), found_id))`. `record_action/1` stays.
   - `react_to_change(socket, :show, :deleted, _entity_id)`: the head becomes `%{assigns: %{auix: %{navigation: nav}}} = socket`; the last pipeline step becomes `|> push_patch(to: Navigation.path(nav, :index))`.
   - The `auix_route_forward` and `auix_route_back` event clauses keep calling the imported `auix_route_forward/2` and `auix_route_back/1`.
   - Load guarantee: `auix.navigation` is written by `auix_handle_params/3` through `assign_auix_current_path/2` (step 3, `put_navigation/2`). `handle_params` runs before any event and before any message of the LiveView, so every clause above finds the key.
5. `lib/aurora_uix/templates/basic/handlers/form_impl.ex` — modified.
   - Delete `alias Aurora.Uix.Navigation` and `alias Aurora.Uix.Stack`: after the edits below the module calls neither.
   - `auix_update/2`: replace the three-line step `|> Navigation.put(Navigation.new(uri_path: Map.get(auix, :uri_path), stack: routing_stack || Stack.new()))` with `|> assign_auix_navigation(routing_stack)`.
   - `conditional_route_back(socket, :new, true)`: the head stays; the body becomes the single call `auix_route_back_to_edit(socket, BasicHelpers.primary_key_value(entity, primary_key))`.
   - `conditional_route_back(socket, _action, _one2many_rendered?)`: unchanged.
   - `route_back_from_close/1`: the head stays; the body becomes the single call `auix_route_back_from(socket, Map.get(auix, :_close_path, ""))`. The comment above the function stays.
   - `@spec` of `conditional_route_back/3`: unchanged. Callers: the generated `handle_event("save", …)` in `FormImpl.__using__/1`, unchanged.
6. `lib/aurora_uix/templates/basic/handlers/show_component_impl.ex` — modified. Delete `alias Aurora.Uix.Navigation` and `alias Aurora.Uix.Stack`. `auix_update/2`: replace the whole `|> then(&Navigation.put(&1, Navigation.new(uri_path: Map.get(&1.assigns.auix, :uri_path), stack: routing_stack || Stack.new())))` step with `|> assign_auix_navigation(routing_stack)`.
7. `lib/aurora_uix/templates/basic/renderers/fields/one_to_many.ex` — returns to its content on `main`: `git checkout origin/main -- lib/aurora_uix/templates/basic/renderers/fields/one_to_many.ex`. That removes `alias Aurora.Uix.Navigation` and restores `|> String.replace(source, related_source)` in `set_related_uri_path/3`.
8. Tests on the branch.
   - `test/cases/navigation_test.exs`: delete the tests `"put/2 stores the struct and mirrors the legacy keys"`, `"the Basic helpers keep their navigation functions"` and `"related_uri_path/3 swaps the source segment"`, and the line `alias Aurora.Uix.Templates.Basic.Helpers`. Add the module attribute `@empty "eJyrVipLzClNLVayio6tBQAhgwS%2F"` and the tests of rows AC-10 to AC-14.
   - `test/cases/templates/basic/helpers_navigation_test.exs`: new, with the tests of rows AC-5, AC-8 and AC-18.
   - `test/cases/routing_components_test.exs`: unchanged.
9. Unchanged on purpose: `actions/index.ex`, `actions/show_component.ex`, `actions/one_to_many.ex`, `renderers/index_renderer.ex` and `components/components.ex` keep reading `@auix.uri_path`, `@auix.uri_path_id`, `@auix.routing_stack`, `@auix[:_current_path]` and `@auix[:index_new_link]`; `put_navigation/2` mirrors them. `components/routing_components.ex` is unchanged: `phx-target` already reaches the anchor through `@rest`, because `:global` attributes include every `phx-*` attribute, and the name `target` is taken by the HTML attribute in `auix_link`'s `include:` list.
10. Contract change. `auix.navigation` is a new `auix` key holding a full `%Aurora.Uix.Navigation{}`. `auix.routing_stack`, `auix.uri_path`, `auix.uri_path_id`, `auix._current_path` and `auix._last_route_path` are written only by `put_navigation/2` in `helpers.ex`; they are read-only mirrors, and a direct `assign_auix/3` of one of them no longer changes navigation. No `@spec` of an existing public function of `helpers.ex` changes. Compared with the branch, `Aurora.Uix.Navigation` loses nine public functions; their callers and new handling:

    | Removed | Callers on the branch | New handling |
    |---|---|---|
    | `get/1`, `put/2` | `helpers.ex`, `index_impl.ex`, `form_impl.ex`, `show_component_impl.ex` | private `navigation/1` and `put_navigation/2` in `helpers.ex` (step 3); handlers bind `navigation: nav` (step 4) |
    | `assign_current_path/2`, `assign_uri_path/1`, `assign_stack/3` | `helpers.ex` | `update_navigation/2` with `put_current_path/2`, `resolve_uri_path/2`, `put_stack/2` (step 3) |
    | `forward/3`, `back/2` | `helpers.ex`, `form_impl.ex` | `forward/2`, `back/1` through `navigate_with/2` (step 3); `auix_route_back_from/2`, `auix_route_back_to_edit/2` (step 5) |
    | `record/4` | `index_impl.ex` | `push_patch/2` with `Navigation.path/3` (step 4) |
    | `related_uri_path/3` | `renderers/fields/one_to_many.ex` | `String.replace/3` (step 7) |
11. Edge cases. `navigation/1` on a socket with no `auix.navigation` returns `Navigation.new()` (the first helper call of a mount, and the first `update/2` of a component). `auix_route_forward/2` on a navigation whose `current_path` is `nil` (a form component, a show component) raises `FunctionClauseError`, as on `main`. `auix_route_back_to_edit/2` with an empty stack raises `Aurora.Uix.Stack.EmptyStackError`, as `Stack.pop!/1` does on `main`. `auix_route_back_from/2` given `""` leaves `current_path` `nil`, and `back/1` then falls back to the path `""`, the result `main` gives for a form with no `_close_path`. `decode_stack/1` on a malformed parameter raises, as on `main`.
12. Components: none new. Theme: none. `dt/1` strings: none.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted: `mix test test/cases/navigation_test.exs test/cases/templates/basic/helpers_navigation_test.exs test/cases/routing_components_test.exs test/cases_live/navigation_test.exs test/cases_live/ash_navigation_test.exs test/cases_live/handler_hooks_index_test.exs test/cases_live/handler_hooks_form_test.exs test/cases_live/handler_hooks_show_test.exs`)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
4. The greps of AC-15, AC-16 and AC-17 print what those ACs state
<!-- section:UI-3:end -->
<!-- section:DOC-2:start -->
### DOC-2 — Documentation · navigation guides after UI-3
Depends on: UI-3

#### Documentation references
- `guides/core/liveview.md § Navigation`
- `guides/core/components.md § Navigation`
- `guides/whats_new/0.2.1.md § Upgrading from 0.2.0`

#### Implementation details

The section corrects the statements of the merged guides that UI-3 makes false. After UI-3, `Aurora.Uix.Navigation` is a pure data module: `forward/2` and `back/1` take the struct, take no socket, and return `{nav, route}`. A socket's navigation is changed only by the helpers of `Aurora.Uix.Templates.Basic.Helpers`. The section edits three guide files and no other file.

##### guides/core/components.md
1. § Navigation — replace the paragraph that starts `` The generated `.Index` LiveView is one such parent. `` with, verbatim:
   ```
   The generated `.Index` LiveView is one such parent. It answers `{:open, action, id}`, `{:closed}` and
   `{:page, page}` with a patch or a navigate under its routes, with the routing stack in `?routing_stack=`.
   Its URLs are the ones it always had. `Aurora.Uix.Navigation` computes each path, and the LiveView applies it.
   ```
2. § Navigation — replace the paragraph that starts `` In the generated LiveView, `@auix.navigation` holds `` with, verbatim:
   ```
   In the generated LiveView, `@auix.navigation` holds the `%Aurora.Uix.Navigation{}`: the base path, the
   current path and the routing stack. `@auix.uri_path`, `@auix.uri_path_id`, `@auix.routing_stack` and
   `@auix[:index_new_link]` remain readable there. They mirror `@auix.navigation`.
   `Aurora.Uix.Navigation` is plain data: its functions return data and take no socket. Change navigation with
   `auix_route_forward/2` and `auix_route_back/1`, not by assigning those keys.
   ```

##### guides/core/liveview.md
1. § Navigation — replace the start of the section body, from the line that starts `` `Aurora.Uix.Navigation` owns the navigation `` through the line `helpers to use in a handler:`, with, verbatim:
   ```
   `Aurora.Uix.Navigation` describes the navigation of the generated LiveView as plain data. The state is
   `@auix.navigation`, an `%Aurora.Uix.Navigation{}` with the base path, the current path and the routing stack.
   The functions take that struct and return data. None takes a socket.

   | Function | Returns |
   |---|---|
   | `Navigation.path(nav, action, id)` | The path of `:index`, `:new`, `:show`, `:edit` or `:show_edit` |
   | `Navigation.forward(nav, target)` | `{nav, route}`: `nav` has the current path pushed on the routing stack, and `route` leads to `target` (`patch: path` or `to: path`) |
   | `Navigation.back(nav)` | `{nav, route}`: `nav` has the routing stack popped, and `route` leads back |

   A route is `%{type: :patch | :navigate, path: path}`. Its path carries the routing stack in `routing_stack=`.

   Only the helpers change a socket. `auix_route_forward/2` calls `Navigation.forward/2` and `auix_route_back/1`
   calls `Navigation.back/1` on `@auix.navigation`; each stores the returned struct and pushes the returned
   route. Use them in a handler:
   ```
   The `auix_handle_event("archive", …)` example and the two paragraphs after it stay.

##### guides/whats_new/0.2.1.md
1. § Upgrading from 0.2.0 — replace the paragraph that starts `No change is required.` with, verbatim:
   ```
   No change is required. `@auix.uri_path`, `@auix.uri_path_id`, `@auix.routing_stack` and
   `@auix[:index_new_link]` stay readable; a handler that assigned one of them directly now changes navigation
   with `auix_route_forward/2` and `auix_route_back/1`.
   ```

##### Unchanged on purpose
1. `CHANGELOG.md § [0.2.1]`: its sentence `` `Aurora.Uix.Navigation` holds the navigation state of the generated LiveView (`@auix.navigation`), which patches and navigates as before. `` is true after UI-3. The section adds no entry: it corrects guides the entry already announces.
2. `guides/whats_new/0.2.1.md § Reusable components`: the bullet `` `Aurora.Uix.Navigation` holds the navigation state of the generated LiveView. `` is true after UI-3.
3. `guides/customization/overriding_components.md`: `auix_link/1`, `auix_link_back/1` and `auix_back/1` fire the same events.
4. `Navigation.back_to_edit/2`, `put_current_path/2`, `put_stack/2`, `resolve_uri_path/2`, `encode_stack/1`, `decode_stack/1` and the helpers `assign_auix_navigation/2`, `auix_route_back_from/2`, `auix_route_back_to_edit/2` get no guide text. The table of `guides/core/liveview.md § Navigation` lists the functions a host handler calls; the `@doc` of each function (UI-3) documents the others.

##### Acceptance criteria
- [x] AC-1: `CHANGELOG.md` is not modified (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD -- CHANGELOG.md` printing nothing)
- [x] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-458-enriched-spec.md`)
- [x] AC-3: `guides/core/liveview.md § Navigation` documents `forward/2` and `back/1` as functions that take the struct and return `{nav, route}` (mechanical — no red test; verified by `grep -c 'Navigation.forward(nav, target)' guides/core/liveview.md` returning `1`, `grep -c 'Navigation.back(nav)' guides/core/liveview.md` returning `1`, `grep -c 'Navigation.path(nav, action, id)' guides/core/liveview.md` returning `1` and `grep -cE 'Navigation\.(forward|back)\(socket' guides/core/liveview.md` returning `0`)
- [x] AC-4: `guides/core/liveview.md § Navigation` states that only the helpers change a socket (mechanical — no red test; verified by `grep -c '^Only the helpers change a socket\.' guides/core/liveview.md` returning `1` and `grep -c 'call them with the socket' guides/core/liveview.md` returning `0`)
- [x] AC-5: `guides/core/components.md § Navigation` names `auix_route_forward/2` and `auix_route_back/1` as the way to change navigation, and describes `Aurora.Uix.Navigation` as plain data (mechanical — no red test; verified by `grep -c 'change navigation through' guides/core/components.md` returning `0`, `grep -c 'its functions return data and take no socket' guides/core/components.md` returning `1` and `grep -c 'Navigation`: a patch' guides/core/components.md` returning `0`)
- [x] AC-6: `guides/whats_new/0.2.1.md § Upgrading from 0.2.0` names the two helpers alone (mechanical — no red test; verified by `grep -c '^with `auix_route_forward/2` and `auix_route_back/1`\.$' guides/whats_new/0.2.1.md` returning `1` and `grep -c 'and `Aurora.Uix.Navigation`\.$' guides/whats_new/0.2.1.md` returning `0`)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-2:end -->

---

### Out of Scope
- Steps 4–7 of the issue (standalone Form/Show that report intents, `.IndexComponent` and `IndexComponentImpl`, `Aurora.Uix.Live.ComponentHooks`, one-to-many through `.IndexComponent`, the `generate:` option) and step 8. They are added to this spec as new sections once UI-3 is merged. `DOC-1` already documents their contract.
- The embedded-component and multiple-instance rows of the navigation test matrix. They need the components of steps 4 and 5.
- A one-to-many field whose `resource:` names an alternate resource on the same schema. Its navigation test is added with step 6.
- Direct load of a `/new` URL. `uri_path` keeps its `/new` suffix there today, so a save patches back to `/new`, and a new parent with a child list redirects to `/new/<id>/edit`. UI-1 does not assert that path, UI-3 reproduces today's parsing, and the fix belongs to a separate issue.
- New tests for `guides/customization/*`. Custom actions, predefined renderers and theming keep their existing tests; a routing-component override has no navigation test.
- An Ash run of the handler-hook tests of UI-2. The handler behaviours, event targets and message delivery they exercise are backend-agnostic.
- A separate test file, test namespace, support module and route for the handler-hook tests. UI-2 extends `test/cases_live/handler_hooks_index_test.exs`, `handler_hooks_form_test.exs` and `handler_hooks_show_test.exs`.
- A test of `push_navigate/2` called from a handler. It is a Phoenix function and runs no library code.
- `README.md` § What's New link. `prepare-release` updates it.
<!-- enriched-spec:end -->
