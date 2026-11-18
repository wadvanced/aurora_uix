<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** high

### Overview
`index_columns` takes a `do` block holding one `card` layout: a composable card with a title, a subtitle, a body built with `inline`, `stacked`, `group` and `field`, and a footer bar of row actions. The card replaces the striped mobile list, and with `show_on: :all` it replaces the table at every breakpoint. The work is backend-agnostic layout, action and rendering code: it covers Ash and Ecto resources alike and changes no parser.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | CHANGELOG.md § [0.2.1] › Added, › Changed · guides/core/layouts.md § Layout Types, § Index Cards (new) · guides/customization/custom_actions.md § Understanding the Action System, § Action Operations, § Row actions in cards (new) · guides/customization/overriding_components.md § `:basic_components` · guides/customization/styling.md § Sizes & dimensions, § Class reference | none | federico/508-doc-1-index-cards | docs: index card layout (#508 · DOC-1) |
| UI-1 | UI | layout DSL · `card` inside `index_columns`, `%Node.Card{}`, field-source rules | DOC-1 | federico/508-ui-1-card-dsl | feat: card layout in index_columns (#508 · UI-1) |
| UI-2 | UI | actions · `destructive?` on `%Aurora.Uix.Action{}` and the row-action operations | DOC-1 | federico/508-ui-2-destructive-actions | feat: destructive row actions (#508 · UI-2) |
| UI-3 | UI | component + theme · card frame, footer action bar, overflow menu (`auix_items_card/1`) | UI-2 | federico/508-ui-3-card-frame | feat: index card frame and footer action bar (#508 · UI-3) |
| UI-4 | UI | renderer + theme · declared card content and `show_on: :all` | UI-1, UI-3 | federico/508-ui-4-card-content | feat: declared index cards and show_on (#508 · UI-4) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
- `CHANGELOG.md § [0.2.1]` › `### Added`, › `### Changed`
- `guides/core/layouts.md § Layout Types`, `§ Index Layout Options`
- `guides/customization/custom_actions.md § Understanding the Action System`, `§ Action Operations`, `§ Custom actions on mobile`
- `guides/customization/overriding_components.md § :basic_components — Aurora.Uix.Templates.Basic.Components`
- `guides/customization/styling.md § Sizes & dimensions`, `§ Class reference`

#### Implementation details

##### CHANGELOG.md
1. § `## [0.2.1]` › `### Added` — insert verbatim after the last line of the `- **Action icons**` entry:
   ```
   - **Index cards**
     - `index_columns` takes a `do` block with one `card`: a title, a subtitle and a body built with
       `inline`, `stacked`, `group` and `field`. `show_on: :all` shows the cards at every breakpoint
       instead of the table (Layouts guide, "Index Cards").
     - Row actions sit in a footer bar below the card body, and `destructive?: true` marks a row
       action as destructive (Custom Actions guide, "Row actions in cards").
   ```
2. § `## [0.2.1]` › `### Changed` — insert verbatim as the last entry of the section:
   ```
   - **Index card styling (CSS class changes)**
     - The mobile list is a list of bordered cards, with no stripes and no italic values.
     - Removed: `auix-items-card-item-content--even` and `auix-items-card-item-content--odd`.
     - The other `auix-items-card-*` classes are restyled and new ones are added (Styling guide,
       "Class reference"): re-run `mix auix.gen.stylesheet` after upgrading.
   ```

##### guides/core/layouts.md
1. § `Layout Types` — replace the `index_columns` bullet with:
   ```
   - **`index_columns`** — Selects which fields appear in the list (table) view and their order. Takes a list of field names, and a `do` block with a `card` that lays out the card view (see [Index Cards](#index-cards)).
   ```
2. Insert a new section `#### Index Cards` between the end of § `Index Layout Options` and the heading `#### Form Layout Options`, verbatim:
   ````
   #### Index Cards

   Below the 768px breakpoint the index shows one card per record instead of a table row. Without
   any configuration the card is derived from the columns: the first column is the title, and the
   others follow as `label · value` rows.

   A `card` inside the `do` block of `index_columns` lays the card out:

   ```elixir
   index_columns :product, [:reference, :name, :msrp, :status, :quantity_at_hand] do
     card title: :name, subtitle: :reference, show_on: :all do
       inline [:msrp, :status]
       group "Stock", [:quantity_at_hand]
     end
   end
   ```

   **Card options:**
   - `:title` — The card title: a field, a text, or a named function of arity 1. The function receives the assigns, with the record in `assigns.entity`
   - `:subtitle` — A second line under the title; takes the same values as `:title`
   - `:show_on` — `:mobile` (default) shows the cards below the 768px breakpoint and the table from it up. `:all` shows the cards at every breakpoint, as a responsive grid, and renders no table

   The card body takes `inline`, `stacked`, `group` and `field`. `sections` is not allowed in a
   card. Options given to a field inside the card apply to the card only:

   ```elixir
   index_columns :product, [:reference, :name, :quantity_at_hand] do
     card title: :name do
       field :quantity_at_hand, label: "On hand"
     end
   end
   ```

   The selection checkbox and the row actions belong to the card frame: the checkbox opens the
   header, and the row actions fill a footer bar (see
   [Custom Actions › Row actions in cards](../customization/custom_actions.md#row-actions-in-cards)).

   The field list is the single source of fields for the table columns, the data loading, the sort
   and the filters:

   | Declared | Columns, sort and filters | Card |
   |---|---|---|
   | field list | the list | derived |
   | field list and `card` | the list | as declared; it may reorder and omit columns, and may not add one (compile-time error) |
   | `card` | the card fields: title, subtitle, then the body in order | as declared |
   | neither | the default columns | derived |

   A column the card omits stays sortable and filterable. With `show_on: :all` the table headers are
   gone, so the card sort control and the filter cards show at every breakpoint.

   A call with a `card` and no field list takes its options after an empty list:
   `index_columns :product, [], page_title: "Products" do ... end`.
   ````

##### guides/customization/custom_actions.md
1. § `Understanding the Action System` — insert after the bullet that starts `` - `:function_component` ``:
   ```
   - `:destructive?` — `true` for an action that destroys data. Index cards place destructive row actions at the leading edge of their footer bar (default `false`; `true` for `:default_row_delete`)
   ```
2. § `Action Operations` — replace the sentence ``All operations accept `{action_name, &function/1}` pairs (except remove, which only needs the name).`` with:
   ```
   All operations accept `{action_name, &function/1}` pairs (except remove, which only needs the name). A row action also takes options as a third element: `{action_name, &function/1, destructive?: true}`.
   ```
3. Insert a new section `### Row actions in cards` between the end of § `Custom actions on mobile` and the heading `## Action Handlers`, verbatim:
   ````
   ### Row actions in cards

   In the card view the row actions fill a footer bar below the card body. Destructive actions sit
   at the leading edge and the others at the trailing edge; the bar mirrors in right-to-left
   layouts. The first three row actions show in the bar. From the fourth on, actions move into a ⋮
   menu at the end of the bar.

   `:default_row_delete` is destructive. Mark your own action with `destructive?: true`:

   ```elixir
   index_columns :product, [:reference, :name],
     add_row_action: {:archive, &MyAppWeb.ProductActions.archive_action/1, destructive?: true}
   ```

   An action that replaces `:default_row_delete` stays destructive unless it says
   `destructive?: false`. Each action in the bar gets a 44px touch target. The default row actions
   carry their label as `title` and `aria-label`; give your own action both, as
   [Custom actions on mobile](#custom-actions-on-mobile) shows.
   ````

##### guides/customization/overriding_components.md
1. § `` `:basic_components` — `Aurora.Uix.Templates.Basic.Components` `` — replace the `auix_items/1` and `auix_items_card/1` table rows with:
   ```
   | `auix_items/1` | Responsive switcher: renders `auix_items_table` on desktop and `auix_items_card` on mobile; with `show_on={:all}` it renders `auix_items_card` alone |
   | `auix_items_card/1` | Card view for collections: one card per record with a header (checkbox, title, subtitle), a body, a footer bar of row actions, and the filter cards |
   ```

##### guides/customization/styling.md
1. § `Sizes & dimensions` — insert after the `--auix-hidden-element-size` row:
   ```
   | `--auix-touch-target-size` | `2.75rem` | Minimum width and height of a row action in a card footer |
   | `--auix-items-card-label-width` | `7.25rem` | Width of the label column of a card `label · value` row |
   | `--auix-items-card-min-width` | `17.5rem` | Minimum card width in the card grid (`show_on: :all`) |
   ```
2. § `Class reference` — append after the `.auix-action-icon-text` row:
   ```
   | `.auix-items-card-list` | List of index cards | `--auix-gap-large` |
   | `.auix-items-card-item-content` | One index card | `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-border-primary`, `--auix-border-radius-default`, `--auix-color-bg-default`, `--auix-color-items-card-item-content-text` |
   | `.auix-items-card-item-group` | Card header: checkbox and heading | `--auix-gap-large`, `--auix-padding-default` |
   | `.auix-items-card-select` | Checkbox slot of the card header | Structural only |
   | `.auix-items-card-heading` | Title and subtitle column of the card header | `--auix-gap-minimal` |
   | `.auix-items-card-title` | Card title | `--auix-font-size-subtitle`, `--auix-font-weight-bold` |
   | `.auix-items-card-subtitle` | Card subtitle | `--auix-font-size-caption`, `--auix-color-text-tertiary` |
   | `.auix-items-card-item` | Card body | `--auix-gap-default`, `--auix-padding-default` |
   | `.auix-items-card-item-fieldset` | One `label · value` row of a card | `--auix-items-card-label-width`, `--auix-gap-large` |
   | `.auix-items-card-actions` | Card footer bar of row actions; `space-between` separates the leading and trailing groups | `--auix-border-width-default`, `--auix-color-border-primary`, `--auix-padding-small`, `--auix-padding-minimal` |
   | `.auix-items-card-actions-leading` | Leading group of the footer bar: the destructive row actions | `--auix-gap-default` |
   | `.auix-items-card-actions-trailing` | Trailing group of the footer bar: the other row actions and the ⋮ menu | `--auix-gap-default` |
   | `.auix-items-card-action` | One row action in the footer bar | `--auix-touch-target-size` |
   | `.auix-items-card-menu` | ⋮ menu toggle at the end of the footer bar | `--auix-touch-target-size` |
   | `.auix-items-card-menu-list` | Overflow menu of the footer bar (hidden until toggled) | `--auix-color-bg-default`, `--auix-color-border-primary`, `--auix-border-radius-default`, `--auix-shadow-md` |
   | `.auix-items-cards` | Card container shown at every breakpoint (`show_on: :all`); lays the cards out as a grid | `--auix-items-card-min-width`, `--auix-gap-large` |
   | `.auix-index-sort-action--always` | Keeps the card-view sort control visible from the `md` breakpoint up (`show_on: :all`) | Structural only |
   ```

##### Acceptance criteria
- [x] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no
      issue-link suffix (mechanical — no red test; verified by
      `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [x] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-508-enriched-spec.md`)
- [x] AC-3: `guides/core/layouts.md § Index Cards` reads as prescribed (mechanical — no red test;
      verified by `grep -n '^#### Index Cards' guides/core/layouts.md` returning one line and
      `grep -c 'show_on' guides/core/layouts.md` returning at least 3)
- [x] AC-4: `guides/customization/custom_actions.md § Row actions in cards` reads as prescribed
      (mechanical — no red test; verified by
      `grep -n '^### Row actions in cards' guides/customization/custom_actions.md` returning one line
      and `grep -c 'destructive?' guides/customization/custom_actions.md` returning at least 4)
- [x] AC-5: `guides/customization/overriding_components.md` describes `auix_items_card/1` as the
      card view (mechanical — no red test; verified by
      `grep -c 'footer bar of row actions' guides/customization/overriding_components.md` returning 1)
- [x] AC-6: `guides/customization/styling.md` lists the new variables and classes (mechanical — no
      red test; verified by `grep -c 'auix-items-card' guides/customization/styling.md` returning 13
      and `grep -c 'auix-touch-target-size' guides/customization/styling.md` returning 2)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->
<!-- section:UI-1:start -->
### UI-1 — UI · layout DSL: `card` inside `index_columns`
Depends on: DOC-1

#### Documentation references
- `guides/core/layouts.md § Index Cards` (DOC-1)

#### Implementation details

Layout types: `:index` only. `:form` and `:show` are untouched. This section builds and validates the layout nodes; nothing renders them until UI-4.

Facts this section builds on:
- Spark 2.7.10 reads the last keyword-list argument of a block-less entity call as entity options once the entity nests another entity (`deps/spark/lib/spark/dsl/extension.ex` `shuffle_opts_to_end/5`). A call with a `do` block is not affected. `index_columns` therefore becomes a macro that always passes a block to the entity.
- A nested entity with no positional argument cannot take keyword options and a block in one call. `card` takes its options through an optional keyword argument, as `@edit_layout` in `lib/aurora_uix/layout/create_ui/dsl.ex` does with `layout_opts`.

##### Acceptance criteria
- [ ] AC-1: Given `index_columns :product, [:reference, :name, :msrp] do card title: :name, subtitle: :reference, show_on: :all do inline [:msrp] end end`, the built index tree has `card: %Node.Card{show_on: :all}` whose `title` and `subtitle` are `%Node.Field{}` nodes with a resolved `field`, and whose children are `[%Node.Inline{id: nil}]`
- [ ] AC-2: Given a card with `field :name, label: "Product name"` and the column `:name`, the card field node's `field.label` is `"Product name"` and the column's `field.label` is not
- [ ] AC-3: Given `index_columns :product do card title: :name, subtitle: :reference do stacked [:msrp, :name] end end`, the columns are `[:name, :reference, :msrp]`
- [ ] AC-4: Given a field list and a card that places a field outside the list, compilation fails with `card fields [:msrp] are not index columns; a card may reorder and omit columns, not add them`
- [ ] AC-5: Given a card holding `sections`, directly and inside an `inline`, compilation fails with `card takes no sections`
- [ ] AC-6: Given `index_columns :product, [:reference], page_title: "Products"` and `index_columns :product, [name: [label: "Product"]]`, both without a block, compilation succeeds; the first keeps `options: [page_title: "Products"]`, the second has one column `:name` whose override label is `"Product"`
- [ ] AC-7: Given `card show_on: :desktop`, compilation fails with a message naming `show_on`
- [ ] AC-8: Given a field list and no card, the built index tree has `card: nil`
- [ ] AC-9: `.formatter.exs` keeps `index_columns` free of parentheses (mechanical — no red test; verified by `mix format --check-formatted` on a tree that contains `index_columns :product, [:name]` without parentheses, which `test/cases/render_tree_test.exs` does after this section)

##### Test ports
- No route. Compile-time port: `compile/1` and `compiled_ui/1` of `test/cases/create_ui_validation_test.exs`, then `mod.auix_layouts()` (layouts as written) and `mod.auix_configurations().product.layout_trees.index` (built tree).
- Built-tree port: the test module of `test/cases/render_tree_test.exs`, read through `__MODULE__.auix_configurations().product.layout_trees.index`.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1, AC-2 | add to `test/cases/render_tree_test.exs` | add to the module's `auix_create_ui` block: `index_columns :product, [:reference, :name, :msrp] do card title: :name, subtitle: :reference, show_on: :all do inline [:msrp]; field :name, label: "Product name" end end` (one statement per line); read `layout_trees.index` in the test | `test/cases/render_tree_test.exs` | `"a card carries resolved field nodes and no ids"` | `assert %Node.Card{show_on: :all, title: %Node.Field{key: :name, field: %{label: title_label}}, subtitle: %Node.Field{key: :reference}, children: [%Node.Inline{id: nil}, %Node.Field{key: :name, field: %{label: "Product name"}}]} = index.card`; `refute title_label == "Product name"`; the `:name` node of `index.children` has `field.label != "Product name"` |
| AC-3 | add to `test/cases/create_ui_validation_test.exs` | `compiled_ui/1` with the AC-3 layout inside `auix_create_ui do … end` | same | `"a card without a field list gives the columns"` | `Enum.map(mod.auix_configurations().product.layout_trees.index.children, & &1.key) == [:name, :reference, :msrp]` |
| AC-4 | add to `test/cases/create_ui_validation_test.exs` | `compile/1` with `index_columns :product, [:reference, :name] do card title: :name do stacked [:msrp] end end` | same | `"a card field outside the field list fails compilation"` | `assert_raise DslError, ~r/card fields \[:msrp\] are not index columns/` |
| AC-5 | add to `test/cases/create_ui_validation_test.exs` | `compile/1` twice: `card do sections do section "A", [:name] end end`, then the same `sections` inside `inline do … end`; field list `[:name]` | same | `"sections in a card fails compilation"` | `assert_raise DslError, ~r/card takes no sections/` for both |
| AC-6 | add to `test/cases/create_ui_validation_test.exs` | `compiled_ui/1` once per layout | same | `"index_columns without a block keeps its options and its pair-only field list"` | first: `[%Node.Index{options: [page_title: "Products"]}] = mod.auix_layouts()`; second: `[%Node.Index{children: [%Node.Field{key: :name, overrides: %{label: "Product"}}]}] = mod.auix_layouts()` |
| AC-7 | add to `test/cases/create_ui_validation_test.exs` | `compile/1` with `index_columns :product, [:name] do card show_on: :desktop end` | same | `"an unknown show_on fails compilation"` | `assert_raise DslError, ~r/show_on/` |
| AC-8 | add to `test/cases/create_ui_validation_test.exs` | `compiled_ui/1` with `index_columns :product, [:reference]` | same | `"an index without a card has none"` | `mod.auix_configurations().product.layout_trees.index.card == nil` |

##### Modules & components
1. `Aurora.Uix.Layout.Node.Card` at `lib/aurora_uix/layout/node/card.ex` — new (`rg -n "Node.Card|defmodule .*Card" lib` returns nothing).
   - `defstruct title: nil, subtitle: nil, show_on: :mobile, children: [], card_opts: [], __spark_metadata__: nil`.
   - `@type text() :: Aurora.Uix.Layout.Node.Field.t() | binary() | (map() -> term()) | nil`; `@type t()` with `title: text()`, `subtitle: text()`, `show_on: :mobile | :all`, `children: [Aurora.Uix.Layout.Node.t()]`, `card_opts: keyword()`, `__spark_metadata__: term()`.
   - `@moduledoc` with `## Key Features` (title and subtitle are a field node, a text, a function of the assigns; `children` is the body; `show_on` chooses the breakpoints) and `## Key Constraints` (`card_opts` and `__spark_metadata__` are only used while the layout DSL builds the node; the nodes under a card carry no `id`).
2. `lib/aurora_uix/layout/node/index.ex` — modified. Add `card: nil` to the `defstruct` after `children: []`, `card: Aurora.Uix.Layout.Node.Card.t() | nil` to `t()`, and one `## Key Features` line: `card` holds the card layout, `nil` when the layout declares none.
3. `lib/aurora_uix/layout/node.ex` — modified.
   - Add `| Node.Card.t()` to `t()`.
   - Add a `fields/1` clause between the `%Node.Field{}` clause and the `%{children: children}` clause:
     ```elixir
     def fields(%Node.Card{title: title, subtitle: subtitle, children: children}),
       do: fields(Enum.filter([title, subtitle], &is_struct(&1, Node.Field)) ++ children)
     ```
   - `fields/1` on a `%Node.Index{}` keeps returning its columns only: the card fields are a subset of them (item 5).
4. `Aurora.Uix.Layout.CreateUI.IndexColumns` at `lib/aurora_uix/layout/create_ui/index_columns.ex` — new (`rg -n "CreateUI.IndexColumns" lib test` returns nothing). It defines the `index_columns` macro over the `auix_index_columns` entity:
   ```elixir
   defmacro index_columns(resource, [do: block]), do: entity(resource, [], [], block)
   defmacro index_columns(resource, columns), do: entity(resource, columns, [], nil)

   defmacro index_columns(resource, columns, [do: block]), do: entity(resource, columns, [], block)
   defmacro index_columns(resource, columns, opts), do: entity(resource, columns, opts, nil)

   defmacro index_columns(resource, columns, opts, [do: block]),
     do: entity(resource, columns, opts, block)

   defp entity(resource, columns, opts, block) do
     quote do
       auix_index_columns(unquote(resource), unquote(columns), unquote(opts), do: unquote(block))
     end
   end
   ```
   - `@doc` and `@spec` (`Macro.t()` arguments and return) on the first clause of each arity; `@spec entity(Macro.t(), Macro.t(), Macro.t(), Macro.t()) :: Macro.t()`.
   - `@moduledoc` `## Key Features`: `index_columns resource, fields, options do card … end`, every part after the resource optional. `## Key Constraints`: the macro always passes a block, because Spark reads the keyword list of a block-less call to an entity with nested entities as entity options; a call with a card and no field list writes its options after `[]`.
5. `lib/aurora_uix/layout/create_ui/dsl.ex` — modified.
   - New attributes, placed after `@section` and before `@sub_layouts`:
     ```elixir
     @card_text {:or, [:atom, :string, {:fun, 1}]}

     @card_schema [
       title: [type: @card_text, doc: "The title: a field, a text or a function of the assigns."],
       subtitle: [type: @card_text, doc: "The subtitle; takes what `title` takes."],
       show_on: [
         type: {:in, [:mobile, :all]},
         doc: "`:mobile` shows the cards below the `md` breakpoint; `:all` shows them at every breakpoint, without the table."
       ]
     ]

     @card %Entity{
       name: :card,
       describe: "The card of an index: a title, a subtitle and a body of sub-layouts.",
       target: Node.Card,
       args: [{:optional, :card_opts, []}],
       entities: [children: [@inline, @stacked, @group, @sections, @section, @field]],
       transform: {__MODULE__, :build_node, []},
       schema: [
         {:card_opts, [type: :keyword_list, keys: @card_schema, default: [], doc: "Options."]}
         | @card_schema
       ]
     }
     ```
     `@sections` and `@section` are listed so that `sections` inside a card reaches `build_node/1` and fails with the message of AC-5.
   - `@index_columns`: set `name: :auix_index_columns`; add `entities: [card: [@card]]` and `singleton_entity_keys: [:card]`. `args` and `schema` stay as they are.
   - `@create_ui` and `@create_layout`: add `imports: [Aurora.Uix.Layout.CreateUI.IndexColumns]` (alias it as `IndexColumns`, alphabetical among the aliases).
   - `build_node/1`, clause head `def build_node(%Node.Index{children: [use: name], options: []} = index) when is_atom(name)`: add `card: nil` to the pattern.
   - `build_node/1`, clause head `def build_node(%Node.Index{} = index) do`: insert `{:ok, columns} <- card_columns(columns, index.card),` after the `field_nodes(index.children)` step.
   - New `build_node/1` clause, placed before `def build_node(%module{} = layout) when module in [Node.Form, Node.Show]`:
     ```elixir
     def build_node(%Node.Card{} = card) do
       if sections?(card.children) do
         {:error, "card takes no sections"}
       else
         {:ok,
          %{
            card
            | title: card_text(card_opt(card, :title)),
              subtitle: card_text(card_opt(card, :subtitle)),
              show_on: card_opt(card, :show_on) || :mobile,
              card_opts: []
          }}
       end
     end
     ```
     The `defstruct` default of `show_on` is `:mobile`; a card written without a block sets the top-level key, a card with a block sets `card_opts`.
   - New private functions, each with `@spec`:
     - `card_opt(Node.Card.t(), atom()) :: term()` — `Keyword.get(card.card_opts, key, Map.fetch!(card, key))`. For `:show_on` the struct default `:mobile` is the fallback.
     - `card_text(term()) :: Node.Card.text()` — `nil` stays `nil`; any other atom `key` becomes `%Node.Field{key: key}`; a binary and a function are returned as given.
     - `sections?([Node.t()]) :: boolean()` — true when a node at any depth has its struct in `[Node.Sections, Node.Section]`: a `%Node.Field{}` gives false, every other node is checked and then its `children`.
     - `card_columns([Node.Field.t()], Node.Card.t() | nil) :: {:ok, [Node.Field.t()]} | {:error, binary()}`:
       - `card_columns(columns, nil)` → `{:ok, columns}`.
       - `card_columns([], card)` → `{:ok, columns}` where `columns` is `card |> Node.fields() |> Enum.uniq_by(& &1.key) |> Enum.map(&%Node.Field{key: &1.key, path: &1.path})`.
       - `card_columns(columns, card)` → the card field keys minus the column keys; `[]` gives `{:ok, columns}`; otherwise `{:error, "card fields #{inspect(added)} are not index columns; a card may reorder and omit columns, not add them"}`, `added` in card order, unique.
   - `@moduledoc`: add `card` to the `## Key Features` line that lists the layouts, and one `## Key Constraints` line: `index_columns` is the macro of `Aurora.Uix.Layout.CreateUI.IndexColumns` over the `auix_index_columns` entity.
6. `lib/aurora_uix/layout/render_tree.ex` — modified. In `build/4`, clause head `def build(%Node.Index{} = layout, :index, resource, _opts) do`, add `card: card(layout.card, resource)` to the map update. New private functions with `@spec`:
   ```elixir
   defp card(nil, _resource), do: nil

   defp card(%Node.Card{} = card, resource) do
     %{
       card
       | title: card_text(card.title, resource),
         subtitle: card_text(card.subtitle, resource),
         children: Enum.map(card.children, &card_node(&1, resource))
     }
   end

   defp card_text(%Node.Field{} = field, resource), do: field_node(field, resource)
   defp card_text(text, _resource), do: text

   defp card_node(%Node.Field{} = field, resource), do: field_node(field, resource)

   defp card_node(%{children: children} = node, resource),
     do: %{node | children: Enum.map(children, &card_node(&1, resource))}
   ```
   `card_node/2` assigns no `id`: a card renders once per row, and a positional id would repeat in the DOM. Add one `## Key Features` line to the `@moduledoc`: resolves the field nodes of an index card and leaves its nodes without ids.
7. `lib/aurora_uix/layout/create_ui.ex` — modified, `@moduledoc` only. § `## Layouts`: replace the `index_columns` bullet with: `` `index_columns resource, fields, options do card ... end` - the index columns and options, and the card of the card view. See `Aurora.Uix.Layout.Options.Index` and `Aurora.Uix.Layout.Node.Card`; `order_by` and `where` set the listed entries. ``
8. `.formatter.exs` — modified.
   - After the `spark_locals_without_parens` list, add:
     ```elixir
     # `index_columns` is a macro over the `auix_index_columns` entity, so `mix spark.formatter`
     # does not list it.
     auix_locals_without_parens = [index_columns: 2, index_columns: 3, index_columns: 4]
     ```
   - Set `locals_without_parens: spark_locals_without_parens ++ auix_locals_without_parens` and `export: [locals_without_parens: spark_locals_without_parens ++ auix_locals_without_parens]`.
   - `mix consistency` rewrites `spark_locals_without_parens` (its `spark.formatter` stage): the list is rebuilt from the entities, so it loses `index_columns` and gains the names of the `auix_index_columns` and `card` entities and of their options. Commit the rewritten file.
9. Components: none. Theme: none. `dt/1` strings: none.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-1:end -->
<!-- section:UI-2:start -->
### UI-2 — UI · actions: `destructive?` on row actions
Depends on: DOC-1

#### Documentation references
- `guides/customization/custom_actions.md § Understanding the Action System`, `§ Action Operations`, `§ Row actions in cards` (DOC-1)

#### Implementation details

Layout types: the marker lives on every `%Aurora.Uix.Action{}`; only the row-action groups (`:index_row_actions`, `:one_to_many_row_actions`) read it, in UI-3. No markup changes here.

##### Acceptance criteria
- [ ] AC-1: `Action.new({:archive, fun})` has `destructive?: false`; `Action.new({:archive, fun, destructive?: true})` has `destructive?: true`
- [ ] AC-2: `Action.new({:default_row_delete, fun})` and `Action.new(:default_row_delete, fun)` have `destructive?: true`; `Action.new({:default_row_delete, fun, destructive?: false})` has `destructive?: false`
- [ ] AC-3: Given a layout tree with `actions: [add_row_action: {:archive, fun, destructive?: true}, replace_row_action: {:default_row_delete, other_fun}]`, `Actions.modify_actions/2` leaves `:index_row_actions` with a destructive `:archive` and a `:default_row_delete` that is still destructive and holds `other_fun`
- [ ] AC-4: `Action.new({:archive, fun, destroys: true})` raises `ArgumentError`

##### Test ports
- No route. Unit port: `Aurora.Uix.Action.new/1`, `new/2` and `Aurora.Uix.Templates.Basic.Actions.modify_actions/2` on a plain assigns map `%{auix: %{layout_tree: %{actions: […]}, index_row_actions: […]}}`.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1, AC-2, AC-4 | add to `test/cases/templates/basic/actions_icon_test.exs` | a named function of the test module, `&__MODULE__.name_icon/1`, as the function component | same | `"new/1 and new/2 set destructive?"` | match `%Action{destructive?: …}` for the five calls; `assert_raise ArgumentError, fn -> Action.new({:archive, fun, destroys: true}) end` |
| AC-3 | add to `test/cases/templates/basic/actions_icon_test.exs` | `assigns = %{auix: %{layout_tree: %{actions: [add_row_action: {:archive, fun, destructive?: true}, replace_row_action: {:default_row_delete, other}]}, index_row_actions: [Action.new(:default_row_delete, fun)]}}`; `Actions.modify_actions(assigns, Action.available_actions(:index))` | same | `"row action operations carry destructive?"` | `[%Action{name: :default_row_delete, destructive?: true, function_component: ^other}, %Action{name: :archive, destructive?: true}] = result.auix.index_row_actions` |

##### Modules & components
1. `lib/aurora_uix/action.ex` — modified.
   - `defstruct [:name, :function_component, destructive?: false]`; add `destructive?: boolean()` to `t()`.
   - New attribute `@destructive_actions [:default_row_delete]`.
   - `new/2`: `%__MODULE__{name: name, function_component: function_component, destructive?: name in @destructive_actions}`.
   - `new/1`, existing clause `def new({name, function_component})`: delegate to `new/2`.
   - `new/1`, new clause after it:
     ```elixir
     def new({name, function_component, opts}) when is_list(opts) do
       opts = Keyword.validate!(opts, destructive?: name in @destructive_actions)
       %__MODULE__{name: name, function_component: function_component, destructive?: opts[:destructive?]}
     end
     ```
   - `@spec new({atom(), function()} | {atom(), function(), keyword()}) :: t()`; update both `@doc` blocks: the `## Examples` output shows `destructive?: false`, and the `new/1` doc states the third element and that `:default_row_delete` is destructive by default.
   - `@moduledoc` `## Key Features`: add "Marks an action as destructive (`destructive?`); `:default_row_delete` is destructive unless the layout says otherwise."
   - Callers of `new/1`, unchanged: `Aurora.Uix.Templates.Basic.Actions.add_actions/3` (`Action.new(&1)` on `{name, function}` pairs — the default delete of `actions/index.ex` `add_default_row_actions/1` and `actions/one_to_many.ex` `add_default_row_actions/1` becomes destructive through its name) and `modify_action/3` (`Action.new(action)` on the layout's tuple, now of 2 and 3 elements).
2. `lib/aurora_uix/templates/basic/actions.ex` — modified, docs only: in `add_actions/3` and `modify_actions/2` state that a tuple takes options as a third element.
3. Components: none. Theme: none. `dt/1` strings: none.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-2:end -->
<!-- section:UI-3:start -->
### UI-3 — UI · component + theme: card frame and footer action bar
Depends on: UI-2

#### Documentation references
- `guides/core/layouts.md § Index Cards` (DOC-1)
- `guides/customization/custom_actions.md § Row actions in cards` (DOC-1)
- `guides/customization/styling.md § Class reference`, `§ Sizes & dimensions` (DOC-1)
- Mockups: https://claude.ai/artifact/DGKCKF4xHaomFLoMnhJEdS, boards A and D

#### Implementation details

Layout types: `:index`, and the one-to-many list (`:form` and `:show` parents), which renders through the same `auix_items/1`. The card content is the derived one: first non-checkbox column as title, the others as `label · value` rows. UI-4 adds the declared content.

##### Acceptance criteria
- [ ] AC-1: Given `index_columns(:product, [:reference, :name, :quantity_at_hand])`, each card `[name='auix-card']` has the checkbox inside `.auix-items-card-select`, the reference inside `[name='auix-card-title']`, and two `.auix-items-card-item-fieldset` rows inside `[name='auix-card-body']` whose labels are `Name` and `Quantity At Hand`
- [ ] AC-2: With the three default row actions, `[name='auix-card-actions-leading']` holds `a[name='auix-delete-product']`, `[name='auix-card-actions-trailing']` holds `a[name='auix-show-product']` and `a[name='auix-edit-product']`, and the card has no `[name='auix-card-menu']`
- [ ] AC-3: The default row actions carry `title` and `aria-label`: `Show`, `Edit`, `Delete`
- [ ] AC-4: Given `insert_row_action: {:archive, &archive_action/1, destructive?: true}` and `add_row_action: {:copy, &copy_action/1}`, the leading group holds the archive action, the trailing group holds show and edit, and `[name='auix-card-menu-list']` holds delete and copy
- [ ] AC-5: The menu toggle `button[name='auix-card-menu-toggle']` has `aria-label='More actions'` and `aria-expanded='false'`
- [ ] AC-6: The menu opens on a tap of the toggle, moves focus to its first action and closes on a tap outside it (manual — no red test; verified by `iex -S mix run test/start_test_server.exs`, opening `/index-card-actions-products` at a 390px viewport)
- [ ] AC-7: With no products, the card container shows `No items to show` and no `[name='auix-card']`
- [ ] AC-8: No card element carries `auix-items-card-item-content--even` nor `auix-items-card-item-content--odd`, and `Base.rule(:auix_items_card_item_value)` has no `font-style`
- [ ] AC-9: The footer bar uses no physical side: `Base.rule(:auix_items_card_actions)` contains `justify-content: space-between`, and neither it nor `Base.rule(:auix_items_card_menu_list)` contains `left` nor `right`
- [ ] AC-10: The one-to-many list passes `destructive?` for each row action (mechanical — no red test; verified by `rg -n "destructive\?=\{action.destructive\?\}" lib/aurora_uix/templates/basic/renderers/fields/one_to_many.ex` returning one line)

##### Test ports
- Route `"/index-card-frame-products"` registered in `test/support/app_web/routes.ex` via `RoutesHelper.register_crud(IndexCardFrameTest.Product, "index-card-frame-products")` · layout type `:index` · observable: `has_element?/2` under `#auix-table-index-card-frame-products-index-mobile`
- Route `"/index-card-actions-products"` registered via `RoutesHelper.register_crud(IndexCardActionsTest.Product, "index-card-actions-products")` · layout type `:index` · observable: `has_element?/2` under `#auix-table-index-card-actions-products-index-mobile`

##### Markup changes — tests that drive the changed selectors
`rg -n "items-card|auix-column-value" test` returns two hits:
| Test | Current selector | New drive |
|---|---|---|
| `test/cases_live/sortable_columns_test.exs` `mobile_name_cells/1` (columns `[:reference, :name, …]`) | `"#auix-table-sortable-columns-products-index-mobile .auix-items-card-item > div:nth-of-type(2) [name='auix-column-value']"` | `"#auix-table-sortable-columns-products-index-mobile .auix-items-card-item > div:nth-of-type(1) [name='auix-column-value']"` — the name is now the first body row; the reference is the title |
| `test/cases_live/ash_sortable_columns_test.exs` `mobile_name_cells/1` (columns `[:name, :bio, :email]`) | `"#auix-table-ash-sortable-columns-authors-index-mobile .auix-items-card-item > div:nth-of-type(1) [name='auix-column-value']"` | `"#auix-table-ash-sortable-columns-authors-index-mobile [name='auix-card-title']"` — the name is now the title |

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file (`rg -ln "auix-card" test` returns nothing) | module `Aurora.UixWeb.Test.IndexCardFrameTest`, `use UICase, :phoenix_case` and `use WebCase, :aurora_uix_for_test`; `auix_resource_metadata(:product, context: Inventory, schema: Product)`; `auix_create_ui do index_columns(:product, [:reference, :name, :quantity_at_hand]) end`; `delete_all_inventory_data()`, `create_sample_products(3, :test)`, `live(conn, "/index-card-frame-products")` | `test/cases_live/index_card_frame_test.exs` | `"a card has a header, a body and labelled rows"` | with `m = "#auix-table-index-card-frame-products-index-mobile"`: `has_element?(view, "#{m} [name='auix-card'] .auix-items-card-select input[type='checkbox']")`; `has_element?(view, "#{m} [name='auix-card-title']", "item_test-1")`; `has_element?(view, "#{m} [name='auix-card-body'] .auix-items-card-item-fieldset .auix-items-card-item-label", "Name")`; same for `"Quantity At Hand"`; `has_element?(view, "#{m} [name='auix-card-body'] [name='auix-column-value']", "Item test-1")` |
| AC-2, AC-3 | add to the new file | same view | same | `"default row actions sit in the footer bar"` | `has_element?(view, "#{m} [name='auix-card-actions-leading'] a[name='auix-delete-product'][title='Delete'][aria-label='Delete']")`; `has_element?(view, "#{m} [name='auix-card-actions-trailing'] a[name='auix-show-product'][title='Show'][aria-label='Show']")`; same for edit with `Edit`; `refute has_element?(view, "#{m} [name='auix-card-menu']")` |
| AC-7 | add to the new file | `delete_all_inventory_data()` then a second `live/2` | same | `"an empty list shows no card"` | `refute has_element?(view, "#{m} [name='auix-card']")`; `has_element?(view, "[name='auix-items-card'] .auix-items-card-empty", "No items to show")` |
| AC-8 | add to the new file | same view as AC-1; `alias Aurora.Uix.Templates.Basic.Themes.Base` | same | `"cards have no stripes and no italic values"` | `refute has_element?(view, "[class*='auix-items-card-item-content--']")`; `refute Base.rule(:auix_items_card_item_value) =~ "font-style"`; `Base.rule(:auix_items_card_item_content__even) == ""` |
| AC-4, AC-5 | new file | module `Aurora.UixWeb.Test.IndexCardActionsTest`; public function components `archive_action/1` and `copy_action/1` in the module, each `~H` rendering `<a href="#" name="auix-archive-product">A</a>` / `<a href="#" name="auix-copy-product">C</a>`; `index_columns(:product, [:reference, :name], insert_row_action: {:archive, &__MODULE__.archive_action/1, destructive?: true}, add_row_action: {:copy, &__MODULE__.copy_action/1})`; one sample product; `live(conn, "/index-card-actions-products")` | `test/cases_live/index_card_actions_test.exs` | `"extra row actions move into the menu"` | with `m = "#auix-table-index-card-actions-products-index-mobile"`: `has_element?(view, "#{m} [name='auix-card-actions-leading'] a[name='auix-archive-product']")`; `has_element?(view, "#{m} [name='auix-card-actions-trailing'] > .auix-items-card-action a[name='auix-show-product']")`; same for edit; `has_element?(view, "#{m} [name='auix-card-menu-list'] a[name='auix-delete-product']")`; same for copy; `has_element?(view, "#{m} button[name='auix-card-menu-toggle'][aria-label='More actions'][aria-expanded='false']")` |
| AC-9 | add to `test/cases/templates/theme_rules_test.exs`, new `describe "card footer rules"` | none | same | `"use no physical side"` | `Base.rule(:auix_items_card_actions) =~ "justify-content: space-between"`; for both rules `refute rule =~ "left"` and `refute rule =~ "right"` |

##### Modules & components
1. `Aurora.Uix.Templates.Basic.Components` at `lib/aurora_uix/templates/basic/components/components.ex` — modified.
   - `auix_items/1` and `auix_items_card/1`: replace `slot(:action, doc: …)` with
     ```elixir
     slot :action, doc: "the slot for showing user actions" do
       attr(:destructive?, :boolean, doc: "places the action at the leading edge of a card footer")
     end
     ```
   - `auix_items_card/1`, clause head `def auix_items_card(%{host_components: nil} = assigns) do`: replace the row element (`<div :for={row <- @rows} …>` through its closing `</div>`) with:
     ```heex
     <div :for={row <- @rows} id={@row_id && "#{@row_id.(row)}"} class="auix-items-card-item-content" name="auix-card">
       <%= if Enum.at(@col, 0) != nil do %>
         <div class="auix-items-card-item-group">
           <div :if={!@first_column_not_checkbox?} class="auix-items-card-select">
             {render_slot(Enum.at(@col, 0), @row_item.(row))}
           </div>
           <div class="auix-items-card-heading">
             <div :for={col <- title_cols(@col, @first_column_not_checkbox?)} class="auix-items-card-title" name="auix-card-title">
               {render_slot(col, @row_item.(row))}
             </div>
           </div>
         </div>
         <div class="auix-items-card-item" name="auix-card-body">
           <div :for={col <- body_cols(@col, @first_column_not_checkbox?)} class="auix-items-card-item-fieldset">
             <div class="auix-items-card-item-label">{dt(col.label)}</div>
             <div class="auix-items-card-item-value" name="auix-column-value">
               {render_slot(col, @row_item.(row))}
             </div>
           </div>
         </div>
         <.card_actions :if={@action != []} action={@action} row={@row_item.(row)} />
       <% end %>
     </div>
     ```
     The filter cards, the list container (`id={"#{@id}-mobile"}`, its `phx-*` attributes, `class="auix-items-card-list"`) and the empty message stay as they are.
   - New private functions with `@spec`: `title_cols(list(), boolean()) :: list()` — `cols |> get_cols(first_column_not_checkbox?) |> Enum.take(1)`; `body_cols(list(), boolean()) :: list()` — the same with `Enum.drop(1)`.
   - Delete the private `even?/1` (both clauses and its comment); nothing else calls it.
   - New private component `card_actions/1`:
     - attrs: `action` (`:list`, required — the `:action` slot entries), `row` (`:any`, required — the mapped row).
     - It splits the entries: `{bar, overflow} = Enum.split(action, 3)`; `leading` = the `bar` entries with `Map.get(entry, :destructive?, false) == true`; `trailing` = the other `bar` entries. It assigns `leading`, `trailing`, `overflow`.
     - Markup:
       ```heex
       <div class="auix-items-card-actions" name="auix-card-actions">
         <div class="auix-items-card-actions-leading" name="auix-card-actions-leading">
           <div :for={action <- @leading} class="auix-items-card-action">{render_slot(action, @row)}</div>
         </div>
         <div class="auix-items-card-actions-trailing" name="auix-card-actions-trailing">
           <div :for={action <- @trailing} class="auix-items-card-action">{render_slot(action, @row)}</div>
           <div :if={@overflow != []} class="auix-items-card-menu" name="auix-card-menu"
               phx-click={toggle_card_menu()} phx-click-away={hide_card_menu()}>
             <.button type="button" class="auix-button--iconized" name="auix-card-menu-toggle"
                 title={dt("More actions")} aria-label={dt("More actions")} aria-haspopup="menu" aria-expanded="false">
               <.icon name="hero-ellipsis-vertical" />
             </.button>
             <div class="auix-items-card-menu-list" name="auix-card-menu-list" role="menu">
               <div :for={action <- @overflow} class="auix-items-card-action">{render_slot(action, @row)}</div>
             </div>
           </div>
         </div>
       </div>
       ```
     - `toggle_card_menu/0 :: JS.t()`: `JS.toggle(to: {:inner, "[name='auix-card-menu-list']"}, display: "flex") |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: {:inner, "[name='auix-card-menu-toggle']"}) |> JS.focus_first(to: {:inner, "[name='auix-card-menu-list']"})`.
     - `hide_card_menu/0 :: JS.t()`: `JS.hide(to: {:inner, "[name='auix-card-menu-list']"}) |> JS.set_attribute({"aria-expanded", "false"}, to: {:inner, "[name='auix-card-menu-toggle']"})`.
     - The menu is addressed relative to its own element (`{:inner, …}`, `Phoenix.LiveView.JS`), so it needs no DOM id and no LiveComponent, and it works for rows without a `row_id`.
   - `@moduledoc` `## Components`: `auix_items_card/1` — card view for collections: header, body and a footer bar of row actions. Update the `@doc` of `auix_items_card/1` with the frame and the `destructive?` slot attribute.
2. `Aurora.Uix.Templates.Basic.Renderers.IndexRenderer` at `lib/aurora_uix/templates/basic/renderers/index_renderer.ex` — modified. In `index_list/1`, replace the `:action` slot with:
   ```heex
   <:action :let={row_info} :for={action <- @auix.index_row_actions} destructive?={action.destructive?}>
     {action.function_component.(%{auix: Map.put(@auix, :row_info, row_info)})}
   </:action>
   ```
3. `Aurora.Uix.Templates.Basic.Renderers.OneToMany` at `lib/aurora_uix/templates/basic/renderers/fields/one_to_many.ex` — modified. In `child_rows/1`, replace the `:action` slot with:
   ```heex
   <:action :let={entity} :for={action <- @auix.one_to_many_row_actions} destructive?={action.destructive?}>
       {action.function_component.(%{auix: Map.put(@auix, :row_info, {BasicHelpers.primary_key_value(entity, @auix.primary_key), entity})})}
   </:action>
   ```
4. `Aurora.Uix.Templates.Basic.Actions.Index` at `lib/aurora_uix/templates/basic/actions/index.ex` — modified. In both clauses of `show_row_action/1` and of `edit_row_action/1`, and in `remove_row_action/1`:
   - after the `:icon` assign, add `|> Map.put(:title, if(Map.get(assigns, :contents, []) == [], do: <label>))` with `<label>` = `dt("Show")`, `dt("Edit")`, `dt("Delete")`;
   - add `title={@title} aria-label={@title}` to the `<.auix_link>`.
   A link that wraps a column value (`contents` given) gets no label: `nil` omits both attributes.
5. `Aurora.Uix.Templates.Basic.Actions.OneToMany` at `lib/aurora_uix/templates/basic/actions/one_to_many.ex` — modified. In the rendering clauses of `show_child_action/1`, `edit_child_action/1` and `delete_child_action/1`, add `title={dt("Show")} aria-label={dt("Show")}` (`dt("Edit")`, `dt("Delete")`) to the `<.auix_link>` / `<.link>`.
6. Theme: `lib/aurora_uix/templates/basic/themes/base_variables.ex` — after the line `--auix-checkbox-group-max-height: 12rem;` add:
   ```css
   --auix-touch-target-size: 2.75rem;
   --auix-items-card-label-width: 7.25rem;
   ```
7. Theme: `lib/aurora_uix/templates/basic/themes/base.ex` — modified.
   - Delete the clauses `rule(:auix_items_card_item_content__even, …)` and `rule(:auix_items_card_item_content__odd, …)`.
   - Replace the CSS of these existing clauses:
     ```css
     /* rule(:auix_items_card_item_content, …) */
     .auix-items-card-item-content {
       display: flex;
       flex-direction: column;
       border-width: var(--auix-border-width-default);
       border-style: var(--auix-border-style-default);
       border-color: var(--auix-color-border-primary);
       border-radius: var(--auix-border-radius-default);
       background-color: var(--auix-color-bg-default);
       color: var(--auix-color-items-card-item-content-text);
     }

     /* rule(:auix_items_card_item_group, …) */
     .auix-items-card-item-group {
       display: flex;
       flex-direction: row;
       align-items: flex-start;
       gap: var(--auix-gap-large);
       padding: var(--auix-padding-default);
     }

     /* rule(:auix_items_card_item, …) */
     .auix-items-card-item {
       display: flex;
       flex-direction: column;
       flex: 1;
       gap: var(--auix-gap-default);
       padding: 0 var(--auix-padding-default) var(--auix-padding-default);
     }

     /* rule(:auix_items_card_item_fieldset, …) */
     .auix-items-card-item-fieldset {
       display: grid;
       grid-template-columns: var(--auix-items-card-label-width) minmax(0, 1fr);
       column-gap: var(--auix-gap-large);
       align-items: baseline;
     }

     /* rule(:auix_items_card_item_label, …) */
     .auix-items-card-item-label {
       font-size: var(--auix-font-size-small);
       font-weight: var(--auix-font-weight-bold);
       color: var(--auix-color-text-tertiary);
     }

     /* rule(:auix_items_card_item_value, …) */
     .auix-items-card-item-value {
       min-width: 0;
       font-size: var(--auix-font-size-caption);
       overflow-wrap: anywhere;
     }

     /* rule(:auix_items_card_actions, …) */
     .auix-items-card-actions {
       display: flex;
       flex-direction: row;
       justify-content: space-between;
       align-items: center;
       border-top-width: var(--auix-border-width-default);
       border-top-style: var(--auix-border-style-default);
       border-top-color: var(--auix-color-border-primary);
       padding-block: var(--auix-padding-small);
       padding-inline: var(--auix-padding-minimal);
     }
     ```
   - Add these clauses after `rule(:auix_items_card_actions, …)`, one `rule/1` clause per comment:
     ```css
     /* rule(:auix_items_card_list, …) */
     .auix-items-card-list {
       display: flex;
       flex-direction: column;
       gap: var(--auix-gap-large);
     }

     /* rule(:auix_items_card_select, …) */
     .auix-items-card-select {
       flex-shrink: 0;
     }

     /* rule(:auix_items_card_heading, …) */
     .auix-items-card-heading {
       display: flex;
       flex-direction: column;
       gap: var(--auix-gap-minimal);
       min-width: 0;
     }

     /* rule(:auix_items_card_title, …) */
     .auix-items-card-title {
       font-size: var(--auix-font-size-subtitle);
       font-weight: var(--auix-font-weight-bold);
     }

     /* rule(:auix_items_card_subtitle, …) */
     .auix-items-card-subtitle {
       font-size: var(--auix-font-size-caption);
       color: var(--auix-color-text-tertiary);
     }

     /* rule(:auix_items_card_actions_leading, …) */
     .auix-items-card-actions-leading {
       display: flex;
       flex-direction: row;
       align-items: center;
       gap: var(--auix-gap-default);
     }

     /* rule(:auix_items_card_actions_trailing, …) */
     .auix-items-card-actions-trailing {
       display: flex;
       flex-direction: row;
       align-items: center;
       gap: var(--auix-gap-default);
     }

     /* rule(:auix_items_card_action, …) */
     .auix-items-card-action,
     .auix-items-card-action > a,
     .auix-items-card-action > button {
       display: inline-flex;
       align-items: center;
       justify-content: center;
       min-width: var(--auix-touch-target-size);
       min-height: var(--auix-touch-target-size);
     }

     /* rule(:auix_items_card_menu, …) */
     .auix-items-card-menu {
       position: relative;
       display: inline-flex;
     }

     .auix-items-card-menu > button {
       min-width: var(--auix-touch-target-size);
       min-height: var(--auix-touch-target-size);
       justify-content: center;
     }

     /* rule(:auix_items_card_menu_list, …) */
     .auix-items-card-menu-list {
       display: none;
       position: absolute;
       inset-inline-end: 0;
       bottom: 100%;
       z-index: 10;
       flex-direction: column;
       border-width: var(--auix-border-width-default);
       border-style: var(--auix-border-style-default);
       border-color: var(--auix-color-border-primary);
       border-radius: var(--auix-border-radius-default);
       background-color: var(--auix-color-bg-default);
       box-shadow: var(--auix-shadow-md);
     }
     ```
     `auix-items-card-subtitle` has no markup until UI-4; its rule ships here with the frame.
   - Regenerate: `mix auix.gen.stylesheet`, then `mix auix.gen.tailwind_classes` (the menu toggle adds `hero-ellipsis-vertical` to `priv/static/classes.js`; commit it).
8. `dt/1` strings: `"More actions"`, `"Show"`, `"Edit"`, `"Delete"`.
9. No inline `class=` beyond `auix-*` theme classes; the menu is JS commands only, no LiveComponent, no hook, no `<script>`.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files, plus `test/cases_live/sortable_columns_test.exs` and
   `test/cases_live/ash_sortable_columns_test.exs`)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-3:end -->
<!-- section:UI-4:start -->
### UI-4 — UI · renderer + theme: declared card content and `show_on: :all`
Depends on: UI-1, UI-3

#### Documentation references
- `guides/core/layouts.md § Index Cards` (DOC-1)
- `guides/customization/styling.md § Class reference` (DOC-1)
- Mockups: https://claude.ai/artifact/DGKCKF4xHaomFLoMnhJEdS, board D

#### Implementation details

Layout types: `:index`. Card fields render with `layout_type: :index` through the existing container renderers of `Aurora.Uix.Templates.Basic.Renderer` (`%Node.Inline{}`, `%Node.Stacked{}`, `%Node.Group{}` clauses of `render/1`). No new `layout_type`. The one-to-many list keeps the derived card of UI-3.

Load guarantee: a card field is an index column (UI-1 `card_columns/2`), so its value is on the row entity the index list already loads; no query changes.

##### Acceptance criteria
- [ ] AC-1: Given `index_columns :product, [:reference, :name, :description, :quantity_at_hand] do card title: :name, subtitle: :reference do group "Stock" do field :quantity_at_hand, label: "On hand" end end end`, each card shows the name in `[name='auix-card-title']` inside the default show link, the reference in `[name='auix-card-subtitle']`, and a `.auix-group-container` titled `Stock` in `[name='auix-card-body']` holding one row labelled `On hand`
- [ ] AC-2: In that layout the table header of the column still reads `Quantity At Hand`, and the card has no row for `Description`
- [ ] AC-3: Given `card title: &card_title/1, subtitle: "Product"`, the title shows what the function returns for the row's entity and the subtitle shows `Product`
- [ ] AC-4: Given `show_on: :all`, the page has no `[name='auix-items-table']`, the card container has the class `auix-items-cards`, and the sort control has the class `auix-index-sort-action--always`
- [ ] AC-5: Given `show_on: :all` and the omitted column `:description`, the sort select offers `option[value='description']`
- [ ] AC-6: Given the default `show_on`, the page has `[name='auix-items-table']`, the card container has the class `auix-items-mobile`, and the sort control lacks `auix-index-sort-action--always`
- [ ] AC-7: Given a card that places `:product_location`, a column the index list drops as an association, the card body has no row for it and the page renders
- [ ] AC-8: The card grid is responsive: `Base.rule(:auix_items_cards)` contains `repeat(auto-fill, minmax(var(--auix-items-card-min-width), 1fr))`
- [ ] AC-9: An `inline` inside a card places its fields side by side below the `md` breakpoint (visual — no red test; verified by `iex -S mix run test/start_test_server.exs`, opening `/index-card-grid-products` at a 390px viewport)

##### Test ports
- Route `"/index-card-content-products"` registered in `test/support/app_web/routes.ex` via `RoutesHelper.register_crud(IndexCardContentTest.Product, "index-card-content-products")` · layout type `:index` · observable: `has_element?/2` under `#auix-table-index-card-content-products-index-mobile`
- Route `"/index-card-grid-products"` registered via `RoutesHelper.register_crud(IndexCardGridTest.Product, "index-card-grid-products")` · layout type `:index` · observable: `has_element?/2` on the page and under `#auix-table-index-card-grid-products-index-mobile`

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1, AC-2, AC-6 | new file (`rg -ln "auix-card-subtitle" test` returns nothing) | module `Aurora.UixWeb.Test.IndexCardContentTest`; `auix_resource_metadata(:product, context: Inventory, schema: Product)`; the AC-1 layout inside `auix_create_ui do … end`; `delete_all_inventory_data()`, `create_sample_products(3, :test)`, `live(conn, "/index-card-content-products")` | `test/cases_live/index_card_content_test.exs` | `"a declared card renders its title, subtitle and body"` | with `m = "#auix-table-index-card-content-products-index-mobile"`: `has_element?(view, "#{m} [name='auix-card-title'] a[name='auix-show-product']", "Item test-1")`; `has_element?(view, "#{m} [name='auix-card-subtitle']", "item_test-1")`; `has_element?(view, "#{m} [name='auix-card-body'] .auix-group-container .auix-group-title", "Stock")`; `has_element?(view, "#{m} [name='auix-card-body'] .auix-items-card-item-label", "On hand")`; `refute has_element?(view, "#{m} .auix-items-card-item-label", "Description")`; `has_element?(view, "[name='auix-items-table'] th[name='auix-column-label']", "Quantity At Hand")`; `has_element?(view, ".auix-items-mobile [name='auix-items-card']")`; `refute has_element?(view, ".auix-index-sort-action--always")` |
| AC-3, AC-4, AC-5, AC-7 | new file | module `Aurora.UixWeb.Test.IndexCardGridTest`; public `card_title(assigns)` returning `"#" <> assigns.entity.reference`; `index_columns :product, [:reference, :name, :description, :product_location] do card title: &__MODULE__.card_title/1, subtitle: "Product", show_on: :all do inline [:name, :product_location] end end`; three sample products; `live(conn, "/index-card-grid-products")` | `test/cases_live/index_card_grid_test.exs` | `"show_on: :all shows the cards alone"` | with `m = "#auix-table-index-card-grid-products-index-mobile"`: `has_element?(view, "#{m} [name='auix-card-title']", "#item_test-1")`; `has_element?(view, "#{m} [name='auix-card-subtitle']", "Product")`; `refute has_element?(view, "[name='auix-items-table']")`; `has_element?(view, ".auix-items-cards [name='auix-items-card']")`; `has_element?(view, ".auix-index-sort-action.auix-index-sort-action--always")`; `has_element?(view, "#auix-sort-form-product option[value='description']")`; `has_element?(view, "#{m} [name='auix-card-body'] .auix-items-card-item-label", "Name")`; `refute has_element?(view, "#{m} [name='auix-card-body'] .auix-items-card-item-label", "Product Location")` |
| AC-8 | add to `test/cases/templates/theme_rules_test.exs`, `describe "card footer rules"` renamed `describe "card rules"` | none | same | `"lay the card grid out responsively"` | `Base.rule(:auix_items_cards) =~ "repeat(auto-fill, minmax(var(--auix-items-card-min-width), 1fr))"` |

##### Modules & components
1. `Aurora.Uix.Templates.Basic.Components` at `lib/aurora_uix/templates/basic/components/components.ex` — modified.
   - `auix_items/1` and `auix_items_card/1`: add
     ```elixir
     slot(:card_title, doc: "the card title; without it the first column is the title")
     slot(:card_subtitle, doc: "the card subtitle")
     slot(:card_body, doc: "the card body; without it the other columns are the body")
     ```
   - `auix_items/1`: add `attr(:show_on, :atom, default: :mobile, values: [:mobile, :all], doc: "`:all` renders the cards alone, at every breakpoint")`, and replace the template with:
     ```heex
     <div :if={@show_on == :mobile} class="auix-items-desktop">
       {auix_items_table(assign_rows(assigns, @streams, @auix.source_key))}
     </div>

     <div class={if @show_on == :all, do: "auix-items-cards", else: "auix-items-mobile"}>
       {assigns
         |> assign_rows(@streams, @auix.source_key, "mobile")
         |> Map.put(:first_column_not_checkbox?, @first_column_not_checkbox?)
         |> auix_items_card}
     </div>
     ```
   - `auix_items_card/1`, in the row element UI-3 wrote:
     - replace the content of `.auix-items-card-heading` with:
       ```heex
       <%= if @card_title != [] do %>
         <div class="auix-items-card-title" name="auix-card-title">{render_slot(@card_title, @row_item.(row))}</div>
       <% else %>
         <div :for={col <- title_cols(@col, @first_column_not_checkbox?)} class="auix-items-card-title" name="auix-card-title">
           {render_slot(col, @row_item.(row))}
         </div>
       <% end %>
       <div :if={@card_subtitle != []} class="auix-items-card-subtitle" name="auix-card-subtitle">
         {render_slot(@card_subtitle, @row_item.(row))}
       </div>
       ```
     - replace the content of `[name='auix-card-body']` with: `{render_slot(@card_body, @row_item.(row))}` when `@card_body != []`, else the `:for={col <- body_cols(…)}` rows of UI-3, unchanged.
2. `Aurora.Uix.Templates.Basic.Renderers.IndexRenderer` at `lib/aurora_uix/templates/basic/renderers/index_renderer.ex` — modified. Add `alias Aurora.Uix.Layout.Node` and `alias Aurora.Uix.Templates.Basic.Renderer` (alphabetical).
   - `index_list/1`: after the `default_show_function` assign, add `|> Map.put(:card, Map.get(assigns.auix.layout_tree, :card))`.
   - `<.auix_items …>`: add `show_on={card_show_on(@card)}`, and these slots after the `:col` slot:
     ```heex
     <:card_title :if={@card} :let={{_id, entity} = row_info}>
       <%= if @default_show_function do %>
         {@default_show_function.(%{auix: Map.put(@auix, :row_info, row_info),
           contents: [%{inner_block: fn _, _ ->
             assigns = %{text: @card.title, entity: entity, auix: @auix}
             ~H"<.card_text text={@text} entity={@entity} auix={@auix}/>" end}]}
         )}
       <% else %>
         <.card_text text={@card.title} entity={entity} auix={@auix}/>
       <% end %>
     </:card_title>

     <:card_subtitle :if={@card && @card.subtitle} :let={{_id, entity}}>
       <.card_text text={@card.subtitle} entity={entity} auix={@auix}/>
     </:card_subtitle>

     <:card_body :if={@card} :let={{_id, entity}}>
       <Renderer.render_inner_elements auix={card_auix(@auix, @card, entity)} />
     </:card_body>
     ```
     The title link is the call shape the `:col` slot of `index_list/1` already uses.
   - New private functions with `@spec`:
     - `card_show_on(Node.Card.t() | nil) :: :mobile | :all` — `:mobile` for `nil`, else `card.show_on`.
     - `card_text(map()) :: Rendered.t()`, four clauses in this order:
       1. `%{text: %Node.Field{field: field}, auix: auix}` — when `field.key` is the key of an entry of `auix.index_fields`, render `<.field_value entity={@entity} field={@text.field} auix={@auix}/>`; otherwise render `~H""`.
       2. `%{text: text}` when `is_function(text, 1)` — render `{@text.(%{auix: Map.put(@auix, :entity, @entity), entity: @entity})}`.
       3. `%{text: text}` when `is_binary(text)` — render `{dt(@text)}`.
       4. any other assigns — `~H""`.
     - `card_auix(map(), Node.Card.t(), map()) :: map()` — `Map.merge(auix, %{layout_tree: card, layout_type: :index, entity: entity, fields_to_reject: card_dropped_keys(auix, card)})`.
     - `card_dropped_keys(map(), Node.Card.t()) :: [atom()]` — `Enum.map(Node.fields(card), & &1.key) -- Enum.map(auix.index_fields, & &1.key)`. `Aurora.Uix.Templates.Basic.Renderer` `inner_path/1` (clause with `fields_to_reject`) drops those field nodes at every depth.
   - `@moduledoc` `## Key Features`: add "Card view: the layout's `card`, else a card derived from the columns; `show_on: :all` renders the cards alone".
3. `Aurora.Uix.Templates.Basic.Renderers.FieldRenderer` at `lib/aurora_uix/templates/basic/renderers/field_renderer.ex` — modified. Add `use Aurora.Uix.GettextResolver`. Add a `do_render/1` clause between the `omitted: true` clause and the generic clause:
   ```elixir
   # A field of an index card: its label and its index value.
   defp do_render(%{auix: %{layout_type: :index} = auix, field: field} = assigns) do
     renderer = Renderers.resolve(field, :index, BasicHelpers.html_type_renderers(auix, :index))

     assigns =
       assigns
       |> assign(:entity, auix.entity)
       |> assign(:renderer, renderer)

     ~H"""
     <div class="auix-items-card-item-fieldset">
       <div class="auix-items-card-item-label">{dt(@field.label)}</div>
       <div class="auix-items-card-item-value" name="auix-column-value">{@renderer.(assigns)}</div>
     </div>
     """
   end
   ```
   The index renderers read `@entity`, `@field` and `@auix`, as `IndexRenderer` `field_value/1` gives them. Update the `@moduledoc`: it renders show, form and index-card fields.
4. `Aurora.Uix.Templates.Basic.Actions.Index` at `lib/aurora_uix/templates/basic/actions/index.ex` — modified. In `sort_header_action/1`, clause head `def sort_header_action(%{auix: %{layout_options: %{sort_disabled?: false}} = auix} = assigns) do`:
   - add `|> Map.put(:always?, match?(%{card: %{show_on: :all}}, auix.layout_tree))` to the assigns pipeline;
   - set the container class to `class={["auix-index-sort-action", @always? && "auix-index-sort-action--always"]}`.
   Update the `@doc`: with `show_on: :all` the control shows at every breakpoint.
5. Theme: `lib/aurora_uix/templates/basic/themes/base_variables.ex` — after the line `--auix-items-card-label-width: 7.25rem;` add `--auix-items-card-min-width: 17.5rem;`.
6. Theme: `lib/aurora_uix/templates/basic/themes/base.ex` — modified.
   - Append to the CSS of `rule(:auix_items_card_item, …)`:
     ```css
     .auix-items-card-item .auix-inline-container {
       flex-direction: row;
       flex-wrap: wrap;
       column-gap: var(--auix-gap-large);
     }
     ```
   - Add after `rule(:auix_items_mobile, …)`:
     ```css
     /* rule(:auix_items_cards, …) */
     .auix-items-cards {
       margin-top: 0;
     }

     .auix-items-cards .auix-items-card-list {
       display: grid;
       grid-template-columns: repeat(auto-fill, minmax(var(--auix-items-card-min-width), 1fr));
       gap: var(--auix-gap-large);
     }
     ```
   - Add after `rule(:auix_index_sort_action, …)`, with `#{breakpoint(:md)}` as that rule writes it:
     ```css
     /* rule(:auix_index_sort_action__always, …) */
     @media (min-width: #{breakpoint(:md)}) {
       .auix-index-sort-action.auix-index-sort-action--always {
         display: flex;
       }
     }
     ```
   - Regenerate: `mix auix.gen.stylesheet`, then `mix auix.gen.tailwind_classes`.
7. `dt/1` strings: none new; a text title goes through `dt/1` at render time.
8. The filter cards live inside `auix_items_card/1` and the table filter row inside `auix_items_table/1`, so with `show_on: :all` the filter cards show at every breakpoint with no further change.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-4:end -->

---

### Out of Scope
- Tapping the whole card to open the show view.
- `sections` inside a card.
- Card-only fields, and separate sort and filter field sets for the card.
- A `:desktop`-only card (a table on mobile).
- A child resource's declared card in one-to-many and embeds-many mobile views: those lists keep the derived card.
- Parser sections: card fields are a subset of the index columns, so data loading is unchanged on the Ash and the Ecto backend alike.
- Labels inside the ⋮ menu: an action renders there as its function component renders it.
- Compile-time validation of the options of a row-action tuple: an unknown option raises `ArgumentError` when the index mounts.
<!-- enriched-spec:end -->
