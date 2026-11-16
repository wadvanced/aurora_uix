<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** high

### Overview
#### What the epic delivers
The UI that `auix_create_ui` generates becomes a set of components a host uses on any page.

- Every resource gets an `.IndexComponent` next to its `.FormComponent` and its `.ShowComponent`. A host renders any of the three in a LiveView it writes.
- Every generated module has a name. A resource takes a component that already exists, with `use:`, instead of generating its own.
- A one-to-many field renders its list through the index component of the related resource.
- The generated `.Index` LiveView keeps its list, its routes, its URLs, its handler hooks and its behaviour.

All sections are backend-agnostic UI work. The navigation suites and the component suites run on both backends: Ecto (`inventory`) and Ash (`blog`).

#### Concepts

| Term | Meaning |
|---|---|
| **Resource** | A schema and its UI metadata, declared with `auix_resource_metadata` under an atom such as `:product`. A module imports a resource another module declared with `@auix_resource_metadata`. |
| **Layout** | A line of `auix_create_ui` that says what a resource shows: `index_columns` for the list, `edit_layout` for the form, `show_layout` for the show view. |
| **Generated module** | A module `auix_create_ui` defines for a resource. Its name is `<declaring module>.<last segment of the schema module>.<Name>`, as in `MyAppWeb.InventoryViews.Product.FormComponent`. |
| **Kind** | What a generated module is: `:index_live` (the `.Index` LiveView), `:index_component`, `:form_component`, `:show_component`. A resource with a schema gets one module of each kind, also without a layout line. A resource the library creates for an embedded field gets none. |
| **Registry** | The map from an atom to a module that every `auix_create_ui` module keeps. `auix_modules/0` returns the map and `auix_module/1` returns one module. The default atoms are `:<schema>_index`, `:<schema>_index_component`, `:<schema>_form_component` and `:<schema>_show_component`. `@auix_modules` adds a module generated in another module, under an atom the importing module chooses. |
| **`module_name:`** | An option of a layout line. It names the component of that line. The atom is the name in the registry and, camelized, the last segment of the module. No suffix is added: `module_name: :product_form` gives `Product.ProductForm`. |
| **`index_live`** | The line `index_live :resource, module_name: :name` inside `auix_create_ui`. It names the LiveView of the resource. `auix_live_resources/3` routes to that LiveView with `index_live: :name`. |
| **`use:`** | An option of a layout line. The resource takes an existing component and generates none for that line. The value is one of two things: a name of the registry, and a generated module such as `OtherViews.auix_module(:name)`. The line takes no field list, no block and no other option. Two checks run at compile time: the kind of the component matches the line, and the resource has every field the layout of the component places. The sections call a `use:` line a **pairing**. |
| **`generate:`** | An option of `auix_create_ui`: the kinds of module this module generates. It defaults to every kind. `generate: []` generates nothing and keeps the checks of `use:`. |
| **`resource`** | An input of a component: an atom that names a resource of the LiveView that renders the component. That LiveView declares the pairing with `use:` in its own `auix_create_ui`. Without the input, a component serves the resource it was generated for. |
| **Intent** | The message `{Aurora.Uix, component_id, intent}` a component sends to its parent: `{:saved, entity}`, `{:closed}`, `{:open, action, id}`, `{:page, page}`, `{:deleted, ids}`. |

#### Who navigates
One rule holds for every component and every parent: a component never navigates. It tells its parent what the user asked for with an intent, and the parent acts.

| The parent | What it does with an intent |
|---|---|
| The generated `.Index` LiveView, which opens the form and the show view in its modal | It navigates. On `{:saved, entity}` and on `{:closed}` from its form, it patches and navigates under its routes, to the URLs and the routing stack of today. |
| Any other parent, such as a LiveView a host writes | It decides: render a form, assign a record, change the URL, do nothing. |

- Today the form pushes the redirect itself, after a save and on close. UI-5 moves that push into the generated `.Index` LiveView.
- The show view has no code that navigates. Opened by the generated `.Index` LiveView, its back action and its edit action are events of that LiveView, and they stay so. The same holds for the record navigator and for the actions of a one-to-many list. They carry no target, and the LiveView handles them as today.
- An embedded show view sends `{:closed}` and `{:open, :edit, id}`. An embedded component renders no record navigator and no one-to-many action.
- The sections say **hosted** for a form and a show view opened by the generated `.Index` LiveView, and **embedded** for any other parent. The two differ in how the component gets its record (UI-5). They do not differ in who navigates.
- The index component is always embedded, because the generated `.Index` LiveView keeps its own list.
- Host handlers keep working. A form handler and a show handler that call `auix_route_back/1`, as the guides show, navigate as today. `FormImpl.conditional_route_back/3` stays. The generated LiveView still receives `{FormImpl, {:saved, entity}}`, before the intent.
- One difference shows in LiveView tests only. The redirect after a form save and after a form close comes from the LiveView, one message after the form event. `render_submit() |> follow_redirect(conn)` becomes `render_submit()` followed by `assert_redirect(view)`. Nothing changes in the browser.

#### The five examples
The schemas: `Product` has many `ProductTransaction` (`:product_transactions`) and belongs to a `ProductLocation` (`:product_location_id`). DOC-3 prescribes the full text of each example in `guides/core/components.md § Naming and reusing generated modules`.

**1. One module.**
```elixir
defmodule MyAppWeb.InventoryViews do
  use Aurora.Uix
  alias MyApp.Inventory
  alias MyApp.Inventory.{Product, ProductLocation, ProductTransaction}

  auix_resource_metadata :product, context: Inventory, schema: Product
  auix_resource_metadata :product_transaction, context: Inventory, schema: ProductTransaction
  auix_resource_metadata :product_location, context: Inventory, schema: ProductLocation

  auix_create_ui do
    index_columns :product, [:reference, :name]
    edit_layout :product do
      inline [:reference, :name]
      stacked [:product_location_id, :product_transactions]
    end
    index_columns :product_transaction, [:type, :quantity, :cost]
    index_columns :product_location, [:reference, :name]
  end
end
```
- It generates twelve modules: four per resource.
- For `:product`: `:product_index` is `Product.Index`, `:product_index_component` is `Product.IndexComponent`, `:product_form_component` is `Product.FormComponent`, `:product_show_component` is `Product.ShowComponent`.
- The same four exist for `:product_transaction` (`ProductTransaction.*`) and for `:product_location` (`ProductLocation.*`).
- The transactions list in the product form is rendered by `ProductTransaction.IndexComponent`. No field needs `resource:`.

**2. Resources in one module, the UI in another.**
- `MyAppWeb.InventoryMetadata` declares the three resources and generates nothing.
- `MyAppWeb.InventoryViews` imports them with `@auix_resource_metadata InventoryMetadata.auix_resources()`, and has the `auix_create_ui` of example 1.
- It generates the same twelve modules under the same names.
- One resource is imported with `@auix_resource_metadata %{product: InventoryMetadata.auix_resource(:product)}`.

**3. Reusing components from another views module.**
```elixir
# MyAppWeb.ProductViews: example 1, with one line changed.
edit_layout :product, module_name: :product_form do

# MyAppWeb.CatalogViews
auix_resource_metadata :catalog_product, context: Inventory, schema: Product

@auix_resource_metadata %{
  product_transaction: ProductViews.auix_resource(:product_transaction),
  product_location: ProductViews.auix_resource(:product_location)
}
@auix_modules %{
  catalog_form: ProductViews.auix_module(:product_form),
  transactions_list: ProductViews.auix_module(:product_transaction_index_component)
}

auix_create_ui do
  index_columns :catalog_product, [:name]
  edit_layout :catalog_product, use: :catalog_form
  index_columns :product_transaction, use: :transactions_list
  index_columns :product_location, [:name]
end
```
- `ProductViews` generates the twelve modules of example 1, except that the product form is `:product_form`, the module `Product.ProductForm`.
- `CatalogViews` imports `:catalog_form` and `:transactions_list`. It generates ten modules: `:product_index`, `:product_index_component`, `:product_show_component`, `:product_transaction_index`, `:product_transaction_form_component`, `:product_transaction_show_component`, and the four of `:product_location`.
- `:catalog_product` links its associations to the two imported resources, so the reused form shows its location select and its transactions list.

**4. Two resources on one schema, in one `auix_create_ui`.**
```elixir
auix_resource_metadata :product do
  context Inventory
  schema Product
  field :product_transactions, resource: :product_transaction_compact
end

auix_resource_metadata :product_transaction, context: Inventory, schema: ProductTransaction

auix_resource_metadata :product_transaction_compact do
  context Inventory
  schema ProductTransaction
  field :cost, readonly: true
end

# Inside auix_create_ui, after the layouts of :product and :product_transaction:
index_columns :product_transaction_compact, [:type, :quantity], module_name: :transactions_compact
edit_layout :product_transaction_compact, use: :product_transaction_form_component
show_layout :product_transaction_compact, use: :product_transaction_show_component
index_live :product_transaction_compact, module_name: :compact_transactions
```
- It generates the twelve modules of example 1 and two more: `:transactions_compact` is `ProductTransaction.TransactionsCompact`, and `:compact_transactions` is `ProductTransaction.CompactTransactions`, the LiveView.
- The second resource takes the form and the show view of the first by their default names.
- The transactions list in the product form is `ProductTransaction.TransactionsCompact`. The field needs `resource:` here, because two resources describe `ProductTransaction`.
- `auix_resource_metadata` takes its options on the line, and it takes a block. It does not take both, so `:product` uses the block.

**5. A LiveView a host writes.**
```elixir
defmodule MyAppWeb.ProductReviewLive do
  use MyAppWeb, :live_view
  use Aurora.Uix

  auix_resource_metadata :product_review do
    context Inventory
    schema Product
    field :reference, readonly: true
  end

  auix_resource_metadata :product_transaction, context: Inventory, schema: ProductTransaction
  auix_resource_metadata :product_location, context: Inventory, schema: ProductLocation

  auix_create_ui generate: [] do
    edit_layout :product_review, use: ProductViews.auix_module(:product_form)
    index_columns :product_transaction, use: ProductViews.auix_module(:product_transaction_index_component)
  end

  # render/1
  # <.live_component module={ProductViews.auix_module(:product_form)} id="product-review-form"
  #   resource={:product_review} entity_id={@id} />
end
```
- The LiveView generates no module. Its `auix_create_ui` attaches the components it needs.
- `resource` is a name. The component looks it up in the LiveView that renders it.

#### Decisions
1. The generated `.Index` LiveView keeps its own list and does not render `.IndexComponent`. Reason: `stream_insert/4` in an `IndexImpl` handler, `auix.load_items_options` and untargeted list events keep working. Both run the list engine of UI-6.
2. A component never navigates, and the generated `.Index` LiveView navigates on the intents of its form (§ Who navigates). Reason: a component then acts the same way in every parent.
3. A component takes no `navigation:` input and no `base_path` input. Reason: no component navigates, so there is nothing to choose.
4. `module_name:` is the last segment of the module as written, with no suffix. Reason: the name in the registry and the name of the module are then the same word.
5. `resource` is resolved in the LiveView that renders the component, and that LiveView declares the pairing in its own `auix_create_ui`. Reason: the parsed options of a resource exist only in a module with `auix_create_ui`, and the checks of `use:` run when that module compiles.
6. A component instance keeps the resource of its first update. Reason: its options are resolved once, on that update. Another resource takes a component with its own `id`.
7. A one-to-many list keeps today's look and actions. Filters, selection, sort and paging are off, and no option turns them on. Reason: UI-9 then changes no existing one-to-many test.
8. Two generated modules with one name are a compile error. Reason: today the second definition silently replaces the first.
9. A resource created for an embedded field generates no modules. Reason: nothing renders them.
10. A resource declared in a module links its associations to the resources the module imports. Reason: the reused form of example 3 then shows its select and its list.
11. `Aurora.Uix.Live.ComponentHooks` serves hand-written LiveViews only. Reason: the generated `.Index` LiveView subscribes on its own.
12. A generator given options without `artifacts`, `used`, `generate` and `exposed_layouts` fills them with the default names, through `Artifacts.put_defaults/1`. Reason: `test/aurora_uix/templates/basic/gettext_coverage_test.exs` builds such options by hand and passes with its file unchanged.
13. A show view opened by the generated `.Index` LiveView keeps its back link and its edit link as events of that LiveView. Reason: its code does not navigate today, and other links would change its markup and bypass a host override of `auix_link/1`.
14. A form opened by the generated `.Index` LiveView still sends `{FormImpl, {:saved, entity}}`, before the intent, and `FormImpl.conditional_route_back/3` stays public and unchanged. Reason: host handlers that use them keep working.
15. A form opened by the generated `.Index` LiveView hands its flash to that LiveView when it closes, in the message `{FormImpl, {:flash, flash}}`. Reason: a flash shown in the form then follows the user to the page behind, as today.

#### Breaking and visible changes
The work is non-breaking for 0.2.1 except the first two items. Both are compile-time changes of UI-4.

1. **Breaking.** Two generated modules with one name no longer compile, and neither do two names that resolve to one module. It happens when two resources of a module share a schema. The fix is `module_name:`, `use:` and an `index_live` line on one of them.
2. **Breaking.** A resource created for an embedded field (`:<parent>__<field>`) generates no `.Index`, `.FormComponent` and `.ShowComponent`.
3. **Visible.** A resource declared in a module links its associations to the resources the module imports with `@auix_resource_metadata` (UI-4). A many-to-one field then shows its select and a one-to-many field shows its list. A module that imports nothing is untouched.
4. **Visible to a custom template.** The map `Aurora.Uix.Template.generate_module/1` receives gains `artifacts`, `used`, `generate` and `exposed_layouts`. The callback is not invoked for a kind left out of `generate:`, and not for a resource created for an embedded field (UI-4, step 11).
5. **Visible in the markup.** The rows container of a one-to-many list keeps its id and its class and gains `data-phx-component` (UI-9).
6. **Visible in LiveView tests only.** The redirect after a form save and after a form close comes from the generated `.Index` LiveView, one message after the form event (UI-5). A test replaces `render_submit() |> follow_redirect(conn)`, and a match on `{:error, {:live_redirect, _}}`, with `render_submit()` followed by `assert_redirect(view)`. The URLs, the routing stack and the flash are those of today, and nothing changes in the browser.
7. **Documentation.** DOC-3 corrects the merged guides where UI-4 to UI-9 make them inexact. It lists items 1 to 3 and the test note of item 6 in the CHANGELOG.

#### The sections in plain words
The Section Map below holds the ids, the dependencies, the branches and the PR titles.

