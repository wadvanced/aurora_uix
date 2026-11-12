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
| UI-2 | UI | handlers · compatibility suite for the documented handler hooks (no library change) | DOC-1 | federico/458-ui-2-compatibility-suite | test: compatibility suite for handler hooks (#458 · UI-2) |
| UI-3 | UI | handlers · extract `Aurora.Uix.Navigation` (`base_path`) | UI-1, UI-2 | federico/458-ui-3-navigation-module | refactor: extract Aurora.Uix.Navigation (#458 · UI-3) |

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
- [ ] AC-1: Given the index at `P`, clicking a row's show link patches to `P/<id>/show` with stack `[{patch, P}, {patch, P}]`; clicking a row's edit link patches to `P/<id>/edit` with the same stack; clicking the new link patches to `P/new` with the same stack
- [ ] AC-2: Given the show modal opened from the index, clicking its edit link patches to `P/<id>/show-edit` with stack `[{patch, P/<id>/show}, {patch, P}, {patch, P}]`; a close request on the form patches to `P/<id>/show` with stack `[{patch, P}, {patch, P}]`; `auix_route_back` then patches to `P` with stack `[{patch, P}]`
- [ ] AC-3: Given the new form opened from the index, a close request patches to `P` with stack `[{patch, P}]`; given the edit form opened from the index, a valid save patches to `P` with stack `[{patch, P}]`
- [ ] AC-4: Given a direct load of `P/<id>/edit`, a close request patches to `P` with an empty stack; a valid save patches to `P` with an empty stack; given a direct load of `P/<id>/show`, `auix_route_back` patches to `P` with an empty stack
- [ ] AC-5: Given a direct load of `P/<id>/edit` and a changed field, a close request sends no patch and opens the discard dialog; clicking discard patches to `P` with an empty stack
- [ ] AC-6: Given a direct load of `P/<id>/edit` with a one-to-many list, clicking the list's new link live-redirects to `C/new` with query `related_key=<key>&parent_id=<id>` and stack `[{navigate, P/<id>/edit}, {patch, P}]`; saving the child live-redirects to `P/<id>/edit` with stack `[{patch, P}]`; a close request on the child form live-redirects to the same path with the same stack
- [ ] AC-7: Given a direct load of `P/<id>/show`, clicking a child row's show link live-redirects to `C/<cid>/show` with stack `[{navigate, P/<id>/show}, {patch, P}]`, and `auix_route_back` on the child view live-redirects to `P/<id>/show` with stack `[{patch, P}]`; given a direct load of `P/<id>/edit`, clicking a child row's edit link live-redirects to `C/<cid>/edit` with query `related_key=<key>&parent_id=<id>` and stack `[{navigate, P/<id>/edit}, {patch, P}]`
- [ ] AC-8: Given the new form opened from the index of a resource whose form renders a one-to-many list, a valid save live-redirects to `P/<new id>/edit` with stack `[{patch, P}]`
- [ ] AC-9: Given the show modal opened from the index, `read_indexed_entry` with a page and an index in that page patches to `P/<that record's id>/show` with no `routing_stack` parameter; with the next page and index `0` it patches to the first record of the next page; `auix_route_back` then patches to `P` with an empty stack
- [ ] AC-10: Given the index at `P`, `pagination_next` patches to `P?page=2` with stack `[{patch, P}, {patch, P}]`; `pagination_to_page` with page `3` then patches to `P?page=3` with three `{patch, P}` entries; opening new then patches to `P/new` with four entries, and a close request patches to `P` with three entries and no `page` parameter
- [ ] AC-11: Given routes declared with `auix_live_resources/3` and `only: [:index, :show]`, `P` and `P/<id>/show` mount, and the router has no route for `P/new`, `P/<id>/edit` and `P/<id>/show-edit`; given `except: [:new, :edit]`, `P/<id>/show-edit` mounts, and the router has no route for `P/new` and `P/<id>/edit`
- [ ] AC-12: A path that carries `?routing_stack=` built by `NavigationHelper.encode_stack/1` from two entries mounts, and `auix_route_back` goes to the top entry's path with the second entry as the remaining stack
- [ ] AC-13: Given the index at `P`, a row's show link and edit link are anchors with `href="#"`, `phx-click="auix_route_forward"`, `phx-value-route_type="patch"` and `phx-value-route_path` equal to `P/<id>/show` and `P/<id>/edit`; the new link is an anchor with the same `phx-click` and `phx-value-route_type`, `phx-value-route_path="P/new"` and no `href` attribute

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
### UI-2 — UI · handlers · compatibility suite for the documented handler hooks
Depends on: DOC-1

#### Documentation references
- `guides/core/liveview.md § Index Handler Hook (LiveView)`, `§ Form/Edit Handler Hook (LiveComponent)`, `§ Show Handler Hook (LiveComponent)`, `§ Advanced: Overriding Phoenix Callbacks`, `§ Adding Custom Events`, `§ Targeting the Component`, `§ Hiding Fields at Runtime`

#### Implementation details

This section adds tests and test support only. It changes no file under `lib/`. Every test passes on its first run. A test that fails on its first run is a spec defect to report, never a reason to change library code.

Layout types covered: `:index`, `:form`, `:show`. The suite runs on the Ecto backend only: the handler behaviours, the event targets and the message delivery it exercises never reach a parser or a CRUD module.

The test hosts mirror the guide examples: the same callback, the same `super` call, the same helper. Guide section to test:

| `guides/core/liveview.md` section | Extension point | Exercised by |
|---|---|---|
| § Index Handler Hook › `auix_mount/3`, `auix_handle_params/3`, `apply_action/2` | override with `super` | AC-1 |
| § Index Handler Hook › `auix_handle_event/3`, `auix_handle_async/3` | custom event, custom async task, fallback to `super` | AC-2 |
| § Index Handler Hook › `auix_handle_info/2` | custom message, fallback to `super` | AC-3, AC-7 |
| § Form/Edit Handler Hook › `auix_update/2`, `auix_handle_event/3` | override with `super` | AC-3, AC-4 |
| § Form/Edit Handler Hook › `save_entity/2` | override with `super` | existing `test/cases_live/handler_hooks_form_test.exs` `"Test main edit link"` |
| § Show Handler Hook › `auix_update/2`, `auix_handle_event/3` | override with `super`, `auix_route_back/1`, `push_navigate/2` | AC-5 |
| § Advanced: Overriding Phoenix Callbacks › `mount/3` | override with `super` | existing `test/cases_live/handler_hooks_index_test.exs` `"Test index hooks"` |
| § Advanced: Overriding Phoenix Callbacks › `update/2` | override with `super` | AC-6 |
| § Adding Custom Events | custom events in the three handlers | AC-2, AC-3, AC-5 |
| § Targeting the Component | `phx-target={@auix._myself}` | AC-3, AC-5 |
| § Hiding Fields at Runtime | `assign_auix(socket, :fields_to_reject, keys)` | AC-4 |

##### Acceptance criteria
- [ ] AC-1: Given an index handler that overrides `auix_mount/3`, `auix_handle_params/3` and `apply_action/2` and calls `super` in each, visiting the index reports the three callbacks to the probe from the LiveView process, and the index lists its rows
- [ ] AC-2: Given the same handler, an untargeted `compat_ping` event reaches its `auix_handle_event/3`; the task it starts with `start_async/3` reaches its `auix_handle_async/3`; an untargeted `filter-toggle` event still reaches the default implementation through `super`
- [ ] AC-3: Given a form footer action whose button carries `phx-target={@auix._myself}`, clicking it reaches the form handler's `auix_handle_event/3`; the `send(self(), {:compat_notify, :form})` it performs reaches the index handler's `auix_handle_info/2` in the LiveView process
- [ ] AC-4: Given a form handler whose `auix_update/2` calls `super` and then assigns `:compat_note` and `:fields_to_reject` with `assign_auix/3`, the form renders the note, renders no input for the rejected field, and still renders the note after a later event
- [ ] AC-5: Given a show footer action with two buttons targeted at `@auix._myself`, `compat_back` runs `auix_route_back/1` in the show handler and patches to the index; `compat_go` runs `push_navigate/2` in the show handler and live-redirects to the edit path
- [ ] AC-6: Given a form handler that overrides `Phoenix.LiveComponent` `update/2` and calls `super`, opening the form reports `:update` before `:auix_update` to the probe
- [ ] AC-7: Given the index handler, a message its `auix_handle_info/2` does not match is passed to `super`, is ignored, and the LiveView keeps rendering

##### Test ports
- Route registered in `test/support/app_web/routes.ex` inside `load_test_routes/0` via `RoutesHelper.register_crud/2`: `register_crud(CompatibilityTest.Product, "compatibility-products")`. `P = "/compatibility-products"`.
- Probe: the test process registers itself with `Process.register(self(), :auix_compat_probe)` in `setup`; each host callback sends `{:compat, callback_name, self()}` to `Process.whereis(:auix_compat_probe)` when it is alive. The same pattern is in `test/cases_live/events_test.exs` (`Aurora.UixWeb.EventsProbeIndexHandler`, `:auix_events_probe`). The test module is `async: false` (the default of `UICase`).
- Observables: `assert_receive/2` on probe messages, `has_element?/2`, `assert_patch/1`, the `{:error, {:live_redirect, %{to: path}}}` return.

##### Red tests
Every row passes on first run (characterization). Setup for every row: `delete_all_inventory_data()`, `create_sample_products(3, :test)`, `id` = the id of `"id_test-1"`.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file (`ls test/cases_live \| grep -i compat` returns nothing) | `{:ok, view, _} = live(conn, P)` | `test/cases_live/compatibility_test.exs` | `"index callbacks run with super in the LiveView process"` | `pid = view.pid`; `assert_receive {:compat, :auix_mount, ^pid}`; same for `:auix_handle_params` and `:apply_action`; `assert has_element?(view, "tr[id^='products-#{id}']")` |
| AC-2 | add to `compatibility_test.exs` | as AC-1 | `test/cases_live/compatibility_test.exs` | `"untargeted index events and async results reach the index handler"` | `render_click(view, "compat_ping", %{})`; `assert_receive {:compat, :auix_handle_event, ^pid}`; `assert_receive {:compat, :auix_handle_async, ^pid}`; `render_click(view, "filter-toggle", %{})` returns HTML (no crash) |
| AC-3 | add to `compatibility_test.exs` | `live(conn, "P/#{id}/edit")` | `test/cases_live/compatibility_test.exs` | `"a targeted form event notifies the index through send(self())"` | `view \|> element("button[name='compat-notify-form']") \|> render_click()`; `assert_receive {:compat, {:form_event, "compat_notify"}, ^pid}`; `assert_receive {:compat, {:auix_handle_info, :form}, ^pid}` |
| AC-4 | add to `compatibility_test.exs` | as AC-3 | `test/cases_live/compatibility_test.exs` | `"custom auix keys survive later events and rejected fields are hidden"` | `assert has_element?(view, "[name='compat-note']", "kept")`; `refute has_element?(view, "input[name='product[description]']")`; `assert has_element?(view, "input[name='product[name]']")`; click `button[name='compat-notify-form']`; `assert has_element?(view, "[name='compat-note']", "kept")` |
| AC-5 | add to `compatibility_test.exs` | `live(conn, "P/#{id}/show")` | `test/cases_live/compatibility_test.exs` | `"targeted show events route back and navigate"` | click `button[name='compat-back']`; `assert_patch(view) =~ ~r"^/compatibility-products\?routing_stack="`; remount; `{:error, {:live_redirect, %{to: to}}} = view \|> element("button[name='compat-go']") \|> render_click()`; `to == "P/#{id}/edit"` |
| AC-6 | add to `compatibility_test.exs` | as AC-3 | `test/cases_live/compatibility_test.exs` | `"a Phoenix update override runs before auix_update"` | `{:messages, messages} = Process.info(self(), :messages)` after `render(view)`; `names = for {:compat, name, ^pid} <- messages, name in [:update, :auix_update], do: name`; `Enum.take(names, 2) == [:update, :auix_update]` |
| AC-7 | add to `compatibility_test.exs` | as AC-1 | `test/cases_live/compatibility_test.exs` | `"an unknown message is ignored through super"` | `send(view.pid, :compat_unknown)`; `assert has_element?(view, "tr[id^='products-#{id}']")` |

##### Modules & components
1. `Aurora.UixWeb.Test.Compatibility.Probe` at `test/support/compatibility/probe.ex` — new (search: `grep -rn "Compatibility" lib test` returns nothing). One function, with `@doc` and `@spec`:
   `report(name :: term()) :: :ok` — sends `{:compat, name, self()}` to `Process.whereis(:auix_compat_probe)` when that returns a pid; returns `:ok` in both cases.
2. `Aurora.UixWeb.Test.Compatibility.IndexHandler` at `test/support/compatibility/index_handler.ex` — new. `use Aurora.Uix.Templates.Basic.Handlers.IndexImpl`, `alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl`, `alias Aurora.UixWeb.Test.Compatibility.Probe` (the header of `Aurora.UixWeb.EventsProbeIndexHandler` in `test/cases_live/events_test.exs`). `start_async/3` comes from the `import Phoenix.LiveView` that `IndexImpl.__using__/1` injects. Every override carries `@impl IndexImpl`:
   - `auix_mount(params, session, socket)` — `Probe.report(:auix_mount)`, then `super(params, session, socket)`.
   - `auix_handle_params(params, url, socket)` — `Probe.report(:auix_handle_params)`, then `super(params, url, socket)`.
   - `apply_action(socket, params)` — `Probe.report(:apply_action)`, then `super(socket, params)`.
   - `auix_handle_event("compat_ping", _params, socket)` — `Probe.report(:auix_handle_event)`; returns `{:noreply, start_async(socket, :compat_async, fn -> :done end)}`. Second clause `auix_handle_event(event, params, socket)` calls `super(event, params, socket)`.
   - `auix_handle_async(:compat_async, {:ok, :done}, socket)` — `Probe.report(:auix_handle_async)`; returns `{:noreply, socket}`. Second clause calls `super(task, result, socket)`.
   - `auix_handle_info({:compat_notify, origin}, socket)` — `Probe.report({:auix_handle_info, origin})`; returns `{:noreply, socket}`. Second clause calls `super(message, socket)`.
3. `Aurora.UixWeb.Test.Compatibility.FormHandler` at `test/support/compatibility/form_handler.ex` — new. `use Aurora.Uix.Templates.Basic.Handlers.FormImpl`, `import Aurora.Uix.Templates.Basic.Helpers, only: [assign_auix: 3]`, `alias Aurora.Uix.Templates.Basic.Handlers.FormImpl`, `alias Aurora.UixWeb.Test.Compatibility.Probe`. `FormImpl.__using__/1` injects no import and no alias, so the module declares them:
   - `@impl Phoenix.LiveComponent` `update(assigns, socket)` — `Probe.report(:update)`, then `super(assigns, socket)`.
   - `@impl FormImpl` `auix_update(assigns, socket)` — `Probe.report(:auix_update)`; `{:ok, socket} = super(assigns, socket)`; returns `{:ok, socket |> assign_auix(:compat_note, "kept") |> assign_auix(:fields_to_reject, [:description])}`.
   - `@impl FormImpl` `auix_handle_event("compat_notify", _params, socket)` — `Probe.report({:form_event, "compat_notify"})`; `send(self(), {:compat_notify, :form})`; returns `{:noreply, socket}`. Second clause calls `super(event, params, socket)`.
4. `Aurora.UixWeb.Test.Compatibility.ShowHandler` at `test/support/compatibility/show_handler.ex` — new. `use Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl`, `import Aurora.Uix.Templates.Basic.Helpers, only: [auix_route_back: 1]`, `import Phoenix.LiveView, only: [push_navigate: 2]`, `alias Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl`, `alias Aurora.UixWeb.Test.Compatibility.Probe`. `ShowComponentImpl.__using__/1` injects no import and no alias, so the module declares them:
   - `@impl ShowComponentImpl` `auix_update(assigns, socket)` — `Probe.report(:show_auix_update)`, then `super(assigns, socket)`.
   - `@impl ShowComponentImpl` `auix_handle_event("compat_back", _params, socket)` — returns `{:noreply, auix_route_back(socket)}`.
   - `auix_handle_event("compat_go", _params, socket)` — reads `%{entity: entity, uri_path: uri_path} = socket.assigns.auix`; returns `{:noreply, push_navigate(socket, to: "/#{uri_path}/#{entity.id}/edit")}`.
   - Last clause calls `super(event, params, socket)`.
5. `Aurora.UixWeb.Test.CompatibilityTest` at `test/cases_live/compatibility_test.exs` — new. Header copied from `test/cases_live/create_ui_actions_show_test.exs` (`use Aurora.Uix.CoreComponentsImporter`, `import Phoenix.Component, only: [sigil_H: 2]`). Two public function components, each with `@spec name(map()) :: Rendered.t()`:
   ```elixir
   def compat_form_footer(assigns) do
     ~H"""
     <div name="compat-form-footer">
       <span name="compat-note">{@auix[:compat_note]}</span>
       <button type="button" name="compat-notify-form" phx-click="compat_notify" phx-target={@auix._myself}>Notify</button>
     </div>
     """
   end

   def compat_show_footer(assigns) do
     ~H"""
     <div name="compat-show-footer">
       <button type="button" name="compat-back" phx-click="compat_back" phx-target={@auix._myself}>Back</button>
       <button type="button" name="compat-go" phx-click="compat_go" phx-target={@auix._myself}>Go</button>
     </div>
     """
   end
   ```
   Metadata and layout:
   ```elixir
   auix_resource_metadata(:product, context: Inventory, schema: Product)

   auix_create_ui do
     index_columns(:product, [:reference, :name],
       handler_module: Aurora.UixWeb.Test.Compatibility.IndexHandler
     )

     edit_layout :product,
       edit_handler_module: Aurora.UixWeb.Test.Compatibility.FormHandler,
       add_footer_action: {:compat_form_footer, &__MODULE__.compat_form_footer/1} do
       stacked([:reference, :name, :description, :quantity_initial])
     end

     show_layout :product,
       show_handler_module: Aurora.UixWeb.Test.Compatibility.ShowHandler,
       add_footer_action: {:compat_show_footer, &__MODULE__.compat_show_footer/1} do
       stacked([:reference, :name, :description, :quantity_initial])
     end
   end
   ```
6. Components: none added to the library. Theme: none. `dt/1` strings: none.

##### Green tests
1. The tests above pass, unmodified (code-issue runs these, targeted: `mix test test/cases_live/compatibility_test.exs`)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
4. `git diff --name-only origin/main...HEAD -- lib` prints nothing
<!-- section:UI-2:end -->
<!-- section:UI-3:start -->
### UI-3 — UI · handlers · extract `Aurora.Uix.Navigation`
Depends on: UI-1, UI-2

#### Documentation references
- `guides/core/liveview.md § Navigation`
- `guides/core/components.md § Navigation`, `§ Events`

#### Implementation details

The section moves the navigation helpers out of `lib/aurora_uix/templates/basic/helpers.ex` into one module, with the navigation state in one struct. No generated URL, event or markup changes. Layout types covered: `:index`, `:form`, `:show`. The module is backend-agnostic: it references no `Ecto.*` and no `Ash.*` module.

##### Acceptance criteria
- [ ] AC-1: `Navigation.path/3` returns `"/<uri_path>"` for `:index`, `"/<uri_path>/new"` for `:new`, and `"/<uri_path>/<id>/show"`, `"/<uri_path>/<id>/edit"`, `"/<uri_path>/<id>/show-edit"` for `:show`, `:edit`, `:show_edit`
- [ ] AC-2: `Navigation.resolve_uri_path/2` without a `base_path` derives `uri_path` from `current_path` exactly as `assign_auix_uri_path/1` does today, for the paths `"/a/products"`, `"/a/products/7/edit"`, `"/a/products/7/show"`, `"/a/products/7/show-edit"` and `"/a/products/new"` (the last keeps today's result, `"a/products/new"`); `uri_path_id` replaces every `/` with `--`
- [ ] AC-3: `Navigation.resolve_uri_path/2` with `base_path: "/shop/products"` sets `uri_path` to `"shop/products"` for every `current_path` and every live action
- [ ] AC-4: `Navigation.encode_stack/1` of an empty stack returns `"eJyrVipLzClNLVayio6tBQAhgwS%2F"`, and `decode_stack/1` of the URI-decoded form of an encoded stack returns a stack with the same entries in the same order
- [ ] AC-5: `Navigation.put/2` stores the struct at `auix.navigation` and mirrors it: `auix.routing_stack` always; `auix.uri_path`, `auix.uri_path_id`, `auix._current_path` and `auix._last_route_path` when the struct field is not `nil`
- [ ] AC-6: the navigation struct has no mode: `Navigation.new(mode: :local)` raises `KeyError`
- [ ] AC-7: `auix_link`, `auix_link_back` and `auix_back` render a `phx-target` attribute they are given, and render none when they are given none
- [ ] AC-8: `Aurora.Uix.Templates.Basic.Helpers` still exports `assign_auix_current_path/2`, `assign_auix_uri_path/1`, `assign_auix_index_new_link/1`, `assign_auix_routing_stack/2`, `assign_auix_routing_stack/3`, `auix_route_forward/2` and `auix_route_back/1`
- [ ] AC-9: the suites of UI-1 and UI-2 pass with their files unchanged (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- test/cases_live/navigation_test.exs test/cases_live/ash_navigation_test.exs test/cases_live/compatibility_test.exs test/support/navigation_helper.ex test/support/compatibility` printing nothing, and `mix test` green)
- [ ] AC-10: `Navigation.related_uri_path/3` replaces the parent source with the related source inside a `uri_path` (`"navigation-products"`, `"products"`, `"product_transactions"` gives `"navigation-product_transactions"`), and returns the path unchanged when both sources are equal

##### Test ports
- No new route. The LiveView behaviour is observed through the routes of UI-1 and UI-2.
- Pure functions of `Aurora.Uix.Navigation`, called directly.
- A bare socket for `put/2`: `%Phoenix.LiveView.Socket{}` with `assigns: %{__changed__: %{}, auix: %{}}`.
- Directly rendered components for AC-7: `Phoenix.LiveViewTest.render_component/2`, as `test/cases/core_components_input_test.exs` does.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file (`ls test/cases \| grep -i navig` returns nothing) | `nav = Navigation.new(uri_path: "a/products")` | `test/cases/navigation_test.exs` | `"path/3 builds the five paths"` | `Navigation.path(nav, :index) == "/a/products"`; `Navigation.path(nav, :new) == "/a/products/new"`; `Navigation.path(nav, :show, 7) == "/a/products/7/show"`; `:edit`, `:show_edit` alike |
| AC-2 | add to `test/cases/navigation_test.exs` | `Navigation.new(current_path: path)` | same | `"resolve_uri_path/2 parses the current path as before"` | for `{path, live_action, expected}` in `{"/a/products", :index, "a/products"}`, `{"/a/products/7/edit", :edit, "a/products"}`, `{"/a/products/7/show", :show, "a/products"}`, `{"/a/products/7/show-edit", :show_edit, "a/products"}`, `{"/a/products/new", :new, "a/products/new"}`: `Navigation.resolve_uri_path(nav, live_action).uri_path == expected`; `.uri_path_id == String.replace(expected, "/", "--")` |
| AC-3 | add to same | `Navigation.new(base_path: "/shop/products", current_path: "/elsewhere/9/edit")` | same | `"resolve_uri_path/2 prefers base_path"` | `.uri_path == "shop/products"` for `:edit` and for `:index` |
| AC-4 | add to same | `Stack.new()`; a stack of two entries | same | `"encode_stack/1 and decode_stack/1 round-trip"` | `Navigation.encode_stack(Stack.new()) == "eJyrVipLzClNLVayio6tBQAhgwS%2F"`; `stack \|> Navigation.encode_stack() \|> URI.decode_www_form() \|> Navigation.decode_stack() == stack` |
| AC-5 | add to same | bare socket; `nav = Navigation.new(uri_path: "a/b", uri_path_id: "a--b")` | same | `"put/2 stores the struct and mirrors the legacy keys"` | after `Navigation.put(socket, nav)`: `auix.navigation == nav`, `auix.uri_path == "a/b"`, `auix.uri_path_id == "a--b"`, `auix.routing_stack == nav.stack`, `refute Map.has_key?(auix, :_current_path)`, `refute Map.has_key?(auix, :_last_route_path)` |
| AC-6 | add to same | none | same | `"new/1 rejects a key the struct does not have"` | `assert_raise KeyError, fn -> Navigation.new(mode: :local) end` |
| AC-7 | new file (`ls test/cases \| grep -i routing` returns nothing) | the test module has `use ExUnit.Case, async: true`, `use Aurora.Uix.CoreComponentsImporter`, `import Aurora.Uix.Templates.Basic.RoutingComponents`, `import Phoenix.Component, only: [sigil_H: 2]`, `import Phoenix.LiveViewTest`, and four function components: `targeted_link/1` = `~H\|<.auix_link patch="/x" phx-target="#c">x</.auix_link>\|`, `targeted_link_back/1` = `~H\|<.auix_link_back phx-target="#c">x</.auix_link_back>\|`, `targeted_back/1` = `~H\|<.auix_back phx-target="#c">x</.auix_back>\|`, `plain_link/1` = `~H\|<.auix_link patch="/x">x</.auix_link>\|` | `test/cases/routing_components_test.exs` | `"routing links pass phx-target through"` | each `render_component(&component/1, %{})` is parsed with `LazyHTML.from_fragment/1`; `LazyHTML.query(html, "a[phx-click='auix_route_forward'][phx-target='#c']")` has one node for `targeted_link/1`; `a[phx-click='auix_route_back'][phx-target='#c']` has one node for `targeted_link_back/1` and for `targeted_back/1`; `a[phx-target]` has no node for `plain_link/1` |
| AC-8 | add to `test/cases/navigation_test.exs` | `Code.ensure_loaded!(Helpers)` | same | `"the Basic helpers keep their navigation functions"` | `function_exported?(Helpers, name, arity)` for the seven name/arity pairs of AC-8 |
| AC-10 | add to `test/cases/navigation_test.exs` | none | same | `"related_uri_path/3 swaps the source segment"` | the two values of AC-10 |

##### Modules & components
1. `Aurora.Uix.Navigation` at `lib/aurora_uix/navigation.ex` — new (search: `grep -rn "Aurora.Uix.Navigation" lib test` returns nothing). `@moduledoc` with `## Key Features` and `## Key Constraints`; `@doc` + `@spec` on every public function; `@spec` on every private function. Aliases: `Aurora.Uix.Stack`, `Phoenix.LiveView.Socket`. Imports: `Phoenix.LiveView, only: [push_navigate: 2, push_patch: 2]`. It writes `auix` through `Aurora.Uix.Templates.Basic.Helpers.assign_auix/3`, called fully qualified through an alias `BasicHelpers`.
   - Struct and type:
     ```elixir
     defstruct base_path: nil,
               current_path: nil,
               uri_path: nil,
               uri_path_id: nil,
               stack: %Stack{},
               last_route_path: nil
     ```
     `@type t()` lists the six fields: `base_path: binary() | nil`, `current_path: binary() | nil`, `uri_path: binary() | nil`, `uri_path_id: binary() | nil`, `stack: Stack.t()`, `last_route_path: binary() | nil`.
   - `new(opts :: keyword()) :: t()` with default `[]` — `struct!(__MODULE__, opts)`. An unknown key raises `KeyError`.
   - `get(socket :: Socket.t()) :: t()` — returns `socket.assigns.auix[:navigation]` when it is a `%Navigation{}`, and `new()` when the key is absent (the first call of a mount).
   - `put(socket :: Socket.t(), nav :: t()) :: Socket.t()` — assigns `:navigation` and `:routing_stack` (`nav.stack`) with `assign_auix/3`; assigns `:uri_path`, `:uri_path_id`, `:_current_path` (`nav.current_path`) and `:_last_route_path` (`nav.last_route_path`) each only when the struct field is not `nil`.
   - `assign_current_path(socket, url :: binary() | URI.t() | nil) :: Socket.t()` — `put(socket, %{get(socket) | current_path: url |> URI.parse() |> Map.get(:path)})`. Body moved from `helpers.ex` `assign_auix_current_path/2`.
   - `resolve_uri_path(nav :: t(), live_action :: atom() | nil) :: t()` — pure. With `nav.base_path` a binary: `uri_path = String.replace_leading(nav.base_path, "/", "")`. Otherwise the algorithm of `helpers.ex` `assign_auix_uri_path/1`, moved verbatim, reading `nav.current_path` in place of `auix._current_path` and the `live_action` argument in place of `assigns[:live_action]`. Both branches set `uri_path_id = String.replace(uri_path, "/", "--")`.
   - `assign_uri_path(socket :: Socket.t()) :: Socket.t()` — `put(socket, resolve_uri_path(get(socket), socket.assigns[:live_action]))`.
   - `assign_stack(socket, params :: map(), default_route :: map() | nil) :: Socket.t()` with default `nil` — the three clauses of `helpers.ex` `assign_auix_routing_stack/3`, each ending in `put(socket, %{get(socket) | stack: stack})` in place of `assign_auix(socket, :routing_stack, stack)`.
   - `path(nav :: t(), action :: :index | :new | :show | :edit | :show_edit, id :: term()) :: binary()` with default `nil` for `id` — the five results of AC-1.
   - `forward(socket :: Socket.t(), nav :: t(), target :: keyword()) :: Socket.t()` — one clause, guarded by `is_binary(nav.current_path)`. `target` is `[to: path]` (navigate) or `[patch: path]`. It pushes `%{type: route_type(target), path: nav.current_path}` on `nav.stack`, sets `last_route_path` to `nav.current_path`, calls `put/2`, then `route_to/3`. Logic moved from `helpers.ex` `auix_route_forward/2` and `add_forward_path/3`.
   - `back(socket :: Socket.t(), nav :: t()) :: Socket.t()` — the body of `helpers.ex` `auix_route_back/1`, with `current_path = nav.current_path || ""` and `nav.stack` in place of `routing_stack`; it calls `put(socket, %{nav | stack: new_stack})`, then `route_to/3`.
   - `record(socket :: Socket.t(), nav :: t(), id :: term(), action :: :show | :edit | :show_edit) :: Socket.t()` — `push_patch(socket, to: path(nav, action, id))`. It adds no `routing_stack` parameter.
   - `related_uri_path(uri_path :: binary(), source :: binary(), related_source :: binary()) :: binary()` — `String.replace(uri_path, source, related_source)`.
   - `encode_stack(stack :: Stack.t()) :: binary()` and `decode_stack(encoded :: binary()) :: Stack.t()` — the bodies of `helpers.ex` `encode_routing_stack/1` and `decode_routing_stack/1`, moved verbatim.
   - Private, moved verbatim from `helpers.ex` with `nav.stack` passed as an argument where they read `auix.routing_stack`: `route_to/3` (`route_to(socket, stack, target)`, the four clauses of `route_to/2`), `route_type/1`, `route_path_with_stack/2`, `determine_fallback_path/1`, `remove_trailing_paths/2`.
2. `lib/aurora_uix/templates/basic/helpers.ex` — modified.
   - Add `alias Aurora.Uix.Navigation` in alphabetical position.
   - `assign_auix_current_path/2`: body becomes `Navigation.assign_current_path(socket, url)`.
   - `assign_auix_uri_path/1`: head becomes `assign_auix_uri_path(socket)`; body becomes `Navigation.assign_uri_path(socket)`.
   - `assign_auix_routing_stack/3`: keep the default-argument head; replace the three clauses with one clause whose body is `Navigation.assign_stack(socket, params, default_route)`.
   - `auix_route_forward/2`: head becomes `auix_route_forward(socket, navigation)`; body becomes `Navigation.forward(socket, Navigation.get(socket), navigation)`.
   - `auix_route_back/1`: head becomes `auix_route_back(socket)`; body becomes `Navigation.back(socket, Navigation.get(socket))`.
   - `assign_auix_index_new_link/1`: unchanged.
   - Delete the private functions `add_forward_path/3`, `route_to/2`, `route_type/1`, `route_path_with_stack/2`, `encode_routing_stack/1`, `decode_routing_stack/1`, `determine_fallback_path/1`, `remove_trailing_paths/2` and their `@spec` lines.
   - Delete `alias Aurora.Uix.Stack`: after the edits above its only remaining mentions are inside the `@doc` of `assign_auix_routing_stack/3`.
   - `@doc` and `@spec` of the five public functions stay; each `@doc` gains one closing line: ``Delegates to `Aurora.Uix.Navigation`.``
3. `lib/aurora_uix/templates/basic/handlers/index_impl.ex` — modified. Add `alias Aurora.Uix.Navigation` in alphabetical position.
   - `auix_handle_params/3`: replace `"/#{&1.assigns.auix.uri_path}"` with `Navigation.path(Navigation.get(&1), :index)`. The other lines of the pipeline stay.
   - `auix_handle_event("delete", %{"id" => id, "get_function" => …, "delete_function" => …}, socket)`: replace `socket.assigns.auix[:_current_path]` with `Navigation.get(socket).current_path`.
   - `auix_handle_event("pagination_to_page", …)`, `("pagination_previous", …)`, `("pagination_next", …)`: replace each `"/#{auix.uri_path}?page=#{…}"` with `"#{Navigation.path(Navigation.get(socket), :index)}?page=#{…}"`, keeping the page expression.
   - `auix_handle_event("read_indexed_entry", …)`: replace the `push_patch(new_socket, to: "/#{uri_path}/#{found_id}/#{live_action_suffix}")` call with `Navigation.record(new_socket, Navigation.get(new_socket), found_id, record_action(socket))`; remove `uri_path` from the pattern that binds `new_socket`; remove the `live_action_suffix` binding.
   - Replace the private `get_live_action_suffix/1` with `record_action/1`: `@spec record_action(Socket.t()) :: :show | :edit | :show_edit`; `live_action: :show_edit` gives `:show_edit`, `live_action: :edit` gives `:edit`, every other socket gives `:show`.
   - `react_to_change(socket, :show, :deleted, _entity_id)`: replace `"/#{auix.uri_path}"` with `Navigation.path(Navigation.get(socket), :index)`.
   - The `auix_route_forward` and `auix_route_back` event clauses keep calling the imported `auix_route_forward/2` and `auix_route_back/1`.
4. `lib/aurora_uix/templates/basic/handlers/form_impl.ex` — modified. Add `alias Aurora.Uix.Navigation` in alphabetical position.
   - `auix_update/2`: replace `|> assign_auix(:routing_stack, routing_stack || Stack.new())` with `|> Navigation.put(Navigation.new(uri_path: Map.get(auix, :uri_path), stack: routing_stack || Stack.new()))`. `auix` is the socket's `auix` already bound in the head; the generated `update/2` (`generators/form_generator.ex`) merges the incoming `uri_path` into it before the handler runs. `current_path` stays `nil`, so `put/2` writes no `_current_path`.
   - `conditional_route_back(socket, :new, true)`: bind `nav = Navigation.get(socket)`; pop `nav.stack` with `Stack.pop!/1`; build the edit path exactly as today; call `Navigation.back(socket, %{nav | stack: Stack.push(new_routing_stack, %{type: :navigate, path: edit_path})})`. The head keeps matching `entity` and `primary_key` and drops `routing_stack`.
   - `conditional_route_back(socket, _action, _one2many_rendered?)`: unchanged.
   - `route_back_from_close/1`: body becomes `nav = Navigation.get(socket)` then `Navigation.back(socket, %{nav | current_path: Map.get(auix, :_close_path, "")})`.
   - `@spec` of `conditional_route_back/3`: unchanged. Callers: the generated `handle_event("save", …)` in `FormImpl.__using__/1`, unchanged.
5. `lib/aurora_uix/templates/basic/handlers/show_component_impl.ex` — modified. Add `alias Aurora.Uix.Navigation`. `auix_update/2`: replace `|> assign_auix(:routing_stack, routing_stack || Stack.new())` with `|> then(&Navigation.put(&1, Navigation.new(uri_path: Map.get(&1.assigns.auix, :uri_path), stack: routing_stack || Stack.new())))`.
6. `lib/aurora_uix/templates/basic/renderers/fields/one_to_many.ex` — modified. Add `alias Aurora.Uix.Navigation` in alphabetical position. In `set_related_uri_path/3`, replace `String.replace(source, related_source)` in the pipeline with `Navigation.related_uri_path(source, related_source)`.
7. Unchanged on purpose: `actions/index.ex`, `actions/show_component.ex`, `actions/one_to_many.ex`, `renderers/index_renderer.ex` and `components/components.ex` keep reading `@auix.uri_path`, `@auix.uri_path_id`, `@auix.routing_stack`, `@auix[:_current_path]` and `@auix[:index_new_link]`; `put/2` mirrors them. `components/routing_components.ex` is unchanged: `phx-target` already reaches the anchor through `@rest`, because `:global` attributes include every `phx-*` attribute, and the name `target` is taken by the HTML attribute in `auix_link`'s `include:` list.
8. Contract change. `auix.navigation` is a new `auix` key. `auix.routing_stack`, `auix.uri_path`, `auix.uri_path_id`, `auix._current_path` and `auix._last_route_path` are now written only by `Navigation.put/2`; a direct `assign_auix/3` of one of them no longer changes navigation. No `@spec` of an existing public function changes.
9. Edge cases. `Navigation.get/1` on a socket with no `auix.navigation` returns `new()`. `forward/3` on a navigation whose `current_path` is `nil` (a form or show component) raises `FunctionClauseError`, as `auix_route_forward/2` does today in a component. `decode_stack/1` on a malformed parameter raises, as `decode_routing_stack/1` does today.
10. Components: none new. Theme: none. `dt/1` strings: none.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted: `mix test test/cases/navigation_test.exs test/cases/routing_components_test.exs test/cases_live/navigation_test.exs test/cases_live/ash_navigation_test.exs test/cases_live/compatibility_test.exs`)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-3:end -->

---

### Out of Scope
- Steps 4–7 of the issue (standalone Form/Show that report intents, `.IndexComponent` and `IndexComponentImpl`, `Aurora.Uix.Live.ComponentHooks`, one-to-many through `.IndexComponent`, the `generate:` option) and step 8. They are added to this spec as new sections once UI-3 is merged. `DOC-1` already documents their contract.
- The embedded-component and multiple-instance rows of the navigation test matrix. They need the components of steps 4 and 5.
- A one-to-many field whose `resource:` names an alternate resource on the same schema. Its navigation test is added with step 6.
- Direct load of a `/new` URL. `uri_path` keeps its `/new` suffix there today, so a save patches back to `/new`, and a new parent with a child list redirects to `/new/<id>/edit`. UI-1 does not assert that path, UI-3 reproduces today's parsing, and the fix belongs to a separate issue.
- New tests for `guides/customization/*`. Custom actions, predefined renderers and theming keep their existing tests; a routing-component override has no navigation test.
- An Ash run of the compatibility suite. The handler behaviours, event targets and message delivery it exercises are backend-agnostic.
- `README.md` § What's New link. `prepare-release` updates it.
<!-- enriched-spec:end -->
