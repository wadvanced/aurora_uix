<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** normal

### Overview
A `renderers:` table maps a `%Field{}.html_type` to a renderer, so a host sets the renderer of every field of one HTML type at once, at six levels: application config, `use Aurora.Uix`, `auix_resource_metadata`, `auix_create_ui`, and the `index_columns` / `edit_layout` / `show_layout` macros. The library also ships named per-type default renderers (`:default_checkbox`, …) and the CHANGELOG entry the predefined renderers never got. Resolution runs downstream of the normalized `%Field{}`, so Ash and Ecto resources behave the same.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | `CHANGELOG.md` § 0.1.6 › Added; `guides/customization/predefined_renderers.md` | none | federico/317-doc-1-html-type-renderers | docs: renderers by HTML type (#317 · DOC-1) |
| UI-1 | UI | resolver: `html_type` tables, application config, named defaults, selection-column exemption | DOC-1 | federico/317-ui-1-html-type-resolver | feat: resolve renderers by HTML type (#317 · UI-1) |
| UI-2 | UI | layout: `renderers:` on `use Aurora.Uix`, `auix_resource_metadata`, `auix_create_ui`, layout macros | UI-1 | federico/317-ui-2-renderers-levels | feat: renderers option at every layout level (#317 · UI-2) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
- `CHANGELOG.md` § `## [0.1.6]` › `### Added`
- `guides/customization/predefined_renderers.md` § How a renderer is chosen, § Built-in catalog, § Writing your own renderer

#### Implementation details

##### CHANGELOG.md
1. § `## [0.1.6]` › `### Added` — append verbatim after the last entry of the section (the
   `- **New action-label layout options and arity-0 name/title functions**` entry), before
   `### Changed`, separated by one blank line:
   ```
   - **Predefined field renderers**
     - A field renderer slot (`renderer`, `index_renderer`, `edit_renderer`, `show_renderer`)
       accepts an atom naming a ready-made widget: `:toggle_switch`, `:color`, `:badge`,
       `:progress_bar`, `:url` and `:rating`.
     - Hosts add their own atoms, or replace a built-in, through a registrar module configured with
       `config :aurora_uix, :renderers, MyApp.Renderers` (see `Aurora.Uix.RendererRegistrar`).
     - The widgets bring new theme classes: re-run `mix auix.gen.stylesheet` after upgrading.

   - **Renderers by HTML type**
     - A `renderers:` map from `html_type` to renderer (`%{checkbox: :toggle_switch}`) sets the
       renderer of every field of that HTML type. It is accepted by the application config
       (`config :aurora_uix, :html_type_renderers, %{...}`), `use Aurora.Uix`,
       `auix_resource_metadata`, `auix_create_ui`, and the `index_columns`, `edit_layout` and
       `show_layout` macros, and applies to Ash and Ecto resources alike.
     - Precedence, highest first: the field's own renderer slot, the layout macro,
       `auix_create_ui`, `auix_resource_metadata`, `use Aurora.Uix`, the application config, the
       default rendering.
     - Association, embed, upload and hidden fields keep their own rendering.
     - New named defaults `:default_checkbox`, `:default_date`, `:default_datetime_local`,
       `:default_number`, `:default_select`, `:default_text`, `:default_textarea` and
       `:default_time` restore the default rendering of one HTML type over a lower level's entry.
   ```

##### guides/customization/predefined_renderers.md
1. § How a renderer is chosen — replace the sentence
   ``(`:index`, `:show` or `:form`) and pattern-matches to decide what to draw.
   `Aurora.Uix.Renderers.resolve/2` picks which one to call, per layout type:``
   with
   ``(`:index`, `:show` or `:form`) and pattern-matches to decide what to draw.
   `Aurora.Uix.Renderers.resolve/3` picks which one to call, per layout type:``
2. § How a renderer is chosen — replace the three table rows with:
   ```
   | `:index` | `index_renderer` → HTML-type tables → default *(index is independent — no `renderer` fallback)* |
   | `:form`  | `edit_renderer` → `renderer` → HTML-type tables → default |
   | `:show`  | `show_renderer` → `renderer` → HTML-type tables → default |
   ```
3. § How a renderer is chosen — append after the paragraph ending
   ``set `index_renderer:` too (e.g. `renderer: :badge, index_renderer: :badge`).``, separated by
   one blank line:
   ```
   When no slot names a renderer, the field's `html_type` is looked up in the HTML-type tables —
   see [Renderers by HTML type](#renderers-by-html-type).
   ```
4. § Built-in catalog — append after the table, separated by one blank line:
   ```
   The catalog also holds one named default per common HTML type: `:default_checkbox`,
   `:default_date`, `:default_datetime_local`, `:default_number`, `:default_select`,
   `:default_text`, `:default_textarea` and `:default_time`. Each renders the field's default
   rendering — the same as the reserved `:default` key, including a host override of it. Use one in
   an HTML-type table to undo a lower level's entry for that type.
   ```
5. Insert a new section verbatim immediately before `## Writing your own renderer`:
   ````
   ## Renderers by HTML type

   A `renderers:` option maps an HTML type to a renderer, so every field of that type gets it
   without a per-field slot. Keys are matched against the field's `html_type` (`:checkbox`,
   `:text`, `:textarea`, `:number`, `:select`, `:date`, `:time`, `:"datetime-local"`, …), not its
   Elixir type. Values are what a slot accepts: a renderer atom, or an arity-1 function.

   ```elixir
   # config/config.exs — the whole application
   config :aurora_uix, :html_type_renderers, %{checkbox: :toggle_switch}

   defmodule MyAppWeb.UserUi do
     # every resource of this module
     use Aurora.Uix, renderers: %{checkbox: :toggle_switch}

     # one resource
     auix_resource_metadata :user,
       context: MyApp.Accounts,
       schema: MyApp.Accounts.User,
       renderers: %{textarea: :url, checkbox: :badge}

     # every layout this auix_create_ui generates, and one layout of it
     auix_create_ui renderers: %{checkbox: :default_checkbox} do
       index_columns :user, [:name, :active], renderers: %{checkbox: :toggle_switch}
     end
   end
   ```

   A table entry covers the index, show and form layouts alike. A renderer that has no clause for
   one of them crashes there, as it does from a slot. `index_columns` sets the index table,
   `edit_layout` the form table and `show_layout` the show table; with no `show_layout`, the show
   layout reuses the `edit_layout` declaration, `renderers:` included.

   Precedence, highest first:

   | Level | Declared with |
   |-------|---------------|
   | Field slot | `renderer`, `index_renderer`, `edit_renderer`, `show_renderer` |
   | Layout | `index_columns`, `edit_layout`, `show_layout` — `renderers:` |
   | UI | `auix_create_ui renderers:` |
   | Resource | `auix_resource_metadata renderers:` |
   | Module | `use Aurora.Uix, renderers:` |
   | Application | `config :aurora_uix, :html_type_renderers` |
   | Default | the default rendering |

   An entry whose atom names no registered renderer is skipped, and the next level down is
   consulted. A `renderers:` value that is not a map raises `ArgumentError`: at compile time for
   the module, resource, UI and layout levels, at render time for the application config.

   Association, embed, upload and hidden fields ignore the tables and keep their own rendering;
   give one of them a slot to change it. The index row-selection checkbox ignores them too.
   ````

##### Acceptance criteria
- [x] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no
      issue-link suffix (mechanical — no red test; verified by
      `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [x] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-317-enriched-spec.md`)
- [x] AC-3: `CHANGELOG.md` § `## [0.1.6]` › `### Added` carries both entries (mechanical — no red
      test; verified by `grep -nE '^- \*\*(Predefined field renderers|Renderers by HTML type)\*\*' CHANGELOG.md`
      returning two lines, both between the `### Added` and `### Changed` lines of `## [0.1.6]`)
- [x] AC-4: `guides/customization/predefined_renderers.md` reads as prescribed (mechanical — no red
      test; verified by `grep -c 'resolve/2' guides/customization/predefined_renderers.md` returning
      `0`, and `grep -n '^## Renderers by HTML type' guides/customization/predefined_renderers.md`
      returning a line above `^## Writing your own renderer`)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->
<!-- section:UI-1:start -->
### UI-1 — UI · renderer resolver
Depends on: DOC-1

#### Documentation references
- `guides/customization/predefined_renderers.md` § How a renderer is chosen, § Built-in catalog, § Renderers by HTML type (as DOC-1 leaves them)

Layout types covered: `:index`, `:form`, `:show` — the resolver serves all three. No markup changes.

#### Implementation details
1. `lib/aurora_uix/renderers.ex` (`Aurora.Uix.Renderers`):
   1. Add the module attribute `@table_exempt_types` (new) with the value
      `[:one_to_many_association, :many_to_one_association, :one_to_one_association, :many_to_many_association, :embeds_one, :embeds_many]`.
   2. Replace the three `resolve/2` clauses
      (`def resolve(field, :index), do: pick(field.index_renderer) || default_fn()` and its
      `:form` / `:show` siblings) and their `@doc` / `@spec` with two public functions, in this
      order:
      ```elixir
      @doc """
      Returns the render function to call for `field` in the given layout type. Same as
      `resolve(field, layout_type, [])`: the application config is the only table consulted.
      """
      @spec resolve(map(), Aurora.Uix.Renderer.layout_type()) :: render_fun()
      def resolve(field, layout_type), do: resolve(field, layout_type, [])

      @doc """
      Returns the render function to call for `field` in the given layout type.

      Order: the field's slots for the layout type, then each map of `tables` in list order
      (highest precedence first), then the application config
      `config :aurora_uix, :html_type_renderers`, then the default renderer. A table is looked up
      by `field.html_type`; an entry that resolves to no renderer is skipped. Association, embed,
      upload and hidden fields skip every table. Always returns a function.
      """
      @spec resolve(map(), Aurora.Uix.Renderer.layout_type(), [map()]) :: render_fun()
      def resolve(field, layout_type, tables),
        do: slot(field, layout_type) || table_pick(field, tables) || default_fn()
      ```
   3. Add `validate_table!/2` (new) after `all/0`:
      ```elixir
      @doc """
      Returns `table` when it is a map of `html_type => renderer`; raises `ArgumentError` naming
      `level` otherwise.
      """
      @spec validate_table!(binary(), term()) :: map()
      def validate_table!(_level, %{} = table), do: table

      def validate_table!(level, other),
        do:
          raise(
            ArgumentError,
            "#{level} expected a map of html_type => renderer, got: #{inspect(other)}"
          )
      ```
   4. Add under `# PRIVATE`, after `pick/1`, the private functions (new):
      ```elixir
      @spec slot(map(), Aurora.Uix.Renderer.layout_type()) :: render_fun() | nil
      defp slot(field, :index), do: pick(field.index_renderer)
      defp slot(field, :form), do: pick(field.edit_renderer) || pick(field.renderer)
      defp slot(field, :show), do: pick(field.show_renderer) || pick(field.renderer)

      @spec table_pick(map(), [map()]) :: render_fun() | nil
      defp table_pick(field, tables) do
        if table_applies?(field) do
          Enum.find_value(tables ++ [app_table()], &pick(Map.get(&1, field.html_type)))
        end
      end

      @spec table_applies?(map()) :: boolean()
      defp table_applies?(%{hidden: true}), do: false
      defp table_applies?(%{type: type}) when type in @table_exempt_types, do: false
      defp table_applies?(%{data: %{upload: upload}}) when is_map(upload), do: false
      defp table_applies?(_field), do: true

      @spec app_table() :: map()
      defp app_table do
        :aurora_uix
        |> Application.get_env(:html_type_renderers, %{})
        |> then(&validate_table!("config :aurora_uix, :html_type_renderers", &1))
      end
      ```
   5. `@moduledoc` — replace the three precedence bullets with:
      ```
      - `:index` → `index_renderer` → HTML-type tables → default (index is independent — no `renderer` fallback)
      - `:form`  → `edit_renderer` → `renderer` → HTML-type tables → default
      - `:show`  → `show_renderer` → `renderer` → HTML-type tables → default

      The HTML-type tables are `html_type => renderer` maps declared with `renderers:` (see
      `resolve/3`), consulted highest level first, and closed by the application config
      `config :aurora_uix, :html_type_renderers`. Association, embed, upload and hidden fields
      skip them.
      ```
      In the same `@moduledoc`, replace `Given a field and the layout type` with
      `Given a field, the layout type and the HTML-type tables`.
2. `lib/aurora_uix/renderers/built_in.ex` (`Aurora.Uix.Renderers.BuiltIn`):
   1. Add `alias Aurora.Uix.Renderers` (aliases stay alphabetical: before
      `alias Aurora.Uix.Templates.Basic.Renderers.DefaultRenderer`).
   2. In `renderers/0`, add after `rating: &Predefined.Rating.render/1,` the eight entries
      (new; `rg -n 'default_checkbox' lib test` returns nothing):
      ```elixir
      default_checkbox: &Renderers.default/1,
      default_date: &Renderers.default/1,
      default_datetime_local: &Renderers.default/1,
      default_number: &Renderers.default/1,
      default_select: &Renderers.default/1,
      default_text: &Renderers.default/1,
      default_textarea: &Renderers.default/1,
      default_time: &Renderers.default/1,
      ```
   3. `@moduledoc` table — add before the `| `:default` |` row:
      ```
      | `:default_checkbox`, `:default_date`, `:default_datetime_local`, `:default_number`, `:default_select`, `:default_text`, `:default_textarea`, `:default_time` | index, show, form | The default rendering, named per HTML type for `renderers:` tables. |
      ```
3. `lib/aurora_uix/templates/basic/handlers/index_impl.ex`, `assign_index_fields/1`: in the
   `select_field` pipeline, replace
   `|> struct(%{label: select_toggle_function, filterable?: false, sortable?: false})` with
   `|> struct(%{label: select_toggle_function, filterable?: false, sortable?: false, index_renderer: :default})`.
   The row-selection column (`:selected_check__`, `html_type: :checkbox`) then resolves through
   its slot and never reaches a table.
4. `lib/aurora_uix/field.ex` `@moduledoc`: replace
   ``renderer to invoke is chosen by `Aurora.Uix.Renderers.resolve/2` per layout type:`` with
   ``renderer to invoke is chosen by `Aurora.Uix.Renderers.resolve/3` per layout type:``, and in
   the three bullets below it replace `→ default` with `→ HTML-type tables → default`.
5. `test/support/app_web/routes.ex`: add after the
   `RoutesHelper.register_crud(PredefinedRenderersInteractiveTest.Product, "predefined-renderers-interactive-products")`
   block:
   ```elixir
   RoutesHelper.register_crud(
     HtmlTypeRenderersAppConfigTest.Product,
     "html-type-renderers-app-config-products"
   )
   ```
6. Contract change: `resolve/2` keeps its `@spec` and now consults the application config; its
   callers `field_renderer.ex` `do_render/1` and `index_renderer.ex` `field_value/1` stay
   unchanged in this section (UI-2 moves them to `resolve/3`). `test/cases_live/predefined_renderers_test.exs`
   calls `resolve/2` in `PredefinedRenderersResolverTest`; those tests keep passing unmodified.

##### Acceptance criteria
- [ ] AC-1: Given `tables = [%{checkbox: :toggle_switch}]`, `resolve(%Field{html_type: :checkbox}, layout, tables)` returns `&Predefined.ToggleSwitch.render/1` for `:index`, `:show` and `:form`.
- [ ] AC-2: A slot beats every table: `resolve(%Field{html_type: :checkbox, renderer: :badge}, :show, [%{checkbox: :toggle_switch}])` returns `&Predefined.Badge.render/1`; on `:index` the same field returns `&Predefined.ToggleSwitch.render/1` (index ignores `renderer`).
- [ ] AC-3: Tables are consulted in list order, and an entry naming no registered renderer is skipped: `[%{checkbox: :badge}, %{checkbox: :toggle_switch}]` yields Badge; `[%{checkbox: :not_a_renderer}, %{checkbox: :toggle_switch}]` yields ToggleSwitch.
- [ ] AC-4: With `config :aurora_uix, :html_type_renderers, %{checkbox: :toggle_switch}`, `resolve(%Field{html_type: :checkbox}, :show, [])` returns ToggleSwitch, and `resolve(..., [%{checkbox: :badge}])` returns Badge.
- [ ] AC-5 (error path): an application config that is not a map raises `ArgumentError` whose message contains `config :aurora_uix, :html_type_renderers expected a map`; `validate_table!("auix_create_ui renderers:", :oops)` raises `ArgumentError` with `auix_create_ui renderers: expected a map`, and `validate_table!/2` returns a map argument unchanged.
- [ ] AC-6 (degraded path): hidden, upload and association/embed fields skip the tables — `%Field{html_type: :checkbox, hidden: true}` with `[%{checkbox: :toggle_switch}]`, `%Field{html_type: :text, data: %{upload: %{}}}` with `[%{text: :badge}]`, and `%Field{html_type: :select, type: :many_to_many_association}` with `[%{select: :badge}]` each resolve to `&DefaultRenderer.render/1` on `:show`.
- [ ] AC-7: `BuiltIn.renderers/0` maps each of the eight `:default_<type>` atoms to `&Aurora.Uix.Renderers.default/1`.
- [ ] AC-8: Given the application config `%{checkbox: :toggle_switch}` and a Product resource with `field(:deleted, renderer: :default_checkbox)`, visiting `/html-type-renderers-app-config-products` renders `input.auix-toggle-switch` and the row-selection input `input[type=checkbox][name='selected_check__<id>']`.
- [ ] AC-9: Same setup, `/html-type-renderers-app-config-products/<id>/show` renders `input[type=checkbox][disabled].auix-toggle-switch` and the default `input[type=checkbox][name='deleted']` (slot beats application config); `/…/<id>/edit` renders `input[type=checkbox][name='product[inactive]'].auix-toggle-switch`.

##### Test ports
- Unit: `Aurora.Uix.Renderers.resolve/3`, `validate_table!/2`, `BuiltIn.renderers/0` — no mount.
- Route `"html-type-renderers-app-config-products"` registered in `routes.ex` via `register_crud/2` · layout types `:index`, `:show`, `:form` · observable: `has_element?/2` on the selectors in AC-8 and AC-9.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | add to `test/cases_live/predefined_renderers_test.exs`, module `Aurora.UixWeb.Test.PredefinedRenderersResolverTest` (async: false) | `%Field{html_type: :checkbox}` | test/cases_live/predefined_renderers_test.exs | "an html_type table entry applies on every layout type" | `for lt <- [:index, :show, :form], do: assert Renderers.resolve(field, lt, [%{checkbox: :toggle_switch}]) == (&Predefined.ToggleSwitch.render/1)` |
| AC-2 | add to same module | `%Field{html_type: :checkbox, renderer: :badge}` | same | "a field slot beats an html_type table" | `:show` → `&Predefined.Badge.render/1`; `:index` → `&Predefined.ToggleSwitch.render/1` |
| AC-3 | add to same module | two-table lists | same | "tables are consulted in order and an unknown atom falls through" | the two `==` assertions of AC-3 |
| AC-4 | add to same module | `Application.put_env(:aurora_uix, :html_type_renderers, %{checkbox: :toggle_switch})`, `on_exit` → `Application.delete_env(:aurora_uix, :html_type_renderers)` | same | "the application config is the lowest table" | ToggleSwitch with `[]`; Badge with `[%{checkbox: :badge}]` |
| AC-5 | add to same module | `Application.put_env(:aurora_uix, :html_type_renderers, :oops)` with the same `on_exit` | same | "a renderers table that is not a map raises" | `assert_raise ArgumentError, ~r/config :aurora_uix, :html_type_renderers expected a map/, fn -> Renderers.resolve(%Field{html_type: :checkbox}, :show, []) end`; `assert_raise ArgumentError, ~r/auix_create_ui renderers: expected a map/, fn -> Renderers.validate_table!("auix_create_ui renderers:", :oops) end`; `assert Renderers.validate_table!("x", %{a: :b}) == %{a: :b}` |
| AC-6 | add to same module | the three fields of AC-6 | same | "hidden, upload and association fields skip html_type tables" | each `== (&DefaultRenderer.render/1)` |
| AC-7 | add to same module | add `alias Aurora.Uix.Renderers.BuiltIn` | same | "named per-type defaults resolve to the default renderer" | `for name <- [:default_checkbox, :default_date, :default_datetime_local, :default_number, :default_select, :default_text, :default_textarea, :default_time], do: assert Map.fetch!(BuiltIn.renderers(), name) == (&Renderers.default/1)` |
| AC-8 | new file (`ls test/cases_live \| grep html_type` returns nothing) | module `Aurora.UixWeb.Test.HtmlTypeRenderersAppConfigTest` with `use Aurora.UixWeb.Test.UICase, :phoenix_case`, `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`; `auix_resource_metadata :product, context: Inventory, schema: Product do field(:deleted, renderer: :default_checkbox) end`; `auix_create_ui()`; `setup` puts the application config `%{checkbox: :toggle_switch}` with `on_exit` deleting it; seed with `delete_all_inventory_data()` + `create_sample_products(1, :test, %{inactive: true})`, id from `get_in([Access.key!("id_test-1"), Access.key!(:id)])` | test/cases_live/html_type_renderers_app_config_test.exs | "index renders the configured checkbox renderer and keeps row selection" | `has_element?(view, "input.auix-toggle-switch")`; `has_element?(view, "input[type=checkbox][name='selected_check__#{id}']")` |
| AC-9 | add to the AC-8 file | same | same | "show and form render the configured checkbox renderer under the field slot" | show: `has_element?(view, "input[type=checkbox][disabled].auix-toggle-switch")`, `has_element?(view, "input[type=checkbox][name='deleted']")`; edit: `has_element?(view, "input[type=checkbox][name='product[inactive]'].auix-toggle-switch")` |

##### Modules & components
1. `Aurora.Uix.Renderers` at `lib/aurora_uix/renderers.ex` — modified (`resolve/2`, `resolve/3` new, `validate_table!/2` new, private `slot/2`, `table_pick/2`, `table_applies?/1`, `app_table/0` new). Called from `field_renderer.ex` `do_render/1` and `index_renderer.ex` `field_value/1`.
2. `Aurora.Uix.Renderers.BuiltIn` at `lib/aurora_uix/renderers/built_in.ex` — modified.
3. `index_impl.ex` `assign_index_fields/1` — modified (selection column slot).
4. Components: none new. Theme: none. `dt/1` strings: none (the `ArgumentError` messages are developer errors, not UI text).
5. Backend boundary: `renderers.ex` matches only `%Field{}` atoms (`type`, `html_type`, `hidden`, `data.upload`); no `Ecto.*` / `Ash.*` reference. Both backends produce `html_type` through their parsers, so no parser change.
6. `%Field{}` type-atom audit: no atom is added. `@table_exempt_types` lists the six association/embed atoms, the same set `index_impl.ex` `assign_index_fields/1` rejects.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-1:end -->
<!-- section:UI-2:start -->
### UI-2 — UI · `renderers:` at every layout level
Depends on: UI-1

#### Documentation references
- `guides/customization/predefined_renderers.md` § Renderers by HTML type (as DOC-1 leaves it)

Layout types covered: `:index`, `:form`, `:show`. No markup changes.

#### Implementation details
1. `lib/aurora_uix/uix.ex` (`Aurora.Uix`), `__using__/1`:
   1. Rename the parameter `_opts` to `opts`.
   2. Add as the first line inside the `quote`, before `Module.register_attribute(__MODULE__, :auix_resource_metadata, accumulate: true)`:
      ```elixir
      @auix_html_type_renderers unquote(Keyword.get(opts, :renderers, Macro.escape(%{})))
      ```
      (attribute new; `rg -n auix_html_type_renderers lib` returns nothing).
   3. `@moduledoc` — add after the `### 2. UI Composition (`auix_create_ui`)` bullet list, separated by one blank line:
      ```
      ### 3. Renderers by HTML type (`renderers:`)
      - `use Aurora.Uix, renderers: %{checkbox: :toggle_switch}` sets the renderer of every field of
        an HTML type for every resource of the module.
      - `auix_resource_metadata`, `auix_create_ui`, `index_columns`, `edit_layout` and `show_layout`
        accept the same option; see `Aurora.Uix.Renderers` for the precedence.
      ```
2. `lib/aurora_uix/layout/create_ui.ex` (`Aurora.Uix.Layout.CreateUI`):
   1. Add `alias Aurora.Uix.Renderers` (alphabetical: after `alias Aurora.Uix.Parser`).
   2. In `build_configurations/4`, after the `layout_trees = layout_tags |> Enum.map(...) |> Map.new()` binding and before the `{resource_config_name, %{...}}` tuple, add:
      ```elixir
      html_type_renderers =
        Map.new(layout_trees, fn {tag, layout_tree} ->
          {tag,
           [
             Renderers.validate_table!(
               "#{tag} layout renderers:",
               Keyword.get(layout_tree.opts, :renderers, %{})
             ),
             Renderers.validate_table!("auix_create_ui renderers:", Keyword.get(opts, :renderers, %{})),
             Renderers.validate_table!(
               "auix_resource_metadata renderers:",
               Keyword.get(resource_config.opts, :renderers, %{})
             ),
             Renderers.validate_table!(
               "use Aurora.Uix, renderers:",
               Module.get_attribute(caller, :auix_html_type_renderers)
             )
           ]}
        end)
      ```
   3. Add `html_type_renderers: html_type_renderers` as the last key of the map in the returned
      `{resource_config_name, %{resource_config_name: ..., template: template}}` tuple.
   4. `@doc` of `auix_create_ui/2`, `## Options` — add after the `:for` bullet:
      ```
      - `:renderers` (map()) - `html_type => renderer` table for every layout this call generates.
        Beats `auix_resource_metadata` and `use Aurora.Uix`; a layout macro's `renderers:` and a
        field slot beat it. See `Aurora.Uix.Renderers`.
      ```
3. `lib/aurora_uix/templates/basic/helpers.ex` (`Aurora.Uix.Templates.Basic.Helpers`): add after
   the two `get_configuration/2` clauses (new; `rg -n 'def html_type_renderers' lib` returns nothing):
   ```elixir
   @doc """
   Returns the `renderers:` tables, highest precedence first, that apply to the current resource in
   `layout_type`. A resource absent from the configurations yields `[]`.
   """
   @spec html_type_renderers(map(), Aurora.Uix.Renderer.layout_type()) :: [map()]
   def html_type_renderers(%{configurations: configurations, resource_name: resource_name}, layout_type) do
     configurations
     |> Map.get(resource_name, %{})
     |> Map.get(:html_type_renderers, %{})
     |> Map.get(layout_type, [])
   end
   ```
4. `lib/aurora_uix/templates/basic/renderers/field_renderer.ex`, `do_render/1`: replace
   ```elixir
   defp do_render(%{auix: %{layout_type: layout_type}, field: field} = assigns),
     do: Renderers.resolve(field, layout_type).(assigns)
   ```
   with
   ```elixir
   defp do_render(%{auix: %{layout_type: layout_type} = auix, field: field} = assigns) do
     tables = BasicHelpers.html_type_renderers(auix, layout_type)
     Renderers.resolve(field, layout_type, tables).(assigns)
   end
   ```
   and in its `@moduledoc` replace `Aurora.Uix.Renderers.resolve/2` with `Aurora.Uix.Renderers.resolve/3`.
5. `lib/aurora_uix/templates/basic/renderers/index_renderer.ex`, `field_value/1`: replace
   `Renderers.resolve(field, :index).(assigns)` with
   `Renderers.resolve(field, :index, BasicHelpers.html_type_renderers(auix, :index)).(assigns)`.
   `auix` here is the index `@auix`, which carries `:configurations` and `:resource_name`
   (`index_impl.ex` `assign_index_fields/1` pattern-matches both on it).
6. `lib/aurora_uix/layout/resource_metadata.ex`, `@doc` of `auix_resource_metadata/3`,
   `### Common Options` — add after the `:order_by` bullet (ending
   `for details about the supported directions.`):
   ```
   - `:renderers` (map()) - `html_type => renderer` table for every field of this resource
     (e.g. `%{checkbox: :toggle_switch}`). Beats `use Aurora.Uix`; `auix_create_ui`, a layout
     macro's `renderers:` and a field slot beat it. See `Aurora.Uix.Renderers`.
   ```
7. `lib/aurora_uix/layout/blueprint.ex` `@doc`s, `## Options` lists — add one bullet each:
   1. `edit_layout/3`, after the `:unsaved_changes_guard_disabled?` bullet:
      ```
      - `:renderers` (map()): `html_type => renderer` table for the form layout. Beats
        `auix_create_ui`; a field slot beats it. With no `show_layout`, the show layout reuses it.
      ```
   2. `show_layout/3`, after the `:page_subtitle` bullet:
      ```
      - `:renderers` (map()): `html_type => renderer` table for the show layout. Beats
        `auix_create_ui`; a field slot beats it.
      ```
   3. `index_columns/3`, after the `:where` bullet:
      ```
      - `:renderers` (map()) - `html_type => renderer` table for the index layout. Beats
        `auix_create_ui`; a field's `:index_renderer` beats it.
      ```
8. `test/support/app_web/routes.ex`: add after the `HtmlTypeRenderersAppConfigTest.Product` block
   UI-1 added:
   ```elixir
   RoutesHelper.register_crud(
     HtmlTypeRenderersModuleTest.Product,
     "html-type-renderers-module-products"
   )

   RoutesHelper.register_crud(
     HtmlTypeRenderersPrecedenceTest.Product,
     "html-type-renderers-precedence-products"
   )
   ```
9. Contract change: the configuration map each resource carries in `auix.configurations` gains
   the key `:html_type_renderers` (`%{index: [map()], form: [map()], show: [map()]}`). Its only
   reader is `BasicHelpers.html_type_renderers/2`; `rg -n 'resource_config_name:' test` returns
   nothing, so no test asserts the map's shape.
10. Load guarantee: every table is computed at compile time in `build_configurations/4` from the
    root `%TreePath{}` of each layout (`layout_tree.opts`), the `auix_create_ui` options
    (`@auix_layout_opts`), `%Resource{}.opts` (filled by `resource_metadata.ex`
    `configure_resource_fields/1`, which keeps every option but `:schema`, `:context` and
    `:ash_resource`) and `@auix_html_type_renderers` (set by `use Aurora.Uix`). The `:show` tree
    copied from `:form` by `fill_missing_paths/3` carries the `edit_layout` options, so its
    `renderers:` applies to show too.

##### Acceptance criteria
- [ ] AC-1: Given `use Aurora.Uix, renderers: %{checkbox: :toggle_switch}` and a Product resource with no slots, visiting `/html-type-renderers-module-products` renders `input.auix-toggle-switch` and the row-selection input `input[type=checkbox][name='selected_check__<id>']`.
- [ ] AC-2: Same module, `/…/<id>/show` renders `input[type=checkbox][disabled].auix-toggle-switch`, and `/…/<id>/edit` renders `input[type=checkbox][name='product[inactive]'].auix-toggle-switch`.
- [ ] AC-3: Given the precedence module below, `/html-type-renderers-precedence-products/<id>/show` renders `input[type=checkbox][disabled].auix-toggle-switch` (the `auix_create_ui` checkbox entry applies), `input[type=checkbox][name='deleted']` (slot beats `auix_create_ui`), `span.auix-rating` and no `div.auix-progress` (the unknown `auix_create_ui` atom falls through to the resource, which beats the module), and no `span.auix-badge` (`auix_create_ui` beats the resource).
- [ ] AC-4: Same module, `/html-type-renderers-precedence-products` renders no `.auix-toggle-switch` (the `index_columns` table beats `auix_create_ui`) and renders `span.auix-rating`.
- [ ] AC-5 (error path): a `renderers:` value that is not a map at the module, resource, UI and layout levels raises `ArgumentError` at compile time with the level label (mechanical — no red test; verified by the UI-1 AC-5 test of `validate_table!/2` and by reading the four `validate_table!/2` calls in `create_ui.ex` `build_configurations/4`).
- [ ] AC-6 (degraded path): a resource absent from `auix.configurations` resolves with no tables — `BasicHelpers.html_type_renderers(%{configurations: %{}, resource_name: :missing}, :show)` returns `[]`.

##### Test ports
- Route `"html-type-renderers-module-products"` registered in `routes.ex` via `register_crud/2` · layout types `:index`, `:show`, `:form` · observable: `has_element?/2` on the AC-1 / AC-2 selectors.
- Route `"html-type-renderers-precedence-products"` registered in `routes.ex` via `register_crud/2` · layout types `:index`, `:show` · observable: `has_element?/2` on the AC-3 / AC-4 selectors.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file (`ls test/cases_live \| grep html_type_renderers_module` returns nothing) | module `Aurora.UixWeb.Test.HtmlTypeRenderersModuleTest`: `use Aurora.UixWeb.Test.UICase, :phoenix_case`; then, in place of `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`, the two lines `Module.register_attribute(__MODULE__, :auix_resource_metadata, persist: true)` and `use Aurora.Uix, renderers: %{checkbox: :toggle_switch}`; `auix_resource_metadata(:product, context: Inventory, schema: Product)`; `auix_create_ui()`; seed with `delete_all_inventory_data()` + `create_sample_products(1, :test, %{inactive: true})`, id from `get_in([Access.key!("id_test-1"), Access.key!(:id)])` | test/cases_live/html_type_renderers_module_test.exs | "a module-level table renders every checkbox column and keeps row selection" | `has_element?(view, "input.auix-toggle-switch")`; `has_element?(view, "input[type=checkbox][name='selected_check__#{id}']")` |
| AC-2 | add to the AC-1 file | same | same | "a module-level table applies to show and form" | show: `has_element?(view, "input[type=checkbox][disabled].auix-toggle-switch")`; edit: `has_element?(view, "input[type=checkbox][name='product[inactive]'].auix-toggle-switch")` |
| AC-3 | new file (`ls test/cases_live \| grep html_type_renderers_precedence` returns nothing) | module `Aurora.UixWeb.Test.HtmlTypeRenderersPrecedenceTest`: `use Aurora.UixWeb.Test.UICase, :phoenix_case`; `Module.register_attribute(__MODULE__, :auix_resource_metadata, persist: true)`; `use Aurora.Uix, renderers: %{number: :progress_bar}`; `auix_resource_metadata :product, context: Inventory, schema: Product, renderers: %{text: :badge, number: :rating} do field(:deleted, show_renderer: :default_checkbox) end`; `auix_create_ui renderers: %{checkbox: :toggle_switch, text: :default_text, number: :not_a_renderer} do index_columns(:product, [:reference, :inactive, :quantity_at_hand], renderers: %{checkbox: :default_checkbox}) end`; seed with `delete_all_inventory_data()` + `create_sample_products(1, :test, %{inactive: true, quantity_at_hand: Decimal.new(3)})`, id as in the AC-1 row | test/cases_live/html_type_renderers_precedence_test.exs | "show applies the precedence slot > ui > resource > module" | `has_element?(view, "input[type=checkbox][disabled].auix-toggle-switch")`; `has_element?(view, "input[type=checkbox][name='deleted']")`; `has_element?(view, "span.auix-rating")`; `refute has_element?(view, "div.auix-progress")`; `refute has_element?(view, "span.auix-badge")` |
| AC-4 | add to the AC-3 file | same | same | "an index_columns table beats auix_create_ui" | `refute has_element?(view, ".auix-toggle-switch")`; `has_element?(view, "span.auix-rating")` |
| AC-6 | add to the AC-3 file | none — pure function call; add `alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers` | same | "a resource absent from the configurations resolves with no tables" | `assert BasicHelpers.html_type_renderers(%{configurations: %{}, resource_name: :missing}, :show) == []` |

##### Modules & components
1. `Aurora.Uix` at `lib/aurora_uix/uix.ex` — modified (`__using__/1`, `@auix_html_type_renderers` new).
2. `Aurora.Uix.Layout.CreateUI` at `lib/aurora_uix/layout/create_ui.ex` — modified (`build_configurations/4`).
3. `Aurora.Uix.Templates.Basic.Helpers` at `lib/aurora_uix/templates/basic/helpers.ex` — modified (`html_type_renderers/2` new).
4. `FieldRenderer` (`field_renderer.ex` `do_render/1`) and `IndexRenderer` (`index_renderer.ex` `field_value/1`) — modified; markup unchanged.
5. `@doc` additions in `resource_metadata.ex` and `blueprint.ex`; no behaviour change there.
6. Components: none new. Theme: none. `dt/1` strings: none.
7. Backend boundary: the tables are read from layout options and consumed against `%Field{}.html_type`; no `Ecto.*` / `Ash.*` reference is added. Ash and Ecto resources take the same path.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-2:end -->

---

### Out of Scope
- No Parser section: `html_type` is already produced by both the Ash and the Ecto (`ctx`) parser, and every change here sits downstream of the normalized `%Field{}`; no backend-specific behaviour exists to test.
- `auix_create_layout` and its layouts: `renderers:` is accepted by `index_columns`, `edit_layout` and `show_layout` only.
- Tables for association, embed, upload and hidden fields; they keep the slot → default chain.
- A named default that changes a field's `html_type`: each `:default_<type>` renders the field's own default rendering; the field option `html_type:` already changes the input type.
<!-- enriched-spec:end -->