- **DOC-1** (merged): writes the component contract down: the new guide `guides/core/components.md`, the CHANGELOG entry and the What's New page.
- **UI-1** (merged): adds tests that lock today's navigation on both backends. No library change.
- **UI-2** (merged): adds tests for the documented handler hooks. No library change.
- **UI-3** (merged): moves the navigation computation into the pure module `Aurora.Uix.Navigation`.
- **DOC-2** (merged): brings the navigation guides in line with UI-3.
- **UI-4**: gives every generated module a name in a registry, and adds `module_name:`, `use:`, `index_live` and `generate:`.
- **UI-5**: makes the form component and the show component work in a LiveView a host writes. They load their own record and send intents. It also moves the form's navigation into the generated `.Index` LiveView.
- **UI-6**: moves the list logic out of `IndexImpl` into one module, `IndexList`. No behaviour change.
- **UI-7**: generates `.IndexComponent`, the list as a LiveComponent. Several instances share a page.
- **UI-8**: adds the `on_mount` hook that forwards record changes to the index components of a hand-written LiveView.
- **UI-9**: renders the list of a one-to-many field through the index component of the related resource. The list looks and acts as today.
- **DOC-3**: brings the guides and the CHANGELOG in line with UI-4 to UI-9, and adds the five examples.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | `CHANGELOG.md` § `[0.2.1]`, `guides/core/components.md` (new), `guides/core/liveview.md` § Module Generation, § Generated Module Structure, § Targeting the Component, § Navigation, § Related guides, `guides/whats_new/0.2.1.md` (new) | none | federico/458-doc-1-components-contract | docs: component contract and navigation spec (#458 · DOC-1) |
| UI-1 | UI | handlers · navigation characterization tests, Ecto and Ash (no library change) | DOC-1 | federico/458-ui-1-navigation-characterization | test: lock current navigation behaviour (#458 · UI-1) |
| UI-2 | UI | handlers · handler-hook tests for the documented callbacks, in the existing `handler_hooks_*` test files (no library change) | DOC-1 | federico/458-ui-2-compatibility-suite | test: cover the documented handler hooks (#458 · UI-2) |
| UI-3 | UI | handlers · extract `Aurora.Uix.Navigation` (`base_path`) as a pure data module; socket layer in `Aurora.Uix.Templates.Basic.Helpers` | UI-1, UI-2 | federico/458-ui-3-navigation-module | refactor: extract Aurora.Uix.Navigation (#458 · UI-3) |
| DOC-2 | Documentation | `guides/core/components.md` § Navigation, `guides/core/liveview.md` § Navigation, `guides/whats_new/0.2.1.md` § Upgrading from 0.2.0 (the pure `Aurora.Uix.Navigation` API of UI-3) | UI-3 | federico/458-doc-2-navigation-guides | docs: navigation guides match the pure Aurora.Uix.Navigation (#458 · DOC-2) |
| UI-4 | UI | layout · generated modules as named artifacts: the naming functions and the name checks in `Aurora.Uix.Layout.CreateUI`, `module_name:`, `use:` (a registry name or a generated module), `index_live`, `generate:`, `auix_modules/0`, `auix_module/1` (name to module, generated and imported), `auix_kind/0`, `auix_fields/0` and `auix_layout/0` on every generated module, pairings declared with `generate: []`, `Helpers.component_binding/3`, name collisions as compile errors, no modules for embedded resources, associations of a declared resource linked to the resources the module imports, `index_live:` on `auix_live_resources/3` | UI-3 | federico/458-ui-4-named-artifacts | feat: generated modules are named artifacts (#458 · UI-4) |
| UI-5 | UI | generators and handlers · standalone Form and Show components: inputs (`resource` resolved in the rendering LiveView), intents, the generated `.Index` LiveView navigates on the intents of its form, `Aurora.UixWeb.Test.ComponentHostLive` | UI-4 | federico/458-ui-5-standalone-form-show | feat: standalone form and show components (#458 · UI-5) |
| UI-6 | UI | handlers · extract the list engine `Handlers.IndexList` (no behaviour change) | UI-4 | federico/458-ui-6-index-list-engine | refactor: extract the index list engine (#458 · UI-6) |
| UI-7 | UI | generators and handlers · `.IndexComponent`, `IndexComponentImpl`, kind `:index_component`, the `resource` input, per-instance ids and event targets | UI-5, UI-6 | federico/458-ui-7-index-component | feat: IndexComponent and IndexComponentImpl (#458 · UI-7) |
| UI-8 | UI | live · `Aurora.Uix.Live.ComponentHooks` | UI-7 | federico/458-ui-8-component-hooks | feat: ComponentHooks forwards events to embedded components (#458 · UI-8) |
| UI-9 | UI | renderers · one-to-many list through the index component of the related resource | UI-8 | federico/458-ui-9-one-to-many-index-component | feat: one-to-many lists through the index component (#458 · UI-9) |
| DOC-3 | Documentation | `CHANGELOG.md` § `[0.2.1]`, `guides/advanced/advanced_usage.md` § Single vs Multiple Resources, § Introspecting generated UI modules, `guides/core/components.md`, `guides/core/liveview.md` § Module Generation, § Generated Module Structure, § Using Generated Modules with Routes, § Specifying Handler Hooks in Layout DSL, `guides/whats_new/0.2.1.md` (what UI-4 to UI-9 deliver) | UI-9 | federico/458-doc-3-components-guides | docs: component guides and CHANGELOG match the delivered components (#458 · DOC-3) |

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

The section corrects the statements of the merged guides that UI-3 makes false. After UI-3, `Aurora.Uix.Navigation` is a pure data module: `forward/2` and `back/1` take the struct and return `{nav, route}`. A handler navigates with the helpers `auix_route_forward/2` and `auix_route_back/1` of `Aurora.Uix.Templates.Basic.Helpers`. The section edits three guide files and no other file.

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
   `@auix[:index_new_link]` remain readable there. They mirror `@auix.navigation`. Change navigation with
   `auix_route_forward/2` and `auix_route_back/1`, not by assigning those keys.
   ```

##### guides/core/liveview.md
1. § Navigation — replace every line between the heading `## Navigation` and the ` ```elixir ` line that opens the `auix_handle_event("archive", …)` example with, verbatim, keeping one blank line after the heading and one before the ` ```elixir ` line:
   ```
   `Aurora.Uix.Navigation` describes the navigation of the generated LiveView as plain data. The state is
   `@auix.navigation`, an `%Aurora.Uix.Navigation{}` with the base path, the current path and the routing stack.
   The functions take that struct and return data.

   | Function | Returns |
   |---|---|
   | `Navigation.path(nav, action, id)` | The path of `:index`, `:new`, `:show`, `:edit` or `:show_edit` |
   | `Navigation.forward(nav, target)` | `{nav, route}`: `nav` has the current path pushed on the routing stack, and `route` leads to `target` (`patch: path` or `to: path`) |
   | `Navigation.back(nav)` | `{nav, route}`: `nav` has the routing stack popped, and `route` leads back |

   A route is `%{type: :patch | :navigate, path: path}`. Its path carries the routing stack in `routing_stack=`.

   `auix_route_forward/2` calls `Navigation.forward/2` and `auix_route_back/1` calls `Navigation.back/1` on
   `@auix.navigation`; each stores the returned struct and pushes the returned route. Use them in a handler:
   ```
   The `auix_handle_event("archive", …)` example and the two paragraphs after it stay, unchanged.

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
- [x] AC-4: `guides/core/liveview.md § Navigation` names `auix_route_forward/2` and `auix_route_back/1` as the helpers to use in a handler, and says what each one does (mechanical — no red test; verified by `grep -c 'each stores the returned struct and pushes the returned route' guides/core/liveview.md` returning `1`, `grep -c 'call them with the socket' guides/core/liveview.md` returning `0` and `grep -c 'Only the helpers change a socket' guides/core/liveview.md` returning `0`)
- [x] AC-5: `guides/core/components.md § Navigation` names `auix_route_forward/2` and `auix_route_back/1` as the way to change navigation, and names `Aurora.Uix.Navigation` as what computes each path (mechanical — no red test; verified by `grep -c 'change navigation through' guides/core/components.md` returning `0`, `grep -c 'Change navigation with$' guides/core/components.md` returning `1`, `grep -c 'computes each path, and the LiveView applies it' guides/core/components.md` returning `1` and `grep -c 'Navigation`: a patch' guides/core/components.md` returning `0`)
- [x] AC-6: `guides/whats_new/0.2.1.md § Upgrading from 0.2.0` names the two helpers alone (mechanical — no red test; verified by `grep -c '^with `auix_route_forward/2` and `auix_route_back/1`\.$' guides/whats_new/0.2.1.md` returning `1` and `grep -c 'and `Aurora.Uix.Navigation`\.$' guides/whats_new/0.2.1.md` returning `0`)
- [x] AC-7: the text of § Navigation in both guides has no statement about a socket; the word stays only in the code examples (mechanical — no red test; verified by `grep -c 'socket' guides/core/components.md` returning `3`, `grep -c 'take no socket' guides/core/components.md` returning `0`, `awk '/^## Navigation$/,/^## Performance Considerations$/' guides/core/liveview.md | grep -c 'socket'` returning `2` and `grep -c 'None takes a socket' guides/core/liveview.md` returning `0`)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-2:end -->
<!-- section:UI-4:start -->
### UI-4 — UI · layout · generated modules are named artifacts
Depends on: UI-3

#### What and why
- **What.** Every module `auix_create_ui` generates gets a name in a registry. A module names its components with `module_name:`, names its LiveView with an `index_live` line, chooses the kinds it generates with `generate:`, and takes an existing component with `use:`.
- **Why.** UI-5 to UI-9 find a component by its name and let one resource take the component of another. Today the name of a generated module is rebuilt from strings where it is needed, and two resources on one schema silently replace each other's modules.
- **For an existing host.** Two compile-time breaking changes and one visible change. They are listed under **Changes an existing host sees** below.

#### Documentation references
- `guides/core/liveview.md § Module Generation with auix_create_ui`, `§ Using Generated Modules with Routes`
- `guides/advanced/advanced_usage.md § Accessing Separated Metadata` (the `@auix_resource_metadata` import this section mirrors)
- `guides/core/components.md § Generating the components alone`

#### Implementation details

**Scope**
- Kinds in this section: `:form_component` (from `edit_layout`), `:show_component` (from `show_layout`) and `:index_live` (the index LiveView, from `auix_create_ui` itself). UI-7 adds `:index_component`.
- Layout types covered: `:form`, `:show`. `:index` keeps generating the LiveView.
- Everything here is backend-agnostic: no `Ecto.*` and no `Ash.*` module is referenced.

**What the section builds**
- Every module `auix_create_ui` generates becomes a named **artifact**: the declaring module keeps a registry that maps an atom to the generated module.
- A module also lists the modules it imports with `@auix_modules`, under the atoms it gives them.
- Every generated module describes itself with three functions: `auix_kind/0`, `auix_fields/0` and `auix_layout/0`.

**Terms used below**
- **Hint**: the last segment of a resource's schema module (`"Product"`). It is the middle segment of every generated module name.
- **Names**: the list of `{name, kind, resource_name, module}` tuples, one per module the declaring module generates (`module_names/5`, step 2). The registry maps each `name` to its `module`. It holds no resource.
- **Target resource**: a resource of the module that has a schema, passes `for:` and has `embedded?: false`.
- **Pairing**: a `use:` line. It gives a resource of the module a component generated elsewhere.

**Pairings**
- `use:` takes a name of the registry of the module, default names included. It also takes a generated module itself: the value `auix_module/1` of another module returns.
- The checks of `use:` run at compile time.
- Every module that calls `use Aurora.Uix` declares pairings, a LiveView written by hand included.
- That LiveView declares its resources, imports the others with `@auix_resource_metadata`, and writes `auix_create_ui generate: [] do edit_layout :product_location, use: ProductViews.auix_module(:reference_form) end`.
- `generate: []` generates no module and keeps every check of `use:`.
- `@auix_modules` gives an imported module a name in the registry of the importing module. A pairing does not need it.
- `Helpers.component_binding/3` turns a pairing into the options the component runs with. The generated LiveView calls it in this section. A component given the input `resource` calls it in UI-5 and UI-7. No resource struct is passed by hand.

**Changes an existing host sees**

Two changes break code that compiles today. Both surface at compile time, and DOC-3 lists both in the CHANGELOG:
- two artifacts with the same name raise `Spark.Error.DslError`, and so do two artifacts that resolve to the same module;
- a resource created for an embedded field generates no modules.

One change is not breaking and is visible to an existing host:
- A resource declared in a module links its associations to the resources that module imports with `@auix_resource_metadata`, as it links them to the resources declared beside it (step 17).
- Today such an association has `data.resource == nil`, so a many-to-one renders a plain input and a one-to-many renders nothing.
- A module that imports nothing is untouched.
- DOC-3 lists the change in the CHANGELOG.

##### Acceptance criteria
- [x] AC-1: `CreateUI.module_name(MyApp.Views, "Product", :index_compact)` returns `MyApp.Views.Product.IndexCompact`; `CreateUI.default_name("ProductLocation", :form_component)` returns `:product_location_form_component`; `CreateUI.default_name("Product", :index_live)` returns `:product_index`; `CreateUI.schema_hint(Aurora.Uix.Guides.Inventory.Product)` returns `"Product"`
- [x] AC-2: a module with one resource `:product` and `auix_create_ui()` defines `<Module>.Product.Index`, `<Module>.Product.FormComponent` and `<Module>.Product.ShowComponent`, and `auix_modules/0` returns exactly `%{product_index: <Module>.Product.Index, product_form_component: <Module>.Product.FormComponent, product_show_component: <Module>.Product.ShowComponent}`; `auix_module(:product_form_component)` returns `<Module>.Product.FormComponent` and `auix_module(:nope)` returns `nil`; `<Module>.Product.FormComponent` exposes `auix_kind/0` returning `:form_component`, `auix_fields/0` returning a list that holds `:reference`, and `auix_layout/0` returning a `%Node.Form{resource: nil}`; `<Module>.Product.Index` exposes `auix_kind/0` returning `:index_live`, `auix_fields/0` returning `[]` and `auix_layout/0` returning `nil`
- [x] AC-3: `edit_layout :product, module_name: :reference_form do … end` defines `<Module>.Product.ReferenceForm`, the name as given with no suffix added, defines no `<Module>.Product.FormComponent`, and registers the module under `:reference_form`
- [x] AC-4: `index_live :product, module_name: :catalog` inside `auix_create_ui` defines `<Module>.Product.Catalog` as the LiveView, defines no `<Module>.Product.Index`, and registers the module under `:catalog`; its `auix_kind/0` returns `:index_live`
- [x] AC-5: `auix_create_ui generate: [:form_component, :show_component]` defines no `<Module>.Product.Index`; no module of `auix_modules/0` has the kind `:index_live`
- [x] AC-6: two declared resources on one schema with default names fail compilation with `Spark.Error.DslError` whose message contains `module name :product_form_component is taken more than once`
- [x] AC-7: two artifacts that resolve to one module under different names (`edit_layout :product_compact, module_name: :form_component do … end` next to the default form of `:product`) fail compilation with a message containing `would be generated twice`
- [x] AC-8: error paths of `use:`. Each fails compilation with `Spark.Error.DslError`: an atom that is neither a name of the registry nor a generated module (`unknown module :nope in use:`, `unknown module Enum in use:`); a module of another kind (`use: :product_show_component names :show_component`); an index LiveView (`names :index_live`); a module whose layout places a field the resource lacks (`unknown fields [:description] for resource :product_location in use:`); `use:` with a `do` block (`use: takes no do block`); `use:` with `module_name:` (`use: takes no other option`)
- [x] AC-9: `generate: [:index_live]` fails compilation with a message containing `the live view of :product needs a form component and a show component`
- [x] AC-10: a module whose resource has embedded fields (`:user` on `Aurora.Uix.Guides.Accounts.User`) defines no `<Module>.Profile.Index`, `<Module>.Profile.FormComponent`, `<Module>.Profile.ShowComponent`, `<Module>.Email.Index`; `the keys of `auix_modules/0` that start with `user` are exactly `:user_index`, `:user_form_component`, `:user_show_component`, none starts with `profile` and none with `email`; `auix_configurations/0` still has the keys `:user__profile` and `:user__emails`
- [x] AC-11: a form component generated in one module and imported with `@auix_modules` serves a resource of another schema in the importing module: with `edit_layout :product_location, use: :reference_form`, the form the generated LiveView opens has the inputs `product_location[reference]` and `product_location[name]`, has no input `product_location[type]`, and saving it updates the product location; the importing module defines no `<Module>.ProductLocation.FormComponent`
- [x] AC-12: `auix_live_resources(path, module, index_live: :locations)` routes the five actions to `<module>.Locations`; without the option the routes point to `<module>.Index`
- [x] AC-13: an `@auix_modules` value that is not a generated module (`%{reference_form: nil}`) fails compilation with a message containing `@auix_modules entry :reference_form is not a generated module`
- [x] AC-14: no runtime code rebuilds a generated module name (mechanical — no red test; verified by `grep -rn 'ModulesGenerator.module_name' lib` printing only the `def module_name` documentation example lines of `lib/aurora_uix/templates/basic/modules_generator.ex`)
- [x] AC-15: every existing test passes with its file unchanged, and `lib/aurora_uix_web/routes.ex` is unchanged (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- test lib/aurora_uix_web` listing only `test/cases/create_ui_validation_test.exs`, `test/cases/resource_metadata_validation_test.exs`, `test/cases_live/named_modules_test.exs` and `test/support/app_web/routes.ex`, and `mix test` green)
- [x] AC-16: `auix_modules/0` and `auix_module/1` return an imported module under the atom the importing module gave it: in the importing module of AC-11, `auix_module(:reference_form)` returns `NamedModulesForms.Product.ReferenceForm`, and `auix_modules/0` has the key `:reference_form`
- [x] AC-17: a module declares a pairing with a generated module and generates nothing: with an imported resource `:product_location`, no `@auix_modules`, and `auix_create_ui generate: [] do edit_layout :product_location, use: NamedModulesForms.auix_module(:reference_form) end`, `auix_modules/0` returns `%{}`; `auix_configurations().product_location` has `artifacts.form_component` equal to `NamedModulesForms.Product.ReferenceForm` and `used` equal to `[:form_component]`; no `<Module>.ProductLocation.FormComponent`, `<Module>.ProductLocation.ShowComponent` and `<Module>.ProductLocation.Index` is defined
- [x] AC-18: `Helpers.component_binding/3` returns the options of a pairing: for the module of AC-17, `component_binding(auix_configurations(), :product_location, :form)` has `resource_name: :product_location`, `layout_type: :form`, `modules.caller` equal to the module, `artifacts.form_component` equal to the imported module, and a `layout_tree` of `:product_location` that places `:reference` and `:name`; error path: a resource the configurations lack raises `KeyError`
- [x] AC-19: a resource declared in a module links its associations to the resources the module imports: with `:catalog_product` declared on `Aurora.Uix.Guides.Inventory.Product` and `:product_transaction` and `:product_location` imported with `@auix_resource_metadata`, `auix_resource(:catalog_product).fields` has `data.resource` equal to `:product_transaction` for `:product_transactions` and to `:product_location` for `:product_location_id`, with `html_type: :select` for `:product_location_id`; the result is the same with the attribute written before the declaration and after it; on the Ash backend, `:article` declared on `Aurora.Uix.Guides.Blog.Post` with `:author` imported has `data.resource` equal to `:author` for `:author`
- [x] AC-20: error and degraded paths of the link. A resource declared beside an imported one on the same schema wins: with `:product_location` imported and `:local_location` declared on the same schema, `data.resource` of `:product_location_id` is `:local_location`. An `@auix_resource_metadata` value that is not a resource (`%{nope: nil}`) is skipped and the module compiles. A module that imports nothing keeps `data.resource == nil` for an association whose related schema it does not declare
- [x] AC-21: degraded path. Options built by hand, with none of `artifacts`, `used`, `generate` and `exposed_layouts`, generate the modules they generated before this section: `CreateUI.put_defaults/1` gives `%{layout_type: :form, layout_tree: tree, modules: %{caller: MyApp.Views}, module_name: "Product"}` the `artifacts` `MyApp.Views.Product.Index`, `MyApp.Views.Product.FormComponent` and `MyApp.Views.Product.ShowComponent` under `index_live`, `form_component` and `show_component`, `used: []`, `generate: CreateUI.kinds()` and `exposed_layouts: %{form_component: %{tree | resource: nil}}`; with `layout_type: :show` the key of `exposed_layouts` is `:show_component`; a key the options carry is kept as given; `test/aurora_uix/templates/basic/gettext_coverage_test.exs`, which gives `FormGenerator.generate_module/1` such options, passes with its file unchanged
- [x] AC-22: the naming code has no module and no test file of its own, and the route helper builds no atom with `String.to_atom/1` (mechanical — no red test; verified by `ls lib/aurora_uix/layout/artifacts.ex test/cases/artifacts_test.exs` reporting both paths as missing, `grep -rn 'Layout.Artifacts' lib test .doctor.exs` printing nothing, and `grep -n 'String.to_atom' lib/aurora_uix/helpers/route_helper.ex` printing nothing)

##### Test ports
- Compile-time behaviour: `Code.compile_string/1` through the private `compile/1` of `test/cases/create_ui_validation_test.exs`. Its header declares `:product`; a test that needs more resources declares them at the start of the body it passes.
- The naming functions of `Aurora.Uix.Layout.CreateUI` (`module_name/3`, `default_name/2`, `schema_hint/1`, `put_defaults/1`, `kinds/0`), called directly.
- `Aurora.UixWeb.Test.NamedModulesHost` (Modules & components step 14), a module that declares one pairing and generates nothing: its `auix_modules/0` and `auix_configurations/0`, and `Helpers.component_binding/3`, called directly.
- Routes under `"/named-modules-locations"` registered in `test/support/app_web/routes.ex`, inside the quote of `load_test_routes/0`, directly after the `"/navigation-except-products"` registration, as `RouteHelper.auix_live_resources("/named-modules-locations", NamedModulesTest.ProductLocation, index_live: :locations)`. `RoutesHelper.register_crud/2` always routes to `Index`, and this route exercises `index_live:`, as the `only:` and `except:` routes of UI-1 exercise theirs · layout types `:index`, `:form` · observable: `has_element?/2` on `input[name='product_location[reference]']`.
- Compile-time behaviour of the resources: `Code.compile_string/1` through the private `compile/1` of `test/cases/resource_metadata_validation_test.exs`, called twice in a test: first for the module that declares the resources to import, then for the module that imports them. `auix_resource/1` of the second module is read directly. No database.

##### Red tests
`CreateUI` is `Aurora.Uix.Layout.CreateUI`; `test/cases/create_ui_validation_test.exs` gains `alias Aurora.Uix.Layout.CreateUI`, directly before its `alias Aurora.Uix.Layout.Node`. `mod` is the module returned by `compile/1` that exports `auix_modules/0`: `{mod, _} = Enum.find(compiled, fn {m, _} -> function_exported?(m, :auix_modules, 0) end)`. `P` is `Aurora.Uix.Guides.Inventory.Product`, `I` is `Aurora.Uix.Guides.Inventory`.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | add to `test/cases/create_ui_validation_test.exs` | none | same | `"names are built from the caller, the schema hint and the atom"` | the four equalities of AC-1 |
| AC-2 | add to `test/cases/create_ui_validation_test.exs` | `compile("  auix_create_ui()\n")` | same | `"every generated module has a registry entry"` | `form = Module.concat(mod, Product.FormComponent)`; `index = Module.concat(mod, Product.Index)`; `mod.auix_modules() == %{product_form_component: form, product_index: index, product_show_component: Module.concat(mod, Product.ShowComponent)}`; `mod.auix_module(:product_form_component) == form`; `mod.auix_module(:nope) == nil`; `form.auix_kind() == :form_component`; `:reference in form.auix_fields()`; `%Node.Form{resource: nil} = form.auix_layout()`; `index.auix_kind() == :index_live`; `index.auix_fields() == []`; `index.auix_layout() == nil` |
| AC-3 | add to same | body: `auix_create_ui do` / `edit_layout :product, module_name: :reference_form do` / `inline [:reference, :name]` / `end` / `end` | same | `"module_name names the component of its layout"` | `form = mod.auix_module(:reference_form)`; `form == Module.concat(mod, Product.ReferenceForm)`; `form.auix_fields() == [:reference, :name]`; `refute Code.ensure_loaded?(Module.concat(mod, Product.FormComponent))` |
| AC-4 | add to same | body: `auix_create_ui do` / `index_live :product, module_name: :catalog` / `end` | same | `"an index_live line names the live view"` | `mod.auix_module(:catalog) == Module.concat(mod, Product.Catalog)`; `mod.auix_module(:catalog).auix_kind() == :index_live`; `refute Code.ensure_loaded?(Module.concat(mod, Product.Index))` |
| AC-5 | add to same | `compile("  auix_create_ui generate: [:form_component, :show_component]\n")` | same | `"generate chooses the kinds of module"` | `refute Code.ensure_loaded?(Module.concat(mod, Product.Index))`; `Enum.all?(mod.auix_modules(), fn {_name, module} -> module.auix_kind() != :index_live end)` |
| AC-6 | add to same | body starts with `auix_resource_metadata :product_compact, context: I, schema: P` (full module names), then `auix_create_ui()` | same | `"two resources on one schema need their own module names"` | `assert_raise DslError, ~r/module name :product_form_component is taken more than once/, fn -> compile(body) end` |
| AC-7 | add to same | body as AC-6, with `auix_create_ui do` / `edit_layout :product_compact, module_name: :form_component do` / `inline [:name]` / `end` / `show_layout :product_compact, module_name: :compact_show do` / `inline [:name]` / `end` / `index_live :product_compact, module_name: :compact` / `end` | same | `"two names for one module fail compilation"` | `assert_raise DslError, ~r/would be generated twice/, fn -> compile(body) end` |
| AC-8 | add to same | five bodies, none rejected by `build_node/1`. (a) `edit_layout :product, use: :nope`. (b) `edit_layout :product, use: :product_show_component`. (c) `edit_layout :product, use: :product_index`. (d) body starts with `auix_resource_metadata :product_location, context: I, schema: Aurora.Uix.Guides.Inventory.ProductLocation`, then `auix_create_ui do` / `edit_layout :product, module_name: :described do` / `inline [:reference, :description]` / `end` / `edit_layout :product_location, use: :described` / `end`. (e) `edit_layout :product, use: Enum` | same | `"use: rejects what it cannot take"` | one `assert_raise DslError, regex, fn -> … end` per body: (a) `~r/unknown module :nope in use:/`; (b) `~r/use: :product_show_component names :show_component/`; (c) `~r/names :index_live/`; (d) `~r/unknown fields \[:description\] for resource :product_location in use:/`; (e) `~r/unknown module Enum in use:/` |
| AC-8 | add to same | one body, the only `compile/1` call of its test: `edit_layout :product, use: :product_form_component do` / `inline [:name]` / `end`. `build_node/1` rejects it. After a `build_node/1` rejection Spark leaves `:recursive_builder_path` set in the process dictionary (`deps/spark/lib/spark/dsl/extension/entity.ex` `setup/6`), and every later `compile/1` call of the same test raises `RuntimeError` | same | `"use: takes no do block"` | `assert_raise DslError, ~r/use: takes no do block/, fn -> compile(body) end` |
| AC-8 | add to same | one body, the only `compile/1` call of its test, for the reason of the row above: `edit_layout :product, use: :product_form_component, module_name: :other` | same | `"use: takes no other option"` | `assert_raise DslError, ~r/use: takes no other option/, fn -> compile(body) end` |
| AC-9 | add to same | `compile("  auix_create_ui generate: [:index_live]\n")` | same | `"a live view needs its form and show components"` | `assert_raise DslError, ~r/the live view of :product needs a form component and a show component/, …` |
| AC-10 | add to same | body starts with `auix_resource_metadata :user, context: Aurora.Uix.Guides.Accounts, schema: Aurora.Uix.Guides.Accounts.User`, then `auix_create_ui()` | same | `"an embedded resource generates no modules"` | `mod.auix_modules() \|> Map.keys() \|> Enum.sort() == [:product_form_component, :product_index, :product_show_component, :user_form_component, :user_index, :user_show_component]`; `refute Code.ensure_loaded?(Module.concat(mod, Profile.Index))`; the same for `Profile.FormComponent`, `Profile.ShowComponent`, `Email.Index`; `Map.has_key?(mod.auix_configurations(), :user__profile)`; `Map.has_key?(mod.auix_configurations(), :user__emails)` |
| AC-11, AC-12 | new file (`ls test/cases_live \| grep named_modules` prints nothing) | two top-level modules in the file, see Modules & components step 14; `delete_all_inventory_data()`; `create_sample_product_locations(1)`; `[location] = Aurora.Uix.Repo.all(ProductLocation)`; `live(conn, "/named-modules-locations/#{location.id}/edit")` | `test/cases_live/named_modules_test.exs` | `"a used form component serves the resource of its host"` | `has_element?(view, "#auix-product_location-form input[name='product_location[reference]']")`; the same for `[name]`; `refute has_element?(view, "input[name='product_location[type]']")`; `view \|> form("#auix-product_location-form", product_location: %{name: "Renamed"}) \|> render_submit()`; `Aurora.Uix.Repo.get!(ProductLocation, location.id).name == "Renamed"`; `refute Code.ensure_loaded?(Aurora.UixWeb.Test.NamedModulesTest.ProductLocation.FormComponent)`; `refute Code.ensure_loaded?(Aurora.UixWeb.Test.NamedModulesTest.ProductLocation.Index)`; `Code.ensure_loaded?(Aurora.UixWeb.Test.NamedModulesTest.ProductLocation.Locations)` |
| AC-13 | add to `test/cases/create_ui_validation_test.exs` | body: `@auix_modules %{reference_form: nil}` then `auix_create_ui()` | same | `"an imported module must be a registry entry"` | `assert_raise DslError, ~r/@auix_modules entry :reference_form is not a generated module/, …` |
| AC-16 | add to `test/cases_live/named_modules_test.exs` | none; `T` is the test module, `Forms` is `Aurora.UixWeb.Test.NamedModulesForms` | same | `"an imported module is in the registry of its importer"` | `T.auix_module(:reference_form) == Forms.Product.ReferenceForm`; `Map.has_key?(T.auix_modules(), :reference_form)` |
| AC-17 | add to same | none; `PairingHost` is `Aurora.UixWeb.Test.NamedModulesHost` | same | `"a module declares a pairing without generating modules"` | `PairingHost.auix_modules() == %{}`; `configuration = PairingHost.auix_configurations().product_location`; `configuration.artifacts.form_component == Forms.Product.ReferenceForm`; `configuration.used == [:form_component]`; `refute Code.ensure_loaded?(Aurora.UixWeb.Test.NamedModulesHost.ProductLocation.FormComponent)`; the same for `ProductLocation.ShowComponent` and `ProductLocation.Index` |
| AC-18 | add to same | `binding = Aurora.Uix.Templates.Basic.Helpers.component_binding(PairingHost.auix_configurations(), :product_location, :form)` | same | `"component_binding/3 builds the options of a pairing"` | `%{resource_name: :product_location, layout_type: :form, modules: %{caller: PairingHost}, artifacts: %{form_component: module}, layout_tree: %Aurora.Uix.Layout.Node.Form{resource: :product_location} = tree} = binding`; `module == Forms.Product.ReferenceForm`; `tree \|> Aurora.Uix.Layout.Node.fields() \|> Enum.map(& &1.key) == [:reference, :name]`; `assert_raise KeyError, fn -> Aurora.Uix.Templates.Basic.Helpers.component_binding(PairingHost.auix_configurations(), :nope, :form) end` |
| AC-19 | add to `test/cases/resource_metadata_validation_test.exs` (the file has no `describe`; add the tests at its end) | `[{meta, _}] = compile(meta_body)`, where `meta_body` declares `auix_resource_metadata :product_transaction, context: Aurora.Uix.Guides.Inventory, schema: Aurora.Uix.Guides.Inventory.ProductTransaction`, the same for `:product_location` on `ProductLocation`, and `auix_resource_metadata :author, ash_resource: Aurora.Uix.Guides.Blog.Author`. `imports = "@auix_resource_metadata %{product_transaction: #{inspect(meta)}.auix_resource(:product_transaction), product_location: #{inspect(meta)}.auix_resource(:product_location)}"`; `declare = "auix_resource_metadata :catalog_product, context: Aurora.Uix.Guides.Inventory, schema: Aurora.Uix.Guides.Inventory.Product"`. Two bodies: `declare` then `imports`, and `imports` then `declare`; `[{mod, _}] = compile(body)` for each | same | `"a declared resource links its associations to imported resources"` | for both bodies: `fields = mod.auix_resource(:catalog_product).fields`; `fields.product_transactions.data.resource == :product_transaction`; `fields.product_location_id.data.resource == :product_location`; `fields.product_location_id.html_type == :select` |
| AC-19 | add to same | `meta` as above; body: `auix_resource_metadata :article, ash_resource: Aurora.Uix.Guides.Blog.Post` then `@auix_resource_metadata %{author: #{inspect(meta)}.auix_resource(:author)}` | same | `"a declared Ash resource links its associations to imported resources"` | `mod.auix_resource(:article).fields.author.data.resource == :author` |
| AC-20 | add to same | `meta` as above. (a) body: `imports`, `declare`, then `auix_resource_metadata :local_location, context: Aurora.Uix.Guides.Inventory, schema: Aurora.Uix.Guides.Inventory.ProductLocation`. (b) body: `@auix_resource_metadata %{nope: nil}` then `declare`. (c) body: `declare` alone | same | `"a declared resource wins, and a module without imports is unchanged"` | (a) `mod.auix_resource(:catalog_product).fields.product_location_id.data.resource == :local_location`; (b) the module compiles and `mod.auix_resource(:catalog_product).fields.product_transactions.data.resource == nil`; (c) `mod.auix_resource(:catalog_product).fields.product_transactions.data.resource == nil` |
| AC-21 | add to `test/cases/create_ui_validation_test.exs` | `tree = %Aurora.Uix.Layout.Node.Form{resource: :product, children: [%Aurora.Uix.Layout.Node.Field{key: :reference}]}`; `show = %Aurora.Uix.Layout.Node.Show{resource: :product}`; `options = %{layout_type: :form, layout_tree: tree, modules: %{caller: MyApp.Views}, module_name: "Product"}`; `defaults = CreateUI.put_defaults(options)` | same | `"options built by hand take the default artifacts"` | `%{index_live: MyApp.Views.Product.Index, form_component: MyApp.Views.Product.FormComponent, show_component: MyApp.Views.Product.ShowComponent} = defaults.artifacts`; `defaults.used == []`; `defaults.generate == CreateUI.kinds()`; `defaults.exposed_layouts == %{form_component: %{tree \| resource: nil}}`; `CreateUI.put_defaults(%{options \| layout_type: :show, layout_tree: show}).exposed_layouts == %{show_component: %{show \| resource: nil}}`; `CreateUI.put_defaults(defaults) == defaults`; `CreateUI.put_defaults(Map.put(options, :artifacts, %{form_component: Enum})).artifacts == %{form_component: Enum}` |

##### Modules & components
1. `lib/aurora_uix/layout/create_ui.ex` — modified: the naming functions and the registry code. The section adds no module for them: `lib/aurora_uix/layout/artifacts.ex` and `test/cases/artifacts_test.exs` do not exist after this section, and `.doctor.exs` is unchanged (its `ignore_modules` already holds `Aurora.Uix.Layout.CreateUI`, which covers the `def`s inside the quotes of `modules_code/1` and `module_code/2`). Every name of this step is new (`grep -rnE 'auix_modules|auix_module\b|schema_hint|def auix_(kind|fields|layout)\b|module_code|modules_code|default_name|put_defaults|default_artifacts|default_exposed_layouts|def kinds\b' lib test` prints nothing). Add `alias Aurora.Uix.Layout.CreateUI.IndexLive` directly after the `Call` alias. Directly after the aliases add:
   ```elixir
   @type kind() :: :index_live | :form_component | :show_component

   @component_kinds [form: :form_component, show: :show_component]

   @collision_hint "set module_name: on the layout of one of them, reuse a module with use:, or rename a live view with an index_live line"
   ```
   Public functions, placed directly after `layouts_code/1`, each with `@doc` (`## Parameters`, `## Returns`) and `@spec`:
   - `kinds/0`, `@spec kinds() :: [kind()]`, returns `[:index_live, :form_component, :show_component]`.
   - `schema_hint(schema)`, `@spec schema_hint(module()) :: binary()`, returns `schema |> Module.split() |> List.last()`.
   - `module_name(caller, schema_hint, name)`, `@spec module_name(module(), binary(), atom()) :: module()`, returns `Module.concat([caller, schema_hint, name |> Atom.to_string() |> Macro.camelize()])`. The name is the last segment as given: no suffix is added.
   - `default_name(schema_hint, kind)`, `@spec default_name(binary(), kind()) :: atom()`, returns `String.to_atom("#{Macro.underscore(schema_hint)}_index")` for `:index_live` and `String.to_atom("#{Macro.underscore(schema_hint)}_#{kind}")` for a component kind. `String.to_atom/1` stays here: a default name is a new atom (no source spells `:product_form_component`), so `String.to_existing_atom/1` raises `ArgumentError` for it. The atom is built at compile time from a schema module name, as `Aurora.Uix.Layout.Helpers.field_embedded_resource/2` builds the name of an embedded resource. The call runs only while the declaring module compiles, on the last segment of a schema module the host declared, and creates at most three atoms per resource (four after UI-7). The `@doc` states both sentences.
   - `modules_code(modules)`, `@spec modules_code(%{atom() => module()}) :: Macro.t()`, returns the quote that defines `auix_modules/0` and `auix_module/1`, in the shape of `ResourceMetadata.resource_functions_code/1` in `lib/aurora_uix/layout/resource_metadata.ex`. It puts no module attribute. `module_function/1` is private:
     ```elixir
     def modules_code(modules) do
       module_functions = Enum.map(modules, &module_function/1)

       quote do
         @doc """
         Gets the generated and imported modules by name.
         """
         @spec auix_modules() :: %{atom() => module()}
         def auix_modules do
           unquote(Macro.escape(modules))
         end

         unquote(module_functions)

         def auix_module(_), do: nil
       end
     end

     @spec module_function({atom(), module()}) :: Macro.t()
     defp module_function({name, module}) do
       quote do
         @doc """
         Gets a generated or imported module by name.
         """
         @spec auix_module(atom()) :: module() | nil
         def auix_module(unquote(name)), do: unquote(module)
       end
     end
     ```
   - `module_code(kind, layout)`, `@spec module_code(kind(), Node.layout() | nil) :: Macro.t()`, returns the quote every generated module evaluates in its body. It defines the three functions a generated module exposes:
     ```elixir
     def module_code(kind, layout) do
       fields = layout |> List.wrap() |> Node.fields() |> Enum.map(& &1.key) |> Enum.uniq()

       quote do
         @doc false
         @spec auix_kind() :: atom()
         def auix_kind, do: unquote(kind)

         @doc false
         @spec auix_fields() :: [atom()]
         def auix_fields, do: unquote(fields)

         @doc false
         @spec auix_layout() :: struct() | nil
         def auix_layout, do: unquote(Macro.escape(layout))
       end
     end
     ```
     `auix_kind/0` is the kind of the module. `auix_layout/0` is the layout the module was generated from, as written and not built, with `resource: nil`; it is `nil` for the index LiveView. `auix_fields/0` is the keys of the fields that layout places; it is `[]` for the index LiveView. `Node.fields/1` of `lib/aurora_uix/layout/node.ex` takes a list.
   - `put_defaults(options)`, `@spec put_defaults(map()) :: map()`, fills the four keys step 11 adds to the options of a generator, each one only when the options lack it. `ui_code/5` fills the four for every module `auix_create_ui` generates (step 11), and this function returns those options as they are. Options built by hand, as `test/aurora_uix/templates/basic/gettext_coverage_test.exs` builds them, take the module names the generators built before this section:
     ```elixir
     def put_defaults(options) do
       options
       |> Map.put_new_lazy(:artifacts, fn -> default_artifacts(options) end)
       |> Map.put_new(:used, [])
       |> Map.put_new(:generate, kinds())
       |> Map.put_new_lazy(:exposed_layouts, fn -> default_exposed_layouts(options) end)
     end

     @spec default_artifacts(map()) :: %{kind() => module()}
     defp default_artifacts(options) do
       caller = options.modules.caller
       hint = options.module_name

       %{
         index_live: module_name(caller, hint, :index),
         form_component: module_name(caller, hint, :form_component),
         show_component: module_name(caller, hint, :show_component)
       }
     end

     @spec default_exposed_layouts(map()) :: %{kind() => Node.layout()}
     defp default_exposed_layouts(%{layout_type: :form} = options),
       do: %{form_component: %{options.layout_tree | resource: nil}}

     defp default_exposed_layouts(%{layout_type: :show} = options),
       do: %{show_component: %{options.layout_tree | resource: nil}}

     defp default_exposed_layouts(_options), do: %{}
     ```
     `options.module_name` is the last segment of the schema module (`option_value/4`, clause `:module_name`, of `lib/aurora_uix/parsers/common.ex`): the schema hint. The default layout of a component is its built `layout_tree` with `resource: nil`. The three generators call the function while they generate a module, at compile time (step 12); no runtime code calls it.
2. `lib/aurora_uix/layout/create_ui.ex` — modified: the checks of the names and of the `use:` lines. Every name of this step is new (`grep -rnE 'validate_modules|module_names|used_layout|resource_modules|raise_naming_error|generated_module\?|using\?|layout_module_name|validate_imported|validate_index_lives|index_live_names|validate_collisions|validate_live_views|used_component|find_component|module_component|own_component|exposed_layout|defp targets\(|defp target\?' lib test` prints nothing). A **target** is a resource with `resource.schema != nil and not resource.embedded?`. A **generated module** is an atom `m` for which `match?({:module, _}, Code.ensure_compiled(m)) and function_exported?(m, :auix_kind, 0)` is `true`. Every error of this step is a `DslError` with `module:` the declaring module and `path: [:auix_create_ui]`.
   - `validate_modules/5` — public, placed directly after `validate_layouts/3`, with `@doc` (`## Parameters`: `module`, `layouts`, `resources`, `opts`, and `naming`, the map `%{index_lives: [IndexLive.t()], imported: %{atom() => module()}}`; `## Returns`: `:ok`, raising `Spark.Error.DslError` otherwise). `GenerateUI.transform/1` calls it directly after `validate_layouts/3` (step 10):
     ```elixir
     @spec validate_modules(module(), [Node.layout()], map(), keyword(), map()) :: :ok
     def validate_modules(module, layouts, resources, opts, naming) do
       :ok = validate_imported(naming.imported, module)
       :ok = validate_index_lives(module, resources, opts, naming)

       names = module_names(module, layouts, resources, opts, naming)
       :ok = validate_collisions(names, naming.imported, module)
       validate_live_views(names, layouts, module)
     end
     ```
     The checks, in order:
     1. Every value of `@auix_modules` is a generated module.
     2. An `index_live` line names a target, a target has one line at most, and a line needs `:index_live` in `generate:`.
     3. Names. Targets are visited in the order of their names. `hint = schema_hint(resource.schema)`. For every target and every pair `{:form, :form_component}`, `{:show, :show_component}` whose kind is in `generate:` and whose declared layout has `use: nil` (a missing layout counts as `use: nil`): the name is `layout.module_name`, and `default_name(hint, kind)` without one; the module is `module_name(caller, hint, layout.module_name)`, and `module_name(caller, hint, kind)` without one. For every target, when `:index_live` is in `generate:`: the name is `line.module_name`, and `default_name(hint, :index_live)` without a line; the module takes the segment `line.module_name`, and `:index` without a line.
     4. Collisions. Names are checked in `Enum.sort/1` order and the first offending one is reported. A name listed twice, and a listed name that is also a key of `@auix_modules`, raise the `is taken more than once` message, whose owners are the resource names of the name, inspected and joined with `", "`, plus the text `@auix_modules` for an imported name. Two names with one module raise the `would be generated twice` message.
     5. Live views. A target with a listed `:index_live` module needs, for the form and for the show, a listed module of that kind, and failing that a declared layout with `use:`.
   - `used_layouts/2` — private, called by `ui_code/5` (step 11). It returns the declared layouts with every `use:` layout replaced by the layout of the component it names. Rules:
     1. Form layouts are replaced first, then show layouts: a resource without a show layout shows a copy of its form (`put_missing_show/1`), and that form is already replaced when a show line reads it.
     2. A `use:` layout of a resource that `for:` leaves out is returned as written. A `use:` layout of a resource that is not a target raises the `is not available` message.
     3. The value of `use:` resolves to a component, first match: a key of `@auix_modules` gives the imported module; a name of `module_names/5` gives the module this declaring module generates for another resource, with the layout that resource declares (`RenderTree.default/3` for a missing one); a generated module gives itself. No match raises the `unknown module` message. A component of another kind, the index LiveView included, raises the `names` message. A field the component places that the resource lacks raises the `unknown fields` message.
     4. The replacement is `%{component.layout | resource: layout.resource, module_name: nil, use: component.module}`: after `used_layouts/2`, the `use` of a layout holds the module taken, and `nil` for a layout the declaring module generates from.
   - `resource_modules/4` — private, called by `build_configurations/5` (step 11). It returns the four keys of one resource: `artifacts` (`%{index_live: module | nil, form_component: module | nil, show_component: module | nil}`), `used` (the kinds taken with `use:`), `generate` (the kinds this declaring module generates for the resource) and `exposed_layouts` (for each generated component kind, the layout its module returns from `auix_layout/0`: the layout of the resource with `resource: nil`, `RenderTree.default/3` for a missing one). A resource that is not a target gets three `nil`, `[]`, `[]` and `%{}`.
   - The private functions, placed directly before the comment `# Builds the resource-specific layouts.`:
     ```elixir
     @spec raise_naming_error(module(), binary()) :: no_return()
     defp raise_naming_error(module, message),
       do: raise(DslError, module: module, path: [:auix_create_ui], message: message)

     # The resources `auix_create_ui` generates modules for, by name.
     @spec targets(map(), keyword()) :: [{atom(), Resource.t()}]
     defp targets(resources, opts) do
       resources
       |> filter_resources(opts[:for])
       |> Enum.filter(fn {_name, resource} -> target?(resource) end)
       |> Enum.sort_by(&elem(&1, 0))
     end

     @spec target?(Resource.t()) :: boolean()
     defp target?(resource), do: resource.schema != nil and not resource.embedded?

     # `Code.ensure_compiled/1` waits for a module that is still compiling.
     @spec generated_module?(term()) :: boolean()
     defp generated_module?(module) when is_atom(module) and not is_nil(module),
       do:
         match?({:module, _}, Code.ensure_compiled(module)) and
           function_exported?(module, :auix_kind, 0)

     defp generated_module?(_module), do: false

     @spec using?(Node.layout() | nil) :: boolean()
     defp using?(nil), do: false
     defp using?(%{use: nil}), do: false
     defp using?(_layout), do: true

     @spec layout_module_name(Node.layout() | nil) :: atom() | nil
     defp layout_module_name(nil), do: nil
     defp layout_module_name(layout), do: layout.module_name

     @spec validate_imported(map(), module()) :: :ok
     defp validate_imported(imported, module) do
       Enum.each(imported, fn {name, imported_module} ->
         if not generated_module?(imported_module),
           do:
             raise_naming_error(
               module,
               "@auix_modules entry #{inspect(name)} is not a generated module; take it from auix_module/1"
             )
       end)
     end

     @spec validate_index_lives(module(), map(), keyword(), map()) :: :ok
     defp validate_index_lives(module, resources, opts, naming) do
       target_names = resources |> targets(opts) |> Enum.map(&elem(&1, 0))
       generate = Keyword.get(opts, :generate, kinds())

       _seen =
         Enum.reduce(naming.index_lives, [], fn line, seen ->
           cond do
             line.resource not in target_names ->
               raise_naming_error(module, "unknown resource #{inspect(line.resource)}")

             line.resource in seen ->
               raise_naming_error(
                 module,
                 "#{inspect(line.resource)} has more than one index_live line"
               )

             :index_live not in generate ->
               raise_naming_error(
                 module,
                 "index_live #{inspect(line.resource)} needs :index_live in generate:"
               )

             true ->
               [line.resource | seen]
           end
         end)

       :ok
     end

     # The names of the modules this module generates: `{name, kind, resource_name, module}`.
     @spec module_names(module(), [Node.layout()], map(), keyword(), map()) ::
             [{atom(), kind(), atom(), module()}]
     defp module_names(module, layouts, resources, opts, naming) do
       generate = Keyword.get(opts, :generate, kinds())

       resources
       |> targets(opts)
       |> Enum.flat_map(fn {resource_name, resource} ->
         hint = schema_hint(resource.schema)
         declared = resource_layouts(layouts, resource_name)

         components =
           @component_kinds
           |> Enum.filter(fn {layout_type, kind} ->
             kind in generate and not using?(Map.get(declared, layout_type))
           end)
           |> Enum.map(fn {layout_type, kind} ->
             given = declared |> Map.get(layout_type) |> layout_module_name()

             {given || default_name(hint, kind), kind, resource_name,
              module_name(module, hint, given || kind)}
           end)

         components ++ index_live_names(module, {resource_name, hint}, naming.index_lives, generate)
       end)
     end

     @spec index_live_names(module(), {atom(), binary()}, [IndexLive.t()], [kind()]) ::
             [{atom(), kind(), atom(), module()}]
     defp index_live_names(module, {resource_name, hint}, index_lives, generate) do
       if :index_live in generate do
         given =
           index_lives
           |> Enum.find(&(&1.resource == resource_name))
           |> layout_module_name()

         [
           {given || default_name(hint, :index_live), :index_live, resource_name,
            module_name(module, hint, given || :index)}
         ]
       else
         []
       end
     end

     @spec validate_collisions(list(), map(), module()) :: :ok
     defp validate_collisions(names, imported, module) do
       by_name = Enum.group_by(names, &elem(&1, 0))

       by_name
       |> Map.keys()
       |> Enum.sort()
       |> Enum.each(&validate_name(&1, Map.fetch!(by_name, &1), imported, module))

       _seen =
         names
         |> Enum.sort_by(&elem(&1, 0))
         |> Enum.reduce(%{}, &validate_module(&1, &2, module))

       :ok
     end

     @spec validate_name(atom(), list(), map(), module()) :: :ok
     defp validate_name(name, rows, imported, module) do
       owners = Enum.map(rows, &inspect(elem(&1, 2)))
       imported? = Map.has_key?(imported, name)

       if length(owners) > 1 or imported? do
         owners_text =
           if imported?,
             do: Enum.join(owners, ", ") <> ", @auix_modules",
             else: Enum.join(owners, ", ")

         raise_naming_error(
           module,
           "module name #{inspect(name)} is taken more than once (#{owners_text}); #{@collision_hint}"
         )
       end

       :ok
     end

     @spec validate_module(tuple(), map(), module()) :: map()
     defp validate_module({name, _kind, _resource_name, generated}, seen, module) do
       case Map.fetch(seen, generated) do
         {:ok, other_name} ->
           raise_naming_error(
             module,
             "#{inspect(generated)} would be generated twice, as #{inspect(other_name)} and #{inspect(name)}; #{@collision_hint}"
           )

         :error ->
           Map.put(seen, generated, name)
       end
     end

     @spec validate_live_views(list(), [Node.layout()], module()) :: :ok
     defp validate_live_views(names, layouts, module) do
       names
       |> Enum.filter(fn {_name, kind, _resource_name, _module} -> kind == :index_live end)
       |> Enum.each(fn {_name, _kind, resource_name, _module} ->
         declared = resource_layouts(layouts, resource_name)

         complete? =
           Enum.all?(@component_kinds, fn {layout_type, kind} ->
             using?(Map.get(declared, layout_type)) or
               Enum.any?(names, &match?({_name, ^kind, ^resource_name, _module}, &1))
           end)

         if not complete?,
           do:
             raise_naming_error(
               module,
               "the live view of #{inspect(resource_name)} needs a form component and a show component; add :form_component and :show_component to generate:, or name them with use:"
             )
       end)
     end

     # Replaces every `use:` layout by the layout of the component it names, bound to the resource
     # of the line. Forms go first: a missing show layout is a copy of the form.
     @spec used_layouts([Node.layout()], map()) :: [Node.layout()]
     defp used_layouts(layouts, context) do
       Enum.reduce(@component_kinds, layouts, fn component_kind, layouts ->
         Enum.map(layouts, &used_layout(&1, component_kind, layouts, context))
       end)
     end

     @spec used_layout(Node.layout(), {atom(), kind()}, [Node.layout()], map()) :: Node.layout()
     defp used_layout(%{use: nil} = layout, _component_kind, _layouts, _context), do: layout

     defp used_layout(%{use: name} = layout, {layout_type, _kind} = component_kind, layouts, context) do
       case {layout_type(layout), Map.fetch(context.resources, layout.resource)} do
         {^layout_type, {:ok, resource}} ->
           component =
             used_component(name, component_kind, {layout.resource, resource}, layouts, context)

           %{component.layout | resource: layout.resource, module_name: nil, use: component.module}

         _other ->
           layout
       end
     end

     defp used_layout(layout, _component_kind, _layouts, _context), do: layout

     @spec used_component(atom(), {atom(), kind()}, {atom(), Resource.t()}, [Node.layout()], map()) ::
             map()
     defp used_component(name, {layout_type, kind}, {resource_name, resource}, layouts, context) do
       if not target?(resource),
         do:
           raise_naming_error(
             context.caller,
             "use: is not available for #{inspect(resource_name)}, an embedded resource"
           )

       component =
         case find_component(name, layouts, context) do
           %{kind: ^kind} = component ->
             component

           nil ->
             raise_naming_error(
               context.caller,
               "unknown module #{inspect(name)} in use:; declare it with module_name:, import it with @auix_modules, or give the module auix_module/1 returns"
             )

           other ->
             raise_naming_error(
               context.caller,
               "use: #{inspect(name)} names #{inspect(other.kind)}; the #{layout_type} layout of #{inspect(resource_name)} takes #{inspect(kind)}"
             )
         end

       missing = Enum.reject(component.fields, &Map.has_key?(resource.fields, &1))

       if missing != [],
         do:
           raise_naming_error(
             context.caller,
             "unknown fields #{inspect(missing)} for resource #{inspect(resource_name)} in use: #{inspect(name)}"
           )

       component
     end

     # The component a `use:` names: imported, generated by this module, or a generated module.
     @spec find_component(atom(), [Node.layout()], map()) :: map() | nil
     defp find_component(name, layouts, context) do
       own = Enum.find(context.names, &(elem(&1, 0) == name))

       cond do
         Map.has_key?(context.imported, name) ->
           context.imported |> Map.fetch!(name) |> module_component()

         own != nil ->
           own_component(own, layouts, context)

         generated_module?(name) ->
           module_component(name)

         true ->
           nil
       end
     end

     @spec module_component(module()) :: map()
     defp module_component(module),
       do: %{
         module: module,
         kind: module.auix_kind(),
         fields: module.auix_fields(),
         layout: module.auix_layout()
       }

     @spec own_component(tuple(), [Node.layout()], map()) :: map()
     defp own_component({_name, :index_live, _resource_name, module}, _layouts, _context),
       do: %{module: module, kind: :index_live, fields: [], layout: nil}

     defp own_component({_name, kind, resource_name, module}, layouts, context) do
       {layout_type, ^kind} = List.keyfind(@component_kinds, kind, 1)

       layout =
         layouts
         |> resource_layouts(resource_name)
         |> put_missing_show()
         |> Map.get(layout_type)
         |> exposed_layout(layout_type, Map.fetch!(context.resources, resource_name), context.opts)

       fields = layout |> Node.fields() |> Enum.map(& &1.key) |> Enum.uniq()
       %{module: module, kind: kind, fields: fields, layout: layout}
     end

     # The layout a generated component returns from `auix_layout/0`.
     @spec exposed_layout(Node.layout() | nil, atom(), Resource.t(), keyword()) :: Node.layout()
     defp exposed_layout(nil, layout_type, resource, opts),
       do: %{RenderTree.default(layout_type, resource, opts) | resource: nil}

     defp exposed_layout(layout, _layout_type, _resource, _opts), do: %{layout | resource: nil}

     # The modules of one resource: generated here, or taken with `use:`.
     @spec resource_modules({atom(), Resource.t()}, map(), list(), keyword()) :: map()
     defp resource_modules({resource_name, resource}, layouts, names, opts) do
       generated =
         names
         |> Enum.filter(fn {_name, _kind, owner, _module} -> owner == resource_name end)
         |> Map.new(fn {_name, kind, _owner, module} -> {kind, module} end)

       used =
         @component_kinds
         |> Enum.filter(fn {layout_type, _kind} -> using?(Map.get(layouts, layout_type)) end)
         |> Map.new(fn {layout_type, kind} -> {kind, Map.fetch!(layouts, layout_type).use} end)

       exposed_layouts =
         @component_kinds
         |> Enum.filter(fn {_layout_type, kind} -> Map.has_key?(generated, kind) end)
         |> Map.new(fn {layout_type, kind} ->
           {kind, exposed_layout(Map.get(layouts, layout_type), layout_type, resource, opts)}
         end)

       %{
         artifacts:
           %{index_live: nil, form_component: nil, show_component: nil}
           |> Map.merge(generated)
           |> Map.merge(used),
         used: Enum.filter([:form_component, :show_component], &Map.has_key?(used, &1)),
         generate: Enum.filter(kinds(), &Map.has_key?(generated, &1)),
         exposed_layouts: exposed_layouts
       }
     end
     ```
     The clauses of `using?/1`, `layout_module_name/1` and `used_layout/4` match `nil` in their heads: `Credo.Check.Refactor.NegatedIsNil` of `.credo.exs` rejects a `not is_nil/1` guard. `layout_module_name/1` reads the `module_name` of a layout and of an `index_live` line.
3. `Aurora.Uix.Layout.CreateUI.IndexLive` at `lib/aurora_uix/layout/create_ui/index_live.ex` — new (`grep -rn 'CreateUI.IndexLive' lib test` prints nothing). `defstruct resource: nil, module_name: nil, __spark_metadata__: nil`, `@type t()`, `@moduledoc` with `## Key Features` (one `index_live` line of `auix_create_ui`: the resource and the name of its LiveView) and `## Key Constraints` (it names a module; it is not a layout and has no fields).
4. `lib/aurora_uix/layout/node/form.ex` and `lib/aurora_uix/layout/node/show.ex` — modified. Add `module_name: nil` and `use: nil` to `defstruct`, directly after `handler_module: nil`, and `module_name: atom() | nil`, `use: atom() | nil` to `@type t()`. Add one line to `## Key Features`: `` `module_name` names the generated component; `use` names the component taken instead of generating one. ``
5. `lib/aurora_uix/layout/create_ui/call.ex` — modified. Add `generate: nil` after `include: nil` and `index_lives: []` after `children: []` in `defstruct`; add `generate: [atom()] | nil` and `index_lives: [Aurora.Uix.Layout.CreateUI.IndexLive.t()]` to `@type t()`; extend the `## Key Constraints` sentence to list `generate` with `renderers`, `default_fields_layout` and `include`.
6. `lib/aurora_uix/layout/create_ui/dsl.ex` — modified.
   - `@ui_schema`: append `generate: [type: {:list, {:in, [:index_live, :form_component, :show_component]}}, doc: "The kinds of module to generate. Defaults to all of them."]`.
   - `@edit_layout` schema: append `module_name: [type: :atom, doc: "Names the generated component."]` and `use: [type: :atom, doc: "Takes a component instead of generating one: a name of the registry or a generated module. No block, no other option."]`. `@show_layout` is built from `@edit_layout` and takes both. Spark reads the keywords of a layout line without a block as entity options, so these two keys carry `edit_layout :r, use: :x`; a line with a block carries its keywords in `layout_opts`.
   - New entity, defined before `@create_ui` (`grep -n 'index_live' lib/aurora_uix/layout/create_ui/dsl.ex` prints nothing): `@index_live %Entity{name: :index_live, describe: "Names the LiveView of a resource.", target: Aurora.Uix.Layout.CreateUI.IndexLive, args: [:resource], schema: [resource: [type: :atom, required: true, doc: "The resource."], module_name: [type: :atom, required: true, doc: "The name of the LiveView."]]}`. Alias `Aurora.Uix.Layout.CreateUI.IndexLive` in alphabetical position.
   - `@create_ui`: `entities: [children: @layouts, index_lives: [@index_live]]`. `@create_layout` is unchanged.
   - `typed_keys/2`, second clause (`_layout_type`): return `[:renderers, :module_name, :use, handler_key]`. The `:index` clause is unchanged, so `module_name:` and `use:` on `index_columns` stay unknown options until UI-7.
   - `container_opts/2`: add `module_name: typed[:module_name]` and `use: typed[:use]` to the returned map.
   - `build_node(%module{} = layout) when module in [Node.Form, Node.Show]`: after `container_opts/2` succeeds, add the step `:ok <- validate_naming(layout, container)` and build the node as `struct(layout, %{container | module_name: container.module_name || layout.module_name, use: layout.use})`. New private function (`grep -rn 'validate_naming' lib` prints nothing):
     ```elixir
     @spec validate_naming(Node.layout(), map()) :: :ok | {:error, binary()}
     defp validate_naming(layout, %{use: nil}), do: validate_use_options(layout)
     defp validate_naming(_layout, _container), do: {:error, "use: takes no do block"}

     @spec validate_use_options(Node.layout()) :: :ok | {:error, binary()}
     defp validate_use_options(%{use: nil}), do: :ok
     defp validate_use_options(%{module_name: nil}), do: :ok
     defp validate_use_options(_layout), do: {:error, "use: takes no other option"}
     ```
     The clauses match `nil` in their heads: `Credo.Check.Refactor.NegatedIsNil` of `.credo.exs` rejects a `not is_nil/1` guard. `validate_use_options/1` is new with it (`grep -rn 'validate_use_options' lib` prints nothing).
   - `build_node(%Node.Index{})`: unchanged. `struct/2` ignores the two new keys of the container map.
   - `@moduledoc` `## Key Features`: add `index_live` to the entities the section holds.
7. `lib/aurora_uix/resource.ex` — modified. Add `embedded?: false` to `defstruct` after `resolved?: false`, `embedded?: boolean()` to `@type t()`, and the `@moduledoc` line `` - `embedded?` (`boolean`) - `true` for a resource the library created for an embedded field. ``
8. `lib/aurora_uix/layout/resource_metadata.ex`, `add_embedded_resources/1` — modified. The parsers prepend the resources they create, so the created ones are the head of the result:
   ```elixir
   defp add_embedded_resources(resources) do
     with_embedded =
       resources
       |> Enum.reject(&is_nil(&1.schema))
       |> Enum.reduce(resources, fn resource, result ->
         resource.type
         |> LayoutHelpers.get_fields_parser_module()
         |> then(& &1.embedded_resource({resource.name, resource.schema, resource.type}, result))
       end)

     {created, declared} = Enum.split(with_embedded, length(with_embedded) - length(resources))
     Enum.map(created, &struct(&1, %{embedded?: true})) ++ declared
   end
   ```
   Load guarantee: `embedded_resource/2` of `lib/aurora_uix/integration/ctx/fields_parser.ex` and of `lib/aurora_uix/integration/ash/fields_parser.ex` both return `[%Resource{…} | result]` from `embedded_resource_config/3`. A resource the host declares under the same name stays `embedded?: false` and wins in `resolve_resources/1`, because `Map.new/1` keeps the last pair. No parser file changes.
9. `lib/aurora_uix/uix.ex`, `__using__/1` — add `Module.register_attribute(__MODULE__, :auix_modules, accumulate: true)` directly after the `:auix_resource_metadata` registration.
10. `lib/aurora_uix/layout/create_ui/generate_ui.ex` — modified. In the `[ui]` branch, directly after the line `:ok = CreateUI.validate_layouts(layouts, resources, module)`, add `naming = %{index_lives: ui.index_lives, imported: imported_modules(module)}` and `:ok = CreateUI.validate_modules(module, layouts, resources, opts, naming)`. The call `CreateUI.ui_code(layouts, resources, opts)` becomes `CreateUI.ui_code(layouts, resources, opts, naming)`. New private function (`grep -rn 'imported_modules' lib` prints nothing):
    ```elixir
    # The modules a module imports by writing `@auix_modules` by hand.
    @spec imported_modules(module()) :: map()
    defp imported_modules(module) do
      module
      |> Module.get_attribute(:auix_modules, [])
      |> Enum.reduce(%{}, &Map.merge(&2, &1))
    end
    ```
11. `lib/aurora_uix/layout/create_ui.ex` — modified.
    - `ui_opts/1`: `Map.take([:renderers, :default_fields_layout, :include, :generate])`.
    - `ui_code/4` becomes `ui_code/5`: `@spec ui_code(module(), [Node.layout()], map(), keyword(), map()) :: Macro.t()`, fifth parameter `naming` (the map `validate_modules/5` takes: `index_lives` and `imported`), documented in `@doc`. Its only caller is `GenerateUI.transform/1` (step 10). The body starts as follows, up to the unchanged line `resource_preloads = extract_resource_preloads(configurations)`:
      ```elixir
      def ui_code(module, declared_layouts, resources, opts, naming) do
        resources =
          resources
          |> Map.new(fn {name, resource} -> {name, Resource.resolve(resource)} end)
          |> filter_resources(opts[:for])
          |> Map.new()

        names = module_names(module, declared_layouts, resources, opts, naming)

        layouts =
          used_layouts(declared_layouts, %{
            caller: module,
            resources: resources,
            names: names,
            imported: naming.imported,
            opts: opts
          })

        configurations =
          resources
          |> Enum.reduce(
            [],
            &[build_configurations(module, &1, layouts, names, opts) | &2]
          )
          |> Enum.reject(&is_nil/1)
          |> Map.new()

        registry =
          Map.merge(
            naming.imported,
            Map.new(names, fn {name, _kind, _resource_name, generated} -> {name, generated} end)
          )
      ```
      The rest of the body is unchanged. Add `unquote(modules_code(registry))` to the returned quote, directly after `unquote(layouts_code(declared_layouts))`. `auix_layouts/0` keeps returning the declared layouts, a `use:` line as written. `auix_modules/0` and `auix_module/1` return an imported module under the atom the importing module gave it. A module named directly in `use:` gets no name and is not in the registry.
    - `build_configurations/4` becomes `build_configurations/5`: new fourth parameter `names`, the list of `module_names/5`; `@spec build_configurations(module(), {atom(), map()}, [Node.layout()], list(), keyword()) :: map() | nil`. Its only caller is `ui_code/5`. The `layouts =` block becomes `layouts = declared_layouts |> resource_layouts(resource_config_name) |> put_missing_show()`, with the new private function (`grep -rn 'defp resource_layouts' lib` prints nothing), placed directly before the comment `# Builds the configuration for a single resource.`:
      ```elixir
      @spec resource_layouts([Node.layout()], atom()) :: map()
      defp resource_layouts(declared_layouts, name) do
        declared_layouts
        |> Enum.filter(&(&1.resource == name))
        |> Map.new(&{layout_type(&1), &1})
      end
      ```
      `layout_trees` keeps `RenderTree.build(Map.get(layouts, tag), tag, resource_config, opts)`. Add five keys to the returned configuration: `modules`: `%{caller: caller, module: resource_module, web: find_web_module(caller), context: resource_config.context}`, the map `build_resource_layouts/3` builds today; and `artifacts`, `used`, `generate` and `exposed_layouts`, merged from `resource_modules({resource_config_name, resource_config}, layouts, names, opts)` (step 2). `auix_configurations/0` returns the five keys for every resource with a schema. Every reader of a configuration takes its keys by name (`parsed_opts`, `resource_config`, `layout_trees`), so no reader changes.
    - `put_missing_show/1` stays where it is. In its second clause, the line `|> Map.put(:handler_module, Keyword.get(form.options, :show_handler_module))` becomes `|> Map.merge(%{handler_module: Keyword.get(form.options, :show_handler_module), module_name: nil, use: nil})`: the copy takes neither the name nor the `use:` of the form, so the show component of a resource whose form is taken with `use:` is generated from the layout of that form.
    - `build_resource_layouts/3`, first clause: bind `modules`, `artifacts`, `used`, `generate` and `exposed_layouts` from the configuration, and delete the `web`, `resource_module` and `modules` computations of the body; the `Enum.each(modules, …)` line stays. Return `[]` when `resource_config.embedded?`. Otherwise reduce over `Enum.filter(layout_tags, &generate_tag?(&1, generate))` and pass `artifacts`, `used`, `generate` and `exposed_layouts` in the first argument of `generate_module/4`. New private function:
      ```elixir
      @spec generate_tag?(atom(), [atom()]) :: boolean()
      defp generate_tag?(:index, generate), do: :index_live in generate
      defp generate_tag?(:form, generate), do: :form_component in generate
      defp generate_tag?(:show, generate), do: :show_component in generate
      defp generate_tag?(_tag, _generate), do: true
      ```
    - `generate_module/4`: add `|> Map.put(:artifacts, layout.artifacts) |> Map.put(:used, layout.used) |> Map.put(:generate, layout.generate) |> Map.put(:exposed_layouts, layout.exposed_layouts)` before the template call.
    - `@moduledoc`: add a `## Generated modules` section before `## Key Features`, stating: the default names (`:<schema>_index` for the LiveView, `:<schema>_form_component`, `:<schema>_show_component`); `module_name:` on `edit_layout` and `show_layout`, used as the last segment of the module as given; `index_live resource, module_name: name`; `use:` with a name of the registry and with a generated module, and what it checks; `@auix_modules` with `auix_module/1`; `auix_modules/0`, which maps the names of the generated and the imported modules to the modules; `auix_kind/0`, `auix_fields/0` and `auix_layout/0` of a generated module; `generate:`; `generate: []` with `use:` lines for a module that only declares pairings, a LiveView written by hand included. Add to `## Key Constraints`: `Two generated modules with one name, or two names for one module, do not compile.`, `A resource created for an embedded field generates no modules.` and `Two modules that import from each other do not compile.`
    - Contract change for a custom template (`Aurora.Uix.Template.generate_module/1`): the map it receives gains `artifacts`, `used`, `generate` and `exposed_layouts`, and the callback is no longer invoked for a `:form` tag without `:form_component` in `generate`, a `:show` tag without `:show_component`, an `:index` tag without `:index_live`, and any tag of an embedded resource. A module a custom template generates evaluates `CreateUI.module_code/2` in its body; without the three functions, `@auix_modules` and `use:` reject it (step 2). The three generators of the Basic template also take the map without the four keys: `CreateUI.put_defaults/1` (step 1) fills them (step 12, AC-21).
12. Basic template — modified.
    - `lib/aurora_uix/templates/basic/modules_generator.ex`: add the public function (new: `grep -rn 'component_opts' lib test` prints nothing), with `@doc` and `@spec component_opts(map()) :: map()`:
      ```elixir
      def component_opts(parsed_opts) do
        cleaned_parsed_opts = remove_omitted_fields(parsed_opts)

        one2many_preload =
          cleaned_parsed_opts
          |> Helpers.extract_association_preload()
          |> Map.get(:one_to_many_association, [])

        one2many_rendered? =
          cleaned_parsed_opts
          |> Map.get(:layout_tree)
          |> Node.fields()
          |> Enum.any?(&(&1.key in one2many_preload))

        Map.put(cleaned_parsed_opts, :one2many_rendered?, one2many_rendered?)
      end
      ```
      Add `alias Aurora.Uix.Layout.Node` and `alias Aurora.Uix.Templates.Basic.Helpers`. `module_name/2` stays, unchanged; no library code calls it after this section.
    - `generators/form_generator.ex`: `parsed_opts = parsed_opts |> CreateUI.put_defaults() |> ModulesGenerator.component_opts()` replaces the `cleaned_parsed_opts`, `one2many_preload`, `one2many_rendered?` and `parsed_opts = Map.put(…)` computations; `field_labels` reads `parsed_opts`; `form_component = parsed_opts.artifacts.form_component`; `handler_module = ModulesGenerator.handler_module(parsed_opts, FormHandler)`. In the generated module, directly after the line `use Aurora.Uix.GettextResolver`, add `unquote(CreateUI.module_code(:form_component, Map.fetch!(parsed_opts.exposed_layouts, :form_component)))`. Add `alias Aurora.Uix.Layout.CreateUI`. Delete the aliases that become unused (`Aurora.Uix.Layout.Node`).
    - `generators/show_component_generator.ex`: the same replacement; `show_component = parsed_opts.artifacts.show_component`. In the generated module, directly after the line `use unquote(parsed_opts.modules.web), :live_component`, add `unquote(CreateUI.module_code(:show_component, Map.fetch!(parsed_opts.exposed_layouts, :show_component)))`. Add `alias Aurora.Uix.Layout.CreateUI`. Delete the unused `Node` alias.
    - `generators/index_generator.ex`: the line `parsed_opts = ModulesGenerator.remove_omitted_fields(parsed_opts)` becomes `parsed_opts = parsed_opts |> CreateUI.put_defaults() |> ModulesGenerator.remove_omitted_fields()`; `index_module = parsed_opts.artifacts.index_live`. In the generated module, directly after the line `use unquote(parsed_opts.modules.web), :live_view`, add `unquote(CreateUI.module_code(:index_live, nil))`. Add `alias Aurora.Uix.Layout.CreateUI`.
    - Load guarantee for the three generators: `parsed_opts.exposed_layouts` holds the kind of every component this module generates for the resource (`resource_modules/4`, step 2), and `generate_module/4` of `create_ui.ex` is called only for those kinds (`generate_tag?/2`, step 11). Options that reach a generator without the keys take them from `CreateUI.put_defaults/1` (step 1), which gives `artifacts` the module of every kind and `exposed_layouts` the layout of the kind of the generator; the options a generator compiles into its module carry the filled keys, so `index_impl.ex` reads `auix.artifacts` and `auix.used` for such a LiveView too.
    - `lib/aurora_uix/templates/basic/helpers.ex`: add the public function (new: `grep -rn 'component_binding' lib test` prints nothing), with `@doc` (`## Parameters`, `## Returns`) and `@spec`. It returns the options a component runs with to serve `resource_name` of the module whose `auix_configurations/0` returned `configurations`. This one function serves the generated LiveView (next item) and a component given the input `resource` (UI-5, UI-7):
      ```elixir
      @spec component_binding(map(), atom(), :form | :show) :: map()
      def component_binding(configurations, resource_name, layout_type) do
        configuration = Map.fetch!(configurations, resource_name)

        configuration.parsed_opts
        |> Map.merge(Map.take(configuration, [:modules, :artifacts, :used, :generate]))
        |> Map.merge(%{
          configurations: configurations,
          resource_name: resource_name,
          layout_type: layout_type,
          layout_tree: Map.fetch!(configuration.layout_trees, layout_type)
        })
        |> ModulesGenerator.component_opts()
      end
      ```
      Add `alias Aurora.Uix.Templates.Basic.ModulesGenerator`. The merged keys are the ones `generate_module/4` of `create_ui.ex` puts in the options of a module it generates (step 11), without `exposed_layouts`, which no runtime code reads. Load guarantee: `auix.configurations` of a generated module and `auix_configurations/0` of its declaring module are the same map (`preload_configurations` in `ui_code/5`); `configurations[name]` carries `parsed_opts` with `:preload` (`build_resource_preload_option/2`), `layout_trees`, and `modules`, `artifacts`, `used`, `generate` (step 11).
    - `lib/aurora_uix/templates/basic/handlers/index_impl.ex`: in `auix_mount/3`, `form_component = auix.artifacts.form_component` and `show_component = auix.artifacts.show_component`. `assign_live_component/1`: the `:show` clause assigns `auix.artifacts.show_component` to `:live_component` and `live_component_binding(auix, :show_component, :show)` to `:live_component_binding`; the other clause assigns `auix.artifacts.form_component` and `live_component_binding(auix, :form_component, :form)`. New private function (`grep -rn 'live_component_binding' lib test` prints nothing):
      ```elixir
      # A component this module generated already holds these options.
      @spec live_component_binding(map(), atom(), :form | :show) :: map()
      defp live_component_binding(%{used: used} = auix, kind, layout_type) do
        if kind in used,
          do: BasicHelpers.component_binding(auix.configurations, auix.resource_name, layout_type),
          else: %{}
      end
      ```
      Load guarantee: `auix.used`, `auix.configurations` and `auix.resource_name` come from the LiveView's compiled options (`generate_module/4`, step 11). Delete the module-level `alias Aurora.Uix.Templates.Basic.ModulesGenerator`; the alias inside the `__using__/1` quote stays, because host handlers compiled with it may call the module.
    - `lib/aurora_uix/templates/basic/renderers/index_renderer.ex`: in the `<.live_component>` of the modal, the `auix` attribute becomes `Map.merge(Map.get(@auix, :live_component_binding, %{}), %{entity: …})`, the second map being today's literal map, unchanged. A component the module generated receives the same assigns as today.
    - How a used component takes the resource: the hosted `update/2` clause of both component generators assigns the incoming `auix` first, and `Helpers.assign_parsed_opts/2` (`Map.merge(parsed_opts, existing)`) lets the keys already in the socket win over the compiled ones. The generators need no other change.
13. `lib/aurora_uix/helpers/route_helper.ex`, `auix_live_resources/3` — modified. Read `index_live = opts |> Keyword.get(:index_live, :index) |> index_live_module(module)` and use `unquote(index_live)` in place of the five `unquote(module).Index`. New private function (`grep -rn 'index_live_module' lib test` prints nothing):
    ```elixir
    # The module `unquote(module).Index` names, for a LiveView of any name.
    @spec index_live_module(atom(), Macro.t()) :: Macro.t()
    defp index_live_module(name, module) when is_atom(name) do
      segment = name |> Atom.to_string() |> Macro.camelize()

      quote do
        Module.concat(unquote(module), unquote(segment))
      end
    end
    ```
    The route names its LiveView with the expression `Module.concat(MyApp.UserLive, "CompactProducts")`, which `Phoenix.LiveView.Router.live/4` evaluates in the router (`quote bind_quoted: binding()`). `route_helper.ex` calls no `String.to_atom/1`: the camelized segment is no atom when the router compiles, so `String.to_existing_atom/1` raises `ArgumentError` for it. `@doc`: add `:index_live` to the options (`` `:index_live` (atom()) - The name given to the LiveView with an `index_live` line. Defaults to `:index`. ``) and one example with `index_live: :compact_products` expanding to `MyApp.UserLive.CompactProducts`.
14. Test modules of `test/cases_live/named_modules_test.exs`, in this order:
    ```elixir
    defmodule Aurora.UixWeb.Test.NamedModulesForms do
      use Aurora.Uix

      alias Aurora.Uix.Guides.Inventory
      alias Aurora.Uix.Guides.Inventory.Product
      alias Aurora.Uix.Guides.Inventory.ProductLocation

      auix_resource_metadata(:product, context: Inventory, schema: Product)
      auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)

      auix_create_ui generate: [:form_component, :show_component] do
        edit_layout :product, module_name: :reference_form do
          inline([:reference, :name])
        end
      end
    end

    defmodule Aurora.UixWeb.Test.NamedModulesHost do
      use Aurora.Uix

      alias Aurora.UixWeb.Test.NamedModulesForms

      @auix_resource_metadata %{
        product_location: NamedModulesForms.auix_resource(:product_location)
      }

      auix_create_ui generate: [] do
        edit_layout(:product_location, use: NamedModulesForms.auix_module(:reference_form))
      end
    end

    defmodule Aurora.UixWeb.Test.NamedModulesTest do
      use Aurora.UixWeb.Test.UICase, :phoenix_case
      use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

      alias Aurora.Uix.Guides.Inventory
      alias Aurora.Uix.Guides.Inventory.ProductLocation
      alias Aurora.UixWeb.Test.NamedModulesForms

      @auix_modules %{reference_form: NamedModulesForms.auix_module(:reference_form)}

      auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)

      auix_create_ui do
        edit_layout(:product_location, use: :reference_form)
        index_live(:product_location, module_name: :locations)
      end

      # the tests of the AC-11, AC-12, AC-16, AC-17 and AC-18 rows
    end
    ```
15. Edge cases.
    - A resource without a schema takes no name and generates nothing, as today.
    - `auix_create_ui for: :a` names only the modules of `:a`.
    - A layout brought in with `include:` keeps its `module_name:` and its `use:`; the name resolves in the including module.
    - A module without `auix_create_ui` defines neither `auix_modules/0` nor `auix_module/1`.
    - Two modules that import a generated module from each other do not compile, because each needs the other compiled first; the same holds for `@auix_resource_metadata`.
    - `generate: []` defines no module and still runs every check of `use:`; with it `module_names/5` returns `[]`.
    - A module imported from a module that imported it is the same module.
    - `NamedModulesHost` (step 14) names its component by the module and has an empty registry; `NamedModulesTest` imports the same module with `@auix_modules` under a name.
    - In step 14, `NamedModulesForms` also generates the default form and show components of `:product_location`; no test reads them.
16. Components: none new. Theme: none. `dt/1` strings: none.
17. Associations of a declared resource link to imported resources. No public function is added and no parser file changes.
    - `lib/aurora_uix/layout/resource_metadata.ex`, `resolve_resources/1` becomes `resolve_resources/2`: `@spec resolve_resources([Resource.t()], [{atom(), Resource.t()}]) :: %{atom() => Resource.t()}`. The second parameter `imported` gets its line in `## Parameters`: `` - `imported` ([{atom(), Resource.t()}]) - Resources the module imports, by name. They are lookup candidates for the associations of `resources`; they are not resolved again and not returned. `` In the body, the line `|> then(fn parsed -> Enum.map(parsed, &resolve_fields(&1, parsed)) end)` becomes `|> then(fn parsed -> Enum.map(parsed, &resolve_fields(&1, parsed ++ imported)) end)`. Nothing else in the function changes.
    - How the link is made, unchanged: `resolve_fields/2` hands its list to `parse_associations/4` of the backend parser, and the private `field_resource/2` of `lib/aurora_uix/integration/ctx/fields_parser.ex` and of `lib/aurora_uix/integration/ash/fields_parser.ex` takes the first `{name, resource}` pair whose `resource.schema` is the related schema. The declared resources come first in `parsed ++ imported`, so a declared resource wins over an imported one on the same schema. `configure_many_to_one_selectors/1` then gives the owner key of a linked many-to-one `html_type: :select`. The field option `resource:` keeps overriding the match.
    - `lib/aurora_uix/layout/resource_metadata/resolve_resources.ex`, `transform/1`, the only caller: `|> ResourceMetadata.resolve_resources()` becomes `|> ResourceMetadata.resolve_resources(imported_resources(module))`. New private function (`grep -rn 'imported_resources' lib test` prints nothing), with `alias Aurora.Uix.Resource` added in alphabetical position:
      ```elixir
      # The resources a module imports by writing `@auix_resource_metadata` by hand.
      @spec imported_resources(module()) :: [{atom(), Resource.t()}]
      defp imported_resources(module) do
        module
        |> Module.get_attribute(:auix_resource_metadata, [])
        |> Enum.flat_map(&Map.to_list/1)
        |> Enum.filter(&match?({_name, %Resource{}}, &1))
        |> Enum.sort_by(&elem(&1, 0))
      end
      ```
      The attribute accumulates (`lib/aurora_uix/uix.ex`, `__using__/1`), and the transformer runs once the module body is read, so the attribute is found in both positions: written before the declarations, and written after them. `GenerateUI.resources/2` reads the same attribute the same way. The transformer itself writes the attribute only later, in the code of `ResourceMetadata.resource_functions_code/1`, so the list holds the hand-written imports alone. The `[] ->` branch of `transform/1` is unchanged: a module that declares no resource resolves nothing.
    - `@moduledoc` of `ResolveResources`, `## Key Features`: add `` - Links the associations of the declared resources to the resources the module imports with `@auix_resource_metadata`, after the declared ones. ``
    - Consumers of the new link. The linked field carries the name of the imported resource in `data.resource`, and that resource is in `auix_configurations/0` of the module, because `GenerateUI.resources/2` merges the imports into the resources it generates from. The many-to-one and one-to-many renderers read it there, as they do for a declared resource. An imported resource keeps the links it was resolved with in its own module.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted: `mix test test/cases/create_ui_validation_test.exs test/cases/resource_metadata_validation_test.exs test/cases_live/named_modules_test.exs test/cases_live/navigation_test.exs test/cases_live/ash_navigation_test.exs test/cases_live/embeds_one_test.exs test/cases_live/ash_embeds_test.exs test/aurora_uix/templates/basic/gettext_coverage_test.exs`)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
4. The grep of AC-14 prints what the AC states
5. The three commands of AC-22 print what the AC states
<!-- section:UI-4:end -->
<!-- section:UI-5:start -->
### UI-5 — UI · generators and handlers · standalone Form and Show components
Depends on: UI-4

#### What and why
- **What.** Two things.
  - The form component and the show component work in a LiveView a host writes. They load their own record from `entity_id`, from `entity`, and from `action: :new`. Given the input `resource`, they serve a resource of the LiveView that renders them.
  - The form never navigates. In every parent it sends `{:saved, entity}` after a save and `{:closed}` on close. The generated `.Index` LiveView navigates when it receives them, to the URLs and the routing stack of today.
- **Why.** Today both components work only inside the modal of the generated `.Index` LiveView, which hands them the record and the routing stack. Today the form also pushes the redirect itself, so it cannot be used where the parent decides.
- **For an existing host.** Nothing changes in the browser, and handler hooks keep working (step 16). In a LiveView test, the redirect after a form save and after a form close arrives one message after the form event (step 15).

#### Documentation references
- `guides/core/components.md § Inputs`, `§ Outputs`, `§ Events`
- `guides/core/liveview.md § Form/Edit Handler Hook (LiveComponent)`, `§ Show Handler Hook (LiveComponent)`

#### Implementation details

A form component and a show component get their record in two ways. The assigns of each `update/2` decide the way:

| Way | Rendered by | Assigns | How the component gets its record |
|---|---|---|---|
| **hosted** | the generated `.Index` LiveView | `auix` holds `entity` and `routing_stack` (what `renderers/index_renderer.ex` passes) | unchanged: the LiveView hands it the record |
| **embedded** | any other parent | anything else | the component loads its record from its inputs |

Who navigates (Overview § Who navigates):
- No code of the form component and of the show component pushes a patch and a navigation, hosted and embedded.
- The form sends `{:saved, entity}` after a save and `{:closed}` on close. An embedded form sends them to `auix.notify`. A hosted form has no `auix.notify` and sends them to the LiveView process.
- The generated `.Index` LiveView answers both intents of its form with the route the form pushes today (step 14).
- A hosted form also sends two messages with `FormImpl.notify_parent/1`: `{:saved, entity}` before the intent, as today, and `{:flash, flash}` before `{:closed}`.
- After a save a hosted form puts no info flash: the generated `.Index` LiveView puts it (step 14), so the page holds one `#flash-info`. An embedded form puts its own.
- A hosted show view is unchanged: its back action and its edit action carry no target and are events of the LiveView. An embedded show view sends `{:closed}` and `{:open, :edit, id}`.

Facts the steps rely on:
- `auix.notify` exists only in an embedded component. Every clause added below selects on it.
- An **intent** is the message `{Aurora.Uix, component_id, intent}`.
- Layout types covered: `:form`, `:show`. `:index` is untouched.
- Backend-agnostic: records are read through `Aurora.Uix.Integration.Crud`.

The input `resource`:
- It is an atom of the LiveView that renders the component. In a component socket, `socket.view` is that LiveView.
- The component reads `socket.view.auix_configurations()`, checks that the pairing declared there (UI-4) names the component, and takes its options from `Helpers.component_binding/3`.
- A component given no `resource` serves the resource it was generated for.
- An instance keeps the resource of its first update.
- A hosted component takes no `resource`: the generated LiveView passes the binding through `auix` (UI-4).

##### Acceptance criteria
- [x] AC-1: an embedded form given `action: :new` renders the inputs of its layout, and a valid submit sends the intent `{:saved, entity}` to the host, shows the info flash `<name> updated successfully` in the form, and pushes no patch and no navigation
- [x] AC-2: an embedded form given `entity_id` renders that record's values with `action` `:edit`; given a different `entity_id` in a later update, it renders the other record
- [x] AC-3: an embedded show given `entity_id` renders the record; its back action sends `{:closed}` and its edit action sends `{:open, :edit, id}`, where `id` is the value the DOM carries
- [x] AC-4: the event `auix_request_close` sent to an embedded form without unsaved changes sends `{:closed}`
- [x] AC-5: an embedded form and an embedded show render no record navigator
- [x] AC-6: error path. `Helpers.assign_component_inputs/3` raises `ArgumentError` for a show component given neither `entity` nor `entity_id`
- [x] AC-7: `Helpers.report_intent/2` sends `{Aurora.Uix, id, intent}` to a pid given as `notify`, and calls `send_update/3` with `auix_intent: {Aurora.Uix, id, intent}` for a `{module, id}` given as `notify`
- [x] AC-8: the same components on the Ash backend load their own record: an embedded form given `action: :new` saves and sends `{:saved, entity}`, and an embedded show given `entity_id` renders that record
- [x] AC-9: a hosted show view and the handler hooks behave as before: the tests of UI-1, UI-2 and UI-4 pass, and the only existing test files this section changes are the four of step 15 (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- test` listing only the files this section creates and `test/cases_live/navigation_test.exs`, `test/cases_live/ash_navigation_test.exs`, `test/cases_live/handler_hooks_show_test.exs` and `test/cases_live/association_one2many_ui_layout_test.exs`, and `mix test` green)
- [x] AC-10: an embedded form given `resource: :product_location`, rendered by a LiveView written by hand that declares `edit_layout :product_location, use: ComponentsPairedViews.auix_module(:reference_form)`, renders the record of `entity_id` in the inputs `product_location[reference]` and `product_location[name]`, renders no input `product_location[type]`, and a submit updates the product location and sends `{:saved, entity}`
- [x] AC-11: error paths of `resource`. `Helpers.resource_binding/4` raises `ArgumentError` when the rendering LiveView declares no `auix_create_ui` (message contains `declares no auix_create_ui`), when the atom is no resource of that LiveView (`unknown resource :nope`), when that LiveView pairs the resource with another module (`does not pair`), and when an instance is given another resource after its first update (`already serves`)
- [x] AC-12: `Helpers.resource_binding/4` returns the binding with `_resource: :product_location` for a declared pairing, `%{_resource: nil}` on the first update of a component given no `resource`, and `%{}` on a later update that repeats the resource or carries none
- [x] AC-13: a form opened by the generated `.Index` LiveView pushes no redirect in its own event, and the LiveView then navigates to the URL and the routing stack of today: a save and a close of a child form return to the parent form, a save of a new parent with a child list goes to its edit form, and the close of a child form on the Ash backend returns to the parent form
- [x] AC-14: the flash follows the redirect of the LiveView: after a save the form opened by the LiveView renders no `#flash-info` of its own and the redirect carries the info flash `<name> updated successfully`, and after a failed save followed by a close the redirect carries the error flash the form showed
- [x] AC-15: `Helpers.report_intent/2` sends `{Aurora.Uix, id, intent}` to the calling process when `auix` has no `notify`

##### Test ports
- No route. A hand-written LiveView, `Aurora.UixWeb.Test.ComponentHostLive`, mounted with `Phoenix.LiveViewTest.live_isolated/3`. Its session key `"components"` lists the components to render; it shows every intent it receives as `#auix-host-intents li[data-component][data-intent][data-value]`.
- Observable: `has_element?/2` on `#auix-product-form input[name='product[reference]']`, `div[name='auix-show-navigate-back'] a`, `a[name='auix-edit-product']`, and on the intent list.
- Direct calls of the helpers on a bare socket for AC-6 and AC-7.
- No route. A second LiveView written by hand, `Aurora.UixWeb.Test.ComponentsPairedHostLive` (Modules & components step 11), mounted with `live_isolated/3`. It declares one pairing and renders the paired form with `resource={:product_location}` · layout type `:form` · observable: `has_element?/2` on `#auix-product_location-form input[name='product_location[reference]']` and on `#auix-paired-saved[data-component]`.
- Direct calls of `Helpers.resource_binding/4` on a bare socket whose `view` is a LiveView of the test files, for AC-11 and AC-12.
- Routes `"/navigation-products"` and `"/navigation-product_transactions"` of `test/cases_live/navigation_test.exs`, and the routes of `test/cases_live/ash_navigation_test.exs`, already registered by UI-1 · layout type `:form` · observable: the return of the form event, which is the rendered HTML, and `assert_redirect/1`, which returns `{path, flash}` for a redirect the LiveView pushes after the event.

##### Red tests
`Host` is `Aurora.UixWeb.Test.ComponentHostLive`. `mount_components(conn, components)` is a private function of each test file: `live_isolated(conn, Host, session: %{"components" => components})`. `T` is the test module of the file.

In the AC-13 and AC-14 rows, `assert is_binary(…)` on the return of a form event is the assertion that fails before this section. Today the form pushes the redirect in its own event, so `render_submit/1` and `render_click/3` return `{:error, {:live_redirect, _}}`. `assert_redirect/1` passes before and after this section: it reads the redirect whoever pushes it.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file (`ls test/cases_live \| grep components_` prints nothing). Module `Aurora.UixWeb.Test.ComponentsFormShowTest`, the two `use` lines of `test/cases_live/separated_single_resource_ui_test.exs`, `auix_resource_metadata(:product, context: Inventory, schema: Product)`, `auix_create_ui()` | `delete_all_inventory_data()`; `mount_components(conn, [%{module: T.Product.FormComponent, id: "f1", props: %{action: :new}}])` | `test/cases_live/components_form_show_test.exs` | `"an embedded form saves and reports"` | `has_element?(view, "#auix-product-form input[name='product[reference]']")`; `view \|> form("#auix-product-form", product: %{reference: "emb-1", name: "Embedded", quantity_initial: 1}) \|> render_submit()`; `has_element?(view, "#auix-host-intents li[data-component='f1'][data-intent='saved']")`; `has_element?(view, "#flash-info", "Product updated successfully")`; `has_element?(view, "#auix-host")`, which proves the view is still alive |
| AC-2 | add to same | `delete_all_inventory_data()`; `create_sample_products(2)`; `[first, second] = Aurora.Uix.Repo.all(Product)`; mount with `props: %{entity_id: first.id}` | same | `"an embedded form loads the record of its entity_id"` | `has_element?(view, "input[name='product[reference]'][value='#{first.reference}']")`; `send(view.pid, {:set_components, [%{module: T.Product.FormComponent, id: "f1", props: %{entity_id: second.id}}]})`; `has_element?(view, "input[name='product[reference]'][value='#{second.reference}']")` |
| AC-3 | add to same | `delete_all_inventory_data()`; `create_sample_products(1)`; `[product] = Aurora.Uix.Repo.all(Product)`; mount `%{module: T.Product.ShowComponent, id: "s1", props: %{entity_id: product.id}}` | same | `"an embedded show reports close and edit"` | `view \|> element("div[name='auix-show-navigate-back'] a") \|> render_click()`; `has_element?(view, "#auix-host-intents li[data-component='s1'][data-intent='closed']")`; `view \|> element("a[name='auix-edit-product']") \|> render_click()`; `has_element?(view, "#auix-host-intents li[data-component='s1'][data-intent='open'][data-value='edit:#{product.id}']")` |
| AC-4 | add to same | mount the form of AC-1 | same | `"closing an embedded form reports closed"` | `view \|> with_target("#auix-host > [data-phx-component]") \|> render_click("auix_request_close", %{})`, the drive `request_close/2` of `test/cases_live/form_discard_guard_test.exs` uses; `has_element?(view, "#auix-host-intents li[data-component='f1'][data-intent='closed']")` |
| AC-5 | add to same | mounts of AC-2 and AC-3 | same | `"embedded components have no record navigator"` | `refute has_element?(view, ".auix-record-navigator-bar")` for both |
| AC-6, AC-7 | new file (`ls test/cases/templates/basic` lists `helpers_actor_test.exs` and `helpers_navigation_test.exs`). Module `Aurora.Uix.Templates.Basic.HelpersIntentTest`, `use ExUnit.Case, async: true` | `socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, id: "c1", auix: %{notify: self()}}}` | `test/cases/templates/basic/helpers_intent_test.exs` | `"report_intent/2 reaches a pid and a component"`; `"a show component needs a record"` | `Helpers.report_intent(socket, {:closed})`; `assert_receive {Aurora.Uix, "c1", {:closed}}`; with `notify: {SomeComponent, "parent"}`: `assert_receive {:phoenix, :send_update, {{SomeComponent, "parent"}, %{id: "parent", auix_intent: {Aurora.Uix, "c1", {:closed}}}}}`. `assert_raise ArgumentError, fn -> Helpers.assign_component_inputs(%Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, id: "s1", auix: %{}}}, %{id: "s1"}, :show) end` |
| AC-8 | new file. Module `Aurora.UixWeb.Test.AshComponentsFormShowTest`, resource `auix_resource_metadata(:author, ash_resource: Aurora.Uix.Guides.Blog.Author)`, `auix_create_ui()` | `delete_all_blog_data()`; `[author] = create_sample_authors(1)`; form mounted with `props: %{action: :new}`, show with `props: %{entity_id: author.id}` | `test/cases_live/ash_components_form_show_test.exs` | `"embedded form and show on Ash"` | form: `view \|> form("#auix-author-form", author: %{name: "Ada", email: "ada@example.com"}) \|> render_submit()`; `has_element?(view, "#auix-host-intents li[data-intent='saved']")`. Show: `has_element?(view, "div.auix-show-container input[name='name'][value='#{author.name}']")`, the container of `lib/aurora_uix/templates/basic/renderers/show_component_renderer.ex` and the drive `test/cases_live/ash_embeds_test.exs` uses on a show field. No click on the back action: AC-3 covers `{:closed}` |
| AC-10 | add to `test/cases_live/components_form_show_test.exs`. Two top-level modules before the test module, see Modules & components step 11 | `delete_all_inventory_data()`; `create_sample_product_locations(1)`; `[location] = Aurora.Uix.Repo.all(ProductLocation)`; `{:ok, view, _html} = live_isolated(conn, Aurora.UixWeb.Test.ComponentsPairedHostLive, session: %{"entity_id" => location.id})` | same | `"a paired form serves a resource of the LiveView that renders it"` | `has_element?(view, "#auix-product_location-form input[name='product_location[reference]'][value='#{location.reference}']")`; `has_element?(view, "input[name='product_location[name]']")`; `refute has_element?(view, "input[name='product_location[type]']")`; `view \|> form("#auix-product_location-form", product_location: %{name: "Renamed"}) \|> render_submit()`; `Aurora.Uix.Repo.get!(ProductLocation, location.id).name == "Renamed"`; `has_element?(view, "#auix-paired-saved[data-component='location-form']")` |
| AC-11 | add to same | `H` is `Aurora.Uix.Templates.Basic.Helpers`, `Paired` is `Aurora.UixWeb.Test.ComponentsPairedHostLive`, `Views` is `Aurora.UixWeb.Test.ComponentsPairedViews`, `Form` is `Views.Product.ReferenceForm`. `first = fn view -> %Phoenix.LiveView.Socket{view: view, assigns: %{__changed__: %{}}} end`; `later = fn view, resource -> %Phoenix.LiveView.Socket{view: view, assigns: %{__changed__: %{}, auix: %{_resource: resource}}} end` | same | `"resource is checked against the LiveView that renders the component"` | `assert_raise ArgumentError, ~r/declares no auix_create_ui/, fn -> H.resource_binding(first.(Host), %{id: "c", resource: :product_location}, Form, :form) end` (`Host` calls no `use Aurora.Uix`); `~r/unknown resource :nope/` for `H.resource_binding(first.(Paired), %{id: "c", resource: :nope}, Form, :form)`; `~r/does not pair/` for `H.resource_binding(first.(Paired), %{id: "c", resource: :product_location}, Views.ProductLocation.FormComponent, :form)`; `~r/already serves/` for `H.resource_binding(later.(Paired, :product_location), %{id: "c", resource: :product}, Form, :form)` |
| AC-12 | add to same | the names of the AC-11 row | same | `"resource_binding/4 binds once"` | `%{_resource: :product_location, resource_name: :product_location, layout_type: :form} = H.resource_binding(first.(Paired), %{id: "c", resource: :product_location}, Form, :form)`; `H.resource_binding(first.(Paired), %{id: "c"}, Form, :form) == %{_resource: nil}`; `H.resource_binding(later.(Paired, :product_location), %{id: "c", resource: :product_location}, Form, :form) == %{}`; `H.resource_binding(later.(Paired, :product_location), %{id: "c"}, Form, :form) == %{}` |
| AC-13 | amend `test/cases_live/navigation_test.exs` `"a new child navigates to the child route and back to the parent form"` | unchanged | same | same | the child save: `saved = child \|> form("#auix-product_transaction-form", product_transaction: %{quantity: "3", type: "in", cost: 1.5}) \|> render_submit()`; `assert is_binary(saved)`; `{saved_to, _flash} = assert_redirect(child)`; the line `assert NavigationHelper.decode_route(saved_to) == back` stays. The child close: `closed = request_close(close_child, "#auix-product_transaction-new-modal [data-phx-component]")`; `assert is_binary(closed)`; `{closed_to, _flash} = assert_redirect(close_child)`; the line `assert NavigationHelper.decode_route(closed_to) == back` stays |
| AC-13 | amend `test/cases_live/navigation_test.exs` `"a new parent with a child list continues on its edit form"` | unchanged | same | same | `saved = view \|> form("#auix-product-form", product: %{reference: ref, name: "n", description: "d", quantity_initial: 1.0}) \|> render_submit()`; `assert is_binary(saved)`; `{to, _flash} = assert_redirect(view)`; the two lines after it stay |
| AC-13 | amend `test/cases_live/ash_navigation_test.exs` `"a new child navigates to the child route and back to the parent form"` | unchanged | same | same | `closed = request_close(child, "#auix-post-new-modal [data-phx-component]:has(> #auix-post-form)")`, the selector of step 15; `assert is_binary(closed)`; `{closed_to, _flash} = assert_redirect(child)`; the line `assert NavigationHelper.decode_route(closed_to) == {"#{@p}/#{id}/edit", %{}, [{:patch, @p}]}` stays |
| AC-14 | add to `test/cases_live/navigation_test.exs` | `id = with_transactions_id()`; `{:ok, view, _html} = live(conn, "#{@p}/#{id}/edit")`; `{:error, {:live_redirect, %{to: to}}} = view \|> element("a[name='auix-new-product__product_transactions-form']") \|> render_click()`; `back = {"#{@p}/#{id}/edit", %{}, [{:patch, @p}]}` | same | `"the flash of a form follows the redirect of the LiveView"` | save: `{:ok, child, _html} = live(conn, to)`; `saved = child \|> form("#auix-product_transaction-form", product_transaction: %{quantity: "3", type: "in", cost: 1.5}) \|> render_submit()`; `assert is_binary(saved)`; `saved \|> LazyHTML.from_document() \|> LazyHTML.query("#flash-info") \|> Enum.count() == 0`, the drive `test/cases_live/where_layout_test.exs` uses on rendered HTML: `saved` is the page before the LiveView handles the intent, so a `#flash-info` in it is the one of the form; `{_saved_to, flash} = assert_redirect(child)`; `flash["info"] =~ "updated successfully"`. Failed save, then close: `{:ok, failed, _html} = live(conn, to)`; `failed \|> form("#auix-product_transaction-form", product_transaction: %{quantity: "-1", type: "in", cost: 1.5}) \|> render_submit()`; `has_element?(failed, "#auix-product_transaction-new-modal")`; `closed = request_close(failed, "#auix-product_transaction-new-modal [data-phx-component]")`; `assert is_binary(closed)`; `{closed_to, flash} = assert_redirect(failed)`; `Map.has_key?(flash, "error")`; `NavigationHelper.decode_route(closed_to) == back` |
| AC-15 | add to `test/cases/templates/basic/helpers_intent_test.exs` (the file of the AC-6, AC-7 row) | `socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, id: "c1", auix: %{}}}` | same | `"report_intent/2 without notify reaches the calling process"` | `Helpers.report_intent(socket, {:closed})`; `assert_receive {Aurora.Uix, "c1", {:closed}}` |

##### Modules & components
1. `lib/aurora_uix/templates/basic/helpers.ex` — four new public functions (`grep -rnE 'assign_component_inputs|resource_binding|bind_resource|report_intent|report_open|auix_open|auix_intent' lib test` prints nothing; `grep -rnE 'defp? component_kind' lib test` prints nothing: in `lib/aurora_uix/layout/create_ui.ex`, `component_kind` is a variable and `@component_kinds` is a module attribute), each with `@doc` (`## Parameters`, `## Returns`) and `@spec`. Place them directly after `assign_parsed_opts/2`.
   - `@spec assign_component_inputs(Socket.t(), map(), :form | :show) :: Socket.t()`. Reads `action`, `entity`, `entity_id` and `notify` from the assigns map with `Map.get/2`. Steps:
     1. `action`: the given one; without one, `:show` for `:show`, `:new` for a form given neither `entity` nor `entity_id`, `:edit` for a form given one of them.
     2. `inputs = {action, entity, entity_id}`. When `socket.assigns.auix[:_inputs] == inputs`, return the socket with only `auix.notify` reassigned.
     3. Otherwise load the record: the given `entity`; else, for `entity_id`, `apply_get_function(auix.get_function, entity_id, socket |> backend_socket_opts(auix.get_function) |> Keyword.put(:preload, auix.preload))`; else, for a form, `apply_new_function(auix.new_function, %{}, socket |> backend_socket_opts(auix.new_function) |> Keyword.put(:preload, auix.preload))`, the call `IndexImpl.apply_action/2` makes for `:new`. A show component with neither input, and a `nil` record, raise `ArgumentError` with the message `"component #{inspect(socket.assigns.id)} needs a record: give it entity or an entity_id that exists"`. The show check runs before any backend call.
     4. Assign `:action` (plain assign) and, in `auix`: `entity`, `_inputs`, `notify` (`Map.get(assigns, :notify, self())`), `routing_stack` (`Stack.new()`), `pagination` (`nil`), `item_index` (`-1`). Remove the keys `:form`, `:_form_dirty?`, `:_discard_confirm_open?` and `:_sections` from `auix`, so the handler rebuilds them for the new record.
   - `@spec report_intent(Socket.t(), tuple()) :: Socket.t()`. Builds `message = {Aurora.Uix, socket.assigns.id, intent}` and reads `notify = Map.get(socket.assigns.auix, :notify, self())`; for a pid, `send(pid, message)`; for `{module, id}`, `send_update(module, id: id, auix_intent: message)`. Returns the socket. A hosted component has no `auix.notify`, so its intents reach the LiveView process.
   - `@spec report_open(Socket.t(), map()) :: Socket.t()`. Takes the params of the event `"auix_open"`: `%{"action" => "show" | "edit" | "new"}` and an optional `"id"`. Maps the action with three explicit clauses to `:show`, `:edit`, `:new` and calls `report_intent(socket, {:open, action, Map.get(params, "id")})`. Another action raises `FunctionClauseError`.
   - `resource_binding/4`, with its two private functions placed under `## PRIVATE`. It returns the map a component merges into `auix` before its compiled options: the binding of the input `resource`, resolved once, on the first update of the instance.
     ```elixir
     @spec resource_binding(Socket.t(), map(), module(), :form | :show) :: map()
     def resource_binding(socket, assigns, component, layout_type) do
       given = Map.get(assigns, :resource)

       case socket.assigns |> Map.get(:auix, %{}) |> Map.fetch(:_resource) do
         :error ->
           given
           |> bind_resource(socket.view, component, layout_type)
           |> Map.put(:_resource, given)

         {:ok, bound} when is_nil(given) or given == bound ->
           %{}

         {:ok, bound} ->
           raise ArgumentError,
                 "component #{inspect(assigns.id)} already serves #{inspect(bound)}; " <>
                   "give #{inspect(given)} a component with its own id"
       end
     end

     @spec bind_resource(atom() | nil, module(), module(), :form | :show) :: map()
     defp bind_resource(nil, _view, _component, _layout_type), do: %{}

     defp bind_resource(resource, view, component, layout_type) do
       if not function_exported?(view, :auix_configurations, 0) do
         raise ArgumentError,
               "#{inspect(view)} declares no auix_create_ui; it renders #{inspect(component)} " <>
                 "with resource: #{inspect(resource)}, which is resolved there"
       end

       configurations = view.auix_configurations()
       kind = component_kind(layout_type)

       case Map.fetch(configurations, resource) do
         {:ok, %{artifacts: %{^kind => ^component}}} ->
           component_binding(configurations, resource, layout_type)

         {:ok, _configuration} ->
           raise ArgumentError,
                 "#{inspect(view)} does not pair #{inspect(resource)} with #{inspect(component)}; " <>
                   "declare it in its auix_create_ui with use:"

         :error ->
           raise ArgumentError, "unknown resource #{inspect(resource)} in #{inspect(view)}"
       end
     end

     @spec component_kind(:form | :show) :: atom()
     defp component_kind(:form), do: :form_component
     defp component_kind(:show), do: :show_component
     ```
     `socket.view` is the LiveView that renders the component: `Phoenix.LiveView.Diff.configure_socket_for_component/3` replaces `assigns` and `private` of the socket and keeps `view`. The LiveView is running, so its module is loaded when `function_exported?/3` reads it. A LiveView that generated the component for that resource itself passes the same check. `send_update/3` assigns carry no `resource` and return `%{}`. Load guarantee: `configurations[resource].artifacts` exists for every configuration (`build_configurations/4`, UI-4 step 11).
2. `generators/form_generator.ex` — modified. Inside the generated module add `defp auix_parsed_opts, do: unquote(Macro.escape(parsed_opts))` and call `auix_parsed_opts()` in the existing clause in place of the inline escape. Add a second `update/2` clause after it:
   ```elixir
   def update(assigns, socket) do
     merged_auix =
       socket.assigns
       |> Map.get(:auix, %{})
       |> Map.merge(Map.get(assigns, :auix, %{}))
       |> Map.merge(Helpers.resource_binding(socket, assigns, __MODULE__, :form))

     socket =
       socket
       |> assign(Map.put(assigns, :auix, merged_auix))
       |> Helpers.assign_parsed_opts(auix_parsed_opts())
       |> Helpers.assign_actor_to_auix()
       |> Helpers.assign_component_inputs(assigns, :form)

     assigns
     |> Map.put(:auix, Map.take(socket.assigns.auix, [:entity, :routing_stack]))
     |> unquote(handler_module).update(socket)
   end
   ```
   The handler receives the assigns shape `FormImpl.auix_update/2` matches today, so a host handler that overrides `auix_update/2` runs unchanged. The binding of `resource` enters `auix` before `Helpers.assign_parsed_opts/2`, which keeps every key already in `auix`; the compiled options fill what a binding leaves out, and `assign_component_inputs/3` then loads the record with the `get_function` of the bound resource. `__MODULE__` is the generated component.
3. `generators/show_component_generator.ex` — the same two edits, with `:show` in `resource_binding/4` and in `assign_component_inputs/3`, and without the `assign_actor_to_auix/1` line the hosted clause does not have either.
4. `handlers/form_impl.ex` — modified. The form no longer pushes a route; it reports.
   - In the quote of `__using__/1`, in the `"save"` clause: replace `FormImpl.notify_parent({:saved, entity})` with `FormImpl.report_saved(socket, entity)`, and delete the last step of the pipeline, `|> FormImpl.conditional_route_back(action, auix.one2many_rendered?)`. The step before it, `|> assign_auix(:entity, new_entity)`, becomes the last one. `action` is still read by `FormImpl.publish_saved(action, entity)`.
   - In the same pipeline of the `"save"` clause: replace the two steps `|> clear_flash()` and `|> put_flash(:info, "#{auix.name} updated successfully")` with the one step `|> FormImpl.put_saved_flash()`. The three `else` branches keep their `|> clear_flash()` and `|> put_flash(:error, …)`.
   - New public function, after `report_saved/2` (`grep -rn 'put_saved_flash' lib test` prints nothing), with `@doc` (`## Parameters`, `## Returns`):
     ```elixir
     @spec put_saved_flash(Socket.t()) :: Socket.t()
     def put_saved_flash(%{assigns: %{auix: %{notify: _notify}}} = socket) do
       socket
       |> clear_flash()
       |> put_flash(:info, "#{socket.assigns.auix.name} updated successfully")
     end

     def put_saved_flash(socket), do: clear_flash(socket)
     ```
     The first clause is the embedded form: it shows its own flash, with the string the `"save"` clause holds today. The second clause is the hosted form: the LiveView puts that flash (step 14). A hosted form no longer redirects in its own event, so a flash it put would stay in the form and render a second `#flash-info` beside that of the LiveView (`renderers/form_renderer.ex` and `renderers/index_renderer.ex` both render `<.flash kind={:info} flash={@flash} …/>`). `clear_flash/1` and `put_flash/3` come from the `import Phoenix.LiveView` of the module. `grep -rn 'updated successfully' test` lists `test/cases_live/events_test.exs` and `test/cases_live/ash_events_test.exs`, whose flash the LiveView puts in `react_to_change/4`: no existing test reads the flash of the form.
   - New public function, after `notify_parent/1` (`grep -rn 'report_saved' lib test` prints nothing): `@spec report_saved(Socket.t(), struct()) :: :ok`. First clause, head `%{assigns: %{auix: %{notify: _notify}}} = socket`: calls `report_intent(socket, {:saved, entity})` and returns `:ok`. Second clause, for a hosted form: calls `notify_parent({:saved, entity})`, then `report_intent(socket, {:saved, entity})`, and returns `:ok`. The order matters: the LiveView re-reads its page on the first message and navigates on the second. `notify_parent/1` stays public and unchanged.
   - `conditional_route_back/3`: unchanged and still public. No library code calls it after this section. Add one sentence to its `@doc`: `The generated LiveView routes after a save itself; this function stays for host handlers that call it.`
   - `auix_handle_event("auix_route_back", _params, socket)`: the body becomes `{:noreply, route_back_from_close(socket)}`.
   - `route_back_from_close/1`: delete the two comment lines above it and replace the function with:
     ```elixir
     # An embedded form reports to its parent. A hosted form also hands its flash to the LiveView,
     # which pushes the route and cannot read the flash of a component.
     @spec route_back_from_close(Socket.t()) :: Socket.t()
     defp route_back_from_close(%{assigns: %{auix: %{notify: _notify}}} = socket),
       do: report_intent(socket, {:closed})

     defp route_back_from_close(socket) do
       notify_parent({:flash, socket.assigns.flash})
       report_intent(socket, {:closed})
     end
     ```
     `request_close/2` and the `"auix_discard_changes"` clause keep calling it. Load guarantee: `socket.assigns.flash` exists in every LiveComponent socket.
5. `handlers/show_component_impl.ex` — two new clauses of `auix_handle_event/3`, placed before the clause that raises: `"auix_route_back"` with the head `%{assigns: %{auix: %{notify: _notify}}} = socket`, returning `{:noreply, report_intent(socket, {:closed})}`; and `"auix_open"`, returning `{:noreply, report_open(socket, params)}`. A hosted show never receives them: its back and edit actions carry no target and reach the LiveView.
6. `actions/show_component.ex` — modified. `edit_header_action/1`: new first clause on `%{auix: %{notify: _notify}} = assigns` rendering `<.auix_link phx-click="auix_open" phx-value-action="edit" phx-value-id={BasicHelpers.primary_key_value(@auix.entity, @auix.primary_key)} phx-target={@auix._myself} name={"auix-edit-#{@auix.module}"}>` around the same `<.button>`. `back_footer_action/1`: new first clause on the same pattern rendering the same `div[name='auix-show-navigate-back']` with `<.auix_back phx-target={@auix._myself}>`. `auix_link/1` and `auix_back/1` pass `phx-target` through (UI-3, AC-7).
7. `components/components.ex`, `record_navigator?/2` — new first clause `def record_navigator?(%{pagination: nil}, _position), do: false`. Callers: `renderers/form_renderer.ex` and `renderers/show_component_renderer.ex`, both passing `@auix`; a hosted component always carries a `%Pagination{}` there, set by `update_streams/1` of the index handler (`handlers/index_impl.ex` on `main`, `handlers/index_list.ex` once UI-6 is merged).
8. `renderers/fields/one_to_many.ex` — modified, so a form embedded outside the routes still renders its child lists. Second `render/1` head: replace `auix: %{uri_path: uri_path} = auix` with `auix: auix`, and bind `uri_path = Map.get(auix, :uri_path)` as the first line of the body. `set_related_uri_path/3`: new first clause `defp set_related_uri_path(related_parsed_opts, _parsed_opts, nil), do: related_parsed_opts`. `set_related_new_link/1`: new last clause `defp set_related_new_link(related_parsed_opts), do: related_parsed_opts`.
9. `actions/one_to_many.ex` — `add_new_child/1`, `show_child_action/1`, `edit_child_action/1` and `delete_child_action/1` each get a new first clause on `%{auix: %{notify: _notify}} = assigns` returning `~H""`: an embedded parent has no child routes to go to.
10. `test/support/app_web/component_host_live.ex` — new (`grep -rn 'ComponentHostLive' lib test` prints nothing). `@moduledoc`, `@doc` and `@spec` in the style of `test/support/app_web/routes_helper.ex`.
    ```elixir
    defmodule Aurora.UixWeb.Test.ComponentHostLive do
      use Aurora.UixWeb.Test, :live_view

      @impl true
      def mount(_params, session, socket) do
        {:ok,
         socket
         |> assign(:components, Map.get(session, "components", []))
         |> assign(:intents, [])}
      end

      @impl true
      def render(assigns) do
        ~H"""
        <div id="auix-host">
          <.live_component
            :for={component <- @components}
            module={component.module}
            id={component.id}
            {component.props}
          />
          <ul id="auix-host-intents">
            <li
              :for={{component_id, intent} <- @intents}
              data-component={component_id}
              data-intent={elem(intent, 0)}
              data-value={intent_value(intent)}
            >
            </li>
          </ul>
        </div>
        """
      end

      @impl true
      def handle_info({Aurora.Uix, component_id, intent}, socket),
        do: {:noreply, update(socket, :intents, &(&1 ++ [{component_id, intent}]))}

      def handle_info({:set_components, components}, socket),
        do: {:noreply, assign(socket, :components, components)}

      defp intent_value({:open, action, id}), do: "#{action}:#{id}"
      defp intent_value({:page, page}), do: "#{page}"
      defp intent_value({:deleted, ids}), do: Enum.join(ids, ",")
      defp intent_value({:saved, entity}), do: "#{Map.get(entity, :id)}"
      defp intent_value({:closed}), do: ""
    end
    ```
    The LiveView has no catch-all `handle_info/2` clause: a message a component must not send fails the test that caused it. It calls no `use Aurora.Uix`: the AC-11 row reads it as a LiveView that declares no `auix_create_ui`.
11. Top-level modules of `test/cases_live/components_form_show_test.exs`, before the test module, in this order (`grep -rn 'ComponentsPaired' lib test` prints nothing):
    ```elixir
    defmodule Aurora.UixWeb.Test.ComponentsPairedViews do
      use Aurora.Uix

      alias Aurora.Uix.Guides.Inventory
      alias Aurora.Uix.Guides.Inventory.Product
      alias Aurora.Uix.Guides.Inventory.ProductLocation

      auix_resource_metadata(:product, context: Inventory, schema: Product)
      auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)

      auix_create_ui generate: [:form_component, :show_component] do
        edit_layout :product, module_name: :reference_form do
          inline([:reference, :name])
        end
      end
    end

    defmodule Aurora.UixWeb.Test.ComponentsPairedHostLive do
      use Aurora.UixWeb.Test, :live_view
      use Aurora.Uix

      alias Aurora.UixWeb.Test.ComponentsPairedViews

      @auix_resource_metadata %{
        product_location: ComponentsPairedViews.auix_resource(:product_location)
      }

      auix_create_ui generate: [] do
        edit_layout(:product_location, use: ComponentsPairedViews.auix_module(:reference_form))
      end

      @impl true
      def mount(_params, session, socket) do
        {:ok,
         socket
         |> assign(:entity_id, Map.fetch!(session, "entity_id"))
         |> assign(:saved, nil)}
      end

      @impl true
      def render(assigns) do
        ~H"""
        <div id="auix-paired-host">
          <.live_component
            module={ComponentsPairedViews.auix_module(:reference_form)}
            id="location-form"
            resource={:product_location}
            entity_id={@entity_id}
          />
          <p id="auix-paired-saved" data-component={@saved}></p>
        </div>
        """
      end

      @impl true
      def handle_info({Aurora.Uix, component_id, {:saved, _entity}}, socket),
        do: {:noreply, assign(socket, :saved, component_id)}
    end
    ```
    `ComponentsPairedViews` generates `Product.ReferenceForm`, and the default `ProductLocation.FormComponent` the AC-11 row names as the other module. The host imports the resource, names the component by its module in `use:` and in `render/1`, needs no `@auix_modules`, and generates nothing.
12. Unchanged on purpose.
    - `renderers/index_renderer.ex` keeps the modal and passes the hosted assigns, so the LiveView keeps receiving `{FormImpl, {:saved, entity}}` in `auix_handle_info/2`.
    - `renderers/form_renderer.ex` keeps its ids: two embedded forms of one resource on one page share `auix-<module>-form` (see Out of Scope).
    - An embedded form has no close control of its own; `auix_request_close` and `auix_route_back` are the events a host action sends to it.
13. Components: none new. Theme: none. `dt/1` strings: none.
14. `handlers/index_impl.ex` — modified. The generated LiveView navigates on the intents of its form. Add `alias Aurora.Uix.Templates.Basic.Handlers.FormImpl` in alphabetical position. Add three clauses of `auix_handle_info/2`, directly before its last clause `def auix_handle_info(_input, socket)`, and two private functions under `## PRIVATE` (`grep -rnE 'route_after_save|put_form_flash|_form_flash' lib test` prints nothing):
    ```elixir
    def auix_handle_info({FormImpl, {:flash, flash}}, socket),
      do: {:noreply, assign_auix(socket, :_form_flash, flash)}

    def auix_handle_info(
          {Aurora.Uix, _component_id, {:saved, entity}},
          %{assigns: %{auix: auix, live_action: action}} = socket
        ) do
      {:noreply,
       socket
       |> clear_flash()
       |> put_flash(:info, "#{auix.name} updated successfully")
       |> route_after_save(entity, action)}
    end

    def auix_handle_info({Aurora.Uix, _component_id, {:closed}}, %{assigns: %{auix: auix}} = socket) do
      {:noreply,
       socket
       |> put_form_flash(Map.get(auix, :_form_flash, %{}))
       |> auix_route_back_from(Map.get(auix, :_current_path) || "")}
    end
    ```
    ```elixir
    # Mirrors `FormImpl.conditional_route_back/3`. The navigation of the form has no current path,
    # hence the empty one.
    @spec route_after_save(Socket.t(), struct(), atom()) :: Socket.t()
    defp route_after_save(%{assigns: %{auix: auix}} = socket, entity, :new) do
      binding = BasicHelpers.component_binding(auix.configurations, auix.resource_name, :form)

      if binding.one2many_rendered?,
        do: auix_route_back_to_edit(socket, BasicHelpers.primary_key_value(entity, auix.primary_key)),
        else: auix_route_back_from(socket, "")
    end

    defp route_after_save(socket, _entity, _action), do: auix_route_back_from(socket, "")

    # A redirect carries the flash put in the same callback, so the flash of the form is put here.
    @spec put_form_flash(Socket.t(), map()) :: Socket.t()
    defp put_form_flash(socket, flash) do
      Enum.reduce(flash, clear_flash(socket), fn {kind, message}, acc ->
        put_flash(acc, kind, message)
      end)
    end
    ```
    - Why the routes are those of today. The form builds its navigation with `assign_auix_navigation/2`: the routing stack the LiveView passes, and no current path. `Navigation.back/1` and `Navigation.back_to_edit/2` read only the stack and the current path.
      - After a save the form calls `auix_route_back/1`. `auix_route_back_from(socket, "")` on the LiveView socket computes the same route: the same stack, and the empty current path.
      - After a save of a new record whose form shows a one-to-many list, the form calls `auix_route_back_to_edit/2`. The same call on the LiveView socket computes the same route: the popped entry is `<origin>/<id>/edit`, the LiveView is on `/new`, so the fallback of `Navigation.back/1` is not taken in either socket.
      - On close the form calls `auix_route_back_from(socket, auix._close_path)`, and `_close_path` is `@auix[:_current_path]` of the LiveView (`renderers/index_renderer.ex`). The clause above passes the same value.
    - Why the flash is that of today. A redirect pushed by a component carries the flash of the component (`Phoenix.LiveView.Channel`, `component_handle/4`). A redirect pushed by the LiveView carries the flash put in the same callback. The `{:saved, entity}` clause puts the flash an embedded form puts in `FormImpl.put_saved_flash/1` (step 4), with the same text; the string is not new. A hosted form puts none, so the two flashes never render together. The `{:closed}` clause puts the flash the form held when it closed.
    - Load guarantees. `auix.configurations` and `auix.resource_name` come from the compiled options of the LiveView (UI-4, step 12). `binding.one2many_rendered?` is the value the form holds in `auix.one2many_rendered?`: `component_binding/3` builds its map from the keys `generate_module/4` gives the form generator and ends with `ModulesGenerator.component_opts/1`, as the form generator does (UI-4, step 12). `live_action` is the `action` the form receives (`renderers/index_renderer.ex`, `action={@live_action}`). `auix.name` and `auix.primary_key` are those of the resource of the form. `auix._current_path` is set by `auix_handle_params/3`.
    - Order of the messages. A hosted form sends `{FormImpl, {:saved, entity}}` before `{Aurora.Uix, id, {:saved, entity}}`, and `{FormImpl, {:flash, flash}}` before `{Aurora.Uix, id, {:closed}}`. The LiveView handles them in that order.
    - UI-6 edits other clauses of this file. These three clauses and the two functions call no list function, and stay as written whichever of the two sections is merged first.
    - Edge case. An `auix_handle_info/2` override that does not pass a message to `super` stops the navigation after a save and on close. `guides/core/liveview.md § How an open index reacts` already requires the override to pass every message it does not handle.
15. Contract change and the tests that drive it. The redirect after a form save and after a form close is pushed by the LiveView, one message after the form event. `render_submit()` and `render_click("auix_request_close", …)` then return the rendered HTML, and `assert_redirect/1` returns `{path, flash}` of the redirect. `grep -rn 'live_redirect' test` lists `navigation_test.exs` and `ash_navigation_test.exs`; `grep -rn 'follow_redirect' test` lists `handler_hooks_show_test.exs` and `association_one2many_ui_layout_test.exs`.
    - Four matches on `{:error, {:live_redirect, %{to: _}}}` take the form of the AC-13 rows: three in `test/cases_live/navigation_test.exs` and one in `test/cases_live/ash_navigation_test.exs`. Each keeps its `NavigationHelper.decode_route/1` equality, on the `to` of the same redirect, so each pins the URL and the routing stack it pins today.
    - The close of the Ash row targets the form component alone.
      - The `:post` form renders a nested `EmbedsManyComponent` for `tags` (`lib/aurora_uix/guides/blog/post.ex`, `attribute :tags, {:array, Tag}`). `#auix-post-new-modal [data-phx-component]` therefore matches two component roots, and `with_target/2` sends the event to each of them in turn (`Phoenix.LiveViewTest.DOM.targets_from_selector/2`).
      - Today the redirect of the form ends the event before the second root receives it. After step 4 the form only reports, the second root receives `auix_request_close`, and `EmbedsManyComponent.handle_event/3` has no clause for it.
      - `#auix-post-new-modal [data-phx-component]:has(> #auix-post-form)` matches one root, the form component: `renderers/form_renderer.ex` renders `<.simple_form id={"auix-#{@auix.module}-form"}>` as a child of the root `<div>` of the component.
      - It is the component the browser reaches: `modal_on_cancel/2` of `renderers/index_renderer.ex` pushes `auix_request_close` with `target: uix_id_selector("auix-#{auix.module}-form")`, which resolves to the component that owns the form.
      - No library code changes for it: no markup sends `auix_request_close` to a nested component, and `components/embeds_many_component.ex` stays as it is.
      - Every other `request_close/2` call of the two files keeps its selector: the `:product`, `:product_transaction` and `:author` forms render no nested component.
    - The other matches on `live_redirect` of the two files stay: they follow a click on a link of the LiveView and the event `"auix_route_back"` sent to the LiveView.
    - Six pipelines `view |> form(…) |> render_submit() |> follow_redirect(conn)` change: in `start_product_creation/1`, `create_multiple_transactions/4` and `edit_single_transaction/4` of `test/cases_live/handler_hooks_show_test.exs`, and in the three functions of the same names of `test/cases_live/association_one2many_ui_layout_test.exs`. In each, `X` is the view the pipeline starts from and `{:ok, name, _html}` is what it is matched on. The pipeline ends at `|> render_submit()` and is no longer matched; two lines follow it: `{path, _flash} = assert_redirect(X)` and `{:ok, name, _html} = live(conn, path)`. The assertions after them stay.
    - The four pipelines of those two files that end `|> render_click() |> follow_redirect(conn)` stay: they click a link of the LiveView.
    - Every assertion on `assert_patch/1` stays: it waits for the patch, whoever pushes it.
16. Host patterns, all kept.
    - A handler that overrides `auix_handle_info/2` and matches `{_component, {:saved, entity}}` still receives that message, before the intent (`test/cases_live/handler_hooks_index_test.exs`, unchanged).
    - A form handler and a show handler that call `auix_route_back/1` and `push_navigate/2` navigate as today: a hosted component keeps `auix.navigation` (`guides/core/liveview.md § Show Handler Hook (LiveComponent)`; `handler_hooks_show_test.exs` `"a targeted custom event routes back from the show handler"`, unchanged).
    - A host that overrides `handle_event("save", …)` and calls `FormImpl.conditional_route_back/3` navigates as today.
    - A custom action that renders `<.auix_link>` and `<.auix_back>` without a target still reaches the LiveView.
    - `renderers/index_renderer.ex` still passes `_close_path`; no library code reads it after this section.
    - One edge differs. The event `"auix_route_back"` sent to a hosted form now closes it as `"auix_request_close"` does, from the current path of the LiveView. No markup of the library sends that event to a form.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted: `mix test test/cases_live/components_form_show_test.exs test/cases_live/ash_components_form_show_test.exs test/cases/templates/basic/helpers_intent_test.exs test/cases_live/navigation_test.exs test/cases_live/ash_navigation_test.exs test/cases_live/handler_hooks_form_test.exs test/cases_live/handler_hooks_show_test.exs test/cases_live/association_one2many_ui_actions_test.exs test/cases_live/association_one2many_ui_layout_test.exs test/cases_live/handler_hooks_index_test.exs test/cases_live/form_discard_guard_test.exs test/cases_live/events_test.exs`)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-5:end -->
<!-- section:UI-6:start -->
### UI-6 — UI · handlers · extract the list engine
Depends on: UI-4

#### What and why
- **What.** The list logic of the index handler moves into one module, `IndexList`, that runs on any socket. The generated `.Index` LiveView calls it.
- **Why.** UI-7 runs the same list inside a LiveComponent. One engine then serves the LiveView and the component.
- **For an existing host.** Nothing changes: no markup, no event name, no `auix` key and no URL.

#### Documentation references
- `guides/core/liveview.md § Index Handler Hook (LiveView)`, `§ Working with Streams`, `§ Scoping the Index Query at Runtime`, `§ Index commands`
- `guides/customization/custom_actions.md` (the bulk-action recipe, which sends list events to the LiveView)

#### Implementation details

- The list logic of `Aurora.Uix.Templates.Basic.Handlers.IndexImpl` moves, unchanged, into one module that works on any socket: `Aurora.Uix.Templates.Basic.Handlers.IndexList`.
- `IndexImpl` keeps its callbacks, its routing and its reactions to an open record, and calls the engine.
- No markup, no event name, no `auix` key and no URL changes.
- Layout type covered: `:index`.
- The engine is backend-agnostic: it reads and deletes through `Aurora.Uix.Integration.Crud`, as the code it receives does.

##### Acceptance criteria
- [x] AC-1: `IndexList.events/0` returns the nine event names `"filter-toggle"`, `"filters-clear"`, `"filters-submit"`, `"index-sort"`, `"index-sort-direction"`, `"index-layout-change"`, `"selected-toggle_all"`, `"selected-cancel_toggle_all"`, `"selected-delete_all"`
- [x] AC-2: `IndexList.previous_page/1` returns `1` for page `1` and `page - 1` above it; `IndexList.next_page/1` returns `pages_count` on the last page and `page + 1` below it
- [x] AC-3: error path. `IndexList.handle_event/3` raises `FunctionClauseError` for an event name that is not in `events/0`
- [x] AC-4: `IndexList.where_conditions/1` returns `[]` for `nil`, the list for a list, the pairs of a map, and a one-element list for a single condition
- [x] AC-5: no test file changes and the suite passes: the index keeps every documented behaviour (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- test` listing only `test/cases/templates/basic/index_list_test.exs`, and `mix test` green)
- [x] AC-6: `IndexImpl` holds no list logic of its own (mechanical — no red test; verified by `grep -cE 'defp (load_items|load_page|read_items|update_streams|prepare_query_options|assign_filters|assign_index_fields|assign_selected_states|refresh_current_page|get_selected_filters)\b' lib/aurora_uix/templates/basic/handlers/index_impl.ex` returning `0`)

##### Test ports
- Pure functions of `IndexList`, called directly in `test/cases/templates/basic/index_list_test.exs`.
- The LiveView behaviour is observed through the existing `test/cases_live/` files, unchanged: `selected_test.exs`, `selected_bulk_action_test.exs`, `sortable_columns_test.exs`, `sort_disabled_test.exs`, `where_filter_layout_test.exs`, `pages_bar_test.exs`, `infinity_scroll_test.exs`, `load_items_options_test.exs`, `events_test.exs`, `handler_hooks_index_test.exs` and their `ash_*` counterparts.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file (`ls test/cases/templates/basic \| grep index_list` prints nothing). Module `Aurora.Uix.Templates.Basic.IndexListTest`, `use ExUnit.Case, async: true` | none | `test/cases/templates/basic/index_list_test.exs` | `"events/0 lists the list events"` | `IndexList.events() == [the nine names, in the order of AC-1]` |
| AC-2 | add to same | none | same | `"previous_page/1 and next_page/1 stay inside the pages"` | `IndexList.previous_page(%{page: 1}) == 1`; `IndexList.previous_page(%{page: 3}) == 2`; `IndexList.next_page(%{page: 3, pages_count: 3}) == 3`; `IndexList.next_page(%{page: 2, pages_count: 3}) == 3` |
| AC-3 | add to same | `socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, auix: %{}}}` | same | `"handle_event/3 takes only list events"` | `assert_raise FunctionClauseError, fn -> IndexList.handle_event("delete", %{}, socket) end` |
| AC-4 | add to same | none | same | `"where_conditions/1 flattens a where"` | `IndexList.where_conditions(nil) == []`; `IndexList.where_conditions([{:a, 1}]) == [{:a, 1}]`; `IndexList.where_conditions(%{a: 1}) == [a: 1]`; `IndexList.where_conditions({:a, :lt, 2}) == [{:a, :lt, 2}]` |

##### Modules & components
1. `Aurora.Uix.Templates.Basic.Handlers.IndexList` at `lib/aurora_uix/templates/basic/handlers/index_list.ex` — new (`grep -rn 'IndexList' lib test` prints nothing). `use Aurora.Uix.GettextResolver` is not needed: the engine renders no text. Imports and aliases: `import Aurora.Uix.Integration.Crud`, `import Aurora.Uix.Templates.Basic.Helpers`, `import Phoenix.Component`, `import Phoenix.LiveView`; aliases `Aurora.Uix.Event`, `Aurora.Uix.Events`, `Aurora.Uix.Filter`, `Aurora.Uix.Layout.Helpers, as: LayoutHelpers`, `Aurora.Uix.Layout.Options, as: LayoutOptions`, `Aurora.Uix.Selection`, `Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers`, `Phoenix.LiveView.Socket`. `@moduledoc` first paragraph: `The list of an index: loading, streams, filters, sort, pagination, selection and bulk actions, for a LiveView socket and for a LiveComponent socket.` `## Key Features`: the nine list events; the two async tasks; page loading; `Aurora.Uix.Event` handling. `## Key Constraints`: it never navigates and never reads `live_action`; it expects the `auix` keys `IndexImpl.auix_mount/3` sets; backend-agnostic.
2. Moved from `index_impl.ex` into `index_list.ex`, bodies and comments verbatim: the module attribute `@allowed_query_options` with its comment, and the private functions `resource_schema/1`, `publish_deleted/2`, `unselect_deleted/2`, `delete_selected/4`, `prepare_initial_pagination/2`, `load_page/2`, `load_items/2`, `layout_query_options/1`, `resource_query_opts/1`, `refresh_current_page/1`, `prepare_query_options/1`, `where_conditions/1`, `merge_preload/2`, `maybe_put_preload/2`, `maybe_put_sort/2`, `apply_sort/2`, `sortable_field/2`, `flip/1`, `next_sort/2`, `read_items/2`, `update_streams/1`, `update_alternate_streams/3`, `merge_extra_option/2`, `merge_option/2`, `assign_layout_options/1`, `assign_index_fields/1`, `drop_upload_sort/1`, `assign_selected_states/1`, `assign_async_selected_toggle_all/2`, `assign_async_delete_all/1`, `assign_filters/1`, `assign_filters_selected_count/1`, `update_filter/3`, `get_selected_filters/1`, `in_values/1`, `escape/1`, `previous_page/1`, `next_page/1`, `get_page_items_id/1`.
3. Of those, these become public (`def`, with `@doc` and the existing `@spec`): `resource_schema/1`, `load_page/2`, `load_items/2` (keeping its default argument), `refresh_current_page/1`, `where_conditions/1`, `previous_page/1`, `next_page/1`. The others stay private.
4. New public functions of `IndexList`, each with `@doc` and `@spec`:
   - `@spec events() :: [binary()]` — the list of AC-1, held in a module attribute `@events`.
   - `@spec init(Socket.t(), map(), (Socket.t() -> Socket.t())) :: Socket.t()`:
     ```elixir
     def init(%{assigns: %{auix: auix}} = socket, params, prepare) do
       socket
       |> assign_auix(:filters_enabled?, false)
       |> assign_auix(:filters_where, [])
       |> assign_auix(:sort, nil)
       |> assign_auix(:selection, Selection.new())
       |> assign_auix(:enable_viewport?, true)
       |> assign_auix(:list_function_selected, auix.list_function_paginated)
       |> assign_auix(:reset_stream?, true)
       |> assign_auix(:empty_list?, true)
       |> assign_layout_options()
       |> prepare.()
       |> assign_index_fields()
       |> assign_filters()
       |> prepare_initial_pagination(params)
       |> load_items()
     end
     ```
     `prepare` runs where `IndexActions.set_actions/1` runs today: after the layout options, before the index fields.
   - `@spec handle_event(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}` — the clauses of `IndexImpl.auix_handle_event/3` for the nine events, moved verbatim and in their order: `"filter-toggle"`, `"filters-clear"`, `"filters-submit"`, the `sort_disabled?` clause with its guard, the three `"index-sort"` clauses, `"index-sort-direction"`, the seven `"index-layout-change"` clauses, `"selected-toggle_all"`, `"selected-cancel_toggle_all"`, `"selected-delete_all"`. It has no catch-all clause.
   - `@spec handle_async(atom(), term(), Socket.t()) :: {:noreply, Socket.t()}` — the two clauses of `IndexImpl.auix_handle_async/3`, verbatim.
   - `@spec delete(Socket.t(), term()) :: {Socket.t(), list()}` — the body of the `"delete"` clause that takes only `"id"`, without the flash: it reads and deletes the record, publishes the deletion, and returns `{socket |> stream_delete(auix.source_key, entity) |> assign_selected_states() |> refresh_current_page(), [id_value]}`, where `id_value` is `BasicHelpers.primary_key_value(entity, auix.primary_key)`.
   - `@spec apply_event(Socket.t(), Event.t()) :: Socket.t()` — `socket |> unselect_deleted(event) |> assign_selected_states() |> refresh_current_page()`.
   - `@spec reset_selection(Socket.t()) :: Socket.t()` — `socket |> assign_auix(:selection, Selection.new()) |> assign_selected_states() |> refresh_current_page()`.
   - `@spec paginate(Socket.t(), integer(), integer() | nil) :: Socket.t()` — the two clauses of `IndexImpl.paginate/3` without `live_action: :index` in their heads and without `assign_auix(:entity, nil)`: the first, with the guard `when is_nil(items_per_page) or items_per_page == per_page`, returns `socket |> load_page(page) |> assign_selected_states()`; the second is today's second clause.
5. `lib/aurora_uix/templates/basic/handlers/index_impl.ex` — modified.
   - Add `alias Aurora.Uix.Templates.Basic.Handlers.IndexList` and the module attribute `@list_events IndexList.events()`.
   - `auix_mount/3`: keep `subscribe_to_changes/1` and the assigns of `:form_component`, `:show_component`, `:index_form_id` and `:item_index`; replace every other step of the pipeline with `|> IndexList.init(params, &IndexActions.set_actions/1)` as the last step.
   - `auix_handle_event/3`: the `"delete"` clause that takes only `"id"` becomes `{socket, _ids} = IndexList.delete(socket, id)` followed by `{:noreply, put_flash(socket, :info, dt("Item deleted successfully"))}`; its head keeps `%{assigns: %{auix: _auix, streams: _streams}} = socket`. Replace the clauses of the nine events with one clause, at the position of the `"filter-toggle"` clause: `def auix_handle_event(event, params, socket) when event in @list_events, do: IndexList.handle_event(event, params, socket)`. In the `"auix_route_back"` clause, `load_items()` becomes `IndexList.load_items()`. In the pagination clauses, `previous_page/1` and `next_page/1` become `IndexList.previous_page/1` and `IndexList.next_page/1`. In `"read_indexed_entry"`, `load_page/2` becomes `IndexList.load_page/2`.
   - `auix_handle_info/2`: the `{:saved, _}` clause and the `{Events, :refresh}` clause call `IndexList.refresh_current_page/1`; the `%Event{}` clause becomes `socket |> IndexList.apply_event(event) |> react_to_open_entity(event)`; the `{Events, :reset_selection}` clause becomes `IndexList.reset_selection(socket)`.
   - `auix_handle_async/3`: one clause, `def auix_handle_async(task, result, socket), do: IndexList.handle_async(task, result, socket)`.
   - `paginate/3` stays private with both heads, `live_action: :index` included. The first keeps its guard and becomes `socket |> IndexList.paginate(page, items_per_page) |> assign_auix(:entity, nil)`; the second becomes `IndexList.paginate(socket, page, items_per_page)`.
   - `subscribe_to_changes/1` calls `IndexList.resource_schema/1`.
   - Stay in `IndexImpl`, unchanged: the behaviour callbacks, `__using__/1`, `auix_handle_params/3`, the `"delete"` clause with `get_function` and `delete_function`, the `auix_route_forward` clauses, the pagination clauses, `"read_indexed_entry"`, `apply_action/2`, `publish_child_deleted/1`, `react_to_open_entity/2`, `react_to_change/4`, `assign_live_component/1`, `assign_index_routing_stack/2`, `record_action/1`. When UI-5 is merged first, the three `auix_handle_info/2` clauses it adds (`{FormImpl, {:flash, flash}}`, `{Aurora.Uix, id, {:saved, entity}}`, `{Aurora.Uix, id, {:closed}}`) and its `route_after_save/3` and `put_form_flash/2` stay too: they call no list function.
   - Delete `import Phoenix.Component` and the aliases `Aurora.Uix.Filter`, `Aurora.Uix.Layout.Helpers, as: LayoutHelpers`, `Aurora.Uix.Layout.Options, as: LayoutOptions` and `Aurora.Uix.Selection`: every function that used them has moved.
   - `@moduledoc`: add the `## Key Constraints` line `The list itself is run by Aurora.Uix.Templates.Basic.Handlers.IndexList.`
6. Kept host patterns.
   - A layout tree changed in `mount/3` before `super`, and `auix.load_items_options`: the moved `load_items/2` reads both at every rebuild (`load_items_options_test.exs`, unchanged).
   - An untargeted list event reaches `auix_handle_event/3`, where a host clause placed before `super` still sees it first (`selected_bulk_action_test.exs`, unchanged).
   - `stream_insert/4` from an `IndexImpl` handler (`guides/core/liveview.md § Accessing Streams in Handler Hooks`): the engine creates the streams with `stream/4` on the socket it is given, the LiveView socket, under the same names (`auix.source_key`), so the call keeps its target; no test file drives this pattern.
7. Edge cases. An event name outside `events/0` given to `IndexList.handle_event/3` raises `FunctionClauseError` (AC-3); `IndexImpl` never forwards one, because of its guard. The catch-all `auix_handle_info/2` clause stays in `IndexImpl`.
8. Components: none. Theme: none. `dt/1` strings: none new; `"Item deleted successfully"` stays in `IndexImpl`.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted: `mix test test/cases/templates/basic/index_list_test.exs test/cases_live/selected_test.exs test/cases_live/selected_bulk_action_test.exs test/cases_live/sortable_columns_test.exs test/cases_live/where_filter_layout_test.exs test/cases_live/pages_bar_test.exs test/cases_live/infinity_scroll_test.exs test/cases_live/load_items_options_test.exs test/cases_live/events_test.exs test/cases_live/handler_hooks_index_test.exs test/cases_live/navigation_test.exs`)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
4. The grep of AC-6 returns `0`
<!-- section:UI-6:end -->
<!-- section:UI-7:start -->
### UI-7 — UI · generators and handlers · `.IndexComponent` and `IndexComponentImpl`
Depends on: UI-5, UI-6

#### What and why
- **What.** `index_columns` generates `.IndexComponent`: the list of a resource as a LiveComponent, with its filters, sort, pagination, selection and row actions. A host renders it in a LiveView it writes, several times on one page when needed. It reports what the user did with intents.
- **Why.** Today the list exists only inside the generated `.Index` LiveView. UI-9 also needs the component for one-to-many lists.
- **Unchanged.** The generated `.Index` LiveView keeps its own list and its markup.

#### Documentation references
- `guides/core/components.md § Embedding a component`, `§ Inputs`, `§ Outputs`, `§ Events`, `§ Several instances on one page`
- `guides/core/liveview.md § Generated Module Structure`, `§ Targeting the Component`

#### Implementation details

- `index_columns` produces a fourth kind of artifact, `:index_component`: a LiveComponent that runs the list engine of UI-6 on its own socket.
- The generated `.Index` LiveView keeps its own list and does not render the component.
- Every instance derives its DOM ids, its stream ids and its event target from its component `id`, so several instances share a page.
- Given the input `resource`, an instance serves that resource of the LiveView that renders it, as the form and the show component do (UI-5).
- Layout type covered: `:index`. `:form` and `:show` are untouched.
- Backend-agnostic.
- A LiveComponent is needed here: the list holds state that survives a re-render (streams, selection, filters, page) and receives its own events.

##### Acceptance criteria
- [ ] AC-1: a module with one resource and `auix_create_ui()` defines `<Module>.Product.IndexComponent`, registered as `:product_index_component`, whose `auix_kind/0` returns `:index_component`; `index_columns :product, [:reference], module_name: :index_compact` defines `<Module>.Product.IndexCompact` instead, whose `auix_fields/0` returns `[:reference]`; `generate: [:index_component]` defines the index component and no `.Index`, `.FormComponent`, `.ShowComponent`
- [ ] AC-2: `index_columns :product_location, use: :index_compact` gives `:product_location` the columns of the used layout in this module (`auix_configurations().product_location.layout_trees.index` lists `:reference` and `:name`), defines no `<Module>.ProductLocation.IndexComponent`, and still defines `<Module>.ProductLocation.Index`
- [ ] AC-3: error paths. `index_columns :product, use: :nope` fails compilation with `unknown module :nope in use:`; `index_columns :product, [:name], use: :product_index_component` fails with `use: takes no field list and no other option`
- [ ] AC-4: an embedded index given `where` lists only the matching records, in rows whose DOM id is `<component id>-<stream name>-<record id>`
- [ ] AC-5: two instances of one index component on one page are isolated: moving one to its second page changes its rows, leaves the rows of the other, and sends `{:page, 2}` under the id of the first only
- [ ] AC-6: an embedded index reports: the show action of a row sends `{:open, :show, id}`, the new action sends `{:open, :new, nil}`, the delete action deletes the record, removes its row and sends `{:deleted, [id]}`
- [ ] AC-7: the `page` input opens the list on that page, and `options: [sort_disabled?: true]` removes the sort controls of that instance only
- [ ] AC-8: an `%Aurora.Uix.Event{}` given to an instance with `send_update/3` (`auix_event:`) makes it re-read its page with its own scope
- [ ] AC-9: empty path. An embedded index whose `where` matches nothing renders `.auix-items-table-empty` and no row
- [ ] AC-10: `component_handler_module:` on `index_columns` sets the handler of the component; a handler that overrides `auix_handle_event/3` receives the event before the default clauses
- [ ] AC-11: the Ash backend: an embedded index of `:author` lists the authors and its delete action sends `{:deleted, [id]}`
- [ ] AC-12: the markup of the generated LiveView does not change, and `@auix._myself` is `nil` there: no test file of the LiveView changes (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- test` listing only `test/cases/create_ui_validation_test.exs`, `test/cases_live/components_index_test.exs` and `test/cases_live/ash_components_index_test.exs`, and `mix test` green)
- [ ] AC-13: an embedded index given `resource: :product_location`, rendered by a LiveView written by hand that declares `index_columns :product_location, use: ComponentsIndexViews.auix_module(:index_compact)`, lists the product locations in rows whose DOM id is `<component id>-product_locations-<record id>`, with the columns of the used layout: a row shows the reference of its record and not its type
- [ ] AC-14: error path. `Helpers.resource_binding/4` with `:index` raises `ArgumentError` (message contains `does not pair`) for an index component the rendering LiveView does not pair with the resource
- [ ] AC-15: degraded path. `CreateUI.put_defaults/1` (UI-4) gives options built by hand the kind of this section: `artifacts.index_component` is `MyApp.Views.Product.IndexComponent`, and with `layout_type: :index` and `layout_tree: index` the `exposed_layouts` are `%{index_component: %{index | resource: nil}}`

##### Test ports
- No route. `Aurora.UixWeb.Test.ComponentHostLive` (UI-5) with `live_isolated/3`.
- No route. `Aurora.UixWeb.Test.ComponentsIndexPairedHostLive`, a LiveView written by hand that declares one pairing, with `live_isolated/3` · layout type `:index` · observable: `has_element?/2` and `has_element?/3` on `#locations tr[id='locations-product_locations-<record id>']`.
- Observable: `has_element?/2` on `#<id> tr[id='<id>-products-<record id>']`, `#<id> .auix-items-table-empty`, `#<id> button[name='auix-sort-reference']`, and on `#auix-host-intents li[data-component][data-intent][data-value]`.
- Compile-time behaviour through `compile/1` of `test/cases/create_ui_validation_test.exs`.

##### Red tests
`Host`, `mount_components/2` and `T` as in UI-5. `C` is `T.Product.IndexComponent`. The products of a test are `delete_all_inventory_data()`, `create_sample_products(10, :test)` and `products = Product |> Aurora.Uix.Repo.all() |> Enum.sort_by(& &1.reference)`; `p(n)` is `Enum.at(products, n - 1)`, whose reference is `"item_test-<nn>"`. The test module declares `auix_resource_metadata(:product, context: Inventory, schema: Product)` and `auix_create_ui do index_columns(:product, [:reference, :name], pagination_items_per_page: 5) end`. `row(id, product)` is the selector `"##{id} tr[id='#{id}-products-#{product.id}']"`.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | amend `test/cases/create_ui_validation_test.exs` `"every generated module has a registry entry"` and `"an embedded resource generates no modules"` (UI-4): add `product_index_component: Module.concat(mod, Product.IndexComponent)` to the expected map of the first, and `:product_index_component` and `:user_index_component` to the expected key list of the second. Amend `"two names for one module fail compilation"` (UI-4): add the line `index_columns :product_compact, [:name], module_name: :index_compact` to its body, directly before the line `index_live :product_compact, module_name: :compact`; its `assert_raise` stays. Add to the same file | `compile/1` with the three bodies of AC-1 | same | `"index_columns generates an index component"` | `mod.auix_module(:product_index_component) == Module.concat(mod, Product.IndexComponent)`; `mod.auix_module(:product_index_component).auix_kind() == :index_component`; with `module_name: :index_compact`: `mod.auix_module(:index_compact) == Module.concat(mod, Product.IndexCompact)`, `mod.auix_module(:index_compact).auix_fields() == [:reference]` and `refute Code.ensure_loaded?(Module.concat(mod, Product.IndexComponent))`; with `generate: [:index_component]`: the component is loaded, and `Product.Index`, `Product.FormComponent`, `Product.ShowComponent` are not |
| AC-2 | add to same | body starts with `auix_resource_metadata :product_location, context: Aurora.Uix.Guides.Inventory, schema: Aurora.Uix.Guides.Inventory.ProductLocation`, then `auix_create_ui do` / `index_columns :product, [:reference, :name], module_name: :index_compact` / `index_columns :product_location, use: :index_compact` / `end` | same | `"use: gives a resource the index layout of another"` | `Enum.map(mod.auix_configurations().product_location.layout_trees.index.children, & &1.key) == [:reference, :name]`; `refute Code.ensure_loaded?(Module.concat(mod, ProductLocation.IndexComponent))`; `Code.ensure_loaded?(Module.concat(mod, ProductLocation.Index))` |
| AC-3 | add to same | the two bodies of AC-3 | same | `"use: on index_columns rejects what it cannot take"` | two `assert_raise DslError, regex, …` |
| AC-4 | new file (`ls test/cases_live \| grep components_index` prints nothing). Module `Aurora.UixWeb.Test.ComponentsIndexTest` | `mount_components(conn, [%{module: C, id: "low", props: %{where: [{:reference, :lt, "item_test-04"}]}}])` | `test/cases_live/components_index_test.exs` | `"an embedded index lists its scope"` | `has_element?(view, row("low", p(1)))`; `has_element?(view, row("low", p(3)))`; `refute has_element?(view, row("low", p(4)))` |
| AC-5 | add to same | two components: `"a"` with the `where` of AC-4, `"b"` without props | same | `"two instances keep their own page"` | `view \|> element("#b div[name$='-xl2'] a[name='auix-pages_bar_page-2']") \|> render_click()`; `has_element?(view, row("b", p(6)))`; `refute has_element?(view, row("b", p(1)))`; `has_element?(view, row("a", p(1)))`; `has_element?(view, "#auix-host-intents li[data-component='b'][data-intent='page'][data-value='2']")`; `refute has_element?(view, "#auix-host-intents li[data-component='a']")` |
| AC-6 | add to same | one component `"a"` without props | same | `"an embedded index reports open and delete"` | click `row("a", p(1)) <> " td.auix-items-table-action-cell a[name='auix-show-product']"`: intent `[data-intent='open'][data-value='show:#{p(1).id}']`; click `"#a a[name='auix-new-product']"`: intent `[data-intent='open'][data-value='new:']`; click `row("a", p(2)) <> " td.auix-items-table-action-cell a[name='auix-delete-product']"`: `refute has_element?(view, row("a", p(2)))`, intent `[data-intent='deleted'][data-value='#{p(2).id}']`, `Aurora.Uix.Repo.get(Product, p(2).id) == nil` |
| AC-7 | add to same | `"a"` with `props: %{page: 2}`; `"b"` with `props: %{options: [sort_disabled?: true]}` | same | `"an instance takes its page and its options"` | `has_element?(view, row("a", p(6)))`; `refute has_element?(view, row("a", p(1)))`; `has_element?(view, "#a button[name='auix-sort-reference']")`; `refute has_element?(view, "#b button[name='auix-sort-reference']")` |
| AC-8 | add to same | `create_sample_products(3, :test)` in place of ten; `"a"` without props; then `{:ok, added} = Aurora.Uix.Repo.insert(%Product{reference: "item_test-9", name: "Added"})` | same | `"an event refreshes an instance"` | `refute has_element?(view, row("a", added))`; `Phoenix.LiveView.send_update(view.pid, C, id: "a", auix_event: %Aurora.Uix.Event{schema: Product, action: :created, ids: [added.id]})`; `has_element?(view, row("a", added))` |
| AC-9 | add to same | `"a"` with `props: %{where: [{:reference, "none"}]}` | same | `"an embedded index with no record says so"` | `has_element?(view, "#a .auix-items-table-empty")`; `refute has_element?(view, "#a tr[id^='a-products-']")` |
| AC-10 | add to same. A second pair of top-level modules in the file, before the test module: `Aurora.UixWeb.Test.ComponentsIndexHandler` (`use Aurora.Uix.Templates.Basic.Handlers.IndexComponentImpl`; one clause `def auix_handle_event("ping", _params, socket), do: {:noreply, Aurora.Uix.Templates.Basic.Helpers.report_intent(socket, {:page, 99})}`, then `def auix_handle_event(event, params, socket), do: super(event, params, socket)`) and `Aurora.UixWeb.Test.ComponentsIndexHandled` (`use Aurora.Uix`, `:product`, `auix_create_ui generate: [:index_component] do index_columns(:product, [:reference], component_handler_module: Aurora.UixWeb.Test.ComponentsIndexHandler) end`) | mount `%{module: Aurora.UixWeb.Test.ComponentsIndexHandled.Product.IndexComponent, id: "h", props: %{}}` | same | `"component_handler_module sets the handler of the component"` | `view \|> with_target("#h") \|> render_click("ping", %{})` (`#h` is the root of the component); `has_element?(view, "#auix-host-intents li[data-component='h'][data-intent='page'][data-value='99']")` |
| AC-11 | new file. Module `Aurora.UixWeb.Test.AshComponentsIndexTest`, `auix_resource_metadata(:author, ash_resource: Aurora.Uix.Guides.Blog.Author)`, `auix_create_ui()` | `delete_all_blog_data()`; `[author \| _] = create_sample_authors(2)`; mount `%{module: T.Author.IndexComponent, id: "a", props: %{}}` | `test/cases_live/ash_components_index_test.exs` | `"an embedded index on Ash"` | `has_element?(view, "#a tr[id='a-authors-#{author.id}']")`; click its `td.auix-items-table-action-cell a[name='auix-delete-author']`; `has_element?(view, "#auix-host-intents li[data-component='a'][data-intent='deleted'][data-value='#{author.id}']")` |
| AC-13 | add to `test/cases_live/components_index_test.exs`. A third pair of top-level modules in the file, before the test module (`grep -rnE 'ComponentsIndexViews\|ComponentsIndexPaired' lib test` prints nothing). `Aurora.UixWeb.Test.ComponentsIndexViews`: `use Aurora.Uix`; `auix_resource_metadata(:product, context: Inventory, schema: Product)`; `auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)`; `auix_create_ui generate: [:index_component] do index_columns(:product, [:reference, :name], module_name: :index_compact) end`. `Aurora.UixWeb.Test.ComponentsIndexPairedHostLive`: `use Aurora.UixWeb.Test, :live_view`; `use Aurora.Uix`; `@auix_resource_metadata %{product_location: Aurora.UixWeb.Test.ComponentsIndexViews.auix_resource(:product_location)}`; `auix_create_ui generate: [] do index_columns(:product_location, use: Aurora.UixWeb.Test.ComponentsIndexViews.auix_module(:index_compact)) end`; `def mount(_params, _session, socket), do: {:ok, socket}`; `render/1` with the template `<div id="auix-paired-host"><.live_component module={Aurora.UixWeb.Test.ComponentsIndexViews.auix_module(:index_compact)} id="locations" resource={:product_location} /></div>`; no `handle_info/2` | `delete_all_inventory_data()`; `create_sample_product_locations(2)`; `[first \| _] = locations = Aurora.Uix.Repo.all(ProductLocation)`; `{:ok, view, _html} = live_isolated(conn, Aurora.UixWeb.Test.ComponentsIndexPairedHostLive)`; `location_row = fn location -> "#locations tr[id='locations-product_locations-#{location.id}']" end` | same | `"a paired index serves a resource of the LiveView that renders it"` | `Enum.all?(locations, &has_element?(view, location_row.(&1)))`; `has_element?(view, location_row.(first), first.reference)`; `refute has_element?(view, location_row.(first), first.type)` |
| AC-14 | add to same | `socket = %Phoenix.LiveView.Socket{view: Aurora.UixWeb.Test.ComponentsIndexPairedHostLive, assigns: %{__changed__: %{}}}` | same | `"an index component is checked against the pairing"` | `assert_raise ArgumentError, ~r/does not pair/, fn -> Aurora.Uix.Templates.Basic.Helpers.resource_binding(socket, %{id: "x", resource: :product_location}, C, :index) end` (`C` is the index component of `:product` in the test module, which the host does not pair) |
| AC-15 | amend `test/cases/create_ui_validation_test.exs` `"options built by hand take the default artifacts"` (UI-4) | add `index = %Aurora.Uix.Layout.Node.Index{resource: :product}` to the setup of the test | same | same | add `defaults.artifacts.index_component == MyApp.Views.Product.IndexComponent` and `CreateUI.put_defaults(%{options \| layout_type: :index, layout_tree: index}).exposed_layouts == %{index_component: %{index \| resource: nil}}` |

##### Modules & components
1. The registry gains the kind (edits of the code of UI-4).
   - `lib/aurora_uix/layout/create_ui.ex`, the naming code (UI-4, steps 1 and 2): `kind()` and `kinds/0` gain `:index_component` (`[:index_live, :index_component, :form_component, :show_component]`). `@component_kinds` becomes `[index: :index_component, form: :form_component, show: :show_component]`: `module_names/5` then names the index component, and `used_layouts/2` handles `:index` first, then `:form`, then `:show`, with the same rules (`use:` substitution, kind check, field check); a `nil` index layout takes `RenderTree.default(:index, resource, opts)` in `exposed_layout/4`. In `validate_live_views/3`, `Enum.all?(@component_kinds, …)` becomes `Enum.all?(Keyword.take(@component_kinds, [:form, :show]), …)`: a LiveView needs its form and its show component only. In `resource_modules/4`, the base map of `artifacts` gains `index_component: nil`, and `exposed_layouts` holds the kind `:index_component` for a resource this module generates the index component for. `put_defaults/1` (UI-4, step 1): the map of `default_artifacts/1` gains `index_component: module_name(caller, hint, :index_component)`, and `default_exposed_layouts/1` gains, directly before its last clause, `defp default_exposed_layouts(%{layout_type: :index} = options), do: %{index_component: %{options.layout_tree | resource: nil}}`. Options built by hand for `IndexGenerator.generate_module/1` (step 4) then generate the LiveView and the component, as `auix_create_ui` does without `generate:`.
   - `lib/aurora_uix/layout/create_ui.ex`, the generation: `generate_tag?(:index, generate)` becomes `:index_live in generate or :index_component in generate`. `@moduledoc` `## Generated modules`: add `:<schema>_index_component` and `component_handler_module:`.
   - `lib/aurora_uix/layout/node/index.ex`: add `module_name: nil`, `use: nil` and `component_handler_module: nil` to `defstruct` after `handler_module: nil`, and to `@type t()`.
   - `lib/aurora_uix/layout/create_ui/dsl.ex`: the `generate` list of `@ui_schema` gains `:index_component`. `typed_keys(:index, handler_key)` returns `[:renderers, :order_by, :where, :module_name, :use, :component_handler_module, handler_key]`. `container_opts/2` adds `component_handler_module: typed[:component_handler_module]` to its map. `index_columns` has no block and no entity option, so Spark hands `index_columns :r, use: :x` over as the column list `[use: :x]`; a new first clause of `build_node/1` reads it, and the existing clause rejects `use:` among the options. `name` takes the two forms `use:` takes on `edit_layout` (UI-4, step 2): a name of the registry, and a generated module. Spark evaluates the value, so `use: Views.auix_module(:index_compact)` arrives as the module:
     ```elixir
     def build_node(%Node.Index{children: [use: name], options: []} = index) when is_atom(name),
       do: {:ok, %{index | children: [], use: name}}

     def build_node(%Node.Index{} = index) do
       with {:ok, columns} <- field_nodes(index.children),
            {:ok, container} <- container_opts(index.options, :index),
            :ok <- validate_index_naming(container) do
         {:ok, struct(%{index | children: columns}, container)}
       end
     end
     ```
     with the new private `validate_index_naming/1` (`@spec validate_index_naming(map()) :: :ok | {:error, binary()}`): `{:error, "use: takes no field list and no other option"}` when `container.use` is not `nil`, `:ok` otherwise. `@moduledoc` `## Key Constraints`: add `` A resource field named `use` cannot be the only column of `index_columns`. ``
   - `lib/aurora_uix/templates/basic/helpers.ex`: the binding functions take `:index`. `component_binding/3` (UI-4) and `resource_binding/4`, `bind_resource/4`, `component_kind/1` (UI-5): `:form | :show` becomes `:index | :form | :show` in the four `@spec`s. `component_kind/1` gains the first clause `defp component_kind(:index), do: :index_component`. In `component_binding/3` the last step `|> ModulesGenerator.component_opts()` becomes `|> binding_opts(layout_type)`, with the new private function (`grep -rn 'binding_opts' lib test` prints nothing):
     ```elixir
     # The options each generator compiles into its module.
     @spec binding_opts(map(), :index | :form | :show) :: map()
     defp binding_opts(opts, :index), do: ModulesGenerator.remove_omitted_fields(opts)
     defp binding_opts(opts, _layout_type), do: ModulesGenerator.component_opts(opts)
     ```
     `IndexGenerator.generate_module/1` applies `ModulesGenerator.remove_omitted_fields/1` alone to the options it compiles; the form and show generators apply `component_opts/1`. Load guarantee: `configurations[resource].artifacts.index_component` is filled by `resource_modules/4` of `create_ui.ex` (first item of this step), also under `generate: []`.
2. `Aurora.Uix.Templates.Basic.Handlers.IndexComponentImpl` at `lib/aurora_uix/templates/basic/handlers/index_component_impl.ex` — new (`grep -rnE 'IndexComponentImpl|Handlers\.IndexComponent\b' lib test` prints nothing). Shape of `handlers/show_component_impl.ex`: callbacks `auix_update/2`, `auix_handle_event/3` and `auix_handle_async/3` (`@callback auix_handle_async(task :: atom(), result :: term(), socket :: Socket.t()) :: {:noreply, Socket.t()}`); `__using__/1` defines `update/2`, `handle_event/3` and `handle_async/3` delegating to them, `defdelegate`s the three to `IndexComponentImpl`, and ends with `defoverridable LiveComponent` and `defoverridable` of the three. Imports `Aurora.Uix.Templates.Basic.Helpers` and `Phoenix.LiveView`; aliases `Aurora.Uix.Event`, `Aurora.Uix.Templates.Basic.Actions.Index, as: IndexActions`, `Aurora.Uix.Templates.Basic.Handlers.IndexComponentImpl`, `Aurora.Uix.Templates.Basic.Handlers.IndexList`, `Aurora.Uix.Templates.Basic.Renderers.IndexRenderer`, `Phoenix.LiveComponent`, `Phoenix.LiveView.Socket`. `@moduledoc` with `## Key Features` (the list engine on a component socket; inputs; intents; per-instance ids) and `## Key Constraints` (never navigates; events arrive through `@auix._myself`; `Aurora.Uix.Event`s arrive through `update/2`).
   - `auix_update/2`, three clauses.
     1. `%{auix_event: %Event{} = event}` with a socket whose `auix` has `:_inputs`: `{:ok, IndexList.apply_event(socket, event)}`.
     2. `%{auix_event: _event}` otherwise: `{:ok, socket}`.
     3. Any other assigns: `inputs = Map.take(assigns, [:where, :order_by, :parent, :page, :options])`. When `socket.assigns.auix[:_inputs] == inputs`, return `{:ok, assign_auix(socket, :notify, Map.get(assigns, :notify, self()))}`. Otherwise run the initialisation below and return `{:ok, socket}`.
   - Initialisation, in this order, with `id = socket.assigns.id` and `first? = not Map.has_key?(socket.assigns.auix, :_inputs)`:
     1. `assign_auix/3` of `:_inputs` (`inputs`), `:_myself` (`socket.assigns.myself`), `:_instance` (`id`), `:notify` (`Map.get(assigns, :notify, self())`), `:index_form_id` (`"auix-index-form-#{id}"`), `:entity` (`nil`), `:item_index` (`-1`).
     2. `assign_auix_new(:_base_layout_tree, auix.layout_tree)`: the layout tree as compiled, kept once.
     3. The instance layout tree, assigned to `:layout_tree`: `struct(base, %{where: where, order_by: Map.get(inputs, :order_by) || base.order_by, options: Keyword.merge(base.options, Map.get(inputs, :options, []))})`, where `scope` is the parent condition (`[{key, value}]` for `parent: {key, value}`, `[]` without) followed by `IndexList.where_conditions(Map.get(inputs, :where))`, and `where` is `base.where` for an empty `scope` and `IndexList.where_conditions(base.where || resource_config.where) ++ scope` otherwise; `resource_config` is `auix.configurations[auix.resource_name].resource_config`. Load guarantee: `Layout.Options` reads every index option from `auix.layout_tree.options`, and `IndexList.load_items/2` reads `where` and `order_by` from `auix.layout_tree`.
     4. `IndexList.init(socket, %{"page" => to_string(Map.get(inputs, :page, 1))}, prepare)`, where `prepare` calls `IndexActions.set_actions/1` and then, when `first?`, `Phoenix.LiveView.stream_configure/3` for every stream name — `auix.source_key`, and `"#{auix.source_key}__#{suffix}"` for each suffix of `auix.layout_options.alternate_streams_suffixes` — with `dom_id: &"#{id}-#{name}-#{&1.id}"`. A stream is configured once, before its first `stream/4`.
     5. Every field of `auix.index_fields` gets `html_id: "#{id}-#{field.html_id}"`, so the filter inputs of two instances differ.
     6. `render_with(&IndexRenderer.render_component/1)`.
   - `auix_handle_event/3`, clauses in this order: `event in @list_events` (`@list_events IndexList.events()`) delegates to `IndexList.handle_event/3`; `"auix_open"` returns `{:noreply, report_open(socket, params)}`; `"delete"` with `%{"id" => id}` runs `{socket, ids} = IndexList.delete(socket, id)` and returns `{:noreply, report_intent(socket, {:deleted, ids})}`; `"pagination_to_page"` with `%{"page" => page}` runs `IndexList.paginate(socket, String.to_integer(page), nil)` and reports `{:page, page}` with the integer; `"pagination_previous"` and `"pagination_next"` follow `IndexImpl`: with `auix.layout_options.pagination_disabled?` true, and with the param `"pagination_disabled?"`, they run `IndexList.paginate(socket, pagination.page - 1, Map.get(params, "items_per_page"))` (`+ 1` for next) and report nothing; otherwise they paginate to `IndexList.previous_page(pagination)` (`next_page/1` for next) and report `{:page, page}`; a last clause raises `"Event not handled. event: #{inspect(event)}. params: #{inspect(params)}"`, as `ShowComponentImpl` does.
   - `auix_handle_async/3`: for `:auix_selection_delete_all` with `{:ok, ids} = result`, run `{:noreply, socket} = IndexList.handle_async(:auix_selection_delete_all, result, socket)` and return `{:noreply, report_intent(socket, {:deleted, ids})}`; every other call delegates to `IndexList.handle_async/3`.
3. `Aurora.Uix.Templates.Basic.Handlers.IndexComponent` at `lib/aurora_uix/templates/basic/handlers/index_component.ex` — new, the default handler: `@moduledoc` in the form of `handlers/show_component.ex` and `use Aurora.Uix.Templates.Basic.Handlers.IndexComponentImpl`.
4. `generators/index_generator.ex` — modified. `generate_module/1` returns a block of up to two modules: the LiveView, unchanged, when `:index_live in parsed_opts.generate`, and the component when `:index_component in parsed_opts.generate`. The component handler is `Map.get(parsed_opts.layout_tree, :component_handler_module) || IndexComponentHandler` (alias `Aurora.Uix.Templates.Basic.Handlers.IndexComponent, as: IndexComponentHandler`).
   ```elixir
   defmodule unquote(parsed_opts.artifacts.index_component) do
     @moduledoc false

     use unquote(parsed_opts.modules.web), :live_component

     unquote(
       CreateUI.module_code(
         :index_component,
         Map.fetch!(parsed_opts.exposed_layouts, :index_component)
       )
     )

     @impl true
     def update(assigns, socket) do
       merged_auix =
         socket.assigns
         |> Map.get(:auix, %{})
         |> Map.merge(Map.get(assigns, :auix, %{}))
         |> Map.merge(Helpers.resource_binding(socket, assigns, __MODULE__, :index))

       socket
       |> assign(assigns |> Map.delete(:auix_event) |> Map.put(:auix, merged_auix))
       |> Helpers.assign_parsed_opts(unquote(Macro.escape(parsed_opts)))
       |> Helpers.assign_actor_to_auix()
       |> then(&unquote(component_handler).update(assigns, &1))
     end

     @impl true
     def handle_event(event, params, socket),
       do: unquote(component_handler).handle_event(event, params, socket)

     @impl true
     def handle_async(task, result, socket),
       do: unquote(component_handler).handle_async(task, result, socket)
   end
   ```
   The binding of `resource` enters `auix` before `Helpers.assign_parsed_opts/2`, as in the form and the show component (UI-5, step 2). An update that carries `auix_event` carries no `resource`, and `resource_binding/4` returns `%{}` for it. `CreateUI.module_code/2` (UI-4, step 1) gives the component `auix_kind/0`, `auix_fields/0` (its columns) and `auix_layout/0` (its `%Node.Index{}` as written, `resource: nil`); `Aurora.Uix.Layout.CreateUI` is aliased in the generator since UI-4.
5. `renderers/index_renderer.ex` — modified. The list moves into a function component both renderers call; the LiveView markup stays the same.
   - New public function component `index_list/1` (`grep -rnE 'index_list\b|render_component\b' lib` prints nothing): `attr(:auix, :map, required: true)`, `attr(:id, :string, required: true)`, `attr(:streams, :any, required: true)`. It computes `default_show_function` from `assigns.auix.index_row_actions`, as `render/1` does today, and renders the markup of `render/1` from `<div class="auix-index-actions">` through the closing tag of `<div name="auix-index-footer-actions">`, with three changes: `<.auix_items id={@id} … streams={@streams}>`; `phx-target={@auix[:_myself]}` on `<.auix_simple_form>`; and `_myself: @auix[:_myself]` added to the map given to `auix_items` as `auix`.
   - `render/1`: drops the `default_show_function` computation and replaces the moved markup with `<.index_list auix={@auix} id={"auix-table-#{@auix.uri_path_id}-index"} streams={@auix.layout_options.get_streams.(assigns)} />`. The hook div, the header, the flashes and the modal stay.
   - New public `render_component/1` (`@spec render_component(map()) :: Rendered.t()`):
     ```heex
     <div id={@id} class="auix-index-container" name="auix-index-component">
       <.index_list auix={@auix} id={"auix-table-#{@id}-index"} streams={@auix.layout_options.get_streams.(assigns)} />
     </div>
     ```
     `auix-index-container` is an existing class of `themes/base.ex`.
   - Selectors the tests assert on: `#<id>` (component root), `#auix-table-<id>-index` (table body), `tr[id='<id>-<stream>-<record id>']`.
6. Event targets. `phx-target={nil}` renders no attribute, so each edit leaves the LiveView markup as it is. New public helpers in `templates/basic/helpers.ex` (`grep -rnE 'target_opts|instance_dom_id' lib test` prints nothing), with `@doc` and `@spec`:
   ```elixir
   @spec target_opts(map(), keyword()) :: keyword()
   def target_opts(%{_myself: target}, opts) when not is_nil(target),
     do: Keyword.put(opts, :target, target)

   def target_opts(_auix, opts), do: opts

   @spec instance_dom_id(map(), binary()) :: binary()
   def instance_dom_id(%{_instance: instance}, base) when not is_nil(instance),
     do: "#{base}-#{instance}"

   def instance_dom_id(%{module: module}, base), do: "#{base}-#{module}"
   ```
   - `components/components.ex`: `auix_items_table/1`, `<tbody>`: add `phx-target={@auix[:_myself]}`. `auix_items_card/1`: the two `JS.push(…)` calls take their options through `BasicHelpers.target_opts(@auix, loading: true, value: %{…})`. `pages_selection/1`: new `attr(:target, :any, default: nil)` and `phx-target={@target}` on its seven `<a>` elements. `table_column_sort/1`: `phx-target={@auix[:_myself]}` on the `<button>`.
   - `actions/index.ex`: `remove_row_action/1`: `JS.push("delete", BasicHelpers.target_opts(@auix, value: %{id: row_info_id(@auix)}))`. Add `phx-target={@auix[:_myself]}` to the two buttons of `selected_uncheck_all_action/1`, the two of `selected_check_all_action/1`, the two `<a>` of `toggle_filters_action/1`, the `<.form>` and the `<.button>` of `sort_header_action/1`, and the buttons of `clear_filters_action/1` and `submit_filters_action/1`. `pagination_action/1`: `target={@auix[:_myself]}` on its four `<.pages_selection>`. Ids: `selected_delete_all_action/1` uses `id={BasicHelpers.instance_dom_id(@auix, "auix-delete-all-button")}`; `sort_header_action/1` uses `BasicHelpers.instance_dom_id(@auix, "auix-sort-form")` and `BasicHelpers.instance_dom_id(@auix, "auix-sort-key")`. `ConfirmButton` already targets `uix_id_selector(@auix.index_form_id)`.
   - `actions/index.ex`, actions that navigate in the LiveView and report in a component. New first clause on `%{auix: %{notify: _notify}} = assigns` for `show_row_action/1`, `edit_row_action/1` and `new_header_action/1`. Each renders the same element with the same `name`, `class` and inner content, with `phx-click="auix_open"`, `phx-value-action` (`"show"`, `"edit"`, `"new"`), `phx-value-id={row_info_id(@auix)}` for the two row actions, and `phx-target={@auix._myself}`, and without `patch`.
   - `handlers/index_impl.ex`, `auix_mount/3`: add `|> assign_auix(:_myself, nil)` before `IndexList.init/3`, so an action shared by both reads `@auix._myself` in the LiveView too.
7. Markup changes and the tests that drive them. In the LiveView no selector, `name`, `id` and label changes: `grep -rn 'auix-sort-form\|auix-sort-key\|auix-delete-all-button\|auix-index-form' test` lists the tests that use those ids, and each id keeps its value because `auix._instance` is absent there. The component markup is new.
8. Edge cases.
   - Inputs that do not change between two updates leave the list as it is (selection, page and filters survive a re-render of the host).
   - A changed input re-initialises the list: filters, sort and selection start again.
   - `send_update/3` to a component that left the page logs a warning in LiveView and raises nothing.
   - A resource whose records have no `id` field cannot be embedded: the stream id reads `id`, as the default stream id does.
   - An instance keeps the resource of its first update; `resource_binding/4` raises for another one (UI-5, AC-11).
9. Components: `index_list/1` (contract in step 5). Theme: none. `dt/1` strings: none.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted: `mix test test/cases/create_ui_validation_test.exs test/cases_live/components_index_test.exs test/cases_live/ash_components_index_test.exs test/cases_live/selected_test.exs test/cases_live/sortable_columns_test.exs test/cases_live/pages_bar_test.exs test/cases_live/where_filter_layout_test.exs test/cases_live/create_ui_actions_index_test.exs test/cases_live/navigation_test.exs`)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-7:end -->
<!-- section:UI-8:start -->
### UI-8 — UI · live · `Aurora.Uix.Live.ComponentHooks`
Depends on: UI-7

#### What and why
- **What.** An `on_mount` hook for a LiveView a host writes. It keeps the index components of that LiveView up to date when a record is created, updated and deleted elsewhere.
- **Why.** An `Aurora.Uix.Event` arrives at the LiveView, and a component cannot receive it. Without the hook the host forwards every event to every component by hand.
- **Unchanged.** The generated `.Index` LiveView does not use the hook.

#### Documentation references
- `guides/core/components.md § Live updates`, `§ Embedding a component`
- `guides/core/liveview.md § Reacting to Data Changes`

#### Implementation details

- The section adds an `on_mount` hook for a hand-written LiveView.
- The index components of the LiveView register with it.
- It subscribes to the `Aurora.Uix.Events` topic of each schema they list, and forwards every `%Aurora.Uix.Event{}` to them through `send_update/3`.
- The generated `.Index` LiveView does not use it: it subscribes on its own (`IndexImpl.subscribe_to_changes/1`).
- Layout type covered: `:index`. Backend-agnostic.

##### Acceptance criteria
- [ ] AC-1: in a LiveView mounted with the hook, an `Aurora.Uix.Events.created/2` published by another process adds the record to an embedded index, with no code in the host
- [ ] AC-2: the same event reaches every registered instance: two instances with different scopes each re-read with their own scope
- [ ] AC-3: without the hook the instance does not change when the event is published
- [ ] AC-4: the hook consumes the events of registered schemas only: a message that is not an `%Aurora.Uix.Event{}` of a registered schema reaches the host's `handle_info/2`
- [ ] AC-5: error path. `ComponentHooks.register/2` in a process without the hook returns `:ok` and subscribes to nothing

##### Test ports
- No route. `Aurora.UixWeb.Test.ComponentHostLive` with `live_isolated/3`; the session key `"hooks"` set to `true` mounts the hook.
- Observable: `has_element?/2` on the rows of the instances and on `#auix-host-other li[data-message]`.

##### Red tests
Names as in UI-7. Events are published from the test process with `Aurora.Uix.Events.created(record)`.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1, AC-2 | new file (`ls test/cases_live \| grep component_hooks` prints nothing). Module `Aurora.UixWeb.Test.ComponentHooksTest`, resource and layout of the UI-7 test module | `delete_all_inventory_data()`; `create_sample_products(3, :test)`; `live_isolated(conn, Host, session: %{"hooks" => true, "components" => [%{module: C, id: "a", props: %{}}, %{module: C, id: "b", props: %{where: [{:reference, :lt, "item_test-2"}]}}]})`; `{:ok, added} = Aurora.Uix.Repo.insert(%Product{reference: "item_test-0", name: "Added"})`; `Aurora.Uix.Events.created(added)`; `_ = :sys.get_state(view.pid)`, so the event is handled before the assertions render | `test/cases_live/component_hooks_test.exs` | `"the hook forwards events to every instance"` | `has_element?(view, "#a tr[id='a-products-#{added.id}']")`; `has_element?(view, "#b tr[id='b-products-#{added.id}']")` (`"item_test-0"` is below `"item_test-2"`) |
| AC-3 | add to same | the same mount without `"hooks"`, one instance `"a"` | same | `"without the hook nothing is forwarded"` | after the publish and `_ = :sys.get_state(view.pid)`: `refute has_element?(view, "#a tr[id='a-products-#{added.id}']")` |
| AC-4 | add to same | mount with `"hooks" => true` and instance `"a"`; `send(view.pid, {:other, "x"})` | same | `"other messages reach the host"` | `has_element?(view, "#auix-host-other li[data-message='x']")` |
| AC-5 | new file. Module `Aurora.Uix.Live.ComponentHooksTest`, `use ExUnit.Case, async: true` | none | `test/cases/component_hooks_test.exs` | `"register/2 without the hook does nothing"` | `ComponentHooks.register(%Phoenix.LiveComponent.CID{cid: 1}, Aurora.Uix.Guides.Inventory.Product) == :ok`; `Process.get({ComponentHooks, :instances}) == nil` |

##### Modules & components
1. `Aurora.Uix.Live.ComponentHooks` at `lib/aurora_uix/live/component_hooks.ex` — new (`grep -rn 'ComponentHooks' lib test` prints nothing; `ls lib/aurora_uix/live` fails: the directory is new). Aliases `Aurora.Uix.Event`, `Aurora.Uix.Events`, `Phoenix.LiveComponent.CID`, `Phoenix.LiveView.Socket`. `@moduledoc` first paragraph: `on_mount hook that forwards Aurora.Uix.Events to the index components of a hand-written LiveView.` `## Key Features`: one subscription per schema; forwarding with `send_update/3`; no code in the host. `## Key Constraints`: the registry lives in the process dictionary of the LiveView; a component that left the page stays registered, and LiveView ignores the update sent to it; the generated `.Index` LiveView does not use the hook.
   ```elixir
   @key {__MODULE__, :instances}

   @spec on_mount(atom(), map(), map(), Socket.t()) :: {:cont, Socket.t()}
   def on_mount(:default, _params, _session, socket) do
     Process.put(@key, %{})
     {:cont, Phoenix.LiveView.attach_hook(socket, :auix_component_events, :handle_info, &forward/2)}
   end

   @spec register(CID.t(), module()) :: :ok
   def register(%CID{} = cid, schema) do
     case Process.get(@key) do
       nil ->
         :ok

       instances ->
         unless Map.has_key?(instances, schema), do: :ok = Events.subscribe(schema)
         Process.put(@key, Map.update(instances, schema, [cid], &Enum.uniq([cid | &1])))
         :ok
     end
   end

   @spec forward(term(), Socket.t()) :: {:cont | :halt, Socket.t()}
   defp forward(%Event{schema: schema} = event, socket) do
     case Map.get(Process.get(@key, %{}), schema) do
       nil ->
         {:cont, socket}

       cids ->
         Enum.each(cids, &Phoenix.LiveView.send_update(&1, %{auix_event: event}))
         {:halt, socket}
     end
   end

   defp forward(_message, socket), do: {:cont, socket}
   ```
   Both public functions get a `@doc` with `## Parameters` and `## Returns`. Above `@key`, one comment: `# A LiveComponent runs in the process of its LiveView and cannot reach the LiveView's socket; the process dictionary is the one place both can read.`
2. `handlers/index_component_impl.ex` (UI-7) — in the initialisation, after step 5 and before `render_with/2`, when `first?` and `connected?(socket)`: `ComponentHooks.register(socket.assigns.myself, IndexList.resource_schema(socket.assigns.auix))`. Add `alias Aurora.Uix.Live.ComponentHooks`. `IndexList.resource_schema/1` is public since UI-6.
3. `test/support/app_web/component_host_live.ex` (UI-5) — modified. `mount/3`: assign `:other` to `[]`; when `Map.get(session, "hooks")` is `true`, replace the socket with the one `{:cont, socket} = Aurora.Uix.Live.ComponentHooks.on_mount(:default, %{}, session, socket)` returns. `render/1`: add `<ul id="auix-host-other"><li :for={message <- @other} data-message={message}></li></ul>` inside `#auix-host`. New clauses of `handle_info/2`: `{:other, message}` appends to `:other`; `%Aurora.Uix.Event{}` appends `"event"` to `:other`, so an event the hook does not consume is visible.
4. Edge cases. `Events.subscribe/1` returns `:ok` without subscribing when no `:pubsub_server` is configured; the hook then forwards nothing and the components still work. A component of a schema registers once per instance; a second registration of the same instance is ignored by `Enum.uniq/1`.
5. Components: none. Theme: none. `dt/1` strings: none.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted: `mix test test/cases_live/component_hooks_test.exs test/cases/component_hooks_test.exs test/cases_live/components_index_test.exs test/cases_live/events_test.exs`)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-8:end -->
<!-- section:UI-9:start -->
### UI-9 — UI · renderers · one-to-many list through the index component
Depends on: UI-8

#### What and why
- **What.** The list of a one-to-many field is rendered by the index component of the related resource. The list looks and acts as today.
- **Why.** One kind of module then renders every list, and the related records are no longer queried inside `render/1`. With two resources on one schema, the field shows the columns of the resource its `resource:` option names.
- **For an existing host.** The rows container keeps its id and its class and gains `data-phx-component`. No existing one-to-many test changes.

#### Documentation references
- `guides/core/components.md § One-to-many lists`
- `guides/core/layouts.md` (the `order_by` and `where` options of a one-to-many field)

#### Implementation details

- The rows of a one-to-many field are held and rendered by the index component of the related resource. That component is the module the registry resolves for `field.data.resource` in the module of the parent.
- The query leaves `render/1`: the component runs it when its inputs change.
- The list looks and acts as before:
  - the same header, columns, actions, `name` attributes and container id;
  - the actions still navigate to the routes of the related resource;
  - filters, selection, sort and paging are off, and no option turns them on.
- Layout types covered: `:form` and `:show` (where a one-to-many field renders).
- Both backends are covered, because the renderer reads only the normalized field (`field.data.resource`, `field.data.related_key`, `field.data.owner_key`).

##### Acceptance criteria
- [ ] AC-1: the rows container `#auix-one_to_many-<parent module>__<field>-<layout type>` is rendered by the index component of the related resource and keeps its id and its class `auix-one-to-many-container`
- [ ] AC-2: every existing one-to-many test passes with its file unchanged (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- test/cases_live/association_one2many_ui_layout_test.exs test/cases_live/association_one2many_ui_actions_test.exs test/cases_live/where_one2many_test.exs test/cases_live/ash_where_one2many_test.exs test/cases_live/navigation_test.exs test/cases_live/ash_navigation_test.exs test/cases_live/handler_hooks_show_test.exs test/cases_live/manual_trees_test.exs test/cases_live/manual_layouts_test.exs test/cases_live/manual_resource_test.exs test/cases_live/manual_ui_test.exs` printing nothing, and `mix test` green)
- [ ] AC-3: a field whose `resource:` names another resource on the same schema lists the columns of that resource's index layout, and its show action navigates to the routes of the schema
- [ ] AC-4: the child list takes the module the registry resolves for the related resource: `auix_configurations().product_compact.artifacts.index_component`
- [ ] AC-5: error path. A one-to-many field whose related resource has no index component in the module raises `ArgumentError` when it renders, with a message that names the field and the fix
- [ ] AC-6: `OneToMany.load_rows/1` returns the preloaded rows for a field without `where` and `order_by`, and `[]` for an association that is not loaded
- [ ] AC-7: the related list is not queried inside `render/1` (mechanical — no red test; verified by `grep -n 'apply_list_function' lib/aurora_uix/templates/basic/renderers/fields/one_to_many.ex` printing one line, inside `load_rows/1`)

##### Test ports
- Routes registered in `test/support/app_web/routes.ex` with `RoutesHelper.register_crud/2`, directly after the registration of UI-4: `RoutesHelper.register_crud(OneToManyComponentTest.Product, "one-to-many-component-products")` and `RoutesHelper.register_crud(OneToManyComponentTest.ProductLocation, "one-to-many-component-product_locations")` · layout types `:form`, `:show` · observable: `has_element?/2` on `#auix-one_to_many-product_location__products-show[data-phx-component]`.
- `OneToMany.load_rows/1` called directly for AC-6.

##### Red tests
The test module `Aurora.UixWeb.Test.OneToManyComponentTest` declares, in this order: `auix_resource_metadata(:product, context: Inventory, schema: Product)`; `auix_resource_metadata(:product_compact, context: Inventory, schema: Product)`; `auix_resource_metadata :product_location do … end` whose block holds the three lines `context(Inventory)`, `schema(ProductLocation)` and `field(:products, resource: :product_compact)`; and
```elixir
auix_create_ui do
  index_columns(:product_compact, [:reference, :name], module_name: :index_compact)
  edit_layout(:product_compact, use: :product_form_component)
  show_layout(:product_compact, use: :product_show_component)
  index_live(:product_compact, module_name: :compact_products)

  show_layout :product_location do
    stacked([:reference, :name, :products])
  end
end
```
Data: `delete_all_inventory_data()`, then one location with two products, created with `Aurora.Uix.Repo.insert/1` (`%ProductLocation{reference: "loc", name: "Loc", type: "t"}`, then two `%Product{reference: …, name: …, product_location_id: location.id}`). `L` is `"/one-to-many-component-product_locations"`.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1, AC-3 | new file (`ls test/cases_live \| grep one_to_many_component` prints nothing) | `{:ok, view, _html} = live(conn, "#{L}/#{location.id}/show")` | `test/cases_live/one_to_many_component_test.exs` | `"the child list is an index component of the related resource"` | `has_element?(view, "#auix-one_to_many-product_location__products-show.auix-one-to-many-container[data-phx-component]")`; `has_element?(view, "div[name='auix-one_to_many-product_location'] th[name='auix-column-label']", "Reference")`; `refute has_element?(view, "div[name='auix-one_to_many-product_location'] th[name='auix-column-label']", "Description")`; `{:error, {:live_redirect, %{to: to}}} = view \|> element("a[name='auix-show-product_location__product-#{product.id}']") \|> render_click()`; `String.starts_with?(to, "/one-to-many-component-products/#{product.id}/show")` |
| AC-4 | add to same | none | same | `"the registry names the module of the child list"` | `T.auix_configurations().product_compact.artifacts.index_component == T.Product.IndexCompact` |
| AC-5 | new file (`ls test/cases/templates/basic \| grep one_to_many` prints nothing). Module `Aurora.Uix.Templates.Basic.OneToManyRowsTest`, `use ExUnit.Case, async: true`, alias `Aurora.Uix.Templates.Basic.Renderers.OneToMany` | `assigns = %{field: %{type: :one_to_many_association, key: :products, data: %{resource: :product}}, auix: %{configurations: %{product: %{artifacts: %{index_component: nil}}}}}` | `test/cases/templates/basic/one_to_many_rows_test.exs` | `"a one-to-many list needs the index component of its resource"` | `assert_raise ArgumentError, ~r/the one-to-many field :products needs an index component for :product/, fn -> OneToMany.render(assigns) end` |
| AC-6 | add to same | `one_to_many = %{field: %{key: :products}, auix: %{entity: %{products: [%{id: 1}]}, layout_tree: %{order_by: nil, where: nil}}}` | `test/cases/templates/basic/one_to_many_rows_test.exs` | `"load_rows/1 takes the preloaded rows"` | `OneToMany.load_rows(one_to_many) == [%{id: 1}]`; with `entity: %{products: %Ecto.Association.NotLoaded{}}`: `== []`; with `entity: nil`: `== []` |

##### Modules & components
1. `lib/aurora_uix/templates/basic/renderers/fields/one_to_many.ex` — modified.
   - `render/1`, second clause: after the existing assigns pipeline, drop `|> apply_options()`. Resolve the module: `component = get_in(auix.configurations, [data.resource, :artifacts, :index_component])`; when it is `nil`, `raise ArgumentError, "the one-to-many field #{inspect(field.key)} needs an index component for #{inspect(data.resource)}; add :index_component to generate:, or name one with use: on its index_columns"`. These two statements are the first of the clause body, before `parsed_opts` is read. Put `component` and `socket_opts` (`BasicHelpers.backend_socket_opts(assigns, related_parsed_opts.list_function)`) in the assigns. Load guarantee: `configurations[name].artifacts` is written by `build_configurations/4` (UI-4) for every resource with a schema, and holds `index_component` since UI-7.
   - In the template, replace the `<div id={"auix-one_to_many-…"} class={@auix.association.related_class}>` element and the `<.auix_items>` inside it with:
     ```heex
     <.live_component
       module={@component}
       id={"auix-one_to_many-#{@auix.association.parsed_opts.module}__#{@field.key}-#{@auix.layout_type}"}
       one_to_many={%{auix: @auix, field: @field, socket_opts: @socket_opts}}
     />
     ```
     The header and the footer stay. `live_component/1` is already imported: `use Aurora.Uix.CoreComponentsImporter` imports `Phoenix.Component`.
   - New public function component `child_rows/1` (`grep -rnE 'child_rows|load_rows' lib test` prints nothing), `@spec child_rows(map()) :: Phoenix.LiveView.Rendered.t()`, taking the assigns `auix` (the parent `auix` with `association` and the one-to-many actions), `field` and `rows` (a list). It has no `attr` declaration, because the module imports `Phoenix.Component` and does not `use` it; its `@doc` lists the three assigns. Its body is the removed `<.auix_items>` element, unchanged except `streams={@rows}`.
   - New public `load_rows/1` (`@spec load_rows(map()) :: list()`), taking the `one_to_many` map. It holds the logic of `apply_options/1` and `maybe_apply_where/1` and returns the list instead of writing it into `auix.entity`: it first reads `Map.get(auix.layout_tree, :order_by)` and `Map.get(auix.layout_tree, :where)`; when both are `nil` it returns the preloaded rows without reading anything else; when an owner key is `nil` (`Enum.map(auix.primary_key, &Map.get(auix.entity, &1))`) it returns the preloaded rows too; otherwise it returns `apply_list_function(list_function, [{:where, where} | query_opts] ++ one_to_many.socket_opts) |> BasicHelpers.list_entries()`, with `where` and `query_opts` built as today by `merge_keys/3` and `merge_custom_where/2`. The preloaded rows are `Map.get(auix.entity || %{}, field.key)` when that value is a list, and `[]` otherwise (an association that is not loaded, a `nil` entity). Delete `apply_options/1` and `maybe_apply_where/1`.
2. `handlers/index_component_impl.ex` (UI-7) — a new first clause of `auix_update/2` for the assigns `%{one_to_many: one_to_many}`:
   - `key = {Map.get(one_to_many.auix.entity || %{}, one_to_many.field.key), Map.get(one_to_many.auix.layout_tree, :where), Map.get(one_to_many.auix.layout_tree, :order_by)}`.
   - When `socket.assigns[:one_to_many_key] != key`, assign `:rows` to `OneToMany.load_rows(one_to_many)` and `:one_to_many_key` to `key`. Always assign `:one_to_many`.
   - Return `{:ok, render_with(socket, &IndexRenderer.render_child/1)}`. The clause calls none of the list functions: this instance has no streams, no filters and no selection.
   - Add `alias Aurora.Uix.Templates.Basic.Renderers.OneToMany`.
   - Reload rule: a delete of a child, a save of a child and a change of the parent all make the LiveView re-read the parent (`push_patch/2` to the current path, `handle_params/3`, `apply_action/2`), so the preloaded value of the field changes and the key with it.
3. `renderers/index_renderer.ex` — new public `render_child/1` (`grep -rn 'render_child' lib` prints nothing; `@spec render_child(map()) :: Rendered.t()`):
   ```heex
   <div id={@id} class="auix-one-to-many-container">
     <OneToMany.child_rows auix={@one_to_many.auix} field={@one_to_many.field} rows={@rows} />
   </div>
   ```
   Add `alias Aurora.Uix.Templates.Basic.Renderers.OneToMany`. `auix-one-to-many-container` is the class the removed `<div>` carried through `related_class`.
4. The generated component module (UI-7, `generators/index_generator.ex`) needs no change: its `update/2` passes every assign to the handler.
5. Markup changes and the tests that drive them. `grep -rln 'auix-one_to_many' test` lists eight files: `association_one2many_ui_layout_test.exs`, `association_one2many_ui_actions_test.exs`, `ash_where_one2many_test.exs`, `handler_hooks_show_test.exs`, `manual_trees_test.exs`, `manual_layouts_test.exs`, `manual_resource_test.exs` and `manual_ui_test.exs`, all in `test/cases_live/`. The container keeps its id and class and gains `data-phx-component`; `div[name='auix-one_to_many-<parent>']`, `a[name='auix-new-<parent>__<field>-form']` and the row action names are rendered by the same functions as before. No test changes its drive.
6. Events. The row and header actions stay untargeted: `auix_route_forward` and `delete` (with `get_function` and `delete_function`) reach the LiveView and `IndexImpl.auix_handle_event/3`, as today. An embedded parent (UI-5) renders no default child action.
7. Unchanged on purpose: `actions/one_to_many.ex`; `set_related_uri_path/3`, so two resources on one schema share the routes of that schema; the columns, read from `BasicHelpers.layout_children(configurations, field.data.resource, :index)` — with `use:` on the related resource's `index_columns`, that layout is the used one (UI-7, AC-2).
8. Edge cases.
   - `field.data.resource == nil` keeps the first `render/1` clause, which renders nothing.
   - A parent that is not saved yet has a `nil` owner key and lists its preloaded rows.
   - `auix_resource_metadata` takes its options and a `do` block only apart: `auix_resource_metadata :r, context: C, schema: S do … end` does not compile (`undefined function auix_resource_metadata/3`), so the test module declares `:product_location` in the block form.
9. Components: `child_rows/1` (contract in step 1). Theme: none. `dt/1` strings: none.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted: `mix test test/cases_live/one_to_many_component_test.exs test/cases/templates/basic/one_to_many_rows_test.exs test/cases/create_ui_validation_test.exs test/cases_live/association_one2many_ui_layout_test.exs test/cases_live/association_one2many_ui_actions_test.exs test/cases_live/where_one2many_test.exs test/cases_live/ash_where_one2many_test.exs test/cases_live/navigation_test.exs test/cases_live/ash_navigation_test.exs`)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
4. The grep of AC-7 prints one line
<!-- section:UI-9:end -->
<!-- section:DOC-3:start -->
### DOC-3 — Documentation · component guides and CHANGELOG after UI-4 to UI-9
Depends on: UI-9

#### What and why
- **What.** The guides and the CHANGELOG say what UI-4 to UI-9 deliver. `guides/core/components.md` gains the section with the five examples of the Overview.
- **Why.** DOC-1 and DOC-2 are merged, and they describe the contract as it stood before UI-4 to UI-9. Three of their statements are false once those sections are merged, three sentences about intents and event targets are too wide, and the two breaking changes of UI-4 are not announced.

#### Documentation references
- `CHANGELOG.md § [0.2.1]`
- `guides/advanced/advanced_usage.md § Single vs Multiple Resources`, `§ Introspecting generated UI modules`
- `guides/core/components.md` (every section)
- `guides/core/liveview.md § Module Generation with auix_create_ui`, `§ Generated Module Structure`, `§ Using Generated Modules with Routes`, `§ Specifying Handler Hooks in Layout DSL`, `§ Navigation`
- `guides/whats_new/0.2.1.md`

#### Implementation details

The section brings the documentation of DOC-1 and DOC-2 in line with what UI-4 to UI-9 deliver. It edits documentation files only.

Three statements of the merged guides are false after UI-4 to UI-9, and are corrected:
- the generated `.Index` LiveView hosts the index component;
- a one-to-many field can turn filters, selection, sort and paging on;
- 0.2.1 has no breaking change.

Three sentences are too wide, and are narrowed. They hold for the form in every parent, and for the show view and the index component when embedded:
- every component sends the intents in every host;
- every event of a component carries `phx-target`;
- the generated `.Index` LiveView answers `{:open, action, id}`, `{:closed}` and `{:page, page}`.

The sentence "a component never navigates" stays: it is true after UI-5.

The section also:
- documents named modules and the pairing a LiveView written by hand declares;
- fixes the samples that no longer compile.
- adds the note for LiveView tests to the CHANGELOG and to the What's New page.

##### CHANGELOG.md
1. § `## [0.2.1]` › `### Added` — replace the entry `- **Reusable components**`, from that line through the line `  - New guide: Reusable Components.`, with, verbatim:
   ```
   - **Reusable components**
     - `auix_create_ui` generates an `IndexComponent` next to `FormComponent` and `ShowComponent`. The three
       components can be embedded in any LiveView. The generated `Index` LiveView keeps its list, routes,
       handler hooks and behaviour.
     - A component never navigates: it reports what the user asked for to its parent, and the parent decides.
       `Aurora.Uix.Navigation` holds the navigation state of the generated LiveView (`@auix.navigation`),
       which patches and navigates as before.
     - Every generated module has a name in its `auix_create_ui` module. `module_name:` on a layout names its
       component, an `index_live` line names the index LiveView, and `auix_modules/0` and `auix_module/1`
       return the modules, with the modules imported through `@auix_modules`. `use:` on a layout takes a
       component generated elsewhere for a resource of this module. A LiveView you write attaches the
       components it needs the same way and gives each one its `resource`.
     - `auix_create_ui generate:` chooses which kinds of module are generated; leaving out `:index_live`
       generates the components alone.
     - `auix_live_resources/3` takes `index_live:` to route to a renamed LiveView.
     - `component_handler_module:` on `index_columns` sets the handler of the `IndexComponent`
       (`IndexComponentImpl`).
     - `Aurora.Uix.Live.ComponentHooks` forwards `Aurora.Uix.Events` to the components of a hand-written LiveView.
     - A one-to-many list is an embedded `IndexComponent`; its columns come from the resource the field names
       with `resource:`.
     - New guide: Reusable Components.
   ```
2. § `## [0.2.1]` — insert a new `### Changed` subsection directly above `### Build`, verbatim:
   ```
   ### Changed

   - **Generated module names (breaking)**
     - Two generated modules with the same name in one `auix_create_ui` module are a compile-time error.
       Before, the second definition silently replaced the first. It happens when two resources of the module
       share a schema: give one of them `module_name:` on its layouts, `use:`, and an `index_live` line.
     - A resource created for an embedded field (`:<parent>__<field>`) generates no modules. The
       `<Module>.<EmbeddedSchema>.Index`, `.FormComponent` and `.ShowComponent` modules are gone; nothing
       rendered them.
   - **Associations to imported resources**
     - A resource declared in a module links its associations to the resources the module imports with
       `@auix_resource_metadata`, as it does to the resources declared beside it. A form or a show view that
       places such a field now shows its select or its list; before, the field had no related resource.
   - **Form navigation in LiveView tests**
     - The generated `Index` LiveView navigates after its form saves and after it closes; the form only
       reports. Nothing changes in the browser: the URLs, the routing stack and the flash are the same. In a
       LiveView test the redirect is no longer the result of the form event: replace
       `render_submit() |> follow_redirect(conn)` with `render_submit()` followed by `assert_redirect(view)`.
   ```

##### guides/advanced/advanced_usage.md
1. § Single vs Multiple Resources, sample **Single Schema with Multiple Representations** — replace the two lines
   ```
   @auix_resource_metadata %{product_admin: ProductMetadata.auix_resource(:product_admin)}
   @auix_resource_metadata %{product_customer: ProductMetadata.auix_resource(:product_customer)}
   ```
   with, verbatim:
   ```
   # In the admin view:
   @auix_resource_metadata %{product_admin: ProductMetadata.auix_resource(:product_admin)}

   # In the customer view:
   @auix_resource_metadata %{product_customer: ProductMetadata.auix_resource(:product_customer)}
   ```
   and insert this paragraph directly after the closing fence of that sample, followed by one blank line, verbatim:
   ```
   Both resources share the `Product` schema. A view that imports both gives one of them its own module names;
   see [Naming and reusing generated modules](../core/components.md#naming-and-reusing-generated-modules).
   ```
2. § Introspecting generated UI modules — replace `exposes two introspection functions` with `exposes three introspection functions`, and append this list item after the `auix_configurations/0` item and its code block, verbatim:
   ````markdown
   - **`auix_modules/0`** — maps the names of the generated and the imported modules to the modules. `auix_module/1` returns one of them. A generated module tells its kind with `auix_kind/0` and the fields its layout places with `auix_fields/0`.

     ```elixir
     MyAppWeb.Products.Index.auix_modules()
     ```
   ````

##### guides/core/components.md
1. Introduction — replace the sentence `` `auix_create_ui` generates three LiveComponents for each resource, and one LiveView that hosts them: `` with `` `auix_create_ui` generates three LiveComponents for each resource, and one LiveView: ``, and replace the table row of `.Index` with, verbatim:
   ```
   | `.Index` | LiveView | Lists the records, owns the routes and opens the form and the show view in a modal |
   ```
2. § Inputs — replace the row of `resource` with `` | `resource` | all | A resource of the LiveView that renders the component, an atom. Defaults to the resource the module was generated for; see [Naming and reusing generated modules](#naming-and-reusing-generated-modules) | ``. Replace the row of `parent` with `` | `parent` | index | `{key, value}`: the owner key and its value, for a list of children | ``. Insert this row directly after the row of `page`: `` | `options` | index | A keyword list of index layout options for this instance | ``. Replace the paragraph that starts `An index instance may also override` with, verbatim:
   ```
   `options` overrides the index layout options (pagination, filters, selection, sort) for one instance. An
   option it leaves out takes the value the layout declares.
   ```
3. § Outputs — replace the sentence `A component sends these in every host. It never patches, navigates or reads the URL.` with, verbatim:
   ```
   A component never patches, navigates or reads the URL. The form sends these in every host. The show view
   and the index component send them when you embed them. In the generated `.Index` LiveView, the back and
   edit actions of the show view are events of that LiveView.
   ```
4. § Events — replace the first two sentences of the section (from `Every event of a component carries` through `the index, the form and the show view.`) with, verbatim:
   ```
   Every event of an embedded component carries `phx-target`, so it never reaches the host LiveView.
   `@auix._myself` holds the target in the index component, the form and the show view. It is `nil` in the
   generated `.Index` LiveView. There the list events, the back and edit actions of the show view, the record
   navigator and the actions of a one-to-many list carry no target and reach the LiveView.
   ```
5. § Navigation — replace the second paragraph (it starts `` The generated `.Index` LiveView is one such parent. ``) with, verbatim:
   ```
   The generated `.Index` LiveView is one such parent. It answers `{:saved, entity}` and `{:closed}` from its
   form with a patch or a navigate under its routes, with the routing stack in `?routing_stack=`. Its list, the
   back and edit actions of its show view, the record navigator and the actions of a one-to-many list are its
   own events, and it navigates on them as before. Its URLs are the ones it always had.
   `Aurora.Uix.Navigation` computes each path, and the LiveView applies it.
   ```
   The first paragraph (`A component does not know how it is used. …`) stays.
6. § Live updates — append to the paragraph that starts `` `on_mount Aurora.Uix.Live.ComponentHooks` does this ``, as its last sentence: `` The generated `.Index` LiveView subscribes on its own and does not use the hook. ``
7. Insert a new section directly above `## One-to-many lists`, verbatim:
   ````markdown
   ## Naming and reusing generated modules

   Every generated module has a name, an atom, in the module that declares it:

   | Module | Default name | Named with |
   |---|---|---|
   | `.Index` | `:<schema>_index` | an `index_live` line |
   | `.IndexComponent` | `:<schema>_index_component` | `module_name:` on `index_columns` |
   | `.FormComponent` | `:<schema>_form_component` | `module_name:` on `edit_layout` |
   | `.ShowComponent` | `:<schema>_show_component` | `module_name:` on `show_layout` |

   `<schema>` is the last part of the schema module, in snake case. A name you give is the last part of the
   module, as you wrote it: no suffix is added. `auix_modules/0` returns the modules by name, and
   `auix_module/1` returns one. A generated module tells its kind with `auix_kind/0` and the fields its
   layout places with `auix_fields/0`.

   The examples share three schemas. `Product` has many `ProductTransaction` (`:product_transactions`, a
   one-to-many) and belongs to a `ProductLocation` (`:product_location_id`, a many-to-one).

   ### One module

   ```elixir
   defmodule MyAppWeb.InventoryViews do
     use Aurora.Uix

     alias MyApp.Inventory
     alias MyApp.Inventory.{Product, ProductLocation, ProductTransaction}

     auix_resource_metadata :product, context: Inventory, schema: Product
     auix_resource_metadata :product_transaction, context: Inventory, schema: ProductTransaction
     auix_resource_metadata :product_location, context: Inventory, schema: ProductLocation

     auix_create_ui do
       index_columns :product, [:reference, :name]

       edit_layout :product do
         inline [:reference, :name]
         stacked [:product_location_id, :product_transactions]
       end

       index_columns :product_transaction, [:type, :quantity, :cost]
       index_columns :product_location, [:reference, :name]
     end
   end
   ```

   Every resource with a schema generates its four modules, also without a layout line. The modules, under
   `MyAppWeb.InventoryViews`:

   | Name | Module |
   |---|---|
   | `:product_index` | `Product.Index` |
   | `:product_index_component` | `Product.IndexComponent` |
   | `:product_form_component` | `Product.FormComponent` |
   | `:product_show_component` | `Product.ShowComponent` |
   | `:product_transaction_index` | `ProductTransaction.Index` |
   | `:product_transaction_index_component` | `ProductTransaction.IndexComponent` |
   | `:product_transaction_form_component` | `ProductTransaction.FormComponent` |
   | `:product_transaction_show_component` | `ProductTransaction.ShowComponent` |
   | `:product_location_index` | `ProductLocation.Index` |
   | `:product_location_index_component` | `ProductLocation.IndexComponent` |
   | `:product_location_form_component` | `ProductLocation.FormComponent` |
   | `:product_location_show_component` | `ProductLocation.ShowComponent` |

   The transactions list in the product form is rendered by `ProductTransaction.IndexComponent`. Each
   association finds its resource by the schema it relates to, so neither field needs `resource:`.

   ### Resources in one module, the UI in another

   ```elixir
   defmodule MyAppWeb.InventoryMetadata do
     use Aurora.Uix

     alias MyApp.Inventory
     alias MyApp.Inventory.{Product, ProductLocation, ProductTransaction}

     auix_resource_metadata :product, context: Inventory, schema: Product
     auix_resource_metadata :product_transaction, context: Inventory, schema: ProductTransaction
     auix_resource_metadata :product_location, context: Inventory, schema: ProductLocation
   end

   defmodule MyAppWeb.InventoryViews do
     use Aurora.Uix

     alias MyAppWeb.InventoryMetadata

     @auix_resource_metadata InventoryMetadata.auix_resources()

     auix_create_ui do
       index_columns :product, [:reference, :name]

       edit_layout :product do
         inline [:reference, :name]
         stacked [:product_location_id, :product_transactions]
       end

       index_columns :product_transaction, [:type, :quantity, :cost]
       index_columns :product_location, [:reference, :name]
     end
   end
   ```

   `InventoryMetadata` generates no module. `InventoryViews` generates the twelve modules of the first
   example, under the same names. The resources can also be imported one by one:
   `@auix_resource_metadata %{product: InventoryMetadata.auix_resource(:product)}`.

   ### Reusing components from another views module

   ```elixir
   defmodule MyAppWeb.ProductViews do
     use Aurora.Uix

     alias MyApp.Inventory
     alias MyApp.Inventory.{Product, ProductLocation, ProductTransaction}

     auix_resource_metadata :product, context: Inventory, schema: Product
     auix_resource_metadata :product_transaction, context: Inventory, schema: ProductTransaction
     auix_resource_metadata :product_location, context: Inventory, schema: ProductLocation

     auix_create_ui do
       index_columns :product, [:reference, :name]

       # Without module_name: the name is :product_form_component and the module Product.FormComponent.
       edit_layout :product, module_name: :product_form do
         inline [:reference, :name]
         stacked [:product_location_id, :product_transactions]
       end

       index_columns :product_transaction, [:type, :quantity, :cost]
       index_columns :product_location, [:reference, :name]
     end
   end

   defmodule MyAppWeb.CatalogViews do
     use Aurora.Uix

     alias MyApp.Inventory
     alias MyApp.Inventory.Product
     alias MyAppWeb.ProductViews

     auix_resource_metadata :catalog_product, context: Inventory, schema: Product

     @auix_resource_metadata %{
       product_transaction: ProductViews.auix_resource(:product_transaction),
       product_location: ProductViews.auix_resource(:product_location)
     }
     @auix_modules %{
       catalog_form: ProductViews.auix_module(:product_form),
       transactions_list: ProductViews.auix_module(:product_transaction_index_component)
     }

     auix_create_ui do
       index_columns :catalog_product, [:name]
       edit_layout :catalog_product, use: :catalog_form
       index_columns :product_transaction, use: :transactions_list
       index_columns :product_location, [:name]
     end
   end
   ```

   `ProductViews` generates the twelve modules of the first example, except that the product form is
   `:product_form`, the module `Product.ProductForm`.

   `:catalog_product` links its associations to the two resources `CatalogViews` imports, so the reused form
   shows its location select and its transactions list. The list is rendered by `:transactions_list`.

   `@auix_modules` imports a module under a name of your choice, and `use:` takes it for the resource of its
   line instead of generating one. A `use:` line has no field list, no block and no other option. `CatalogViews`
   imports `:catalog_form` and `:transactions_list`, and generates, under `MyAppWeb.CatalogViews`:

   | Name | Module |
   |---|---|
   | `:product_index` | `Product.Index` |
   | `:product_index_component` | `Product.IndexComponent` |
   | `:product_show_component` | `Product.ShowComponent` |
   | `:product_transaction_index` | `ProductTransaction.Index` |
   | `:product_transaction_form_component` | `ProductTransaction.FormComponent` |
   | `:product_transaction_show_component` | `ProductTransaction.ShowComponent` |
   | `:product_location_index` | `ProductLocation.Index` |
   | `:product_location_index_component` | `ProductLocation.IndexComponent` |
   | `:product_location_form_component` | `ProductLocation.FormComponent` |
   | `:product_location_show_component` | `ProductLocation.ShowComponent` |

   Two rules are checked when the module compiles: the kind of the component matches the layout line, and
   the resource has every field the layout of the component places. The two resources may have different
   schemas. A LiveView cannot be taken this way. Two views modules that import from each other do not
   compile.

   ### Two resources on one schema

   ```elixir
   defmodule MyAppWeb.InventoryViews do
     use Aurora.Uix

     alias MyApp.Inventory
     alias MyApp.Inventory.{Product, ProductLocation, ProductTransaction}

     auix_resource_metadata :product do
       context Inventory
       schema Product
       field :product_transactions, resource: :product_transaction_compact
     end

     auix_resource_metadata :product_transaction, context: Inventory, schema: ProductTransaction

     auix_resource_metadata :product_transaction_compact do
       context Inventory
       schema ProductTransaction
       field :cost, readonly: true
     end

     auix_resource_metadata :product_location, context: Inventory, schema: ProductLocation

     auix_create_ui do
       index_columns :product, [:reference, :name]

       edit_layout :product do
         inline [:reference, :name]
         stacked [:product_location_id, :product_transactions]
       end

       index_columns :product_transaction, [:type, :quantity, :cost, :inserted_at]

       edit_layout :product_transaction do
         inline [:type, :quantity, :cost]
         stacked [:product_id]
       end

       show_layout :product_transaction do
         inline [:type, :quantity, :cost]
       end

       index_columns :product_transaction_compact, [:type, :quantity], module_name: :transactions_compact
       edit_layout :product_transaction_compact, use: :product_transaction_form_component
       show_layout :product_transaction_compact, use: :product_transaction_show_component
       index_live :product_transaction_compact, module_name: :compact_transactions

       index_columns :product_location, [:reference, :name]
     end
   end
   ```

   The module generates the twelve modules of the first example, and two more:

   | Name | Module |
   |---|---|
   | `:transactions_compact` | `ProductTransaction.TransactionsCompact` |
   | `:compact_transactions` | `ProductTransaction.CompactTransactions`, the LiveView |

   Two generated modules with one name do not compile. `:product_transaction` and
   `:product_transaction_compact` describe the same schema, so the second one names its index component and
   its LiveView, and takes the form and the show view of the first with `use:`, by their default names. The
   transactions list in the product form is `ProductTransaction.TransactionsCompact`: the `resource:` option
   of the field says which of the two resources the list shows. A field needs `resource:` only then.

   `auix_resource_metadata` takes its options on the line, or a block that holds them with the field
   options. It does not take both.

   ### In a LiveView you write

   A LiveView you write attaches the components it needs with `auix_create_ui`, and generates nothing with
   `generate: []`. `use:` takes the module that `auix_module/1` of the other views module returns, so the
   LiveView needs no `@auix_modules`. With `MyAppWeb.ProductViews` from the example above:

   ```elixir
   defmodule MyAppWeb.ProductReviewLive do
     use MyAppWeb, :live_view
     use Aurora.Uix

     alias MyApp.Inventory
     alias MyApp.Inventory.{Product, ProductLocation, ProductTransaction}
     alias MyAppWeb.ProductViews

     auix_resource_metadata :product_review do
       context Inventory
       schema Product
       field :reference, readonly: true
     end

     auix_resource_metadata :product_transaction, context: Inventory, schema: ProductTransaction
     auix_resource_metadata :product_location, context: Inventory, schema: ProductLocation

     auix_create_ui generate: [] do
       edit_layout :product_review, use: ProductViews.auix_module(:product_form)
       index_columns :product_transaction, use: ProductViews.auix_module(:product_transaction_index_component)
     end

     def mount(%{"id" => id}, _session, socket), do: {:ok, assign(socket, :id, id)}

     def render(assigns) do
       ~H"""
       <.live_component
         module={ProductViews.auix_module(:product_form)}
         id="product-review-form"
         resource={:product_review}
         entity_id={@id}
       />
       """
     end
   end
   ```

   The LiveView generates no module. `resource` is a name: the component looks it up in the LiveView that
   renders it, and serves it with the layout its `use:` line attached. It raises `ArgumentError` in three
   cases: that LiveView has no `auix_create_ui`; it has no such resource; it attaches another module to the
   resource. Without `resource` a component serves the resource it was generated for. A component keeps its
   resource: give another resource a component with its own `id`.

   `:product_review` describes `Product` with its own field options. The second `use:` line attaches the
   index component that lists the transactions inside the form.

   ### Routes

   Route to a renamed LiveView with `index_live:`:

   ```elixir
   auix_live_resources("/compact-transactions", MyAppWeb.InventoryViews.ProductTransaction,
     index_live: :compact_transactions
   )
   ```
   ````
8. § One-to-many lists — replace the first paragraph (it starts `A one-to-many field renders an`) with, verbatim:
   ```
   A one-to-many field renders an `IndexComponent` scoped to the parent record. In the generated LiveView it
   looks and acts as before: its new, show and edit actions navigate to the child resource's routes. The list
   has no filters, selection, sort and paging.
   ```
   and replace the rest of the section, from the paragraph that starts `The list takes its columns` through the closing fence of its sample, with, verbatim:
   ```
   The list takes its columns from the index layout of the resource the field shows. When two resources
   describe the schema of the children, `resource:` on the field says which one; see
   [Two resources on one schema](#two-resources-on-one-schema).
   ```
   The sample on `main` is removed: it gives `auix_resource_metadata` options and a `do` block together, which does not compile, and the example of step 7 replaces it.
9. § Design decisions — replace item 3 with, verbatim (the number stays):
   ```
   3. **Components report, parents decide.** A component never navigates. It tells its parent what the user
      asked for, and the parent decides. The generated `.Index` LiveView is one such parent: it turns the
      intents of its form into patches and navigations.
   ```
10. § Generating the components alone — replace the line `` `[:live_view, :index_component, :form_component, :show_component]`. `` with, verbatim:
   ```
   `[:index_live, :index_component, :form_component, :show_component]`.
   ```

##### guides/core/liveview.md
1. § Module Generation with `auix_create_ui` — in the fenced module tree, replace the line of `Overview.Product.Index` with, verbatim:
   ```
   ├── Overview.Product.Index            # LiveView - Lists the records, owns the routes
   ```
2. § Generated Module Structure — replace the list item that starts `- Holds the list state the Index LiveView delegates to it` with, verbatim:
   ```
   - Holds the state of an embedded list: streams, filters, sort, pagination and selection
   ```
3. § Using Generated Modules with Routes — append to the end of the section, after the `only:` / `except:` sample, preceded by one blank line, verbatim:
   ````markdown
   A LiveView renamed with an `index_live` line is routed with `index_live:`:

   ```elixir
   auix_live_resources("/catalog", Overview.Product, index_live: :catalog)
   ```
   ````
4. § Specifying Handler Hooks in Layout DSL — append after the closing fence of the sample, preceded by one blank line, verbatim:
   ```
   `component_handler_module:` on `index_columns` sets the handler of the `IndexComponent`. It implements
   `Aurora.Uix.Templates.Basic.Handlers.IndexComponentImpl`: `auix_update/2`, `auix_handle_event/3` and
   `auix_handle_async/3`.
   ```

##### guides/whats_new/0.2.1.md
1. Introduction — replace the sentence `0.2.1 has no breaking change.` with, verbatim:
   ```
   0.2.1 has two compile-time changes that can stop a module from compiling; see
   [Upgrading from 0.2.0](#upgrading-from-0-2-0).
   ```
2. § Reusable components — replace the five list items (from the item that starts `` - The generated `Index` LiveView hosts `` through the item `` - A one-to-many list is an embedded `IndexComponent`. ``) with, verbatim:
   ```
   - The generated `Index` LiveView keeps its list, routes, handler hooks and modal.
   - `generate:` on `auix_create_ui` chooses the kinds of module; leave out `:index_live` to get the components
     alone.
   - A component never navigates. It tells its parent what the user asked for, and the parent decides.
     `Aurora.Uix.Navigation` holds the navigation state of the generated LiveView.
   - Every generated module has a name: `module_name:` and `index_live` set it, `use:` takes a component
     generated in another module. A LiveView you write declares the same pairing and gives the component its
     `resource`.
   - `on_mount Aurora.Uix.Live.ComponentHooks` keeps embedded components up to date with `Aurora.Uix.Events`.
   - A one-to-many list is an embedded `IndexComponent`.
   ```
3. § Upgrading from 0.2.0 — replace the paragraph that starts `No change is required.` with, verbatim:
   ```
   Two cases need a change:

   - A views module with two resources on one schema no longer compiles: their generated modules had the same
     names, and one silently replaced the other. Give one resource `module_name:` on its layouts, `use:` and an
     `index_live` line; see
     [Naming and reusing generated modules](../core/components.md#naming-and-reusing-generated-modules).
   - A resource created for an embedded field generates no modules. Remove any reference to
     `<Module>.<EmbeddedSchema>.Index`, `.FormComponent` and `.ShowComponent`.

   `@auix.uri_path`, `@auix.uri_path_id`, `@auix.routing_stack` and `@auix[:index_new_link]` stay readable; a
   handler that assigned one of them directly now changes navigation with `auix_route_forward/2` and
   `auix_route_back/1`.

   In a LiveView test, the redirect after a form save and after a form close now comes from the generated
   `Index` LiveView, one message after the form event. Replace `render_submit() |> follow_redirect(conn)`
   with `render_submit()` followed by `assert_redirect(view)`. Nothing changes in the browser.
   ```

##### Unchanged on purpose
1. `guides/advanced/advanced_usage.md § Single vs Multiple Resources`, sample **Multiple Schemas in Same Context**: its view imports `:product_admin` and `:category_admin`, which have different schemas, so no name collides. The samples of § Example Use Cases import one resource per view.
2. `guides/core/liveview.md § Targeting the Component`: `@auix._myself` exists in the index after UI-7 (`nil` in the LiveView) and an untargeted event still reaches `auix_handle_event/3`. `§ Navigation`: its sentence `The components never navigate: they report to the LiveView that hosts them` is true after UI-5.
3. `guides/core/components.md § Embedding a component`, `§ Several instances on one page`: true after UI-7 and UI-8. `§ Generating the components alone` keeps its sample and its first sentence.
4. `guides/core/components.md § Design decisions`, items 1, 2, 4, 5 and 6: true after UI-9. `§ Navigation`, first paragraph: true after UI-5.
5. `README.md`: `prepare-release` updates its What's New link.

##### Acceptance criteria
- [ ] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no
      issue-link suffix (mechanical — no red test; verified by
      `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [ ] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-458-enriched-spec.md`)
- [ ] AC-3: `CHANGELOG.md § [0.2.1]` states both breaking changes under `### Changed` and no longer says the LiveView hosts the components (mechanical — no red test; verified by `grep -c 'Generated module names (breaking)' CHANGELOG.md` returning `1`, `grep -c 'silently replaced the first' CHANGELOG.md` returning `1`, `grep -c 'generates no modules' CHANGELOG.md` returning `1` and `grep -c 'LiveView hosts them' CHANGELOG.md` returning `0`)
- [ ] AC-4: `guides/core/components.md` has the section Naming and reusing generated modules, and keeps the input `resource` (mechanical — no red test; verified by `grep -c '^## ' guides/core/components.md` returning `11`, `grep -c '^## Naming and reusing generated modules$' guides/core/components.md` returning `1` and `grep -c '^| `resource` | all | A resource of the LiveView that renders the component' guides/core/components.md` returning `1`)
- [ ] AC-5: `guides/core/components.md` says that no component navigates, that the generated LiveView answers the intents of its form, and promises no opt-in for one-to-many lists (mechanical — no red test; verified by `grep -c 'A component sends these in every host' guides/core/components.md` returning `0`, `grep -c 'The form sends these in every host' guides/core/components.md` returning `1`, `grep -c 'It answers .{:saved, entity}. and .{:closed}. from its' guides/core/components.md` returning `1`, `grep -c 'A component has no navigation mode' guides/core/components.md` returning `0` and `grep -c 'unless the field turns them on' guides/core/components.md` returning `0`)
- [ ] AC-6: `guides/core/components.md § One-to-many lists` points to the example of two resources on one schema and holds no sample of its own (mechanical — no red test; verified by `grep -c 'Two resources on one schema](#two-resources-on-one-schema)' guides/core/components.md` returning `1`, `grep -c ':product_compact' guides/core/components.md` returning `0` and `grep -c 'index_live :product_transaction_compact, module_name: :compact_transactions' guides/core/components.md` returning `1`)
- [ ] AC-7: `guides/core/liveview.md` documents `index_live:` on routes and `component_handler_module:`, and no longer says the Index LiveView delegates its list (mechanical — no red test; verified by `grep -c 'index_live: :catalog' guides/core/liveview.md` returning `1`, `grep -c 'component_handler_module:' guides/core/liveview.md` returning `1`, `grep -c 'delegates to it' guides/core/liveview.md` returning `0` and `grep -c 'Hosts the components' guides/core/liveview.md` returning `0`)
- [ ] AC-8: `guides/whats_new/0.2.1.md` announces the two compile-time changes (mechanical — no red test; verified by `grep -c 'has no breaking change' guides/whats_new/0.2.1.md` returning `0`, `grep -c 'No change is required' guides/whats_new/0.2.1.md` returning `0` and `grep -c 'generates no modules' guides/whats_new/0.2.1.md` returning `1`)
- [ ] AC-9: `guides/advanced/advanced_usage.md` imports the two product resources in two views and documents `auix_modules/0` (mechanical — no red test; verified by `grep -c '^# In the customer view:$' guides/advanced/advanced_usage.md` returning `1` and `grep -c 'auix_modules/0' guides/advanced/advanced_usage.md` returning `1`)
- [ ] AC-10: `guides/core/components.md` shows a LiveView written by hand that attaches its components with `auix_create_ui` and passes `resource` (mechanical — no red test; verified by `grep -c 'auix_create_ui generate: \[\] do' guides/core/components.md` returning `1`, `grep -c 'edit_layout :product_review, use: ProductViews.auix_module(:product_form)' guides/core/components.md` returning `1`, `grep -c 'resource={:product_review}' guides/core/components.md` returning `1` and `grep -c 'A component keeps its resource' guides/core/components.md` returning `1`)
- [ ] AC-11: `guides/core/components.md` holds the five examples and the routes sample, every one with its generated modules (mechanical — no red test; verified by `grep -c '^### ' guides/core/components.md` returning `6`, `grep -c '^defmodule MyAppWeb\.' guides/core/components.md` returning `8` and `grep -c ':compact_transactions' guides/core/components.md` returning `3`)
- [ ] AC-12: no sample of `guides/core/components.md` gives `auix_resource_metadata` options and a block together, none places `field` inside `auix_create_ui`, and the kind is `:index_live` (mechanical — no red test; verified by `grep -cE 'auix_resource_metadata :[a-z_]+, .* do$' guides/core/components.md` returning `0`, `grep -c '\[:live_view' guides/core/components.md` returning `0` and `grep -c '\[:index_live, :index_component, :form_component, :show_component\]' guides/core/components.md` returning `1`)
- [ ] AC-13: `CHANGELOG.md § [0.2.1]` states that a declared resource links its associations to imported resources (mechanical — no red test; verified by `grep -c 'Associations to imported resources' CHANGELOG.md` returning `1`), and `guides/core/components.md` says so for the reused form (mechanical — no red test; verified by `grep -c 'links its associations to the two resources' guides/core/components.md` returning `1`)
- [ ] AC-14: the CHANGELOG and the What's New page carry the note for LiveView tests (mechanical — no red test; verified by `grep -c 'Form navigation in LiveView tests' CHANGELOG.md` returning `1`, `grep -c 'assert_redirect(view)' CHANGELOG.md` returning `1` and `grep -c 'assert_redirect(view)' guides/whats_new/0.2.1.md` returning `1`)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-3:end -->

---

### Out of Scope
- Step 8 of the issue: editing the children of a one-to-many list in place.
- Filters, selection, sort and paging in a one-to-many list, and a field option that turns them on. The list ships with them off.
- The generated `.Index` LiveView rendering `.IndexComponent` for its list, as the issue's decision 1 proposed. The LiveView keeps its own list state and runs the list engine of UI-6 itself, so `stream_insert/4` in an `IndexImpl` handler, `auix.load_items_options` and untargeted list events keep working.
- Intents from the show view opened by the generated `.Index` LiveView, from the record navigator and from the actions of a one-to-many list. They stay events of that LiveView, with their markup (Overview § Who navigates).
- The `navigation: :url | :local` and `base_path` inputs of the issue. No component navigates, so no input chooses how.
- A flash handed to the parent by an embedded form. An embedded form shows its own flash; only a form opened by the generated `.Index` LiveView hands it over.
- A `views` input that names another module to resolve `resource` in. `resource` resolves in the LiveView that renders the component.
- Changing the resource of a mounted component. An instance keeps the resource of its first update and raises for another one.
- A new public function for a host to build a binding by hand. A host declares the pairing and passes `resource`.
- Two embedded forms, and two embedded show views, of one resource on one page. Their inner DOM ids derive from the resource (`auix-<module>-form`). Several instances are supported for the index component.
- `Aurora.Uix.Live.ComponentHooks` in the generated `.Index` LiveView, as the issue proposed. That LiveView subscribes on its own. Unregistering a component that left the page: LiveView ignores an update sent to it.
- Two views modules that import generated modules from each other. They do not compile, as two modules that import resources from each other do not; UI-4 and DOC-3 document it.
- Modules for a resource created for an embedded field. UI-4 removes them.
- An Ash run of the list engine unit tests of UI-6 and of the hook tests of UI-8. Both are backend-agnostic; the Ash list behaviour is covered by the existing `ash_*` LiveView tests and by UI-7.
- Direct load of a `/new` URL. `uri_path` keeps its `/new` suffix there today, so a save patches back to `/new`, and a new parent with a child list redirects to `/new/<id>/edit`. UI-1 does not assert that path, UI-3 reproduces today's parsing, and the fix belongs to a separate issue.
- New tests for `guides/customization/*`. Custom actions, predefined renderers and theming keep their existing tests; a routing-component override has no navigation test.
- An Ash run of the handler-hook tests of UI-2. The handler behaviours, event targets and message delivery they exercise are backend-agnostic.
- A separate test file, test namespace, support module and route for the handler-hook tests. UI-2 extends `test/cases_live/handler_hooks_index_test.exs`, `handler_hooks_form_test.exs` and `handler_hooks_show_test.exs`.
- A test of `push_navigate/2` called from a handler. It is a Phoenix function and runs no library code.
- `README.md` § What's New link. `prepare-release` updates it.
<!-- enriched-spec:end -->
