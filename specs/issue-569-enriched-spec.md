<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** high

### Overview
This issue replaces the 710 tests and 8 browser features with fewer than 100 scenario tests over one mirrored fixture: one set of tables in the PostgreSQL schema `mirror`, an Ecto schema and an Ash resource over each table, and views modules in `test/support`. Every scenario runs on `:ash` and on `:ctx`, except the backend-specific ones the issue names. The issue delivers neither a feature nor a fix, so it has no `DOC-1` and no CHANGELOG entry; `AGENTS.md` and the `.claude/skills` files are outside the documentation set and are edited by `UI-3`.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| UI-1 | UI | test support · mirrored fixture: migration, Ecto schemas and context, Ash resources and domain, seeds, fixture test | none | federico/569-ui-1-mirror-fixture | test: add the mirrored Ecto and Ash test fixture (#569 · UI-1) |
| UI-2 | UI | test support · scenario harness, views variants, mirror routes, default-layout scenario, guide pages test | UI-1 | federico/569-ui-2-scenario-harness | test: add the scenario harness and the mirrored views (#569 · UI-2) |
| UI-3 | UI | rules · `AGENTS.md` § Testing and the pipeline skills state the scenario rule | UI-2 | federico/569-ui-3-scenario-rule | chore: state the scenario test rule (#569 · UI-3) |
| UI-4 | UI | tests · parsers and metadata | UI-3 | federico/569-ui-4-parsers-metadata | test: cover parsers and metadata with scenarios (#569 · UI-4) |
| UI-5 | UI | tests · layout and generation; guide capture views | UI-4 | federico/569-ui-5-layout-generation | test: cover layout and generation with scenarios (#569 · UI-5) |
| UI-6 | UI | tests · index | UI-5 | federico/569-ui-6-index | test: cover the index with scenarios (#569 · UI-6) |
| UI-7 | UI | tests · form | UI-6 | federico/569-ui-7-form | test: cover the form with scenarios (#569 · UI-7) |
| UI-8 | UI | tests · show | UI-7 | federico/569-ui-8-show | test: cover the show view with scenarios (#569 · UI-8) |
| UI-9 | UI | tests · associations and embeds | UI-8 | federico/569-ui-9-associations-embeds | test: cover associations and embeds with scenarios (#569 · UI-9) |
| UI-10 | UI | tests · navigation and extension | UI-9 | federico/569-ui-10-navigation-extension | test: cover navigation and extension with scenarios (#569 · UI-10) |
| UI-11 | UI | tests · backend-specific | UI-10 | federico/569-ui-11-backend-specific | test: consolidate the backend-specific tests (#569 · UI-11) |
| UI-12 | UI | tests · theme and assets | UI-11 | federico/569-ui-12-theme-assets | test: cover theme and assets with five tests (#569 · UI-12) |
| UI-13 | UI | tests · browser; retire unused support; final count and coverage | UI-12 | federico/569-ui-13-browser-closing | test: cover the browser behaviour and retire unused support (#569 · UI-13) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:UI-1:start -->
### UI-1 — UI · test support · mirrored fixture
Depends on: none

#### Documentation references
- `AGENTS.md` § Key Patterns (the library is transport-only for writes), § Testing
- `guides/core/ash_integration.md`, `guides/core/resource_metadata.md` (no edit)

#### Implementation details

This section adds test support and one test. It changes no file under `lib/`. The test passes on its first run. A step that fails as written is a spec defect: report it; never change library code.

Facts this section builds on, proven on `main` at 25a9ae6 with a rolled-back probe:
- An Ecto schema with `@schema_prefix "mirror"` and an Ash resource with `postgres do schema "mirror"; migrate? false end` read and write the same rows: scalars, an atom enum over a `text` column, an atom list over `text[]`, an embeds-one over `jsonb`, an embeds-many over `jsonb[]`, many-to-one, one-to-many, one-to-one and many-to-many.
- The Ecto embeds carry `primary_key: false`, so both backends write the same JSON keys.
- `Aurora.Uix.Parsers.Common.option_value/4` (`lib/aurora_uix/parsers/common.ex`, clause `:source`) takes the resource source from `schema.__schema__(:source)`. A table `products` in the schema `mirror` keeps the source `products`, so DOM names, stream names and related routes equal the ones of the inventory guide.

New names in this section (search `rg -n "MirrorCtx|MirrorAsh|Mirror\.Seeds|mirror_fixture" lib test mix.exs` returns nothing): every module, file and function below.

##### Acceptance criteria
- [x] AC-1: after `MIX_ENV=test mix ecto.migrate`, the schema `mirror` holds the six tables of step 1 (mechanical — no red test; verified by `psql` on the test database: `\dt mirror.*` lists `product_barcodes`, `product_locations`, `product_suppliers`, `product_transactions`, `products`, `suppliers`)
- [x] AC-2: Given a product written through `Aurora.Uix.Test.MirrorCtx` with a packaging, two contacts, a location, a barcode, two transactions and two suppliers, when `Aurora.Uix.Test.MirrorAsh.Product` reads it with those relationships loaded, then every scalar, both embeds and every related record equal the written values
- [x] AC-3: Given a product created through the `:create` action of `Aurora.Uix.Test.MirrorAsh.Product` with the same data, when `Aurora.Uix.Test.MirrorCtx.Product` reads it with preloads, then the values are equal; an update through each backend of the row the other backend wrote is read back by both
- [x] AC-4: Given the two parsed resource maps, `Aurora.Uix.Integration.FieldsParser` output for `MirrorCtx.Product` and for `MirrorAsh.Product`, then for every key both define, `type` and `html_type` are equal; the keys only Ash defines are exactly `[:summary, :suppliers_join_assoc]`
- [x] AC-5: Given a blank `name`, the Ecto changeset is invalid and the Ash `:create` action returns `{:error, %Ash.Error.Invalid{}}`; neither writes a row
- [x] AC-6: no file under `lib/` is modified (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- lib` returning nothing)
- [x] AC-7: line coverage holds (mechanical — no red test; verified by `.claude/scripts/suite.sh --cover`, then `grep -E '\| Total' /tmp/suite-<branch>.log` showing at least 81.62% and the summary line showing `0 failures`; the script exits 3 because the project threshold is 90%, as on `main`)

##### Test ports
- `Aurora.Uix.Test.MirrorCtx` (new) · Ecto context · out: `{:ok, struct}` / `{:error, Ecto.Changeset.t()}`
- `Aurora.Uix.Test.MirrorAsh` (new) · Ash domain · `Ash.create/2`, `Ash.update/2`, `Ash.read!/2`
- `Aurora.Uix.Test.Mirror.Seeds` (new) · seed functions of step 5
- `auix_resource_metadata/2`, read back with the generated `auix_resource/1` (`lib/aurora_uix/layout/resource_metadata.ex`, `resource_functions/1`) · out: `%Aurora.Uix.Resource{fields: %{key => %Aurora.Uix.Field{}}}`

##### Red tests
The row passes on first run (characterization of the fixture).

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-2, AC-3, AC-4, AC-5 | new file (`ls test/cases_live \| grep -i mirror` returns nothing) | `use Aurora.UixWeb.Test.UICase, :phoenix_case`; `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`; in the module body `auix_resource_metadata(:ctx_product, context: Aurora.Uix.Test.MirrorCtx, schema: Aurora.Uix.Test.MirrorCtx.Product)` and `auix_resource_metadata(:ash_product, ash_resource: Aurora.Uix.Test.MirrorAsh.Product)`, no `auix_create_ui`; data from `Mirror.Seeds` | `test/cases_live/mirror_fixture_test.exs` | `"the mirrored fixture gives both backends the same fields and the same rows"` | call every function of step 5 once; read through the other backend and compare field by field with `==` (decimals with `Decimal.equal?/2`); `ctx = auix_resource(:ctx_product).fields` and `ash = auix_resource(:ash_product).fields` (maps of `%Aurora.Uix.Field{}` by key); compare `type` and `html_type` per shared key; `assert Enum.sort(Map.keys(ash) -- Map.keys(ctx)) == [:summary, :suppliers_join_assoc]`; `assert Map.keys(ctx) -- Map.keys(ash) == []`; `assert {:error, %Ash.Error.Invalid{}} = Ash.create(MirrorAsh.Product, %{name: ""})`; `refute MirrorCtx.Product.changeset(%MirrorCtx.Product{}, %{name: ""}).valid?` |

The module name is `Aurora.UixWeb.Test.MirrorFixtureTest`. `mix.exs` `test_module_name/2` reads every `test/cases_live/*.exs` file and requires one line that starts with `defmodule ` and ends with `Test do`.

##### Modules & components

1. **Migration.** Run `mix ecto.gen.migration create_mirror_fixture`. Write `up/0` and `down/0`:
   - `up/0`: `execute("CREATE SCHEMA IF NOT EXISTS mirror")`, then one `create table(<name>, prefix: "mirror", primary_key: false)` per table below. Every table except `product_suppliers` has `add(:id, :uuid, primary_key: true)` and `timestamps(type: :utc_datetime_usec)`.
   - `down/0`: `execute("DROP SCHEMA mirror CASCADE")`.

   | Table | Columns |
   |---|---|
   | `product_locations` | `reference :string, size: 30` · `name :string` · `type :string, size: 20` |
   | `products` | `reference :string, size: 30` · `name :string` · `description :text` · `status :string, size: 20, default: "in_stock"` · `grade :string` · `labels {:array, :string}` · `quantity_at_hand`, `quantity_initial`, `quantity_entries`, `quantity_exits`, `cost`, `weight`, `length`, `width`, `height` each `:numeric, precision: 14, scale: 6` · `msrp`, `rrp`, `list_price`, `discounted_price` each `:numeric, precision: 12, scale: 2` · `units_per_box :integer` · `margin :float` · `released_on :date` · `opens_at :time` · `audited_at :naive_datetime` · `discontinued_at :utc_datetime` · `image :binary` · `thumbnail :binary` · `deleted :boolean, default: false` · `inactive :boolean, default: false` · `packaging :map` · `contacts {:array, :map}` · `product_location_id references("product_locations", type: :uuid, prefix: "mirror", on_delete: :nilify_all)` |
   | `product_transactions` | `type :string, size: 20` · `quantity :numeric, precision: 14, scale: 6` · `cost :numeric, precision: 14, scale: 6` · `product_id references("products", type: :uuid, prefix: "mirror", on_delete: :delete_all)` |
   | `product_barcodes` | `code :string, size: 20` · `symbology :string, size: 20, default: "EAN-13"` · `registered_at :date` · `product_id references("products", type: :uuid, prefix: "mirror", on_delete: :delete_all)` |
   | `suppliers` | `name :string, size: 60` · `country :string, size: 40` |
   | `product_suppliers` | `product_id references("products", type: :uuid, prefix: "mirror", on_delete: :delete_all), null: false, primary_key: true` · `supplier_id references("suppliers", type: :uuid, prefix: "mirror", on_delete: :delete_all), null: false, primary_key: true` |

   Indexes, each with `prefix: "mirror"`: unique on `products [:reference]`; on `products [:product_location_id]`; on `product_transactions [:product_id]`; unique on `product_barcodes [:code]`; unique on `product_barcodes [:product_id]`; on `product_suppliers [:supplier_id]`.

2. **Ecto schemas**, one file each under `test/support/mirror/ctx/`. Every schema module has `@moduledoc false`, `use Ecto.Schema`, `import Ecto.Changeset`, `@primary_key {:id, :binary_id, autogenerate: true}`, `@foreign_key_type :binary_id`, `@schema_prefix "mirror"`, `@timestamps_opts [type: :utc_datetime_usec]` and a `@type t`.

   | Module · file | Copy from | Changes to the copy |
   |---|---|---|
   | `Aurora.Uix.Test.MirrorCtx.ProductLocation` · `product_location.ex` | `lib/aurora_uix/guides/inventory/product_location.ex` | module names |
   | `Aurora.Uix.Test.MirrorCtx.ProductTransaction` · `product_transaction.ex` | `lib/aurora_uix/guides/inventory/product_transaction.ex` | module names |
   | `Aurora.Uix.Test.MirrorCtx.ProductBarcode` · `product_barcode.ex` | `lib/aurora_uix/guides/inventory/product_barcode.ex` | module names |
   | `Aurora.Uix.Test.MirrorCtx.Supplier` · `supplier.ex` | `lib/aurora_uix/guides/inventory/supplier.ex` | module names; `many_to_many(:products, Product, join_through: ProductSupplier)` |
   | `Aurora.Uix.Test.MirrorCtx.ProductSupplier` · `product_supplier.ex` | new | `@primary_key false`; `schema "product_suppliers"` with `belongs_to(:product, Product, primary_key: true)` and `belongs_to(:supplier, Supplier, primary_key: true)`; no timestamps; no changeset |
   | `Aurora.Uix.Test.MirrorCtx.Product` · `product.ex` | `lib/aurora_uix/guides/inventory/product.ex` | below |

   Changes to the `Product` copy:
   - `many_to_many(:suppliers, Supplier, join_through: ProductSupplier, on_replace: :delete)`.
   - Added fields: `field(:grade, Ecto.Enum, values: [:standard, :premium, :clearance])`, `field(:units_per_box, :integer)`, `field(:margin, :float)`, `field(:released_on, :date)`, `field(:opens_at, :time)`, `field(:audited_at, :naive_datetime)`, `field(:discontinued_at, :utc_datetime)`.
   - Added embeds:
     ```elixir
     embeds_one :packaging, Packaging, primary_key: false, on_replace: :update do
       field(:material, Ecto.Enum, values: [:box, :bag, :crate])
       field(:fragile, :boolean)
       field(:notes, :string)
     end

     embeds_many :contacts, Contact, primary_key: false, on_replace: :delete do
       field(:email, :string)
       field(:name, :string)
     end
     ```
   - `changeset/2`: add the seven new fields to the `cast/3` list; append `|> cast_embed(:packaging, with: &packaging_changeset/2)` and `|> cast_embed(:contacts, with: &contact_changeset/2)`.
   - `packaging_changeset/2`: `cast(attrs, [:material, :fragile, :notes])`.
   - `contact_changeset/2`: the body of `email_changeset/2` in `lib/aurora_uix/guides/accounts/user.ex`.

3. **Ecto context** `Aurora.Uix.Test.MirrorCtx` at `test/support/mirror/ctx.ex`: `@moduledoc false`, `use Aurora.Ctx`, `alias Aurora.Uix.Repo`, then `ctx_register_schema(<Schema>, Repo)` for `Product`, `ProductTransaction`, `ProductLocation`, `ProductBarcode`, `Supplier`, as `lib/aurora_uix/guides/inventory.ex` ends. No hand-written function.

4. **Ash resources**, one file each under `test/support/mirror/ash/`, and the domain. Every table resource has `@moduledoc false`, `use Ash.Resource, data_layer: AshPostgres.DataLayer, domain: Aurora.Uix.Test.MirrorAsh`, and
   ```elixir
   postgres do
     table "<table>"
     schema "mirror"
     repo Aurora.Uix.Repo
     migrate? false
   end
   ```
   Every attribute carries `public?: true`. Every table resource except `ProductSupplier` has `uuid_primary_key :id`, `create_timestamp :inserted_at`, `update_timestamp :updated_at`.

   | Module · file | Attributes | Relationships | Actions and the rest |
   |---|---|---|---|
   | `Aurora.Uix.Test.MirrorAsh.Packaging` · `packaging.ex` (`data_layer: :embedded`, no `domain`, no `postgres`) | `material :atom, constraints: [one_of: [:box, :bag, :crate]]` · `fragile :boolean` · `notes :string` | — | — |
   | `Aurora.Uix.Test.MirrorAsh.Contact` · `contact.ex` (`data_layer: :embedded`) | `email :string, allow_nil?: false` · `name :string` | — | `validations do validate match(:email, "^[^\\s]+@[^\\s]+$"), message: "must be a valid email address" end` (the pattern is a string, as the `match/2` example in `deps/ash/lib/ash/resource/validation/builtins.ex` writes it) |
   | `…MirrorAsh.ProductLocation` · `product_location.ex` | `reference :string, constraints: [max_length: 30]` · `name :string, allow_nil?: false` · `type :string, allow_nil?: false, constraints: [max_length: 20]` | `has_many :products, Product` | `default_accept [:reference, :name, :type]`; `defaults [:destroy, :create, :update]`; `read :read do primary? true; pagination required?: false, offset?: true end`; `read :read_all`; aggregates: `count :products_count, :products`, `first :latest_product_name, :products, :name do sort inserted_at: :desc end`, `list :product_names, :products, :name`, `max :last_discontinued_at, :products, :discontinued_at` |
   | `…MirrorAsh.ProductTransaction` · `product_transaction.ex` | `type :string, allow_nil?: false, constraints: [max_length: 20]` · `quantity :decimal, allow_nil?: false, constraints: [min: 0]` · `cost :decimal, allow_nil?: false, constraints: [min: 0]` | `belongs_to :product, Product, allow_nil?: false, public?: true` | `default_accept [:type, :quantity, :cost, :product_id]`; `defaults [:destroy, :create, :update]`; the paginated `:read` as above |
   | `…MirrorAsh.ProductBarcode` · `product_barcode.ex` | `code :string, allow_nil?: false, constraints: [max_length: 20]` · `symbology :string, default: "EAN-13", constraints: [max_length: 20]` · `registered_at :date` | `belongs_to :product, Product, public?: true` | `default_accept [:code, :symbology, :registered_at, :product_id]`; `defaults [:read, :destroy, :create, :update]`; `identities do identity :unique_product, [:product_id] end` |
   | `…MirrorAsh.Supplier` · `supplier.ex` | `name :string, allow_nil?: false, constraints: [max_length: 60]` · `country :string, constraints: [max_length: 40]` | — | `default_accept [:name, :country]`; `defaults [:destroy, :create, :update]`; the paginated `:read` |
   | `…MirrorAsh.ProductSupplier` · `product_supplier.ex` | none | `belongs_to :product, Product, primary_key?: true, allow_nil?: false` · `belongs_to :supplier, Supplier, primary_key?: true, allow_nil?: false` | `defaults [:read, :destroy, create: :*, update: :*]` |
   | `…MirrorAsh.Product` · `product.ex` | below | below | below |

   `MirrorAsh.Product`:
   - Attributes: `reference :string, constraints: [max_length: 30]`; `name :string, allow_nil?: false`; `description :string`; `status :string, allow_nil?: false, default: "in_stock", constraints: [max_length: 20]`; `grade :atom, constraints: [one_of: [:standard, :premium, :clearance]]`; `labels {:array, :atom}, constraints: [nil_items?: true, items: [one_of: [:fragile, :perishable, :hazardous]]]`; `quantity_initial :decimal, allow_nil?: false, constraints: [min: 0]`; `quantity_at_hand`, `cost`, `msrp`, `rrp`, `list_price`, `discounted_price`, `weight`, `length`, `width`, `height` each `:decimal, constraints: [min: 0]`; `quantity_entries`, `quantity_exits` each `:decimal`; `units_per_box :integer`; `margin :float`; `released_on :date`; `opens_at :time`; `audited_at :naive_datetime`; `discontinued_at :utc_datetime`; `image :binary`; `thumbnail :binary`; `deleted :boolean, default: false`; `inactive :boolean, default: false`; `packaging Packaging`; `contacts {:array, Contact}`.
   - Relationships: `belongs_to :product_location, ProductLocation, public?: true`; `has_many :product_transactions, ProductTransaction`; `has_one :product_barcode, ProductBarcode`; `many_to_many :suppliers, Supplier do through ProductSupplier; source_attribute_on_join_resource :product_id; destination_attribute_on_join_resource :supplier_id end`.
   - Actions: `default_accept` lists every attribute above and `:product_location_id`; `defaults [:destroy]`; the paginated `:read`; `create :create` and `update :update` copied from the two actions of `Aurora.Uix.Guides.Blog.Post` (`lib/aurora_uix/guides/blog/post.ex`) with `topics` renamed `suppliers`, plus, in both, `argument :product_barcode, :map, allow_nil?: true` and `change manage_relationship(:product_barcode, :product_barcode, type: :direct_control)` as in `Aurora.Uix.Guides.Blog.Author` (`lib/aurora_uix/guides/blog/author.ex`).
   - `reject_blank_suppliers/2` and `reject_blank_labels/2`: the bodies of `reject_blank_topics/2` and `reject_blank_labels/2` of `Blog.Post`, with `@doc false` and a `@spec`.
   - `calculations do calculate :summary, :string, expr(name <> " is " <> status) end`.

   Domain `Aurora.Uix.Test.MirrorAsh` at `test/support/mirror/ash.ex`: `@moduledoc false`, `use Ash.Domain`, `resources do … end` listing the six table resources.

   `cast_embed`, `cast_assoc`, `put_assoc` and `manage_relationship` in these files are host code of the fixture, as in the guides. The library builds no changeset.

5. **Seeds** `Aurora.Uix.Test.Mirror.Seeds` at `test/support/mirror/seeds.ex`, with a `@moduledoc` (`## Key Features`, `## Key Constraints`), `@doc` and `@spec` on every public function. Every function writes through `Aurora.Uix.Repo` and the `MirrorCtx` schemas, so one seed serves both backends.

   | Function | Body |
   |---|---|
   | `create_sample_products/3`, `create_sample_products_with_transactions/4`, `create_sample_product_locations/2`, `create_sample_products_with_suppliers/2`, `create_sample_products_with_barcodes/1` | the same-named function of `test/support/helper.ex`, with its private helpers `create_sample_product_transactions/2`, `reference_id/3` and `transaction_type/0`, the guide schemas replaced by the `MirrorCtx` schemas; same arguments, same return shapes |
   | `create_sample_products_with_embeds/1` (`count`) → `[MirrorCtx.Product.t()]` | products `item_embeds-<i>` with `packaging: %{material: :box, fragile: true, notes: "note <i>"}` and `contacts: [%{email: "work<i>@test.com", name: "Work"}, %{email: "home<i>@test.com", name: "Home"}]`, inserted through `MirrorCtx.Product.changeset/2` |
   | `delete_all_mirror_data/0` → `:ok` | `Repo.delete_all/1` on `ProductSupplier`, `ProductTransaction`, `ProductBarcode`, `Product`, `Supplier`, `ProductLocation`, in that order |

6. `dt/1` strings: none. Theme: none.

##### Green tests
1. `MIX_ENV=test mix ecto.migrate`; the test above passes (code-issue runs it, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs only this section's test file and the coverage run of AC-7)
3. `mix compile --warnings-as-errors` clean; `MIX_ENV=test mix compile --warnings-as-errors` clean
<!-- section:UI-1:end -->
<!-- section:UI-2:start -->
### UI-2 — UI · test support · scenario harness, views variants, mirror routes
Depends on: UI-1

#### Documentation references
- `AGENTS.md` § Testing, § Phoenix / LiveView Rules
- `guides/core/layouts.md`, `guides/core/liveview.md § Using Generated Modules with Routes` (no edit)

#### Implementation details

This section adds test support and two tests. It changes no file under `lib/`. Both tests pass on their first run.

Layout types covered: `:index`, `:form`, `:show`, with the default layouts only.

Facts this section builds on, proven on `main` at 25a9ae6 with a probe:
- A views module whose `auix_resource_metadata` and `auix_create_ui` calls come from the `quote` of a `__using__/1` macro compiles, and generates `<Views>.<Schema>.Index`, `.IndexComponent`, `.FormComponent` and `.ShowComponent` for each backend.
- The backend must be known when the macros expand: `Module.put_attribute(__CALLER__.module, :mirror_backend, backend)` runs inside `__using__/1`, outside its `quote`. A module attribute set inside the `quote` is not yet set when the next macro expands.
- A function component defined inside the `quote` cannot use `~H` (the `assigns` variable is hygienic). Function components of a variant are ordinary functions of the variant definition module, referenced by remote capture.
- `Aurora.Uix.Layout.CreateUI` `find_web_module/1` (`lib/aurora_uix/layout/create_ui.ex`) takes the web module from the nearest compiled parent of the views module. Views modules therefore live under `Aurora.UixWeb.Test.`.
- Under `mix test --cover`, each generated module counts one line, covered once the module is mounted. A generated module no test mounts is one missed line.
- The one-to-many renderer builds a related route by replacing the source in the current path (`lib/aurora_uix/templates/basic/renderers/fields/one_to_many.ex`, `set_related_uri_path/3`). A mirror route therefore ends with the source of its resource.
- `use Aurora.UixWeb.Test.ConnCase` (`test/support/conn_case.ex`, `using` block) runs `use TestWeb, :verified_routes` (`test/support/aurora_uix_web.ex`, `verified_routes/0`), which imports every function and macro of `Phoenix.VerifiedRoutes`, the macros `path/2` and `path/3` among them. A second import of the same name and arity makes the unqualified call a compile error. The route helper of step 1 is therefore named `mirror_path`, and no function of `Scenario` is named `path`, `url`, `static_path`, `static_url`, `static_integrity`, `unverified_path` nor `unverified_url`.
- No other name of this section is exported by a module a scenario test imports: `backends`, `each_backend`, `mirror_path` and `scenario_case` are absent from the exports of `Kernel`, `ExUnit.Case`, `ExUnit.Assertions`, `ExUnit.Callbacks`, `Phoenix.VerifiedRoutes`, `Plug.Conn`, `Phoenix.ConnTest`, `Aurora.UixWeb.Test.ConnCase`, `Phoenix.LiveViewTest`, `Aurora.Uix.Test.Mirror.Seeds`, `Aurora.UixWeb.Test.UICase`, `Aurora.UixWeb.Test.SectionHelper`, `Wallaby.Browser` and `Wallaby.Feature`. `rg -l "mirror_resource|register_mirror|each_backend|mirror_path" deps lib` returns nothing.

New names in this section (search `rg -n "Test\.Scenario|UixWeb\.Test\.Mirror(\b|Ash|Ctx)|each_backend|register_mirror|mirror_resource|mirror_path|scenario_case|GuidesTest|LayoutScenariosTest" lib test mix.exs` returns nothing): every module, macro and function below.

##### Acceptance criteria
- [ ] AC-1: Given the `Default` variant, for each backend and each of `products`, `product_locations`, `product_transactions`, `product_barcodes`, `suppliers`: the index, `/new`, `/<id>/show` and `/<id>/edit` routes mount and render `.auix-index-container`; the new and edit routes render `.auix-form-container` inside `#auix-<resource>-<action>-modal`; the show route renders `.auix-show-container`
- [ ] AC-2: Given an index with no row, each backend renders `.auix-index-container` and no `.auix-items-table-row`
- [ ] AC-3: `Scenario.each_backend/2` deletes every mirror row before each backend runs, and a failed assertion names the backend in its message (covered by the tests of AC-1: the second backend starts from an empty index)
- [ ] AC-4: Given one inventory product, one location, one author, one category and one post created with `test/support/helper.ex`, each guide route of `Aurora.UixWeb.Routes.load_routes/0` under `/guides-overview` mounts its index, `/new`, `/<id>/show` and `/<id>/edit`
- [ ] AC-5: no file under `lib/` is modified (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- lib` returning nothing)
- [ ] AC-6: line coverage holds (mechanical — no red test; verified by `.claude/scripts/suite.sh --cover`, then `grep -E '\| Total' /tmp/suite-<branch>.log` showing at least 81.62% and the summary line showing `0 failures`; exit code 3 is the unmet 90% project threshold, as on `main`)

##### Test ports
- Routes registered in `test/support/app_web/routes.ex` `load_test_routes/0` with the new `RoutesHelper.register_mirror/3` (step 4): `/mirror-<ash|ctx>-default-<source>` for the five sources of AC-1 · layout types `:index`, `:form`, `:show` · observable: `has_element?/2`
- Guide routes, existing: `/guides-overview/products`, `/guides-overview/product-locations`, `/guides-overview/product_transactions`, `/guides-overview/posts`, `/guides-overview/authors`, `/guides-overview/categories` (`lib/aurora_uix_web/routes.ex`, `load_routes/0`, mounted by `test/support/app_web/router.ex` scope `"/guides-overview"`)

##### Red tests
Both rows pass on first run.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1, AC-2, AC-3 | new file (`ls test/cases_live \| grep -i scenario` returns nothing) | `use Aurora.UixWeb.Test.UICase, :scenario_case`; inside `each_backend(fn backend -> … end)`: mount the five empty indexes first, then `create_sample_products_with_transactions(1, 2, :test)`, `create_sample_product_locations(1, :test)`, `create_sample_products_with_barcodes(1)`, `create_sample_products_with_suppliers(1, 2)` | `test/cases_live/layout_scenarios_test.exs` (module `Aurora.UixWeb.Test.LayoutScenariosTest`) | `"default layouts mount index, new, show and edit for every resource"` | `{:ok, view, _} = live(conn, mirror_path(backend, "default", "products"))`; `assert has_element?(view, ".auix-index-container")`; `refute has_element?(view, ".auix-items-table-row")` before seeding; after seeding, for each source and each of `""`, `"/new"`, `"/<id>/show"`, `"/<id>/edit"`: `live/2` returns `{:ok, view, _}` and the containers of AC-1 are present |
| AC-4 | new file (`ls test/cases_live \| grep -i guides` returns nothing) | `use Aurora.UixWeb.Test.UICase, :phoenix_case`; `delete_all_sample_data()`; `create_sample_products_with_transactions(1, 1, :test)`; `create_sample_product_locations(1, :test)`; `[author] = create_sample_authors(1)`; `[category] = create_sample_categories(1)`; `create_sample_posts(1, %{author_id: author.id, category_id: category.id})` | `test/cases_live/guides_test.exs` (module `Aurora.UixWeb.Test.GuidesTest`) | `"the guide pages mount on both backends"` | for each guide route and each of `""`, `"/new"`, `"/<id>/show"`, `"/<id>/edit"`: `assert {:ok, view, _} = live(conn, route)`; `assert has_element?(view, ".auix-index-container")` |

##### Modules & components

1. **`Aurora.UixWeb.Test.Scenario`** at `test/support/scenario.ex` — new. `@moduledoc` with `## Key Features` and `## Key Constraints`; `@doc` and `@spec` on each function.
   - `@type backend :: %{name: :ash | :ctx, slug: binary()}`.
   - `backends/0` → `[%{name: :ash, slug: "ash"}, %{name: :ctx, slug: "ctx"}]`.
   - `each_backend(names \\ [:ash, :ctx], fun)` — for each backend whose `name` is in `names`, in the order of `backends/0`: call `Aurora.Uix.Test.Mirror.Seeds.delete_all_mirror_data/0`, then `fun.(backend)`. An `ExUnit.AssertionError` raised by `fun` is re-raised with `"[backend: <name>] "` prepended to its `message`, keeping `__STACKTRACE__`. Returns `:ok`.
   - `mirror_path(backend, variant, source, suffix \\ "")` → `"/mirror-#{backend.slug}-#{variant}-#{source}#{suffix}"`. Every test calls it unqualified, as `mirror_path/3` and as `mirror_path/4`.

2. **`Aurora.UixWeb.Test.Mirror`** at `test/support/mirror_web/mirror.ex` — new. `@moduledoc` as above.
   - `defmacro __using__(backend: backend)`: calls `Module.put_attribute(__CALLER__.module, :mirror_backend, backend)`, then returns
     ```elixir
     quote do
       Module.register_attribute(__MODULE__, :auix_resource_metadata, persist: true)
       use Aurora.Uix
       import Aurora.UixWeb.Test.Mirror, only: [mirror_resource: 1, mirror_resource: 2, mirror_resource: 3]
     end
     ```
   - `defmacro mirror_resource(name, opts \\ [], block \\ [do: nil])`. When `opts` holds a `:do` key and `block` is `[do: nil]`, `opts` is the block. `schema = Keyword.get(opts, :schema, name)`. The backend is `Module.get_attribute(__CALLER__.module, :mirror_backend)`. The macro returns
     ```elixir
     quote do
       auix_resource_metadata unquote(name) do
         unquote(source_lines)
         unquote(block[:do])
       end
     end
     ```
     where `source_lines` is `quote(do: ash_resource(unquote(ash_module)))` for `:ash`, and `quote do context(Aurora.Uix.Test.MirrorCtx); schema(unquote(ctx_module)) end` for `:ctx`. The modules come from this fixed map, a private function with one clause per key and no catch-all:

     | `schema` | `ctx_module` | `ash_module` |
     |---|---|---|
     | `:product` | `Aurora.Uix.Test.MirrorCtx.Product` | `Aurora.Uix.Test.MirrorAsh.Product` |
     | `:product_location` | `…MirrorCtx.ProductLocation` | `…MirrorAsh.ProductLocation` |
     | `:product_transaction` | `…MirrorCtx.ProductTransaction` | `…MirrorAsh.ProductTransaction` |
     | `:product_barcode` | `…MirrorCtx.ProductBarcode` | `…MirrorAsh.ProductBarcode` |
     | `:supplier` | `…MirrorCtx.Supplier` | `…MirrorAsh.Supplier` |

3. **Variants.** A variant is three files:
   - the definition, `test/support/mirror_web/variants/<name>.ex`, module `Aurora.UixWeb.Test.Mirror.Variants.<Name>`, with `defmacro __using__(opts)` whose `quote` holds `use Aurora.UixWeb.Test.Mirror, unquote(opts)`, the `mirror_resource` calls and the `auix_create_ui` call; its function components and handler callbacks are ordinary functions of this module;
   - `test/support/mirror_web/ash/<name>.ex`: `defmodule Aurora.UixWeb.Test.MirrorAsh.<Name> do @moduledoc false; use Aurora.UixWeb.Test.Mirror.Variants.<Name>, backend: :ash end`;
   - `test/support/mirror_web/ctx/<name>.ex`: the same with `MirrorCtx` and `backend: :ctx`.

   This section creates the variant `Default` (slug `default`): `mirror_resource(:product)`, `mirror_resource(:product_location)`, `mirror_resource(:product_transaction)`, `mirror_resource(:product_barcode)`, `mirror_resource(:supplier)`, then `auix_create_ui()`.

4. **Routes.** In `test/support/app_web/routes_helper.ex` add `defmacro register_mirror(variant, slug, sources)` with `@doc` and `@spec`. `variant` is an alias such as `Default`; `sources` is a list of source binaries. `slug` is a literal binary, and `sources` is a literal list of binaries: the macro iterates it when it expands. For each backend pair `{MirrorAsh, "ash"}`, `{MirrorCtx, "ctx"}` and each source, it emits one call in the form `register_product_crud/2` of the same file uses: `Module.concat([<Backend>, unquote(variant), <Schema>]) |> RoutesHelper.register_crud("mirror-<slug of backend>-<slug>-<source>")`, with `<Schema>` from this fixed map: `"products"` → `Product`, `"product_locations"` → `ProductLocation`, `"product_transactions"` → `ProductTransaction`, `"product_barcodes"` → `ProductBarcode`, `"suppliers"` → `Supplier`. `<Backend>`, the variant and `<Schema>` are written with no prefix; the `scope "/", Aurora.UixWeb.Test` of `test/support/app_web/router.ex` that calls `load_test_routes()` prepends `Aurora.UixWeb.Test`. In `test/support/app_web/routes.ex`, inside the `quote` of `load_test_routes/0`, directly after `require Aurora.UixWeb.Test.RoutesHelper`, add
   `RoutesHelper.register_mirror(Default, "default", ["products", "product_locations", "product_transactions", "product_barcodes", "suppliers"])`.
   `register_product_crud/2` and `register_user_crud/2` stay as they are.

5. **Case.** In `test/support/ui_case.ex` add `scenario_case/0` (`@spec scenario_case() :: Macro.t()`) below `phoenix_case/0`:
   ```elixir
   quote do
     use Aurora.UixWeb.Test.ConnCase
     import Phoenix.LiveViewTest
     import Aurora.Uix.Test.Mirror.Seeds
     import Aurora.UixWeb.Test.Scenario
     import Aurora.UixWeb.Test.UICase
     import Aurora.UixWeb.Test.SectionHelper
   end
   ```
   `scenario_case` does not import `Aurora.Uix.Test.Helper`: its function names equal the ones of `Mirror.Seeds`.

6. Theme: none. `dt/1` strings: none.

##### Green tests
1. The two tests above pass (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs only this section's test files and the coverage run of AC-6)
3. `mix compile --warnings-as-errors` clean; `MIX_ENV=test mix compile` adds no warning that names a `Mirror` module
<!-- section:UI-2:end -->
<!-- section:UI-3:start -->
### UI-3 — UI · rules · the scenario test rule in `AGENTS.md` and the pipeline skills
Depends on: UI-2

#### Documentation references
- `AGENTS.md` § Glossary, § Core Structure, § Key Patterns, § Testing
- `.claude/skills/improve-issue/SKILL.md` § Test rules; `.claude/skills/code-issue/SKILL.md` § Rules beyond AGENTS.md, § Project rules, § Test patterns; `.claude/skills/review-issue/SKILL.md` Step 4 › Tests; `.claude/skills/shared/improve-issue/templates/ui.md` § Rules; `.claude/skills/shared/improve-issue/templates/schema.md` § Rules

#### Implementation details

This section edits agent guidance only: `AGENTS.md` and five files under `.claude/skills/`. None of them is in the documentation set (`CHANGELOG.md`, `README.md`, `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md`), so no `DOC-1` exists. It changes no file under `lib/` and no test. Layout types: none.

Every edit below replaces the quoted text with the given text. Text outside the quotes stays.

##### Acceptance criteria
- [ ] AC-1: `AGENTS.md` § Testing › Scope and Coverage states the scenario rule and no longer says "Each test should assert one behavior clearly" (mechanical — no red test; verified by `grep -c "assert one behavior" AGENTS.md` returning `0` and `grep -c "One scenario per feature, on both backends" AGENTS.md` returning `1`)
- [ ] AC-2: `AGENTS.md` names the mirrored fixture as the source of test data (mechanical — no red test; verified by `grep -c "test/support/mirror" AGENTS.md` returning at least `4`)
- [ ] AC-3: no skill tells the coder to seed tests from the guide schemas, and none tells it to write one test per acceptance criterion (mechanical — no red test; verified by `grep -rn "create_sample_products/2" .claude/skills` returning nothing and `grep -c "Every Parser and UI AC has a red-test row" .claude/skills/improve-issue/SKILL.md` returning `0`)
- [ ] AC-4: an edit whose quoted text is absent from its file stops the section with a spec defect, and no partial rewording is committed (mechanical — no red test; verified by `git diff --stat origin/main...HEAD` listing exactly the six files of this section and the spec file)

##### Test ports
None: this section changes no executable code.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|

##### Modules & components

###### `AGENTS.md`
1. § Glossary — replace the row
   `| **Guides** | `lib/aurora_uix/guides/` — demo schemas shipped with the library, doubling as test fixtures. `blog/` is Ash, `inventory/` is Ecto. |`
   with
   ```
   | **Guides** | `lib/aurora_uix/guides/` — demo schemas shipped with the library. `blog/` is Ash, `inventory/` is Ecto. |
   | **Mirror fixture** | `test/support/mirror/` — the test fixture: one set of tables in the PostgreSQL schema `mirror`, with an Ecto schema (`MirrorCtx`) and an Ash resource (`MirrorAsh`) over each table. |
   | **Scenario** | One test that drives one feature through the UI on both backends, written once with `Scenario.each_backend/2`. |
   ```
2. § Core Structure — replace the five lines from `  cases/                # metadata + parser tests (no DB)` through `  support/              # UICase, WebCase, helper.ex, app_web/routes.ex` with
   ```
     cases/                # metadata + parser tests (no DB)
     cases_live/           # scenario tests — the default for UI work
     browser_cases/        # Wallaby — last resort
     doctests/
     support/              # UICase, WebCase, scenario.ex, app_web/routes.ex
       mirror/             #   the mirrored fixture: ctx/ (Ecto), ash/ (Ash), seeds.ex
       mirror_web/         #   views variants: variants/, ash/, ctx/
   ```
3. § Key Patterns — replace `The only `cast_*` calls in this repo are in `lib/aurora_uix/guides/`, which is demo host code.` with `The only `cast_*` calls in this repo are in `lib/aurora_uix/guides/` and `test/support/mirror/`, which are demo and test host code.`
4. § Testing › Test layers — replace the row `| `test/cases_live/` | rendered LiveView behaviour — **the default for UI work** | yes |` with `| `test/cases_live/` | scenario tests over the generated LiveViews — **the default for UI work** | yes |`.
5. § Testing › Test Case Modules — replace the two bullets
   `- `use Aurora.UixWeb.Test.UICase, :phoenix_case` and `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`. There is no `FeatureCase` and no `test/support/factory.ex`.`
   `- Test data comes from the guide schemas via `test/support/helper.ex` (`create_sample_products/2`, `delete_all_inventory_data/0`, …)`
   with
   ```
   - A scenario test file starts with `use Aurora.UixWeb.Test.UICase, :scenario_case`. A test with no LiveView keeps `use ExUnit.Case`. There is no `FeatureCase` and no `test/support/factory.ex`.
   - Test data comes from the mirror fixture through `Aurora.Uix.Test.Mirror.Seeds` (`test/support/mirror/seeds.ex`): `create_sample_products/3`, `create_sample_products_with_transactions/4`, `delete_all_mirror_data/0`, … One seed serves both backends, because both read the same tables.
   - Views modules live in `test/support/mirror_web/`: one variant per layout, written once in `variants/<name>.ex` and compiled for each backend by `ash/<name>.ex` and `ctx/<name>.ex`. A test file declares no views module.
   - A variant's routes are registered in `test/support/app_web/routes.ex` with `RoutesHelper.register_mirror/3`; a scenario builds its path with `Scenario.mirror_path/4`.
   - `test/support/helper.ex` seeds the guide schemas, for the guide pages and the guide image capture only.
   ```
6. § Testing › Scope and Coverage — replace the three bullets of the subsection with
   ```
   - **One scenario per feature, on both backends.** A scenario is one test. It runs its body for `:ash` and for `:ctx` with `Scenario.each_backend/2`, drives the UI (click, type, submit) and asserts what the feature does and how the page is built: containers and `auix-*` classes, on stable selectors.
   - **Amend the scenario of the feature.** A new behaviour of an existing feature is asserted inside that feature's scenario. A new test is written only for a feature no scenario covers.
   - **A backend-specific test states why.** A test that runs on one backend covers what only that backend has: Ash actors and policies, calculations and aggregates, a query parser, `ctx` CRUD function discovery.
   - **Compile errors are table-driven.** One test per DSL loops over its cases, each case a source body and the expected message.
   - **Theme tests do not restate CSS.** They check that the stylesheet generates, that every rule is emitted, that every variable resolves in each theme, and that the sanitizer rejects what it must.
   - **Don't over-test.** Once a behaviour is asserted, do not repeat the assertion in another scenario.
   ```
7. § Testing › No Mocks — replace the two bullets
   `- Create test data through the guide schemas and `test/support/helper.ex`, not by hand-rolling structs.`
   `- Cover **both backends** when a change touches the parser layer — an Ash-only or Ecto-only test is an incomplete test.`
   with
   ```
   - Create test data through `Aurora.Uix.Test.Mirror.Seeds`, not by hand-rolling structs.
   - Cover **both backends** in every scenario and in every parser test — an Ash-only or Ecto-only test is an incomplete test, unless it is backend-specific as defined above.
   ```

###### `.claude/skills/improve-issue/SKILL.md`
1. § Test rules, rule 1, table row `amend an existing test` — replace `| amend an existing test | a test already exercises the port | `amend <file> "<test>"` |` with `| amend an existing scenario | a scenario already drives the feature | `amend <file> "<test>"` |`.
2. § Test rules, rule 3 — replace `the sample data from `test/support/helper.ex` (`create_sample_products/2`,` and the next line `` `delete_all_inventory_data/0`, …). No mocks, no `Process.sleep/1`.`` with `the sample data from `Aurora.Uix.Test.Mirror.Seeds` (`test/support/mirror/seeds.ex`), and the views variant under `test/support/mirror_web/` whose routes `RoutesHelper.register_mirror/3` registers. No mocks, no `Process.sleep/1`.`
3. § Test rules, rule 5 — replace `**Every Parser and UI AC has a red-test row, or ends**` with `**Every Parser and UI AC is named by a red-test row, or ends**`, and add after the rule's last line: `One row may name several ACs: a row is a scenario, and a scenario asserts every AC of its feature.`
4. § Test rules, rule 6 — replace the rule's two lines with
   ```
     6. **Both backends.** A UI row runs on `:ash` and on `:ctx` through `Scenario.each_backend/2`, or
        states why it is backend-specific. A Parser section for one backend names the mirrored section
        for the other, or the sentence in `### Out of Scope` that excuses it.
   ```

###### `.claude/skills/code-issue/SKILL.md`
1. § Rules beyond AGENTS.md — replace the bullet that starts `- **Seed test data through `test/support/helper.ex`**` (two lines) with
   ```
   - **Seed test data through `Aurora.Uix.Test.Mirror.Seeds`** (`test/support/mirror/seeds.ex`) and the
     mirror fixture — never hand-rolled structs, never mocks.
   ```
2. § Red → Green → Refactor — after the sentence `For each row of the `##### Red tests` table, in order:` add the paragraph: `A row whose placement is `amend` extends the named scenario: add the assertions inside its `each_backend/2` body, so they run on both backends. Never add a second test for a feature a scenario already drives.`
3. § Project rules, bullet **Tests** — replace `- **Tests**: `use Aurora.UixWeb.Test.UICase, :phoenix_case` and` and the next line `` `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`. There is no `FeatureCase` and no`` with `- **Tests**: one scenario per feature, on both backends: `use Aurora.UixWeb.Test.UICase, :scenario_case`,` and `` `Scenario.each_backend/2`, views variants from `test/support/mirror_web/`. There is no `FeatureCase` and no``.
4. § Test patterns — replace the code block lines from `# test/cases_live/ — declare metadata + layout, then drive the generated UI.` through the `end` that closes `defmodule Aurora.UixWeb.Test.MyFeatureTest do` with
   ```elixir
   # test/cases_live/ — one scenario per feature, on both backends.
   defmodule Aurora.UixWeb.Test.MyFeatureScenariosTest do
     use Aurora.UixWeb.Test.UICase, :scenario_case

     test "the form renders and saves the field", %{conn: conn} do
       each_backend(fn backend ->
         {:ok, view, _html} = live(conn, mirror_path(backend, "default", "products", "/new"))
         assert has_element?(view, ".auix-form-container input[name='product[reference]']")
       end)
     end
   end
   ```
5. § Test patterns — replace the paragraph that starts `**Every route used by a `test/cases_live/` test must be registered in` (four lines) with: `**Every route a scenario visits belongs to a views variant** under `test/support/mirror_web/`, registered in `test/support/app_web/routes.ex` with `RoutesHelper.register_mirror/3` — otherwise the test 404s. Do **not** extend `register_product_crud/2`.`

###### `.claude/skills/review-issue/SKILL.md`
1. Step 4, list **Tests:** — add two items after `- Mocks: `scoped 'Mox|Mock|:meck'`; `Process.sleep/1`: `scoped 'Process\.sleep'``:
   ```
   - A new test for a feature an existing scenario already drives, instead of an amendment of that scenario
   - A `test/cases_live/` test that runs on one backend and does not state why it is backend-specific
   ```

###### `.claude/skills/shared/improve-issue/templates/ui.md`
1. § Rules, rule 1 — replace `Tests use `Phoenix.LiveViewTest` in `test/cases_live/`, on real data from` and the next line's `` `test/support/helper.ex`.`` with `Tests are scenarios in `test/cases_live/`: one per feature, run on both backends with `Scenario.each_backend/2`, on real data from `Aurora.Uix.Test.Mirror.Seeds`.`
2. § Rules, rule 2 — replace the rule's three lines with
   ```
   2. Every route a scenario visits belongs to a views variant under `test/support/mirror_web/`, registered
      in `test/support/app_web/routes.ex` through `RoutesHelper.register_mirror/3`. The section names the
      variant. It never extends `register_product_crud/2`.
   ```

###### `.claude/skills/shared/improve-issue/templates/schema.md`
1. § Rules, rule 7 — replace `Fixture helpers in `test/support/helper.ex` that the section's dependants need are prescribed` with `Seed functions in `test/support/mirror/seeds.ex` that the section's dependants need, and the matching change to both sides of the mirror fixture (`test/support/mirror/ctx/` and `test/support/mirror/ash/`), are prescribed`.

##### Green tests
1. The greps of AC-1 to AC-4 return what they state (code-issue runs these)
2. `mix test` — full suite green (review-issue runs this)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-3:end -->
<!-- section:UI-4:start -->
### UI-4 — UI · tests · parsers and metadata
Depends on: UI-3

#### Documentation references
- `AGENTS.md` § Testing › Scope and Coverage
- `guides/core/resource_metadata.md`, `guides/core/ash_integration.md` (no edit)

#### Implementation details

This section rewrites tests only. It changes no file under `lib/`. Every test passes on its first run. Layout types: none (no rendered view). No database: every test file here keeps `use ExUnit.Case, async: true`.

The four golden-map tests stay byte for byte: `"Validate fields_parser"` and `"Validate association_parser"` in `test/cases/integration/ash/fields_parser_test.exs` and in `test/cases/integration/ctx/fields_parser_test.exs`, with `test/cases/integration/fields_parser_validations_test.exs`.

Target for this area: 10 tests — the four golden-map tests, `"the mirrored fixture gives both backends the same fields and the same rows"` (UI-1), and S1 to S5 below.

##### Acceptance criteria
- [ ] AC-1: the four golden-map tests and `fields_parser_validations_test.exs` are unchanged (mechanical — no red test; verified by `git diff origin/main...HEAD -- test/cases/integration/fields_parser_validations_test.exs` returning nothing and both `"Validate …"` tests of each parser file passing)
- [ ] AC-2: S1 asserts, for the Ash parser, every enum flavour, every aggregate kind and the generated-field flags the replaced tests assert
- [ ] AC-3: S2 asserts `sortable?` and `embedded_schema?/1` for both parsers, including a key the resource does not define and a module that is neither a schema nor a resource
- [ ] AC-4: S3 asserts the resource defaults, the field overrides, the field order and the `generated?` loading on both backends
- [ ] AC-5: S4 asserts that `resource:` and a declared resource link embedded fields and associations to resources, on both backends
- [ ] AC-6: S5 is one table-driven test: each case is `{label, source body, message regex}`; each replaced compile-error test is one case; a case that compiles fails the test with its label
- [ ] AC-C1: every file listed under `##### Replaced files` is deleted, with its route registrations, and `mix test` is green (mechanical — no red test; verified by `git diff --name-status origin/main...HEAD -- test` showing a `D` line for each listed file)
- [ ] AC-C2: no file under `lib/` is modified (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- lib` returning nothing)
- [ ] AC-C3: line coverage holds (mechanical — no red test; verified by `.claude/scripts/suite.sh --cover`, then `grep -E '\| Total' /tmp/suite-<branch>.log` showing at least 81.62% and the summary line showing `0 failures`; exit code 3 is the unmet 90% project threshold, as on `main`)

##### Test ports
- `Aurora.Uix.Integration.Ash.FieldsParser` and `Aurora.Uix.Integration.Ctx.FieldsParser`, through the calls the replaced tests make · existing
- `auix_resource_metadata/2` compiled with `Code.compile_string/1`, as `compile/1` of `test/cases/resource_metadata_validation_test.exs` does · out: `Spark.Error.DslError` with a message

##### Red tests
Every row passes on first run.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-2 | add to `test/cases/integration/ash/fields_parser_test.exs`, replacing its `describe "enum flavours without a `one_of` constraint"` and `describe "aggregates"` blocks | the schemas the file already declares | same file | S1 `"enum flavours and aggregates parse to typed, generated fields"` | the assertions of the 11 tests of the two blocks, in one test |
| AC-3 | new file (`ls test/cases/integration \| grep -i parity` returns nothing); the `describe "sortable?"` and `describe "embedded_schema?/1"` blocks of both parser test files are removed | `use ExUnit.Case, async: true`; fixtures: `Aurora.Uix.Test.MirrorAsh.Product` with `Ash.FieldsParser`, `Aurora.Uix.Test.MirrorCtx.Product` with `Ctx.FieldsParser`, parsed with the calls the two removed `setup` blocks make; one inline `embedded_schema` with `field :settings, :map` for the map-column case | `test/cases/integration/parser_parity_test.exs` (module `Aurora.Uix.Test.Cases.ParserParityTest`) | S2 `"sortable? and embedded_schema? answer the same on both backends"` | per backend: `name`, `quantity_initial`, `released_on` sortable; `labels`, `packaging`, `contacts` not sortable; `product_location_id` sortable and `product_location` not; a key the resource does not define not sortable; Ecto only: the `:map` field not sortable; `embedded_schema?/1` true for `MirrorAsh.Packaging` and `MirrorCtx.Product.Packaging`, false for both `Product` modules and for `String` |
| AC-4 | new file (`ls test/cases \| grep -x resource_metadata_test.exs` returns nothing) | `use ExUnit.Case, async: true`; the metadata modules declared inside the test module, over `Aurora.Uix.Test.MirrorCtx` and `Aurora.Uix.Test.MirrorAsh` | `test/cases/resource_metadata_test.exs` (module `Aurora.Uix.Test.Cases.ResourceMetadataTest`) | S3 `"resource metadata: defaults, field changes, field order and generated fields"` | the assertions of the files in the S3 row below |
| AC-5 | add to `test/cases/resource_metadata_test.exs` | as S3 | same file | S4 `"resource: and declared resources link fields to resources"` | the assertions of the S4 tests below |
| AC-6 | add to `test/cases/resource_metadata_test.exs` | `compile/1` copied from `test/cases/resource_metadata_validation_test.exs` | same file | S5 `"resource metadata compile errors"` | `for {label, body, regex} <- cases do assert_raise(Spark.Error.DslError, regex, fn -> compile(body) end) end`, wrapped so that a failure message starts with `label` |

After S1 and S2, `test/cases/integration/ash/fields_parser_test.exs` holds its two golden-map tests and S1, and `test/cases/integration/ctx/fields_parser_test.exs` holds only its two golden-map tests; both keep the schemas those tests use.

##### Carry rules
These rules apply to every row of `##### Replaced files`.
1. `file → S` means: scenario `S` makes every assertion of every test of that file, except the tests the row lists under Dropped. The old file is the source of the selectors, the input names and the drives.
2. Re-pointing an Ecto (inventory) test: a guide module becomes the `MirrorCtx` / `MirrorAsh` module of the same last name; a route becomes `mirror_path(backend, "<variant slug>", "<source>", "<suffix>")`; a seed call keeps its name and arguments (`Aurora.Uix.Test.Mirror.Seeds`); a `delete_all_*_data()` call is removed, because `each_backend/2` empties the mirror tables. Selectors, input names and element names stay as written.
3. `on :ash` in a row means the file is the Ash twin of an Ecto file in the same row: its assertions are the Ecto ones, and the scenario makes them on `:ash` by running there. A test listed as `Ash-only` has no Ecto twin: carry it with the name map the row gives, and assert it on both backends.
4. An assertion on an `auix-field-*` id, and an `=~` on rendered HTML, is rewritten as `has_element?/2` on the same element, selected by the first of these it has: its `name` attribute, its input name, its `auix-*` class.
5. Every scenario also asserts the structure its row lists, on both backends.
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing>: <what happens>`, and list it under "Library defects found" in the section log. Never change a file under `lib/`.
7. Delete each replaced file with `git rm`. Remove from `test/support/app_web/routes.ex` every registration whose module argument starts with the test module of a deleted file. A module a deleted file defines beside its test module moves as `##### Modules & components` of this section says.
8. A views variant declares only the resources and layouts its scenarios mount, and each generated module is mounted by a scenario: an unmounted generated module is a missed line in the coverage total.

##### Replaced files
| Old file (tests) | Home | Dropped, with the reason |
|---|---|---|
| `test/cases/integration/ash/fields_parser_test.exs` (20) — kept, amended | golden-map tests kept; the 11 tests of `enum flavours…` and `aggregates` → S1; the 7 tests of `sortable?` and `embedded_schema?/1` → S2 | none |
| `test/cases/integration/ctx/fields_parser_test.exs` (9) — kept, amended | golden-map tests kept; the 7 tests of `sortable?` and `embedded_schema?/1` → S2 | none |
| `test/cases/metadata_default_with_options_test.exs` (2) | S3 | none |
| `test/cases/metadata_default_without_options_test.exs` (1) | S3 | none |
| `test/cases/metadata_modifying_fields_test.exs` (3) | S3 | none |
| `test/cases/create_with_options_no_layouts_test.exs` (2) | S3 | none |
| `test/cases/create_without_options_test.exs` (1) | S3 | none |
| `test/cases/generated_field_test.exs` (4) | `"a field declared generated? is loaded with the entity"`, `"a field not declared generated? is not"` → S3; `"generated? must be a boolean"`, `"data no longer accepts generated"` → S5 cases | none |
| `test/cases/resource_metadata_validation_test.exs` (15) | the seven tests that compile (`"a declared resource on a schema with a table is not embedded"`, `"a declared resource links its associations to imported resources"`, `"a declared Ash resource links its associations to imported resources"`, `"a declared resource wins, and a module without imports is unchanged"`, `"resource: links an Ash embedded field and a many-to-one"`, `"resource: links an Ecto embedded field"`, `"resource: links to an imported resource"`) → S4; the eight `fails compilation` / `validated by the backend` tests → S5 cases | none |

Guide modules these files name (`Aurora.Uix.Guides.Inventory.*`, `Aurora.Uix.Guides.Blog.*`, `Aurora.Uix.Guides.Accounts.User`) become the mirror modules: `Inventory.X` → `MirrorCtx.X`; `Blog.Author` → `MirrorAsh.ProductLocation`; `Blog.Post` → `MirrorAsh.Product`; `Accounts.User` and its `profile` / `emails` embeds → `MirrorCtx.Product` and its `packaging` / `contacts` embeds; `Blog.Post` `comment` / `tags` → `MirrorAsh.Product` `packaging` / `contacts`. An expected field list in an assertion is rewritten for the mirror schema with the same rule the old assertion applies. A schema a test file declares inline (`Person`, `Address`) stays inline.

##### Modules & components
1. No views variant, no route, no theme rule, no `dt/1` string.
2. `test/cases/resource_metadata_test.exs` — new, three tests (S3, S4, S5). `test/cases/integration/parser_parity_test.exs` — new, one test (S2).

##### Green tests
1. The scenarios above pass, on both backends where the row says both (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs only this section's test files and the coverage run of AC-C3)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-4:end -->
<!-- section:UI-5:start -->
### UI-5 — UI · tests · layout and generation
Depends on: UI-4

#### Documentation references
- `AGENTS.md` § Testing › Scope and Coverage, › Test Case Modules
- `guides/core/layouts.md`, `guides/core/components.md`, `CONTRIBUTING.md § Screenshots` (no edit)

#### Implementation details

This section rewrites tests and test support only. It changes no file under `lib/`. Every test passes on its first run. Layout types covered: `:index`, `:form`, `:show`.

Target for this area: 7 tests, S1 to S7. S1 already exists (`UI-2`) and is amended.

`test/guides/capture_layout_images.exs` requires five test files this issue deletes. Step 3 of `##### Modules & components` gives the capture script its own views, over the guide schemas, so the guide images keep their content.

##### Acceptance criteria
- [ ] AC-1: S1 asserts, on both backends, that the default index, show and form render every field of the product in declaration order, stacked for `Default` and inline for `DefaultInline`, and that a product created through the default form appears in the index
- [ ] AC-2: S2 asserts groups, sections and nested sections on both backends: `.auix-group-container` per group; `.auix-sections-container` with one tab button per section; clicking a tab shows its fields and hides the others (`.auix-visually-hidden`); the `default: true` section is active on mount
- [ ] AC-3: S3 asserts titles and subtitles of index, new, edit and show, the layout preload, the resource preload and the resource `where`, on both backends; a relationship that is not preloaded renders the `NOT_LOADED` marker
- [ ] AC-4: S4 asserts named modules, `use:`, `index_live` and included layouts on both backends: a used form component serves the resource of its host; a local layout replaces the included one
- [ ] AC-5: S5 asserts layouts declared with `auix_create_layout`, resources taken from another module, and, on `:ctx` only, a resource map built by hand
- [ ] AC-6: S6 asserts the generation metadata with no database: the module registry, module names, `generate:`, `use:`, cards, render trees and the layout option sets
- [ ] AC-7: S7 is one table-driven test over `auix_create_ui`, `auix_create_layout` and layout option declarations: each replaced compile-error test is one case `{label, source body, message regex}`; a case that compiles fails the test with its label
- [ ] AC-8: `test/guides/capture_layout_images.exs` requires no file under `test/cases_live/` (mechanical — no red test; verified by `grep -c "cases_live" test/guides/capture_layout_images.exs` returning `0` and `MIX_ENV=test mix test test/guides/capture_layout_images.exs` exiting `0`, followed by `git checkout -- guides` to discard the regenerated images)
- [ ] AC-C1: every file listed under `##### Replaced files` is deleted, with its route registrations, and `mix test` is green (mechanical — no red test; verified by `git diff --name-status origin/main...HEAD -- test` showing a `D` line for each listed file)
- [ ] AC-C2: no file under `lib/` is modified (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- lib` returning nothing)
- [ ] AC-C3: line coverage holds (mechanical — no red test; verified by `.claude/scripts/suite.sh --cover`, then `grep -E '\| Total' /tmp/suite-<branch>.log` showing at least 81.62% and the summary line showing `0 failures`; exit code 3 is the unmet 90% project threshold, as on `main`)

##### Test ports
- Mirror routes `/mirror-<ash|ctx>-<slug>-<source>` of the variants below · layout types `:index`, `:form`, `:show` · observable: `has_element?/2`, `element/2`, the section helpers of `test/support/section_helper.ex`
- `Aurora.Uix.Layout.CreateUI` (`module_name/3`, `default_name/2`, `schema_hint/1`, `put_defaults/1`), `auix_modules/0`, `auix_module/1`, `auix_configurations/0` of a compiled views module, as the replaced tests call them · existing

##### Red tests
Every row passes on first run.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | amend `test/cases_live/layout_scenarios_test.exs` `"default layouts mount index, new, show and edit for every resource"` | variants `Default`, `DefaultInline`; `create_sample_products(3, :test)` | same file | S1, name unchanged | carried assertions, plus `.auix-index-container`, `.auix-form-container`, `.auix-show-container`, `.auix-show-content` |
| AC-2 | add to `test/cases_live/layout_scenarios_test.exs` | variants `Groups`, `Sections`, `NestedSections`; `create_sample_products(1, :test)`; edit route | same file | S2 `"groups, sections and nested sections lay out the form"` | carried assertions, plus `.auix-group-container`, `.auix-sections-container`, `.auix-sections-tab-container`, `.auix-sections-content` |
| AC-3 | add to `test/cases_live/layout_scenarios_test.exs` | variant `Options`; `create_sample_products_with_transactions(2, 2, :test)`, `create_sample_product_locations(3, :test)` | same file | S3 `"layout options set titles and preloads"` | carried assertions; the `where` bounds are the references of the first and the second seeded location; the third location is absent from the index |
| AC-4 | add to `test/cases_live/layout_scenarios_test.exs` | variants `NamedForms`, `Named`, `Included`; `create_sample_product_locations(1, :test)`, `create_sample_products(1, :test)` | same file | S4 `"named modules, use: and included layouts render through their host"` | carried assertions |
| AC-5 | add to `test/cases_live/layout_scenarios_test.exs` | variants `Manual`, `Separated`; the hand-built resource module of step 2; `create_sample_products_with_transactions(1, 1, :test)` | same file | S5 `"manual layouts and resources from another module render"` | carried assertions; the hand-built resource part runs inside `each_backend([:ctx], …)` |
| AC-6 | new file (`ls test/cases \| grep -x generation_test.exs` returns nothing) | `use ExUnit.Case, async: true`; reads `Aurora.UixWeb.Test.MirrorCtx.<Variant>` and `Aurora.UixWeb.Test.MirrorAsh.<Variant>` modules; `compile/1` copied from `test/cases/create_ui_validation_test.exs` with its `auix_resource_metadata` re-pointed to `Aurora.Uix.Test.MirrorCtx` | `test/cases/generation_test.exs` (module `Aurora.Uix.Test.Cases.GenerationTest`) | S6 `"generated modules, names, render trees and option sets"` | carried assertions |
| AC-7 | add to `test/cases/generation_test.exs` | as S6 | same file | S7 `"create_ui and layout option compile errors"` | `for {label, body, regex} <- cases`, `assert_raise(Spark.Error.DslError, regex, fn -> compile(body) end)`; a failure message starts with `label`; a case whose old test asserts another exception keeps that exception |

##### Carry rules
These rules apply to every row of `##### Replaced files`.
1. `file → S` means: scenario `S` makes every assertion of every test of that file, except the tests the row lists under Dropped. The old file is the source of the selectors, the input names and the drives.
2. Re-pointing an Ecto (inventory) test: a guide module becomes the `MirrorCtx` / `MirrorAsh` module of the same last name; a route becomes `mirror_path(backend, "<variant slug>", "<source>", "<suffix>")`; a seed call keeps its name and arguments (`Aurora.Uix.Test.Mirror.Seeds`); a `delete_all_*_data()` call is removed, because `each_backend/2` empties the mirror tables. Selectors, input names and element names stay as written.
3. `on :ash` in a row means the file is the Ash twin of an Ecto file in the same row: its assertions are the Ecto ones, and the scenario makes them on `:ash` by running there. A test listed as `Ash-only` has no Ecto twin: carry it with the name map the row gives, and assert it on both backends.
4. An assertion on an `auix-field-*` id, and an `=~` on rendered HTML, is rewritten as `has_element?/2` on the same element, selected by the first of these it has: its `name` attribute, its input name, its `auix-*` class.
5. Every scenario also asserts the structure its row lists, on both backends.
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing>: <what happens>`, and list it under "Library defects found" in the section log. Never change a file under `lib/`.
7. Delete each replaced file with `git rm`. Remove from `test/support/app_web/routes.ex` every registration whose module argument starts with the test module of a deleted file. A module a deleted file defines beside its test module moves as `##### Modules & components` of this section says.
8. A views variant declares only the resources and layouts its scenarios mount, and each generated module is mounted by a scenario: an unmounted generated module is a missed line in the coverage total.
##### Variant rules
1. A variant is the three files `UI-2` defines: `test/support/mirror_web/variants/<name>.ex` (module `Aurora.UixWeb.Test.Mirror.Variants.<Name>`), `test/support/mirror_web/ash/<name>.ex` and `test/support/mirror_web/ctx/<name>.ex`. Its routes are one `RoutesHelper.register_mirror(<Name>, "<slug>", [<sources>])` line in `test/support/app_web/routes.ex`, below the existing `register_mirror` lines.
2. "DSL of `<old file>`" means the `auix_resource_metadata` and `auix_create_ui` calls of that file, moved into the `quote` of the variant's `__using__/1`. `auix_resource_metadata(:x, context: …, schema: …)` and `auix_resource_metadata(:x, ash_resource: …)` become `mirror_resource(:x)`; resource options and `field` lines go in its `do` block, unchanged. For an Ash (blog) source file the row gives the resource and field names to use.
3. A function a layout references (`&__MODULE__.fun/1`) becomes a public function of the variant definition module with `@doc false`, referenced as `&Aurora.UixWeb.Test.Mirror.Variants.<Name>.fun/1`. A handler module a layout names becomes `Aurora.UixWeb.Test.Mirror.Handlers.<SameLastName>` at `test/support/mirror_web/handlers/<name>.ex`, body unchanged.
4. When two sources in one variant give the same resource the same layout type, the row says which list is kept; a positional selector (`nth-child`, `nth-of-type`) of a carried assertion is recomputed for that list.
5. When a row moves a source's DSL to another resource (for example a products test onto `:product_location`), its fields are replaced by fields of that resource with the same type, its seed call by that resource's seed function, and each carried assertion states the same fact about the new resource.

##### Replaced files
| Old file (tests) | Home | Dropped, with the reason |
|---|---|---|
| `test/cases_live/create_ui_default_layout_test.exs` (5) | S1 | none |
| `test/cases_live/create_ui_default_layout_inline_test.exs` (1) | S1 | none |
| `test/cases_live/group_ui_layout_test.exs` (1) | S2 | none |
| `test/cases_live/section_ui_layout_test.exs` (1) | S2 | none |
| `test/cases_live/nested_sections_ui_layout_test.exs` (1) | S2 | none |
| `test/cases_live/preload_layout_test.exs` (1) | S3 | none |
| `test/cases_live/preload_metadata_test.exs` (2) | S3 | none |
| `test/cases_live/ash_preload_metadata_test.exs` (1) | S3, on :ash | none |
| `test/cases_live/named_modules_test.exs` (4) | S4 (`"a used form component serves the resource of its host"`); the other three → S6 | none |
| `test/cases_live/included_layouts_test.exs` (2) | S4 | none |
| `test/cases_live/manual_layouts_test.exs` (4), `manual_trees_test.exs` (4), `manual_ui_test.exs` (4) | S5 | the three `"Test UI default with schema, context, basic layout"` copies after the first, and the three `"Test CREATE new, context, basic layout"` copies after the first: the same index mount and the same create flow, already asserted by S1 |
| `test/cases_live/manual_resource_test.exs` (4) | S5, on `:ctx` | none |
| `test/cases_live/separated_multiple_resources_ui_test.exs` (4), `separated_single_resource_ui_test.exs` (2), `unseparated_multiple_resources_ui_test.exs` (4) | S5 | the `unseparated` file: its two resources in one module are what every variant already declares |
| `test/cases/create_ui_validation_test.exs` (39) | the tests whose name ends `fails compilation`, and `"use: rejects what it cannot take"`, `"use: takes no do block"`, `"use: takes no other option"`, `"use: on index_columns rejects what it cannot take"`, `"a one-to-many field rejects an action_icons key of another field type"`, `"a many-to-many field takes no action_icons key"`, `"a live view needs its form and show components"`, `"an imported module must be a registry entry"` → S7 cases; every other test → S6 | none |
| `test/cases/layout_options_test.exs` (6) | `"lists each option of the set with its layout type"`, `"available_options/1 reads the options of every set"`, `"a listed option is read from the layout, then from get_default/2"` → S6; the three `fails compilation` tests → S7 cases | none |
| `test/cases/render_tree_test.exs` (4) | S6 | none |

Partly carried here, deleted by a later section: `test/cases_live/ash_default_layout_test.exs` — `"Default layout index"` and `"Test show default behaviour"` are covered by S1 on `:ash`; `test/cases_live/create_ui_layout_test.exs` — its titles and subtitles are asserted by S3. Both files stay until `UI-7`.

##### Modules & components
1. Variants (rules above):

   | Variant · slug | Sources | DSL |
   |---|---|---|
   | `DefaultInline` · `default-inline` | `products` | `mirror_resource(:product)`; `auix_create_ui(default_fields_layout: :inline)` |
   | `Groups` · `groups` | `products` | DSL of `test/cases_live/group_ui_layout_test.exs` |
   | `Sections` · `sections` | `products` | DSL of `test/cases_live/section_ui_layout_test.exs` |
   | `NestedSections` · `nested-sections` | `products` | DSL of `test/cases_live/nested_sections_ui_layout_test.exs` |
   | `Options` · `options` | `products`, `product_transactions`, `product_locations` | `:product`: DSL of `test/cases_live/create_ui_layout_test.exs`, without its `backend_opts`; `:product_transaction`: `field(:type, index_renderer: &…Variants.Options.product_marker/1)` and `index_columns(:product_transaction, [:type, :quantity], preload: [:product])`; `:product_location`: `preload([:products])`, `where [{:reference, :between, <first>, <second>}]`, `field(:name, index_renderer: &…Variants.Options.products_marker/1)` and `index_columns(:product_location, [:reference, :name])`. `product_marker/1` and `products_marker/1` are `location_marker/1` of `test/cases_live/preload_layout_test.exs`, reading `@entity.product` and `@entity.products`; each renders `NOT_LOADED` for `%Ecto.Association.NotLoaded{}` and for `%Ash.NotLoaded{}`, else `LOADED` |
   | `NamedForms` · no route | — | the module `Aurora.UixWeb.Test.NamedModulesForms` of `test/cases_live/named_modules_test.exs` |
   | `Named` · `named` | `product_locations` | the module `Aurora.UixWeb.Test.NamedModulesTest` of the same file; the route is `Aurora.Uix.RouteHelper.auix_live_resources("/mirror-<ash\|ctx>-named-product_locations", <Backend>.Named.ProductLocation, index_live: :locations)`, written as two lines beside the `register_mirror` lines, as the existing `"/named-modules-locations"` line is written; `NamedModulesHost` of the old file becomes `Aurora.UixWeb.Test.Mirror.Variants.NamedHost` with its two backend modules |
   | `Included` · `included` | `products` | `test/cases_live/included_layouts_test.exs`: its `IncludedLayouts` module becomes `Aurora.UixWeb.Test.Mirror.IncludedLayouts` at `test/support/mirror_web/included_layouts.ex`, unchanged; its test module becomes the variant |
   | `Manual` · `manual` | `products` | DSL of `test/cases_live/manual_layouts_test.exs` (its two `auix_create_layout` calls and its `auix_create_ui` call) |
   | `Separated` · `separated` | `products`, `product_transactions` | `test/cases_live/separated_multiple_resources_ui_test.exs`: its nested `TestResources` module becomes the variant `SeparatedResources` (no route, `mirror_resource` calls only); `Separated` reads `@auix_resource_metadata` from the `SeparatedResources` module of its own backend |

   A cross-module reference inside a variant (`NamedForms`, `SeparatedResources`, `NamedHost`) resolves to the module of the same backend: `__using__/1` builds it from `backend` with `Module.concat([Aurora.UixWeb.Test, <MirrorAsh for :ash, MirrorCtx for :ctx>, <Name>])` and unquotes it.

2. Hand-built resource (S5, `:ctx` only): `Aurora.UixWeb.Test.MirrorCtx.ManualResource` at `test/support/mirror_web/ctx/manual_resource.ex` — the `@auix_resource_metadata` map and the `auix_create_ui` call of `test/cases_live/manual_resource_test.exs`, with `schema:` and `context:` and each `related:` re-pointed to `Aurora.Uix.Test.MirrorCtx`. Route: `RoutesHelper.register_crud(MirrorCtx.ManualResource.Product, "mirror-ctx-manual-resource-products")`.

3. Capture views. Create one file per row under `test/guides/views/`, each a module that copies the views DSL of the named test file over the guide schemas, with `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test` and no test:

   | New file · module | DSL copied from | Routes |
   |---|---|---|
   | `default_layout.exs` · `Aurora.UixWeb.Test.GuidesCapture.DefaultLayout` | `test/cases_live/create_ui_default_layout_test.exs` | `RoutesHelper.register_crud(GuidesCapture.DefaultLayout.Product, "guides-capture-default-products")` |
   | `selector_layout.exs` · `…GuidesCapture.SelectorLayout` | `test/cases_live/association_many2one_selector_ui_layout_test.exs` | `RoutesHelper.register_product_crud(GuidesCapture.SelectorLayout, "guides-capture-selector-")` |
   | `group_layout.exs` · `…GuidesCapture.GroupLayout` | `test/cases_live/group_ui_layout_test.exs` | `RoutesHelper.register_crud(GuidesCapture.GroupLayout.Product, "guides-capture-group-products")` |
   | `section_layout.exs` · `…GuidesCapture.SectionLayout` | `test/cases_live/section_ui_layout_test.exs` | `RoutesHelper.register_crud(GuidesCapture.SectionLayout.Product, "guides-capture-section-products")` |
   | `nested_sections_layout.exs` · `…GuidesCapture.NestedSectionsLayout` | `test/cases_live/nested_sections_ui_layout_test.exs` | `RoutesHelper.register_crud(GuidesCapture.NestedSectionsLayout.Product, "guides-capture-nested-sections-products")` |

   In `test/guides/capture_layout_images.exs`: replace the five `Code.require_file("test/cases_live/…")` lines with five `Code.require_file("test/guides/views/<file>")` lines; replace `"/create-ui-default-layout-products"` with `"/guides-capture-default-products"`, `"/association-many_to_one_selector-layout-product_locations"` with `"/guides-capture-selector-product_locations"`, `"/association-many_to_one_selector-layout-products"` with `"/guides-capture-selector-products"`, `"group-ui-layout-products"` with `"/guides-capture-group-products"`, `"section-ui-layout-products"` with `"/guides-capture-section-products"`, `"nested-sections-ui-layout-products"` with `"/guides-capture-nested-sections-products"`. These modules are `.exs` files: they are loaded by the capture script only and are outside the compiled test support.

4. Theme: none. `dt/1` strings: none.

##### Green tests
1. The scenarios above pass, on both backends where the row says both (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs only this section's test files and the coverage run of AC-C3)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-5:end -->
<!-- section:UI-6:start -->
### UI-6 — UI · tests · index
Depends on: UI-5

#### Documentation references
- `AGENTS.md` § Testing › Scope and Coverage, › LiveView Streams
- `guides/core/layouts.md § Index Cards`, `guides/customization/custom_actions.md` (no edit)

#### Implementation details

This section rewrites tests and test support only. It changes no file under `lib/`. Every test passes on its first run. Layout type covered: `:index` (the form and show modals are opened only to return from them).

Target for this area: 12 tests, S1 to S12, in `test/cases_live/index_scenarios_test.exs` (module `Aurora.UixWeb.Test.IndexScenariosTest`, new: `ls test/cases_live | grep -x index_scenarios_test.exs` returns nothing). Every test starts with `use Aurora.UixWeb.Test.UICase, :scenario_case` in the module and runs its body in `each_backend/2`.

##### Acceptance criteria
- [ ] AC-1: S1 asserts the table structure and one cell per field type on both backends: `.auix-index-container`, `.auix-items-table`, `.auix-items-table-header`, one `.auix-items-table-row` per seeded product, the mobile `.auix-items-card-container`; a text, a number, a boolean, a select label, a many-to-one label and the joined multi-select labels
- [ ] AC-2: S2 asserts the header sort: ascending on the first click, descending on the second, the backend order on the third; no sort button on an opted-out column; an unknown key and a forged event leave the order unchanged; the sort survives a submitted filter and `auix_route_back`
- [ ] AC-3: S3 asserts the card sort select and the card sort menu, and that `sort_disabled?` and an index without sortable fields render neither
- [ ] AC-4: S4 asserts the metadata `order_by`, the layout `order_by` that overrides it, and a runtime `where` from `load_items_options` applied from the next sort
- [ ] AC-5: S5 asserts the filter bar: it opens on the toggle; equality, `ge`, `between`, many-to-one and `contains` conditions select the expected rows; `contains` escapes the `ilike` wildcards; a non-text field offers no `contains`; a filter matching no row shows `.auix-items-table-empty`
- [ ] AC-6: S6 asserts that a layout `where` narrows with submitted filters, that an in-list condition trims its entries, and that the filters survive `auix_route_back`
- [ ] AC-7: S7 asserts paging: no pages bar for one page; `.auix-pagination-container` with next, previous and to-page for several; `previous_page/1` and `next_page/1` stay inside the pages
- [ ] AC-8: S8 asserts infinite scroll with `pagination_disabled?: true`: no pages bar (`div[name='auix-pages_bar-product_locations']` absent), and the first load renders `Aurora.Uix.Layout.Options.Index.default_infinity_scroll_items_load/0` rows out of a larger seed
- [ ] AC-9: S9 asserts selection: select, deselect, check all, delete selected; `Aurora.Uix.Selection.unselect/2` removes ids from every page
- [ ] AC-10: S10 asserts the bulk action: hidden while nothing is selected; it deactivates the ticked rows and clears the selection; it covers every row after check all
- [ ] AC-11: S11 asserts cards: header, body and labelled rows; a declared title, subtitle and group; `show_on: :all` shows the cards alone; the menu opens through `aria-expanded`, lists the row actions in order with the destructive one last; an empty list shows no card
- [ ] AC-12: S12 asserts row, header and footer actions and their icons: removed, replaced, added and inserted actions; default icons, replaced icons, a function icon; the delete-selected badge; a row delete hides the row through an attribute selector
- [ ] AC-C1: every file listed under `##### Replaced files` is deleted, with its route registrations, and `mix test` is green (mechanical — no red test; verified by `git diff --name-status origin/main...HEAD -- test` showing a `D` line for each listed file)
- [ ] AC-C2: no file under `lib/` is modified (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- lib` returning nothing)
- [ ] AC-C3: line coverage holds (mechanical — no red test; verified by `.claude/scripts/suite.sh --cover`, then `grep -E '\| Total' /tmp/suite-<branch>.log` showing at least 81.62% and the summary line showing `0 failures`; exit code 3 is the unmet 90% project threshold, as on `main`)

##### Test ports
- Mirror routes `/mirror-<ash|ctx>-<slug>-<source>` of the variants below · layout type `:index` · observable: `has_element?/2`, `element/2`, `render_click/3`, `render_change/2`
- Pure functions, called inside the scenario that owns the feature: `Aurora.Uix.Templates.Basic.Handlers.IndexList` (`events/0`, `previous_page/1`, `next_page/1`, `handle_event/3`, `where_conditions/1`), `Aurora.Uix.Selection.unselect/2`, the icon functions `actions_icon_test.exs` calls, `Aurora.Uix.Templates.Basic.CoreComponents.uix_id_selector` · existing, as the replaced files call them

##### Red tests
Every row passes on first run. Test file for every row: `test/cases_live/index_scenarios_test.exs`. Placement: the first row is `new file`; the others are `add to` that file.

| AC | Variant · setup | Test name | Assertion sketch |
|---|---|---|---|
| AC-1 | `Index` · `create_sample_product_locations(2, :test)`, `create_sample_products(5, :test, …)` with a location, a status, two labels and `inactive: true` on the first | S1 `"the table shows one cell per field type"` | carried assertions, plus the structure of AC-1 |
| AC-2 | `Index` · the seeds of `sortable_columns_test.exs` | S2 `"column headers sort, reverse and return to the backend order"` | carried assertions |
| AC-3 | `Index` (`products`, `suppliers`, `product_locations`) · as S2, plus `create_sample_products_with_suppliers(1, 3)` | S3 `"the card sort control sorts, and is absent when sorting is off"` | carried assertions |
| AC-4 | `Index` for the metadata order, `IndexQuery` for the layout order and the runtime `where` · the shuffled seeds of `order_by_layout_test.exs` | S4 `"order_by comes from the metadata, the layout and load_items_options"` | carried assertions |
| AC-5 | `Index` · the seeds of `special_fields_ui_test.exs` | S5 `"the filter bar filters by each condition"` | carried assertions, plus `.auix-filter-card` |
| AC-6 | `IndexWhere` · the seeds of `where_filter_layout_test.exs` | S6 `"a layout where narrows with the submitted filters"` | carried assertions |
| AC-7 | `IndexQuery` (`products`) · `create_sample_products(100, :test)`; then 5 products for the one-page case | S7 `"the pages bar pages through the rows"` | carried assertions, plus `.auix-pagination-container` |
| AC-8 | `IndexQuery` (`product_locations`, `pagination_disabled?: true`) · `create_sample_product_locations(Index.default_infinity_scroll_items_load() + 10, :test)` | S8 `"infinite scroll loads the first batch without a pages bar"` | carried assertions, counted with `LazyHTML` on the rows of the table as the old test counts them |
| AC-9 | `Index` · the seeds of `selected_test.exs` | S9 `"rows are selected, deselected and deleted in bulk"` | carried assertions |
| AC-10 | `IndexActions` · the seeds of `selected_bulk_action_test.exs` | S10 `"a custom bulk action runs on the selection"` | carried assertions |
| AC-11 | `IndexCards`, and `Index` for the default card frame · the seeds of the four card files | S11 `"index cards show their frame, content, grid and menu"` | carried assertions, plus `.auix-items-card-container`, `.auix-items-card-title`, `.auix-items-card-menu` |
| AC-12 | `IndexActions` · `create_sample_products(3, :test)`, `create_sample_products_with_suppliers(1, 2)` | S12 `"index actions and their icons are replaced, added and removed"` | carried assertions, plus `[name='auix-index-header-actions']`, `[name='auix-index-footer-actions']`, `.auix-index-row-action` |

##### Carry rules
These rules apply to every row of `##### Replaced files`.
1. `file → S` means: scenario `S` makes every assertion of every test of that file, except the tests the row lists under Dropped. The old file is the source of the selectors, the input names and the drives.
2. Re-pointing an Ecto (inventory) test: a guide module becomes the `MirrorCtx` / `MirrorAsh` module of the same last name; a route becomes `mirror_path(backend, "<variant slug>", "<source>", "<suffix>")`; a seed call keeps its name and arguments (`Aurora.Uix.Test.Mirror.Seeds`); a `delete_all_*_data()` call is removed, because `each_backend/2` empties the mirror tables. Selectors, input names and element names stay as written.
3. `on :ash` in a row means the file is the Ash twin of an Ecto file in the same row: its assertions are the Ecto ones, and the scenario makes them on `:ash` by running there. A test listed as `Ash-only` has no Ecto twin: carry it with the name map the row gives, and assert it on both backends.
4. An assertion on an `auix-field-*` id, and an `=~` on rendered HTML, is rewritten as `has_element?/2` on the same element, selected by the first of these it has: its `name` attribute, its input name, its `auix-*` class.
5. Every scenario also asserts the structure its row lists, on both backends.
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing>: <what happens>`, and list it under "Library defects found" in the section log. Never change a file under `lib/`.
7. Delete each replaced file with `git rm`. Remove from `test/support/app_web/routes.ex` every registration whose module argument starts with the test module of a deleted file. A module a deleted file defines beside its test module moves as `##### Modules & components` of this section says.
8. A views variant declares only the resources and layouts its scenarios mount, and each generated module is mounted by a scenario: an unmounted generated module is a missed line in the coverage total.
##### Variant rules
1. A variant is the three files `UI-2` defines: `test/support/mirror_web/variants/<name>.ex` (module `Aurora.UixWeb.Test.Mirror.Variants.<Name>`), `test/support/mirror_web/ash/<name>.ex` and `test/support/mirror_web/ctx/<name>.ex`. Its routes are one `RoutesHelper.register_mirror(<Name>, "<slug>", [<sources>])` line in `test/support/app_web/routes.ex`, below the existing `register_mirror` lines.
2. "DSL of `<old file>`" means the `auix_resource_metadata` and `auix_create_ui` calls of that file, moved into the `quote` of the variant's `__using__/1`. `auix_resource_metadata(:x, context: …, schema: …)` and `auix_resource_metadata(:x, ash_resource: …)` become `mirror_resource(:x)`; resource options and `field` lines go in its `do` block, unchanged. For an Ash (blog) source file the row gives the resource and field names to use.
3. A function a layout references (`&__MODULE__.fun/1`) becomes a public function of the variant definition module with `@doc false`, referenced as `&Aurora.UixWeb.Test.Mirror.Variants.<Name>.fun/1`. A handler module a layout names becomes `Aurora.UixWeb.Test.Mirror.Handlers.<SameLastName>` at `test/support/mirror_web/handlers/<name>.ex`, body unchanged.
4. When two sources in one variant give the same resource the same layout type, the row says which list is kept; a positional selector (`nth-child`, `nth-of-type`) of a carried assertion is recomputed for that list.
5. When a row moves a source's DSL to another resource (for example a products test onto `:product_location`), its fields are replaced by fields of that resource with the same type, its seed call by that resource's seed function, and each carried assertion states the same fact about the new resource.

##### Replaced files
| Old file (tests) | Home | Dropped, with the reason |
|---|---|---|
| `test/cases_live/sortable_columns_test.exs` (11), `ash_sortable_columns_test.exs` (7, on :ash) | header tests → S2; card sort tests → S3 | none |
| `test/cases_live/sort_disabled_test.exs` (4) | S3; `"a forged index-sort event is ignored when sorting is disabled"` → S2 | none |
| `test/cases_live/order_by_metadata_test.exs` (1), `order_by_layout_test.exs` (1), `ash_order_by_metadata_test.exs` (1, on :ash), `ash_order_by_layout_test.exs` (1, on :ash) | S4 | none |
| `test/cases_live/load_items_options_test.exs` (1) | S4 | none |
| `test/cases_live/ash_filter_bar_test.exs` (9) | S5, on :ash; Ash-only: `"a filter matching no row shows the empty state"`, `"the filter bar opens on the toggle"` — names: `post` → `product`, `title` → `name`, `author_id` → `product_location_id`, `published_at` → `discontinued_at` | none |
| `test/cases_live/where_layout_test.exs` (1), `ash_where_layout_test.exs` (1, on :ash) | S6: rows inside the bounds, in the layout order | none |
| `test/cases_live/where_filter_layout_test.exs` (5), `ash_where_filter_layout_test.exs` (5, on :ash) | S6 | none |
| `test/cases_live/pages_bar_test.exs` (2) | S7 | none |
| `test/cases/templates/basic/index_list_test.exs` (4) | S7 | none |
| `test/cases_live/infinity_scroll_test.exs` (1) | S8 | none |
| `test/cases_live/selected_test.exs` (2) | S9 | none |
| `test/cases/selection_test.exs` (1) | S9 | none |
| `test/cases_live/selected_bulk_action_test.exs` (3) | S10 | none |
| `test/cases_live/index_card_frame_test.exs` (6), `index_card_content_test.exs` (1), `index_card_grid_test.exs` (1), `index_card_actions_test.exs` (1) | S11 | `"cards have no stripes and no italic values"`: it restates CSS declarations (issue, Expected behaviour 7) |
| `test/cases_live/create_ui_actions_index_test.exs` (5) | S12 | `"Test UI default with schema, context, basic layout"`: the index mount S1 asserts |
| `test/cases_live/action_icons_index_test.exs` (3) | S12 | none |
| `test/cases/templates/basic/actions_icon_test.exs` (4) | S12 | none |
| `test/cases/id_selector_guard_test.exs` (2) | S12 | none |

Partly carried here, deleted by `UI-7`: `test/cases_live/special_fields_ui_test.exs` — its nine `"Test filters …"` tests are covered by S5; `test/cases_live/ash_default_layout_test.exs` — `"Pagination navigation test"` is covered by S7 on `:ash` and `"Test filters contains matches a substring, case-insensitively"` by S5 on `:ash`; `test/cases_live/multi_select_ui_test.exs` and `ash_multi_select_test.exs` — the joined labels of their `index` tests are asserted by S1.

##### Modules & components
1. Variants (rules above):

   | Variant · slug | Sources | DSL |
   |---|---|---|
   | `Index` · `index` | `products`, `product_locations`, `suppliers` | `:product`: the resource block of `test/cases_live/sortable_columns_test.exs` plus the `field(:status, …)` and `field(:product_location_id, option_label: :name)` lines of `test/cases_live/special_fields_ui_test.exs`; `index_columns(:product, [:reference, :name, :cost, :image, :product_location_id, :status, :inactive, :quantity_at_hand, :labels, description: [sortable?: false]])`; `edit_layout :product do stacked([:reference, :name, :description, :status]) end`. `:product_location`: `field(:reference, sortable?: false)`, `field(:name, sortable?: false)`, `index_columns(:product_location, [:reference, :name])`. `:supplier`: `index_columns(:supplier, [:name, :country], sort_disabled?: true)` |
   | `IndexQuery` · `index-query` | `products`, `product_locations` | `:product`: DSL of `test/cases_live/order_by_layout_test.exs`, with `handler_module: Aurora.UixWeb.Test.Mirror.Handlers.LoadItemsOptionsHandler` added to its `index_columns` options. `:product_location`: `index_columns(:product_location, [:reference, :name], order_by: :name, pagination_disabled?: true)` |
   | `IndexWhere` · `index-where` | `products` | DSL of `test/cases_live/where_filter_layout_test.exs`, with `order_by: :name` added to its `index_columns` options |
   | `IndexCards` · `index-cards` | `products`, `product_locations` | `:product`: DSL of `test/cases_live/index_card_content_test.exs`. `:product_location`: `index_columns :product_location, [:reference, :name, :type] do card title: &…Variants.IndexCards.card_title/1, subtitle: "Location", show_on: :all do inline([:name, :type]) end end`, with `card_title/1` from `test/cases_live/index_card_grid_test.exs` |
   | `IndexActions` · `index-actions` | `products`, `product_locations`, `suppliers` | `:product`: DSL of `test/cases_live/create_ui_actions_index_test.exs`, with `:inactive` appended to its column list and the `handler_module:` and `add_selected_action:` options of `test/cases_live/selected_bulk_action_test.exs` added. `:product_location`: the `index_columns` options of `test/cases_live/index_card_actions_test.exs` on `index_columns(:product_location, [:reference, :name], …)`, the two action names ending `-product_location`. `:supplier`: the `action_icons:` option of `test/cases_live/action_icons_index_test.exs` on `index_columns(:supplier, [:name, :country], …)` |

2. Handlers moved (variant rule 3): `LoadItemsOptionsHandler` from `load_items_options_test.exs`, `SelectedBulkActionIndexHandler` from `selected_bulk_action_test.exs`.
3. Theme: none. `dt/1` strings: none.

##### Green tests
1. The scenarios above pass, on both backends where the row says both (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs only this section's test files and the coverage run of AC-C3)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-6:end -->
<!-- section:UI-7:start -->
### UI-7 — UI · tests · form
Depends on: UI-6

#### Documentation references
- `AGENTS.md` § Testing › Scope and Coverage
- `guides/customization/predefined_renderers.md`, `guides/customization/custom_actions.md`, `guides/core/resource_metadata.md` (no edit)

#### Implementation details

This section rewrites tests and test support only. It changes no file under `lib/`. Every test passes on its first run. Layout type covered: `:form` (new, edit and show-edit); the index and the show view are visited only to reach a form and to observe its result.

Target for this area: 12 tests, S1 to S12, in `test/cases_live/form_scenarios_test.exs` (module `Aurora.UixWeb.Test.FormScenariosTest`, new: `ls test/cases_live | grep -x form_scenarios_test.exs` returns nothing). The module starts with `use Aurora.UixWeb.Test.UICase, :scenario_case`; every test runs its body in `each_backend/2`.

##### Acceptance criteria
- [ ] AC-1: S1 creates a product through `/new` on both backends with a value for every field type of the `Form` variant (text, textarea, integer, float, decimal, boolean, date, time, both datetimes, the string select, the enum, the multi-select, the many-to-one select), and reads every value back from the row `MirrorCtx.Product` loads; the new row appears in the index without a remount; the titles and subtitles of the `Options` variant render on the new form
- [ ] AC-2: S2 edits that product from the index and from the show view (`show-edit`), changes one field of every type, reads the values back, and deletes the row from the index
- [ ] AC-3: S3 asserts that a blank required field keeps the form open, writes no row and shows an error element under the field, on both backends; inputs and show inputs carry `.auix-form-field-container`; `input/1` with `copyable: true` renders its copy button, and warns when it has no `id`
- [ ] AC-4: S4 asserts `.auix-flash--success` and `.auix-flash--warning` with their icon, and no flash element without a message
- [ ] AC-5: S5 asserts the discard guard: a clean form closes; a changed form opens `#auix-product-discard-confirm-modal`; keep editing keeps the change; discard closes without saving; a second close request while the dialog is open keeps editing; with `unsaved_changes_guard_disabled?: true` a changed form closes without a prompt
- [ ] AC-6: S6 asserts the select field, the enum select with one option per enum value, and a field with `html_type: :unimplemented`: read-only value, the empty message, joined values in the index cell
- [ ] AC-7: S7 asserts the multi-select: one checkbox per value and the empty-list sentinel; stored values checked on edit; toggle all; every checked value saved; show lists the selection, and the empty message for an empty one; label, header and footer actions replaced and added
- [ ] AC-8: S8 asserts that a true boolean renders checked, a true disabled boolean disabled and checked, a false one unchecked, from the edit route, from the index and from the show view
- [ ] AC-9: S9 asserts uploads: the live file input; an entry and its cancel; the `consume` callback result persisted for arity 1 and arity 2; a save without a file keeps the stored value; `{:error, reason}` aborts the save with an error flash; no download button without `download`; with `download`, the button, the `auix_download` push event and `:no_download`; `upload_fields/1`
- [ ] AC-10: S10 asserts custom renderers: `index_renderer`, `show_renderer`, `edit_renderer`, the generic `renderer` fallback, options threaded through `index_columns` and through an inline field list; a field with no renderer renders the default input
- [ ] AC-11: S11 asserts the predefined renderers in index, show and form, the interactive rating, slot resolution, a host registrar, and `html_type` tables: module, resource, layout, `index_columns` and application config, in their precedence; a table that is not a map raises
- [ ] AC-12: S12 asserts form header and footer actions (added, inserted) and the action icons of the form and of the show view, each icon with its label kept
- [ ] AC-C1: every file listed under `##### Replaced files` is deleted, with its route registrations, and `mix test` is green (mechanical — no red test; verified by `git diff --name-status origin/main...HEAD -- test` showing a `D` line for each listed file)
- [ ] AC-C2: no file under `lib/` is modified (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- lib` returning nothing)
- [ ] AC-C3: line coverage holds (mechanical — no red test; verified by `.claude/scripts/suite.sh --cover`, then `grep -E '\| Total' /tmp/suite-<branch>.log` showing at least 81.62% and the summary line showing `0 failures`; exit code 3 is the unmet 90% project threshold, as on `main`)

##### Test ports
- Mirror routes `/mirror-<ash|ctx>-<slug>-<source>` of the variants below and of `Options` (`UI-5`) · layout type `:form` · observable: `form/3`, `render_change/1`, `render_submit/1`, `file_input/4`, `render_upload/3`, `assert_push_event/3`, `has_element?/2`
- Persisted values: `Aurora.Uix.Repo.get!(Aurora.Uix.Test.MirrorCtx.Product, id)` with preloads, for both backends (the tables are shared)
- `Aurora.Uix.Templates.Basic.CoreComponents.input/1` through `render_component/2`, as `test/cases/core_components_input_test.exs` renders it · existing

##### Red tests
Every row passes on first run. Test file for every row: `test/cases_live/form_scenarios_test.exs`. Placement: the first row is `new file`; the others are `add to` that file.

| AC | Variant · setup | Test name | Assertion sketch |
|---|---|---|---|
| AC-1 | `Form`, `Options` · `create_sample_product_locations(2, :test)` | S1 `"a product is created with every field type"` | submit `form("#auix-product-form", product: %{…})` on `/new`; read the row; carried assertions; `.auix-form-container`, `[name='auix-form-footer-actions']` |
| AC-2 | `Form`, `Options` · `create_sample_products(3, :test)`, `create_sample_product_locations(2, :test)` | S2 `"a product is edited from the index and from the show view, then deleted"` | carried assertions |
| AC-3 | `Form` · none | S3 `"a blank required field keeps the form open and marks the field"` | submit with `name: ""`; `assert has_element?(view, "#auix-product-form")`; `assert Repo.aggregate(MirrorCtx.Product, :count) == 0`; carried assertions |
| AC-4 | `FormOptions` · `create_sample_products(1, :test)` | S4 `"success and warning flashes render with their class and icon"` | carried assertions |
| AC-5 | `Form`, `FormOptions` · `create_sample_products(1, :test)` | S5 `"the discard guard holds a changed form"` | carried assertions |
| AC-6 | `Form`, `Renderers` · `create_sample_products(2, :test, …)` with labels on the first | S6 `"select, enum and unimplemented fields render their options and values"` | carried assertions; `select[name='product[grade]'] option` count is 4: the blank and the three values |
| AC-7 | `Form`, `FormOptions` · the seeds of `multi_select_ui_test.exs` | S7 `"a multi-select checks, toggles, saves and shows its values"` | carried assertions, plus `.auix-multi-select-container` |
| AC-8 | `Form` · the seed of `checkbox_checked_test.exs` | S8 `"booleans keep their checked state in the edit form"` | carried assertions |
| AC-9 | `Uploads` · the seeds of `upload_field_test.exs` | S9 `"an upload field selects, cancels, consumes and downloads a file"` | carried assertions, plus `.auix-upload-entry` |
| AC-10 | `Renderers` · the seeds of `custom_field_renderers_test.exs` | S10 `"custom renderers replace the field in index, show and form"` | carried assertions |
| AC-11 | `PredefinedRenderers`, `RendererModuleTable`, `RendererPrecedence`, `Renderers` · the seeds of `predefined_renderers_test.exs` | S11 `"predefined renderers and html_type tables resolve in their precedence"` | carried assertions; each `Application.put_env/3` is undone with `on_exit/1`, as the old `setup` blocks do |
| AC-12 | `FormOptions` · `create_sample_products(1, :test)` | S12 `"form and show actions and their icons are added and replaced"` | carried assertions, plus `[name='auix-form-header-actions']`, `[name='auix-show-header-actions']` |

##### Carry rules
These rules apply to every row of `##### Replaced files`.
1. `file → S` means: scenario `S` makes every assertion of every test of that file, except the tests the row lists under Dropped. The old file is the source of the selectors, the input names and the drives.
2. Re-pointing an Ecto (inventory) test: a guide module becomes the `MirrorCtx` / `MirrorAsh` module of the same last name; a route becomes `mirror_path(backend, "<variant slug>", "<source>", "<suffix>")`; a seed call keeps its name and arguments (`Aurora.Uix.Test.Mirror.Seeds`); a `delete_all_*_data()` call is removed, because `each_backend/2` empties the mirror tables. Selectors, input names and element names stay as written.
3. `on :ash` in a row means the file is the Ash twin of an Ecto file in the same row: its assertions are the Ecto ones, and the scenario makes them on `:ash` by running there. A test listed as `Ash-only` has no Ecto twin: carry it with the name map the row gives, and assert it on both backends.
4. An assertion on an `auix-field-*` id, and an `=~` on rendered HTML, is rewritten as `has_element?/2` on the same element, selected by the first of these it has: its `name` attribute, its input name, its `auix-*` class.
5. Every scenario also asserts the structure its row lists, on both backends.
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing>: <what happens>`, and list it under "Library defects found" in the section log. Never change a file under `lib/`.
7. Delete each replaced file with `git rm`. Remove from `test/support/app_web/routes.ex` every registration whose module argument starts with the test module of a deleted file. A module a deleted file defines beside its test module moves as `##### Modules & components` of this section says.
8. A views variant declares only the resources and layouts its scenarios mount, and each generated module is mounted by a scenario: an unmounted generated module is a missed line in the coverage total.
##### Variant rules
1. A variant is the three files `UI-2` defines: `test/support/mirror_web/variants/<name>.ex` (module `Aurora.UixWeb.Test.Mirror.Variants.<Name>`), `test/support/mirror_web/ash/<name>.ex` and `test/support/mirror_web/ctx/<name>.ex`. Its routes are one `RoutesHelper.register_mirror(<Name>, "<slug>", [<sources>])` line in `test/support/app_web/routes.ex`, below the existing `register_mirror` lines.
2. "DSL of `<old file>`" means the `auix_resource_metadata` and `auix_create_ui` calls of that file, moved into the `quote` of the variant's `__using__/1`. `auix_resource_metadata(:x, context: …, schema: …)` and `auix_resource_metadata(:x, ash_resource: …)` become `mirror_resource(:x)`; resource options and `field` lines go in its `do` block, unchanged. For an Ash (blog) source file the row gives the resource and field names to use.
3. A function a layout references (`&__MODULE__.fun/1`) becomes a public function of the variant definition module with `@doc false`, referenced as `&Aurora.UixWeb.Test.Mirror.Variants.<Name>.fun/1`. A handler module a layout names becomes `Aurora.UixWeb.Test.Mirror.Handlers.<SameLastName>` at `test/support/mirror_web/handlers/<name>.ex`, body unchanged.
4. When two sources in one variant give the same resource the same layout type, the row says which list is kept; a positional selector (`nth-child`, `nth-of-type`) of a carried assertion is recomputed for that list.
5. When a row moves a source's DSL to another resource (for example a products test onto `:product_location`), its fields are replaced by fields of that resource with the same type, its seed call by that resource's seed function, and each carried assertion states the same fact about the new resource.

##### Replaced files
| Old file (tests) | Home | Dropped, with the reason |
|---|---|---|
| `test/cases_live/create_ui_layout_test.exs` (10) | the six tests up to `"Test new link"` → S1; `"Test main show link"`, `"Test show link - edit link"`, `"Test main edit link"`, `"Test main delete link"` → S2 | none |
| `test/cases_live/ash_default_layout_test.exs` (7) | `"Test CREATE new author"`, `"Test CREATE new author updates the index list without remounting"` → S1 on :ash; `"Test UPDATE existing author"` → S2 on :ash; the other four are covered by `UI-5` S1 and `UI-6` S5, S7 | none |
| `test/cases_live/form_controls_test.exs` (2) | S3 | none |
| `test/cases/core_components_input_test.exs` (5) | S3 | none |
| `test/cases_live/flash_kinds_test.exs` (2) | S4 | none |
| `test/cases_live/form_discard_guard_test.exs` (8), `form_discard_guard_disabled_test.exs` (1), `ash_form_discard_guard_test.exs` (2, on :ash) | S5 | none |
| `test/cases_live/special_fields_ui_test.exs` (10) | `"Test select field"` → S6; the nine filter tests are covered by `UI-6` S5 | none |
| `test/cases_live/unimplemented_field_ui_test.exs` (3) | S6 | none |
| `test/cases_live/multi_select_ui_test.exs` (7), `ash_multi_select_test.exs` (7, on :ash), `multi_select_ui_actions_test.exs` (3) | S7 | none |
| `test/cases_live/checkbox_checked_test.exs` (5), `ash_checkbox_checked_test.exs` (5, on :ash) | S8 | the `active?` attribute name of the `AshCheckbox.Item` fixture: the mirror has no column named with `?`; the checked-state guard it exercised is asserted on `inactive` and `deleted` |
| `test/cases_live/upload_field_test.exs` (21), `upload_field_error_test.exs` (1) | S9 | none |
| `test/cases_live/custom_field_renderers_test.exs` (8) | S10 | none |
| `test/cases_live/predefined_renderers_test.exs` (17) | S11 | none |
| `test/cases_live/html_type_renderers_app_config_test.exs` (2), `html_type_renderers_module_test.exs` (2), `html_type_renderers_precedence_test.exs` (3) | S11 | none |
| `test/cases_live/create_ui_actions_form_test.exs` (2), `action_icons_form_show_test.exs` (2) | S12 | none |

Also deleted: `test/support/ash_checkbox/domain.ex`, `test/support/ash_checkbox/item.ex` and the route registrations of `AshCheckboxCheckedTest` in `test/support/app_web/routes.ex`.

##### Modules & components
1. In `test/support/mirror_web/mirror.ex` (`UI-2`), `__using__/1` accepts an optional `uix:` keyword list: `backend = Keyword.fetch!(opts, :backend)`, `uix_opts = Keyword.get(opts, :uix, [])`, and its quote calls `use Aurora.Uix, unquote(uix_opts)`. A variant passes it as `use Aurora.UixWeb.Test.Mirror, Keyword.put(unquote(opts), :uix, renderers: %{…})`.

2. Variants (rules above):

   | Variant · slug | Sources | DSL |
   |---|---|---|
   | `Form` · `form` | `products`, `product_locations` | `:product`: `order_by(:reference)`; `field(:deleted, disabled: true)`; `field(:description, html_type: :textarea)`; the `field(:status, …)` select block and `field(:product_location_id, option_label: :name)` of `test/cases_live/special_fields_ui_test.exs`; `index_columns(:product, [:reference, :name, :labels])`; `edit_layout :product do stacked([:reference, :name, :description, :quantity_initial, :units_per_box, :margin, :list_price, :released_on, :opens_at, :audited_at, :discontinued_at, :status, :grade, :inactive, :deleted, :labels, :product_location_id]) end`; `show_layout :product` with the same field list. `:product_location`: `mirror_resource(:product_location)` with `field(:products, omitted: true)` |
   | `FormOptions` · `form-options` | `products` | `:product`: `index_columns(:product, [:reference, :name], handler_module: Aurora.UixWeb.Test.Mirror.Handlers.FlashKindsHandlerHook)`; `edit_layout :product` with `unsaved_changes_guard_disabled?: true`, the two action options of `test/cases_live/create_ui_actions_form_test.exs` and `action_icons: [default_save: "hero-bolt"]`, body `stacked([:reference, :name, :quantity_initial, labels: […]])` where the `labels:` options are the ones of `test/cases_live/multi_select_ui_actions_test.exs`; `show_layout :product, action_icons: [default_back: "←"] do inline([:reference, :name]) end` |
   | `Uploads` · `uploads` | `products` | `:product`: four upload fields — `image` with the `upload` block of `Aurora.UixWeb.Test.UploadFieldTest`, `thumbnail` with the block of `DownloadUploadFieldTest`, `description` with the block of `SocketAwareUploadFieldTest`, `status` with the block of `test/cases_live/upload_field_error_test.exs`; `edit_layout` and `show_layout`: `stacked([:reference, :name, :quantity_initial, :image, :thumbnail, :description, :status])`. The consumer and downloader modules of the two files become `Aurora.UixWeb.Test.Mirror.Handlers.<SameLastName>` |
   | `Renderers` · `renderers` | `products` | DSL of the three views modules of `test/cases_live/custom_field_renderers_test.exs`, merged on `:product`, plus `field(:deleted, renderer: :default_checkbox)` and `field(:labels, html_type: :unimplemented)`; the `index_columns` and layouts of `CustomFieldRenderersIndexColumnsTest` and `InlineFieldOptsTest` are kept; `:labels` is appended to the index columns and to the edit and show field lists |
   | `PredefinedRenderers` · `predefined-renderers` | `products` | DSL of `PredefinedRenderersTest` and `PredefinedRenderersInteractiveTest` of `test/cases_live/predefined_renderers_test.exs`, merged on `:product`; its `HostToggle` and `HostRegistrar` modules become `Aurora.UixWeb.Test.Mirror.Handlers.HostToggle` and `…Handlers.HostRegistrar` |
   | `RendererModuleTable` · `renderer-module-table` | `products` | DSL of `test/cases_live/html_type_renderers_module_test.exs`, with `uix: [renderers: %{checkbox: :toggle_switch}]` |
   | `RendererPrecedence` · `renderer-precedence` | `products` | DSL of `test/cases_live/html_type_renderers_precedence_test.exs`, with `uix: [renderers: %{number: :progress_bar}]` |

   In `Uploads`, a consumer that returns `{:ok, value}` for `description` and `status` returns a string of at most 20 characters, so the value fits both columns.

3. Handler moved (variant rule 3): `FlashKindsHandlerHook` from `flash_kinds_test.exs`.
4. Theme: none. `dt/1` strings: none.

##### Green tests
1. The scenarios above pass, on both backends where the row says both (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs only this section's test files and the coverage run of AC-C3)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-7:end -->
<!-- section:UI-8:start -->
### UI-8 — UI · tests · show
Depends on: UI-7

#### Documentation references
- `AGENTS.md` § Testing › Scope and Coverage
- `guides/core/layouts.md § Sections and groups`, `guides/customization/custom_actions.md` (no edit)

#### Implementation details

This section rewrites tests and test support only. It changes no file under `lib/`. Every test passes on its first run. Layout type covered: `:show`; the edit form is opened only for the record navigator it shares with the show view.

Target for this area: 3 tests, S1 to S3, in `test/cases_live/show_scenarios_test.exs` (module `Aurora.UixWeb.Test.ShowScenariosTest`, new: `ls test/cases_live | grep -x show_scenarios_test.exs` returns nothing). The module starts with `use Aurora.UixWeb.Test.UICase, :scenario_case`; every test runs its body in `each_backend/2`.

##### Acceptance criteria
- [ ] AC-1: S1 asserts, on both backends, that the show view of the `Form` variant (`UI-7`) renders one read-only element per field type inside `.auix-show-container .auix-show-content`, with the seeded value; that a replaced header action and an added footer action of the `Show` variant render in `[name='auix-show-header-actions']` and `[name='auix-show-footer-actions']`; that a product with no value in an optional field renders that field empty and the page still mounts
- [ ] AC-2: S2 asserts groups, sections and tabs in the show layout of the `Show` variant: one `.auix-group-container` with its title; `.auix-sections-container` with one tab button per section; clicking the second tab shows its fields and hides the first tab's
- [ ] AC-3: S3 asserts record navigation: previous on the first record and next on the last are absent; previous and next inside a page, into the previous page and into the next page open the expected record; `record_navigator: :none`, `:top`, `:bottom` and the default place the navigator as declared
- [ ] AC-C1: every file listed under `##### Replaced files` is deleted, with its route registrations, and `mix test` is green (mechanical — no red test; verified by `git diff --name-status origin/main...HEAD -- test` showing a `D` line for each listed file)
- [ ] AC-C2: no file under `lib/` is modified (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- lib` returning nothing)
- [ ] AC-C3: line coverage holds (mechanical — no red test; verified by `.claude/scripts/suite.sh --cover`, then `grep -E '\| Total' /tmp/suite-<branch>.log` showing at least 81.62% and the summary line showing `0 failures`; exit code 3 is the unmet 90% project threshold, as on `main`)

##### Test ports
- Mirror routes `/mirror-<ash|ctx>-<slug>-<source>/<id>/show` and `/<id>/edit` of the variants below and of `Form` · layout types `:show`, `:form` · observable: `has_element?/2`, `element/2`, `render_click/3`, `assert_patch/1`, the section helpers of `test/support/section_helper.ex`

##### Red tests
Every row passes on first run. Test file for every row: `test/cases_live/show_scenarios_test.exs`. Placement: the first row is `new file`; the others are `add to` that file.

| AC | Variant · setup | Test name | Assertion sketch |
|---|---|---|---|
| AC-1 | `Form`, `Show` · `create_sample_product_locations(1, :test)`; one product with a value in every field of the `Form` show layout, one with only the required fields | S1 `"the show view renders every field type and its actions"` | carried assertions, plus the structure of AC-1 |
| AC-2 | `Show` · `create_sample_products(1, :test)` | S2 `"groups, sections and tabs lay out the show view"` | `assert has_element?(view, ".auix-show-content .auix-group-container")`; `click_section_button/4` and `assert_section_is_active/3` of `SectionHelper`, as `test/cases_live/section_ui_layout_test.exs` uses them on the form |
| AC-3 | `Show`, `ShowNavigator` · the seeds of `record_navigation_test.exs` and of `record_navigation_disable_test.exs` | S3 `"the record navigator moves across records and pages"` | carried assertions |

##### Carry rules
These rules apply to every row of `##### Replaced files`.
1. `file → S` means: scenario `S` makes every assertion of every test of that file, except the tests the row lists under Dropped. The old file is the source of the selectors, the input names and the drives.
2. Re-pointing an Ecto (inventory) test: a guide module becomes the `MirrorCtx` / `MirrorAsh` module of the same last name; a route becomes `mirror_path(backend, "<variant slug>", "<source>", "<suffix>")`; a seed call keeps its name and arguments (`Aurora.Uix.Test.Mirror.Seeds`); a `delete_all_*_data()` call is removed, because `each_backend/2` empties the mirror tables. Selectors, input names and element names stay as written.
3. `on :ash` in a row means the file is the Ash twin of an Ecto file in the same row: its assertions are the Ecto ones, and the scenario makes them on `:ash` by running there. A test listed as `Ash-only` has no Ecto twin: carry it with the name map the row gives, and assert it on both backends.
4. An assertion on an `auix-field-*` id, and an `=~` on rendered HTML, is rewritten as `has_element?/2` on the same element, selected by the first of these it has: its `name` attribute, its input name, its `auix-*` class.
5. Every scenario also asserts the structure its row lists, on both backends.
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing>: <what happens>`, and list it under "Library defects found" in the section log. Never change a file under `lib/`.
7. Delete each replaced file with `git rm`. Remove from `test/support/app_web/routes.ex` every registration whose module argument starts with the test module of a deleted file. A module a deleted file defines beside its test module moves as `##### Modules & components` of this section says.
8. A views variant declares only the resources and layouts its scenarios mount, and each generated module is mounted by a scenario: an unmounted generated module is a missed line in the coverage total.
##### Variant rules
1. A variant is the three files `UI-2` defines: `test/support/mirror_web/variants/<name>.ex` (module `Aurora.UixWeb.Test.Mirror.Variants.<Name>`), `test/support/mirror_web/ash/<name>.ex` and `test/support/mirror_web/ctx/<name>.ex`. Its routes are one `RoutesHelper.register_mirror(<Name>, "<slug>", [<sources>])` line in `test/support/app_web/routes.ex`, below the existing `register_mirror` lines.
2. "DSL of `<old file>`" means the `auix_resource_metadata` and `auix_create_ui` calls of that file, moved into the `quote` of the variant's `__using__/1`. `auix_resource_metadata(:x, context: …, schema: …)` and `auix_resource_metadata(:x, ash_resource: …)` become `mirror_resource(:x)`; resource options and `field` lines go in its `do` block, unchanged. For an Ash (blog) source file the row gives the resource and field names to use.
3. A function a layout references (`&__MODULE__.fun/1`) becomes a public function of the variant definition module with `@doc false`, referenced as `&Aurora.UixWeb.Test.Mirror.Variants.<Name>.fun/1`. A handler module a layout names becomes `Aurora.UixWeb.Test.Mirror.Handlers.<SameLastName>` at `test/support/mirror_web/handlers/<name>.ex`, body unchanged.
4. When two sources in one variant give the same resource the same layout type, the row says which list is kept; a positional selector (`nth-child`, `nth-of-type`) of a carried assertion is recomputed for that list.
5. When a row moves a source's DSL to another resource (for example a products test onto `:product_location`), its fields are replaced by fields of that resource with the same type, its seed call by that resource's seed function, and each carried assertion states the same fact about the new resource.

##### Replaced files
| Old file (tests) | Home | Dropped, with the reason |
|---|---|---|
| `test/cases_live/create_ui_actions_show_test.exs` (1) | S1 | none |
| `test/cases_live/record_navigation_test.exs` (6) | S3 | none |
| `test/cases_live/record_navigation_disable_test.exs` (4) | S3 | none |

S2 replaces no file: no test on `main` drives a group in a show layout, and none drives a section there. It is the scenario the issue's Target suite names for the show view.

##### Modules & components
1. Variants (rules above):

   | Variant · slug | Sources | DSL |
   |---|---|---|
   | `Show` · `show` | `products` | `:product`: `index_columns(:product, [:reference, :name, :quantity_initial], order_by: :reference)`; the `edit_layout` of `test/cases_live/record_navigation_test.exs`; `show_layout :product` with the two action options of `test/cases_live/create_ui_actions_show_test.exs` and the body `inline([:reference, :name, :description])`, `group "Quantities" do inline([:quantity_at_hand, :quantity_initial]) end`, `sections do section "Prices" do stacked([:list_price, :rrp]) end; section "Dimensions" do inline([:width, :height, :length]) end end` |
   | `ShowNavigator` · `show-navigator` | `products`, `product_locations` | DSL of `test/cases_live/record_navigation_disable_test.exs` |

2. Theme: none. `dt/1` strings: none.

##### Green tests
1. The scenarios above pass, on both backends where the row says both (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs only this section's test files and the coverage run of AC-C3)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-8:end -->
<!-- section:UI-9:start -->
### UI-9 — UI · tests · associations and embeds
Depends on: UI-8

#### Documentation references
- `AGENTS.md` § Key Patterns (transport-only writes), § Testing › Scope and Coverage
- `guides/core/resource_metadata.md`, `guides/core/layouts.md`, `guides/core/ash_integration.md` (no edit)

#### Implementation details

This section rewrites tests and test support only. It changes no file under `lib/`. Every test passes on its first run. Layout types covered: `:form`, `:show`, and `:index` for the columns an association never takes.

Target for this area: 10 tests, S1 to S10, in `test/cases_live/association_scenarios_test.exs` (module `Aurora.UixWeb.Test.AssociationScenariosTest`, new: `ls test/cases_live | grep -x association_scenarios_test.exs` returns nothing). The module starts with `use Aurora.UixWeb.Test.UICase, :scenario_case`; every test runs its body in `each_backend/2`.

Writes go through the fixture's own changeset and actions (`UI-1`): the library forwards the params untouched.

##### Acceptance criteria
- [ ] AC-1: S1 asserts the many-to-one select on both backends: one option per related record; labels from an atom, from a function of the entity and from a function of the assigns and the entity; `query_opts` `order_by` and `where` order and limit the options; the selected value is saved
- [ ] AC-2: S2 asserts the parent record fields of a many-to-one (`{:product_location, :name}`, `product_location: :type`, `:product_location`) in the form and in the show view, and that they change when the select changes and the form is saved
- [ ] AC-3: S3 asserts the one-to-many list: `.auix-one-to-many-field` with one row per child; layout `order_by` and `where`; the empty state for a parent with no child; the list is the index component of the related resource; a parent that is not saved yet offers no new-child link
- [ ] AC-4: S4 asserts one-to-many header, row and footer actions, replaced and added, in the table and in the child cards, and the `action_icons` of the list
- [ ] AC-5: S5 asserts the one-to-one: blank nested inputs on new; pre-filled inputs and the hidden child id on edit; the child's foreign key is not rendered; parent and child are created in one submit; an edit updates the existing child and adds none; show renders the child read-only inside `.auix-one-to-one-container`, and `.auix-one-to-one-empty-msg` when there is none; the association is no index column
- [ ] AC-6: S6 asserts the many-to-many: `.auix-many-to-many-container` with one option per candidate; current members pre-selected; added members written as join rows; a removed member deletes the join row and keeps the supplier; de-selecting everything clears membership; toggle all, the mixed state, and a toggled-all membership that survives submit; show lists the members, and the empty message for none; the association is no index column
- [ ] AC-7: S7 asserts many-to-many label, header and footer actions, and option labels taken from the related resource when no `option_label` is declared
- [ ] AC-8: S8 asserts the embeds-one: `.auix-embeds-one-container` with its nested inputs (`product[packaging][material]`, `product[packaging][fragile]`, `product[packaging][notes]`) on new and on edit, the values in show, and the embedded column in the index
- [ ] AC-9: S9 asserts the embeds-many: `.auix-embeds-many-container`; the entries of a seeded product in show and in edit; `expanded` opens the details; the header and entry action icons; a product created with no contact has none
- [ ] AC-10: S10 asserts two embeds on one schema: one submit creates a product with a packaging and two contacts; one edit changes the packaging and removes one contact; an invalid contact email keeps the form open and writes nothing
- [ ] AC-C1: every file listed under `##### Replaced files` is deleted, with its route registrations, and `mix test` is green (mechanical — no red test; verified by `git diff --name-status origin/main...HEAD -- test` showing a `D` line for each listed file)
- [ ] AC-C2: no file under `lib/` is modified (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- lib` returning nothing)
- [ ] AC-C3: line coverage holds (mechanical — no red test; verified by `.claude/scripts/suite.sh --cover`, then `grep -E '\| Total' /tmp/suite-<branch>.log` showing at least 81.62% and the summary line showing `0 failures`; exit code 3 is the unmet 90% project threshold, as on `main`)

##### Test ports
- Mirror routes `/mirror-<ash|ctx>-<slug>-<source>` of the variants below · layout types `:form`, `:show`, `:index` · observable: `form/3`, `render_change/1`, `render_submit/1`, `has_element?/2`, `element/2`
- Persisted values: `Aurora.Uix.Repo` reads of `MirrorCtx.Product` with `preload: [:product_location, :product_transactions, :product_barcode, :suppliers]`, and of `MirrorCtx.ProductSupplier`, for both backends
- `Aurora.Uix.Templates.Basic.Renderers.OneToMany` `load_rows/1`, as `test/cases/templates/basic/one_to_many_rows_test.exs` calls it · existing

##### Red tests
Every row passes on first run. Test file for every row: `test/cases_live/association_scenarios_test.exs`. Placement: the first row is `new file`; the others are `add to` that file.

| AC | Variant · setup | Test name | Assertion sketch |
|---|---|---|---|
| AC-1 | `ManyToOne`, `ManyToOneQueries` · the seeds of `association_many2one_selector_atom_test.exs` | S1 `"a many-to-one select lists, labels, orders and filters its options"` | carried assertions |
| AC-2 | `ManyToOne`, `ManyToOneQueries` · `create_sample_product_locations(3, :test)`, `create_sample_products(1, :test, …)` with the first location | S2 `"parent fields of a many-to-one follow the selected record"` | carried assertions |
| AC-3 | `OneToMany`, `OneToManyComponent` · `create_sample_products_with_transactions(2, 15, :test)`, one product with no transaction | S3 `"a one-to-many list shows, orders and filters the children"` | carried assertions, plus `.auix-one-to-many-field`, `[name='auix-one_to_many-header-actions']` |
| AC-4 | `OneToManyActions` · `create_sample_products_with_transactions(1, 3, :test)` | S4 `"one-to-many actions and icons are replaced and added"` | carried assertions |
| AC-5 | `OneToOne` · `create_sample_products_with_barcodes(2)`, `create_sample_products(1, :test)` | S5 `"a one-to-one child is created, updated and shown with its parent"` | carried assertions |
| AC-6 | `ManyToMany` · `create_sample_products_with_suppliers(2, 4)` | S6 `"many-to-many membership is selected, toggled, saved and shown"` | carried assertions; join rows read with `Repo.all(MirrorCtx.ProductSupplier)` |
| AC-7 | `ManyToManyActions` · as S6 | S7 `"many-to-many actions are replaced and added"` | carried assertions |
| AC-8 | `Embeds` · `create_sample_products_with_embeds(1)` | S8 `"an embeds-one renders and saves its nested fields"` | carried assertions |
| AC-9 | `Embeds`, `EmbedsExpanded` · `create_sample_products_with_embeds(1)`, `create_sample_products(1, :test)` | S9 `"an embeds-many lists its entries and opens expanded"` | carried assertions |
| AC-10 | `Embeds` · none | S10 `"two embeds on one schema save in one submit"` | `render_submit` of `product: %{reference: …, name: …, quantity_initial: 1, packaging: %{material: "box", fragile: "true", notes: "n"}, contacts: %{"0" => %{email: "a@test.com", name: "A"}, "1" => %{email: "b@test.com", name: "B"}}}`; read the row; edit with one contact and `material: "bag"`; submit `contacts: %{"0" => %{email: "not-an-email"}}` and assert the form stays and the row is unchanged |

##### Carry rules
These rules apply to every row of `##### Replaced files`.
1. `file → S` means: scenario `S` makes every assertion of every test of that file, except the tests the row lists under Dropped. The old file is the source of the selectors, the input names and the drives.
2. Re-pointing an Ecto (inventory) test: a guide module becomes the `MirrorCtx` / `MirrorAsh` module of the same last name; a route becomes `mirror_path(backend, "<variant slug>", "<source>", "<suffix>")`; a seed call keeps its name and arguments (`Aurora.Uix.Test.Mirror.Seeds`); a `delete_all_*_data()` call is removed, because `each_backend/2` empties the mirror tables. Selectors, input names and element names stay as written.
3. `on :ash` in a row means the file is the Ash twin of an Ecto file in the same row: its assertions are the Ecto ones, and the scenario makes them on `:ash` by running there. A test listed as `Ash-only` has no Ecto twin: carry it with the name map the row gives, and assert it on both backends.
4. An assertion on an `auix-field-*` id, and an `=~` on rendered HTML, is rewritten as `has_element?/2` on the same element, selected by the first of these it has: its `name` attribute, its input name, its `auix-*` class.
5. Every scenario also asserts the structure its row lists, on both backends.
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing>: <what happens>`, and list it under "Library defects found" in the section log. Never change a file under `lib/`.
7. Delete each replaced file with `git rm`. Remove from `test/support/app_web/routes.ex` every registration whose module argument starts with the test module of a deleted file. A module a deleted file defines beside its test module moves as `##### Modules & components` of this section says.
8. A views variant declares only the resources and layouts its scenarios mount, and each generated module is mounted by a scenario: an unmounted generated module is a missed line in the coverage total.
##### Variant rules
1. A variant is the three files `UI-2` defines: `test/support/mirror_web/variants/<name>.ex` (module `Aurora.UixWeb.Test.Mirror.Variants.<Name>`), `test/support/mirror_web/ash/<name>.ex` and `test/support/mirror_web/ctx/<name>.ex`. Its routes are one `RoutesHelper.register_mirror(<Name>, "<slug>", [<sources>])` line in `test/support/app_web/routes.ex`, below the existing `register_mirror` lines.
2. "DSL of `<old file>`" means the `auix_resource_metadata` and `auix_create_ui` calls of that file, moved into the `quote` of the variant's `__using__/1`. `auix_resource_metadata(:x, context: …, schema: …)` and `auix_resource_metadata(:x, ash_resource: …)` become `mirror_resource(:x)`; resource options and `field` lines go in its `do` block, unchanged. For an Ash (blog) source file the row gives the resource and field names to use.
3. A function a layout references (`&__MODULE__.fun/1`) becomes a public function of the variant definition module with `@doc false`, referenced as `&Aurora.UixWeb.Test.Mirror.Variants.<Name>.fun/1`. A handler module a layout names becomes `Aurora.UixWeb.Test.Mirror.Handlers.<SameLastName>` at `test/support/mirror_web/handlers/<name>.ex`, body unchanged.
4. When two sources in one variant give the same resource the same layout type, the row says which list is kept; a positional selector (`nth-child`, `nth-of-type`) of a carried assertion is recomputed for that list.
5. When a row moves a source's DSL to another resource (for example a products test onto `:product_location`), its fields are replaced by fields of that resource with the same type, its seed call by that resource's seed function, and each carried assertion states the same fact about the new resource.

##### Replaced files
| Old file (tests) | Home | Dropped, with the reason |
|---|---|---|
| `test/cases_live/association_many2one_selector_atom_test.exs` (4), `association_many2one_selector_function_test.exs` (3), `association_many2one_selector_assigns_test.exs` (3), `association_many2one_selector_ui_layout_test.exs` (3) | S1 | the `check_listing` tests of the last three files: the same index mount as the first file's |
| `test/cases_live/where_many2one_test.exs` (1), `ash_where_many2one_test.exs` (1, on :ash) | S1 | none |
| `test/cases_live/ash_many_to_one_select_test.exs` (1) | S1, on :ash | none |
| `test/cases_live/association_many2one_ui_layout_test.exs` (1), `association_many2one_parent_ui_layout_test.exs` (1) | S2 | none |
| `test/cases_live/association_one2many_ui_layout_test.exs` (4) | S3 | none |
| `test/cases_live/where_one2many_test.exs` (1), `ash_where_one2many_test.exs` (2) | S3, on :ash; Ash-only: `"an author with no post shows the empty one-to-many state"` — names: `author` → `product`, `posts` → `product_transactions` | none |
| `test/cases_live/one_to_many_component_test.exs` (1) | S3 | none |
| `test/cases/templates/basic/one_to_many_rows_test.exs` (2) | S3 | none |
| `test/cases_live/association_one2many_ui_actions_test.exs` (4) | S4 | none |
| `test/cases_live/action_icons_fields_test.exs` (2) | `"one-to-many actions take the field's action_icons"` → S4; `"embeds-many actions take the field's action_icons"` → S9 | none |
| `test/cases_live/association_one2one_ui_layout_test.exs` (8), `ash_one2one_test.exs` (7, on :ash) | S5 | none |
| `test/cases_live/association_many2many_ui_layout_test.exs` (12), `ash_many2many_test.exs` (10, on :ash) | S6; Ash-only: `"labels each option from the related resource when no option_label is declared"` → S7 — names: `post` → `product`, `topics` → `suppliers` | none |
| `test/cases_live/association_many2many_ui_actions_test.exs` (3) | S7 | none |
| `test/cases_live/embeds_one_test.exs` (2) | S8 — names: `user` → `product`, `profile` → `packaging`, `online` / `dark_mode` → `fragile`, `visibility` → `material`, `given_name` → `reference`, `family_name` → `name` | none |
| `test/cases_live/embeds_many_test.exs` (3) | S9 — names: `user` → `product`, `emails` → `contacts`; `"Create new user with emails"` → S10 | none |

Partly carried here, deleted by `UI-11`: `test/cases_live/ash_embeds_test.exs` — `"Show from list embeds-many"`, `"embeds_many with :expanded renders the details open in show and edit"` and `"Test forms creation"` are covered by S8, S9 and S10 on `:ash` (names: `post` → `product`, `tags` → `contacts`, `comment` → `packaging`).

##### Modules & components
1. Variants (rules above):

   | Variant · slug | Sources | DSL |
   |---|---|---|
   | `ManyToOne` · `many-to-one` | `products`, `product_locations`, `product_transactions`, `product_barcodes` | `:product_location`: the block and the `edit_layout` of `test/cases_live/association_many2one_selector_atom_test.exs`. `:product`: `field(:product_location_id, option_label: :name, query_opts: [order_by: [desc: :name]])`; `edit_layout :product do stacked([:reference, :name, :description, :quantity_initial, :product_location_id, {:product_location, :name}, product_location: :type]) end`. `:product_transaction`: `field(:product_id, option_label: &…Variants.ManyToOne.option_label/1)`; `edit_layout :product_transaction do stacked([:type, :quantity, :cost, :product_id]) end`. `:product_barcode`: `field(:product_id, option_label: &…Variants.ManyToOne.option_label/2)`; `edit_layout :product_barcode do stacked([:code, :symbology, :product_id]) end`. `option_label/1` and `option_label/2` come from `association_many2one_selector_function_test.exs` and `association_many2one_selector_assigns_test.exs` |
   | `ManyToOneQueries` · `many-to-one-queries` | `products`, `product_locations` | DSL of `test/cases_live/where_many2one_test.exs`, with `:product_location` added after `:product_location_id` in the `edit_layout` of `:product` |
   | `OneToMany` · `one-to-many` | `products`, `product_transactions`, `product_locations` | `:product`: DSL of `test/cases_live/association_one2many_ui_layout_test.exs`. `:product_location`: `edit_layout :product_location do stacked([:reference, :name, products: [order_by: [desc: :name], where: {:name, :between, <a>, <b>}]]) end`, the bounds taken from the seeded product names as `test/cases_live/where_one2many_test.exs` takes its bounds |
   | `OneToManyComponent` · `one-to-many-component` | `products`, `product_locations` | DSL of `test/cases_live/one_to_many_component_test.exs`; `:product_compact` is `mirror_resource(:product_compact, schema: :product)` |
   | `OneToManyActions` · `one-to-many-actions` | `products`, `product_transactions`, `product_locations` | `:product`: DSL of `test/cases_live/association_one2many_ui_actions_test.exs`. `:product_location`: `edit_layout :product_location do stacked([:reference, :name, products: [action_icons: [default_new: "hero-sparkles", default_row_edit: "hero-pencil-square"]]]) end` |
   | `OneToOne` · `one-to-one` | `products`, `product_barcodes` | DSL of `test/cases_live/association_one2one_ui_layout_test.exs` |
   | `ManyToMany` · `many-to-many` | `products`, `suppliers` | DSL of `test/cases_live/association_many2many_ui_layout_test.exs` |
   | `ManyToManyActions` · `many-to-many-actions` | `products`, `suppliers` | DSL of `test/cases_live/association_many2many_ui_actions_test.exs`, without its `field(:suppliers, option_label: :name)` line |
   | `Embeds` · `embeds` | `products` | `:product`: `index_columns(:product, [:reference, :name, :packaging, :contacts])`; `edit_layout :product, new_title: "Embeds" do stacked do inline([:reference, :name]); inline([:quantity_initial]); stacked([:packaging, :contacts]) end end` |
   | `EmbedsExpanded` · `embeds-expanded` | `products` | `:product`: `field(:contacts, expanded: &…Variants.EmbedsExpanded.always_expanded/1)`; `edit_layout :product do stacked([:reference, :name, :quantity_initial, contacts: [action_icons: [default_header_enable_add_entry: "hero-sparkles", default_remove_entry: "hero-x-mark"]]]) end`; `show_layout :product do stacked([:reference, :name, :contacts]) end`; `always_expanded/1` from `test/cases_live/ash_embeds_test.exs` |

2. Theme: none. `dt/1` strings: none.

##### Green tests
1. The scenarios above pass, on both backends where the row says both (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs only this section's test files and the coverage run of AC-C3)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-9:end -->
<!-- section:UI-10:start -->
### UI-10 — UI · tests · navigation and extension
Depends on: UI-9

#### Documentation references
- `AGENTS.md` § Testing › Scope and Coverage, § Localization
- `guides/core/liveview.md § Navigation`, `guides/core/components.md`, `guides/core/internationalization.md` (no edit)

#### Implementation details

This section rewrites tests and test support only. It changes no file under `lib/`. Every test passes on its first run. Layout types covered: `:index`, `:form`, `:show`.

Target for this area: 11 tests, S1 to S11. S1, S9 and S11 need no LiveView mount for their pure parts.

The rewritten event tests must not depend on test order: every test that subscribes to `Aurora.Uix.PubSub` unsubscribes in the same test (`on_exit/1`), and a test that changes `:pubsub_server` in the application environment restores it with `on_exit/1`. The issue lists a leftover PubSub subscriber in `test/cases/events_test.exs` among the order-dependent failures on `main`.

##### Acceptance criteria
- [ ] AC-1: S1 asserts the `Aurora.Uix.Navigation` functions with no database: the five paths, `resolve_uri_path/2`, the stack round trip, `forward/2`, `back/1`, `back_to_edit/2`, and the raise for an unknown key and for a missing current path
- [ ] AC-2: S2 asserts the routing stack on both backends: the index opens show, edit and new with the index pushed twice; show to show-edit and back unwinds the stack; closing and saving return to the index; a directly loaded form and a directly loaded show each return to the index with an empty stack; the discard guard holds navigation
- [ ] AC-3: S3 asserts child navigation on both backends: a new child navigates to the child route and back to the parent form; child show and edit links carry the parent on the stack; a new parent with a child list continues on its edit form
- [ ] AC-4: S4 asserts route options: `only:` and `except:` limit the mounted routes; a forwarded `routing_stack` is honoured on back; pagination pushes the index and closing a form drops the page; record navigation patches without a stack; index links keep their anchor attributes; the flash of a form follows the redirect
- [ ] AC-5: S5 asserts handler hooks on both backends: `auix_mount`, `auix_handle_params`, `auix_handle_event`, `auix_handle_async` and `auix_handle_info` in the index; `update`, `auix_update` and a targeted custom event in the form and in the show view; a built-in event falls through to `super`
- [ ] AC-6: S6 asserts the embedded index component on both backends: its scope, two instances with their own page, open and delete intents, its options, its own sort, a refresh on an event, the empty message, a custom component handler, and a pairing checked against the host
- [ ] AC-7: S7 asserts the embedded form and show components on both backends: save and report, load by `entity_id`, close and edit intents, no record navigator, a paired form, `resource` checked against the host, `resource_binding/4`, and `report_intent/2`
- [ ] AC-8: S8 asserts component hooks: with the hook, an event reaches every instance; without it nothing is forwarded; other messages reach the host; `register/2` without the hook does nothing
- [ ] AC-9: S9 asserts the `Aurora.Uix.Events` functions on both backends' structs: one topic per schema, the payloads of `created/1`, `updated/1`, `deleted/2` and `changed/1`, `from:`, `unsubscribe/1`, `refresh/1`, `reset_selection/1`; an unset `pubsub_server` subscribes and broadcasts nothing; a `pubsub_server` that is not started raises on subscribe
- [ ] AC-10: S10 asserts events between views on both backends: a save, a create and a row delete in one view update another index; delete selected publishes only what it deleted; the originating view does not receive its own event; an open show re-reads on `:updated` and closes on `:deleted`; an open form keeps typed input and reports the update
- [ ] AC-11: S11 asserts gettext: `dt/1` through `Aurora.Uix.GettextResolver`, the `@gettext_domain` attribute, the save and edit buttons and the field labels rendered through `dt/1`, and that the template sources route their strings through `dt/1`
- [ ] AC-C1: every file listed under `##### Replaced files` is deleted, with its route registrations, and `mix test` is green (mechanical — no red test; verified by `git diff --name-status origin/main...HEAD -- test` showing a `D` line for each listed file)
- [ ] AC-C2: no file under `lib/` is modified (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- lib` returning nothing)
- [ ] AC-C3: line coverage holds (mechanical — no red test; verified by `.claude/scripts/suite.sh --cover`, then `grep -E '\| Total' /tmp/suite-<branch>.log` showing at least 81.62% and the summary line showing `0 failures`; exit code 3 is the unmet 90% project threshold, as on `main`)

##### Test ports
- Mirror routes of the variants below; `Aurora.Uix.RouteHelper.auix_live_resources/3` routes with `only:` and `except:`; the host LiveViews of step 2 · observable: `assert_patch/1`, the `{:error, {:live_redirect, %{to: path}}}` return of `render_click/1`, `Aurora.UixWeb.Test.NavigationHelper.decode_route/1` and `encode_stack/1` (`test/support/navigation_helper.ex`), `Phoenix.Router.route_info/4`, `has_element?/2`, `assert_receive/2`
- `Aurora.Uix.Navigation`, `Aurora.Uix.Events`, `Aurora.Uix.Live.ComponentHooks`, `Aurora.Uix.GettextResolver`, `Aurora.Uix.Templates.Basic.Helpers` (`report_intent/2`, the navigation helpers) · existing, as the replaced files call them

##### Red tests
Every row passes on first run.

| AC | Placement | Variant · setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | amend `test/cases/navigation_test.exs`: its ten tests become one | `use ExUnit.Case, async: true` | same file | S1 `"Navigation builds paths and moves the routing stack"` | carried assertions |
| AC-2 | new file (`ls test/cases_live \| grep -x navigation_scenarios_test.exs` returns nothing) | `Navigation` · the seeds of `test/cases_live/navigation_test.exs` | `test/cases_live/navigation_scenarios_test.exs` (module `Aurora.UixWeb.Test.NavigationScenariosTest`) | S2 `"the routing stack follows index, show, edit and new"` | carried assertions |
| AC-3 | add to that file | `Navigation` · `create_sample_products_with_transactions(1, 2, :test)` | same | S3 `"child routes navigate with the parent on the stack"` | carried assertions |
| AC-4 | add to that file | `Navigation` · `create_sample_products(100, :test)` | same | S4 `"route options, forwarded stacks and pagination keep navigation consistent"` | carried assertions |
| AC-5 | new file (`ls test/cases_live \| grep -x extension_scenarios_test.exs` returns nothing) | `Hooks` · `create_sample_products_with_transactions(2, 2, :test)` | `test/cases_live/extension_scenarios_test.exs` (module `Aurora.UixWeb.Test.ExtensionScenariosTest`) | S5 `"handler hooks run in the index, the form and the show view"` | carried assertions |
| AC-6 | add to that file | `Components` and the host LiveViews · `create_sample_products(12, :test)`, `create_sample_product_locations(2, :test)` | same | S6 `"an embedded index component pages, sorts and reports its intents"` | carried assertions, plus `[name='auix-index-component']` |
| AC-7 | add to that file | `Components` and the host LiveViews · `create_sample_products(1, :test)`, `create_sample_product_locations(1, :test)` | same | S7 `"embedded form and show components save, load and report"` | carried assertions |
| AC-8 | add to that file | `Components` · `create_sample_products(12, :test)` | same | S8 `"component hooks forward events to every instance"` | carried assertions |
| AC-9 | amend `test/cases/events_test.exs`: its eight tests become one | `use ExUnit.Case` (not async: it reads the application environment) | same file | S9 `"Events names topics, builds payloads and honours the pubsub configuration"` | carried assertions, with the cleanup this section states |
| AC-10 | add to `extension_scenarios_test.exs` | `Events` · the seeds of `test/cases_live/events_test.exs` | same | S10 `"events from one view update the index, the show and the form of another"` | carried assertions |
| AC-11 | add to `extension_scenarios_test.exs` | `Gettext` · `create_sample_products(1, :test)` | same | S11 `"labels and buttons render through dt and the gettext domain"` | carried assertions |

##### Carry rules
These rules apply to every row of `##### Replaced files`.
1. `file → S` means: scenario `S` makes every assertion of every test of that file, except the tests the row lists under Dropped. The old file is the source of the selectors, the input names and the drives.
2. Re-pointing an Ecto (inventory) test: a guide module becomes the `MirrorCtx` / `MirrorAsh` module of the same last name; a route becomes `mirror_path(backend, "<variant slug>", "<source>", "<suffix>")`; a seed call keeps its name and arguments (`Aurora.Uix.Test.Mirror.Seeds`); a `delete_all_*_data()` call is removed, because `each_backend/2` empties the mirror tables. Selectors, input names and element names stay as written.
3. `on :ash` in a row means the file is the Ash twin of an Ecto file in the same row: its assertions are the Ecto ones, and the scenario makes them on `:ash` by running there. A test listed as `Ash-only` has no Ecto twin: carry it with the name map the row gives, and assert it on both backends.
4. An assertion on an `auix-field-*` id, and an `=~` on rendered HTML, is rewritten as `has_element?/2` on the same element, selected by the first of these it has: its `name` attribute, its input name, its `auix-*` class.
5. Every scenario also asserts the structure its row lists, on both backends.
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing>: <what happens>`, and list it under "Library defects found" in the section log. Never change a file under `lib/`.
7. Delete each replaced file with `git rm`. Remove from `test/support/app_web/routes.ex` every registration whose module argument starts with the test module of a deleted file. A module a deleted file defines beside its test module moves as `##### Modules & components` of this section says.
8. A views variant declares only the resources and layouts its scenarios mount, and each generated module is mounted by a scenario: an unmounted generated module is a missed line in the coverage total.
##### Variant rules
1. A variant is the three files `UI-2` defines: `test/support/mirror_web/variants/<name>.ex` (module `Aurora.UixWeb.Test.Mirror.Variants.<Name>`), `test/support/mirror_web/ash/<name>.ex` and `test/support/mirror_web/ctx/<name>.ex`. Its routes are one `RoutesHelper.register_mirror(<Name>, "<slug>", [<sources>])` line in `test/support/app_web/routes.ex`, below the existing `register_mirror` lines.
2. "DSL of `<old file>`" means the `auix_resource_metadata` and `auix_create_ui` calls of that file, moved into the `quote` of the variant's `__using__/1`. `auix_resource_metadata(:x, context: …, schema: …)` and `auix_resource_metadata(:x, ash_resource: …)` become `mirror_resource(:x)`; resource options and `field` lines go in its `do` block, unchanged. For an Ash (blog) source file the row gives the resource and field names to use.
3. A function a layout references (`&__MODULE__.fun/1`) becomes a public function of the variant definition module with `@doc false`, referenced as `&Aurora.UixWeb.Test.Mirror.Variants.<Name>.fun/1`. A handler module a layout names becomes `Aurora.UixWeb.Test.Mirror.Handlers.<SameLastName>` at `test/support/mirror_web/handlers/<name>.ex`, body unchanged.
4. When two sources in one variant give the same resource the same layout type, the row says which list is kept; a positional selector (`nth-child`, `nth-of-type`) of a carried assertion is recomputed for that list.
5. When a row moves a source's DSL to another resource (for example a products test onto `:product_location`), its fields are replaced by fields of that resource with the same type, its seed call by that resource's seed function, and each carried assertion states the same fact about the new resource.

##### Replaced files
| Old file (tests) | Home | Dropped, with the reason |
|---|---|---|
| `test/cases/navigation_test.exs` (10) — kept, amended | S1 | none |
| `test/cases/templates/basic/helpers_navigation_test.exs` (3), `test/cases/routing_components_test.exs` (1) | S1 | none |
| `test/cases_live/navigation_test.exs` (14) | the first five tests → S2; `"a new child navigates to the child route and back to the parent form"`, `"child show and edit links navigate with the parent on the stack"`, `"a new parent with a child list continues on its edit form"` → S3; the other six → S4 | none |
| `test/cases_live/ash_navigation_test.exs` (4, on :ash) | S2, S3 | none |
| `test/cases_live/handler_hooks_index_test.exs` (4), `handler_hooks_form_test.exs` (5), `handler_hooks_show_test.exs` (4) | S5 | `"Test CREATE new, context, basic layout"`, `"Test main edit link"`, `"Test one-to-many relationship UI workflow"`, `"Test one-to-many relationship UI workflow new Product"`: copies of flows `UI-7` S1, S2 and `UI-9` S3 assert; their hook assertions, when a test has one, are carried |
| `test/cases_live/components_index_test.exs` (10), `ash_components_index_test.exs` (1, on :ash) | S6 | none |
| `test/cases_live/components_form_show_test.exs` (8), `ash_components_form_show_test.exs` (1, on :ash) | S7 | none |
| `test/cases/templates/basic/helpers_intent_test.exs` (3) | S7 | none |
| `test/cases_live/component_hooks_test.exs` (3), `test/cases/component_hooks_test.exs` (1) | S8 | none |
| `test/cases/events_test.exs` (8) — kept, amended | S9 | none |
| `test/cases_live/events_test.exs` (19), `ash_events_test.exs` (8, on :ash) | S10 | none |
| `test/cases_live/gettext_domain_test.exs` (2) | S11 | none |
| `test/aurora_uix/helpers/gettext_resolver_test.exs` (3), `test/aurora_uix/templates/basic/gettext_coverage_test.exs` (3) | S11 | none |

After this section the directory `test/aurora_uix/` no longer exists.

##### Modules & components
1. Variants (rules above):

   | Variant · slug | Sources | DSL |
   |---|---|---|
   | `Navigation` · `navigation` | `products`, `product_transactions` | DSL of `test/cases_live/navigation_test.exs`. Beside its `register_mirror` line, four lines as the existing `"/navigation-only-products"` and `"/navigation-except-products"` lines: `Aurora.Uix.RouteHelper.auix_live_resources("/mirror-<ash\|ctx>-navigation-only-products", <Backend>.Navigation.Product, only: [:index, :show])` and the same with `-except-` and `except: [:new, :edit]`, for each backend |
   | `Hooks` · `hooks` | `products`, `product_transactions` | `:product`: the `index_columns` of `test/cases_live/handler_hooks_index_test.exs`; `edit_layout :product` with `edit_handler_module:` and `add_footer_action:` of `handler_hooks_form_test.exs` and `show_handler_module:` of `handler_hooks_show_test.exs`, body `stacked([:reference, :name, :description, :quantity_initial, :product_transactions])`; the `show_layout` of `handler_hooks_form_test.exs` |
   | `Components` · `components` | `products` | DSL of `Aurora.UixWeb.Test.ComponentsIndexTest` (`test/cases_live/components_index_test.exs`) |
   | `ComponentsPaired` · no route | — | the modules `ComponentsPairedViews`, `ComponentsIndexViews` and `ComponentsIndexHandled` of the two components files, merged: `auix_create_ui generate: [:index_component, :form_component, :show_component]` with the `index_columns` and the `edit_layout` of the three |
   | `Events` · `events` | `products`, `product_locations`, `product_transactions` | DSL of `test/cases_live/events_test.exs` |
   | `Gettext` · `gettext` | `products` | DSL of `test/cases_live/gettext_domain_test.exs` |

2. Host LiveViews. `ComponentsPairedHostLive` and `ComponentsIndexPairedHostLive` of the two components files move to `test/support/mirror_web/hosts/paired_form_host_live.ex` and `paired_index_host_live.ex`, as `Aurora.UixWeb.Test.Mirror.Hosts.PairedFormHostLive` and `…PairedIndexHostLive`. Each reads the session key `"backend"` (`"ash"` for Ash, `"ctx"` for Ecto) and renders the component of the `ComponentsPaired` module of that backend, `Aurora.UixWeb.Test.MirrorAsh.ComponentsPaired` and `Aurora.UixWeb.Test.MirrorCtx.ComponentsPaired`, picked by a two-clause private function. `Aurora.UixWeb.Test.ComponentHostLive` (`test/support/app_web/component_host_live.ex`) stays unchanged: a scenario passes the component modules of the current backend in the `"components"` session key. `Aurora.UixWeb.Test.ComponentsIndexHandler` moves under variant rule 3.
3. Handlers moved (variant rule 3): `IndexHandlerHook`, `FormHandlerHook`, `ShowHandlerHook`, `EventsProbeIndexHandler`.
4. Theme: none. `dt/1` strings: none added; S11 asserts existing msgids only.

##### Green tests
1. The scenarios above pass, on both backends where the row says both (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs only this section's test files and the coverage run of AC-C3)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-10:end -->
<!-- section:UI-11:start -->
### UI-11 — UI · tests · backend-specific
Depends on: UI-10

#### Documentation references
- `AGENTS.md` § Testing › Scope and Coverage (a backend-specific test states why)
- `guides/core/ash_integration.md` (no edit)

#### Implementation details

This section rewrites tests and test support only. It changes no file under `lib/`. Every test passes on its first run. Layout types covered: `:index`, `:form`, `:show`, on one backend per test.

Target for this area: 6 tests, S1 to S6. Each covers what one backend alone has, and its file says so in a one-line `@moduledoc`: Ash actors and policies (S1, S2), the Ash query parser (S3), the CRUD dispatcher over both backend modules (S4), Ash calculations and aggregates (S5), `ctx` CRUD function discovery (S6).

##### Acceptance criteria
- [ ] AC-1: S1 asserts, through the generated UI on Ash resources with `Ash.Policy.Authorizer`: create, update and the delete link with the actor in the session, for the `:current_user` and the `:scope` assign; the embeds-many component under an actor; index and new form mount with no actor configured and with the assign absent; a create without an actor shows an error and writes no row
- [ ] AC-2: S2 asserts with no UI: `Aurora.Uix.Integration.Ash.Crud` `list/2`, `create/3`, `update/4`, `delete/3` with and without an actor (`{:error, %Ash.Error.Forbidden{}}`, never a raise); `socket_opts/2`; `CrudSpec.new/0`, `new/3`, `new/4`; the `:ash_actor_assign` and `:actor_assign` options; `Helpers.backend_socket_opts/2`
- [ ] AC-3: S3 asserts the Ash query parser: direction-first `order_by`, nulls directions, Ash sorts and atoms, a single-tuple `where`, an `in` list, a comma-separated `in` value left whole, and an unsupported sort direction returned as an invalid query
- [ ] AC-4: S4 asserts `Aurora.Uix.Integration.Crud.apply_socket_opts/2`: `[]` for a `nil` connector, dispatch to the Ash module for `:ash`, `[]` for `:ctx` and for an Ash connector without `actor_assign`; `Ctx.Crud.socket_opts/2` returns `[]`
- [ ] AC-5: S5 asserts, on `MirrorAsh`: a calculation and each aggregate kind are fields typed from their source, disabled, and added to `auix_preloads` when a layout references them; a `:first` aggregate renders as an index column; the show view renders the calculation value with no manual load
- [ ] AC-6: S6 asserts, on `MirrorCtx`: with no `backend_opts`, the index, create, update and delete of a product run through the functions `ctx_register_schema/2` generates; with `backend_opts: [list_function_paginated: &Aurora.Uix.Test.MirrorCtx.list_products_paginated/1]` the index lists the same rows
- [ ] AC-C1: every file listed under `##### Replaced files` is deleted, with its route registrations, and `mix test` is green (mechanical — no red test; verified by `git diff --name-status origin/main...HEAD -- test` showing a `D` line for each listed file)
- [ ] AC-C2: no file under `lib/` is modified (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- lib` returning nothing)
- [ ] AC-C3: line coverage holds (mechanical — no red test; verified by `.claude/scripts/suite.sh --cover`, then `grep -E '\| Total' /tmp/suite-<branch>.log` showing at least 81.62% and the summary line showing `0 failures`; exit code 3 is the unmet 90% project threshold, as on `main`)

##### Test ports
- Routes of `test/support/app_web/router.ex` live sessions `:actor_current_user` and `:actor_scope`, and `ash-actor-…` routes of `test/support/app_web/routes.ex` · existing; their module prefix changes in step 1
- Routes `/mirror-ash-aggregates-<source>` and `/mirror-ctx-context-functions-products` · new, step 2
- `Aurora.Uix.Integration.Ash.Crud`, `Aurora.Uix.Integration.Ash.CrudSpec`, `Aurora.Uix.Integration.Ash.ContextParserDefaults`, `Aurora.Uix.Integration.Ash.QueryParser`, `Aurora.Uix.Integration.Crud`, `Aurora.Uix.Integration.Ctx.Crud`, `Aurora.Uix.Templates.Basic.Helpers.backend_socket_opts/2` · existing, as the replaced files call them

##### Red tests
Every row passes on first run.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | amend `test/cases_live/ash_actor_policy_test.exs`: its ten tests become one; its views DSL moves to step 1 | `use Aurora.UixWeb.Test.UICase, :phoenix_case`; the `AshActorTest` resources of `test/support/ash_actor/` | same file | S1 `"an Ash actor reaches every action, and a policy denies without one"` | carried assertions |
| AC-2 | amend `test/cases/integration/ash/crud_policy_test.exs`: its ten tests become one | the resources that file declares | same file | S2 `"Ash CRUD forwards the actor and returns Forbidden without one"` | carried assertions of the five files in the S2 row below |
| AC-3 | amend `test/cases/integration/ash/query_parser_test.exs`: its seven tests become one | as the file has it | same file | S3 `"the Ash query parser translates order_by and where"` | carried assertions |
| AC-4 | amend `test/cases/integration/crud_test.exs`: its four tests become one | as the file has it | same file | S4 `"the CRUD dispatcher picks the backend module"` | carried assertions, plus the one of `test/cases/integration/ctx/crud_test.exs` |
| AC-5 | new file (`ls test/cases_live \| grep -x ash_aggregates_test.exs` returns nothing) | `use Aurora.UixWeb.Test.UICase, :scenario_case`; `each_backend([:ash], …)`; `create_sample_product_locations(1, :test)` and three products in that location with `discontinued_at` set | `test/cases_live/ash_aggregates_test.exs` (module `Aurora.UixWeb.Test.AshAggregatesTest`) | S5 `"Ash calculations and aggregates are typed fields that render in index, form and show"` | carried assertions — names: `author` → `product_location`, `posts` → `products`, `posts_count` → `products_count`, `latest_post_title` → `latest_product_name`, `post_titles` → `product_names`, `last_published_at` → `last_discontinued_at`, `post` → `product`, `summary` → `summary` |
| AC-6 | new file (`ls test/cases_live \| grep -x ctx_context_functions_test.exs` returns nothing) | `use Aurora.UixWeb.Test.UICase, :scenario_case`; `each_backend([:ctx], …)`; `create_sample_products(3, :test)` | `test/cases_live/ctx_context_functions_test.exs` (module `Aurora.UixWeb.Test.CtxContextFunctionsTest`) | S6 `"a ctx resource runs its CRUD through the context functions"` | on `/mirror-ctx-default-products`: three rows; create through `/new`, edit, delete, each read back with `Repo`; on `/mirror-ctx-context-functions-products`: the same three references |

##### Carry rules
These rules apply to every row of `##### Replaced files`.
1. `file → S` means: scenario `S` makes every assertion of every test of that file, except the tests the row lists under Dropped. The old file is the source of the selectors, the input names and the drives.
2. Re-pointing an Ecto (inventory) test: a guide module becomes the `MirrorCtx` / `MirrorAsh` module of the same last name; a route becomes `mirror_path(backend, "<variant slug>", "<source>", "<suffix>")`; a seed call keeps its name and arguments (`Aurora.Uix.Test.Mirror.Seeds`); a `delete_all_*_data()` call is removed, because `each_backend/2` empties the mirror tables. Selectors, input names and element names stay as written.
3. `on :ash` in a row means the file is the Ash twin of an Ecto file in the same row: its assertions are the Ecto ones, and the scenario makes them on `:ash` by running there. A test listed as `Ash-only` has no Ecto twin: carry it with the name map the row gives, and assert it on both backends.
4. An assertion on an `auix-field-*` id, and an `=~` on rendered HTML, is rewritten as `has_element?/2` on the same element, selected by the first of these it has: its `name` attribute, its input name, its `auix-*` class.
5. Every scenario also asserts the structure its row lists, on both backends.
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing>: <what happens>`, and list it under "Library defects found" in the section log. Never change a file under `lib/`.
7. Delete each replaced file with `git rm`. Remove from `test/support/app_web/routes.ex` every registration whose module argument starts with the test module of a deleted file. A module a deleted file defines beside its test module moves as `##### Modules & components` of this section says.
8. A views variant declares only the resources and layouts its scenarios mount, and each generated module is mounted by a scenario: an unmounted generated module is a missed line in the coverage total.

##### Replaced files
| Old file (tests) | Home | Dropped, with the reason |
|---|---|---|
| `test/cases_live/ash_actor_policy_test.exs` (10) — kept, amended | S1 | none |
| `test/cases/integration/ash/crud_policy_test.exs` (10) — kept, amended | S2 | none |
| `test/cases/integration/ash/crud_test.exs` (6), `crud_spec_test.exs` (4), `context_parser_defaults_actor_test.exs` (4) | S2 | none |
| `test/cases/templates/basic/helpers_actor_test.exs` (4) | S2 | none |
| `test/cases/integration/ash/query_parser_test.exs` (7) — kept, amended | S3 | none |
| `test/cases/integration/crud_test.exs` (4) — kept, amended | S4 | none |
| `test/cases/integration/ctx/crud_test.exs` (1) | S4 | none |
| `test/cases_live/ash_embeds_test.exs` (9) | the six tests from `"Validate that summary calculation is a good resource"` on → S5; the first three are covered by `UI-9` S8, S9, S10 | none |

##### Modules & components
1. Actor views. The `auix_resource_metadata` and `auix_create_ui` calls of `test/cases_live/ash_actor_policy_test.exs` move to `Aurora.UixWeb.Test.AshActorViews` at `test/support/ash_actor/views.ex` (`@moduledoc false`, `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`). In `test/support/app_web/router.ex` and `test/support/app_web/routes.ex`, each `AshActorPolicyTest.` module prefix becomes `AshActorViews.`. The test module keeps its name and its tests.
2. Backend views, each one file, no variant definition:
   - `Aurora.UixWeb.Test.MirrorAsh.Aggregates` at `test/support/mirror_web/ash/aggregates.ex`: `use Aurora.UixWeb.Test.Mirror, backend: :ash`; the DSL of `test/cases_live/ash_embeds_test.exs` with the names of the S5 row, without its `tags` and `comment` fields. Route line: `RoutesHelper.register_crud(MirrorAsh.Aggregates.ProductLocation, "mirror-ash-aggregates-product_locations")` and the same for `Product` with `…-products`.
   - `Aurora.UixWeb.Test.MirrorCtx.ContextFunctions` at `test/support/mirror_web/ctx/context_functions.ex`: `Module.register_attribute(__MODULE__, :auix_resource_metadata, persist: true)`, `use Aurora.Uix`, `auix_resource_metadata(:product, context: Aurora.Uix.Test.MirrorCtx, schema: Aurora.Uix.Test.MirrorCtx.Product, backend_opts: [list_function_paginated: &Aurora.Uix.Test.MirrorCtx.list_products_paginated/1])`, `auix_create_ui do index_columns(:product, [:reference, :name]) end`. Route line: `RoutesHelper.register_crud(MirrorCtx.ContextFunctions.Product, "mirror-ctx-context-functions-products")`.
3. Theme: none. `dt/1` strings: none.

##### Green tests
1. The scenarios above pass, on both backends where the row says both (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs only this section's test files and the coverage run of AC-C3)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-11:end -->
<!-- section:UI-12:start -->
### UI-12 — UI · tests · theme and assets
Depends on: UI-11

#### Documentation references
- `AGENTS.md` § CSS / Assets, § Testing › Scope and Coverage (theme tests do not restate CSS)
- `guides/customization/theming.md`, `guides/customization/styling.md` (no edit)

#### Implementation details

This section rewrites tests only. It changes no file under `lib/` and no theme rule. Every test passes on its first run. Layout types: none. No database.

Target for this area: 5 tests, S1 to S5.

Facts this section builds on, measured on `main` at 25a9ae6:
- `Aurora.Uix.Templates.Basic.Themes.WhiteCharcoal`, `VitreousMarble` and `BlueGraphite` each return 236 names from `rule_names/0`, all distinct, and 236 rules from `rules/0`, none with empty CSS.
- Every one of the 213 `var(--…)` names in `ThemeHelper.generate_rules_stylesheet/0` is declared: in `ThemeHelper.generate_variables_stylesheet/0` for most, in the rules stylesheet itself for the rest.

The rewritten tests must not depend on test order: no test creates the named ETS table of `Aurora.Uix.Templates.CssSanitizer`, and none assumes it exists; the test file is not `async`, and each test reaches the sanitizer only through `ThemeHelper` and the theme modules.

##### Acceptance criteria
- [ ] AC-1: S1 asserts the stylesheet task in a temporary directory: the default run writes the variables, rules and combined files and neither the custom file nor the baseline file; `--baseline` and `--custom` each create their file once, keep it on a second run, and overwrite it with `--force`; the two flags are independent
- [ ] AC-2: S2 asserts, for each of the three theme modules: `rules/0` lists each name of `rule_names/0` once, in that order, each with non-empty CSS; the rules stylesheet holds `.auix-` selectors and no `:root` block, the variables stylesheet the reverse, and both halves recombine to `generate_stylesheet/0`; the daisyUI bridge file is shipped
- [ ] AC-3: S3 asserts that every `var(--name)` the rules stylesheet uses is declared, and that each theme declares, light and dark, every color variable `WhiteCharcoal` declares, under selectors scoped to its theme name
- [ ] AC-4: S4 asserts the sanitizer: `resize` keeps its six keywords and drops any other value; `content` keeps one plain quoted string and drops any other value
- [ ] AC-5: S5 asserts the theme DSL: a local rule replaces an included one and keeps its place; `import_rule` copies and renames; an unknown rule name gives empty CSS; and, table-driven, each declaration that must fail compilation fails with its message
- [ ] AC-C1: every file listed under `##### Replaced files` is deleted, with its route registrations, and `mix test` is green (mechanical — no red test; verified by `git diff --name-status origin/main...HEAD -- test` showing a `D` line for each listed file)
- [ ] AC-C2: no file under `lib/` is modified (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- lib` returning nothing)
- [ ] AC-C3: line coverage holds (mechanical — no red test; verified by `.claude/scripts/suite.sh --cover`, then `grep -E '\| Total' /tmp/suite-<branch>.log` showing at least 81.62% and the summary line showing `0 failures`; exit code 3 is the unmet 90% project threshold, as on `main`)

##### Test ports
- `Mix.Tasks.Auix.Gen.Stylesheet.run/1`, as `test/mix/tasks/auix/gen/stylesheet_test.exs` runs it · existing
- `Aurora.Uix.Templates.ThemeHelper` `generate_stylesheet/0`, `generate_variables_stylesheet/0`, `generate_rules_stylesheet/0` (`lib/aurora_uix/templates/theme_helper.ex`); `rules/0`, `rule_names/0`, `theme_name/0` of a theme module (`lib/aurora_uix/templates/theme.ex`) · existing
- The theme DSL compiled with `Code.compile_string/1`, as `test/cases/templates/theme_rules_test.exs` compiles it · out: `Spark.Error.DslError`

##### Red tests
Every row passes on first run.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | amend `test/mix/tasks/auix/gen/stylesheet_test.exs`: its ten tests become one | the file's own `setup` | same file | S1 `"the stylesheet task writes its files and honours --baseline, --custom and --force"` | carried assertions |
| AC-2 | new file (`ls test/cases/templates \| grep -x theme_test.exs` returns nothing) | `use ExUnit.Case` | `test/cases/templates/theme_test.exs` (module `Aurora.Uix.Test.Cases.ThemeTest`) | S2 `"every theme emits every rule once and the stylesheet splits cleanly"` | `for theme <- themes do assert Enum.map(theme.rules(), & &1.name) == theme.rule_names(); assert theme.rule_names() == Enum.uniq(theme.rule_names()); refute Enum.any?(theme.rules(), &(&1.css in [nil, ""])) end`; carried split and bridge assertions |
| AC-3 | add to `theme_test.exs` | as S2 | same | S3 `"every variable a rule uses is declared, in each theme, light and dark"` | `used = Regex.scan(~r/var\((--[a-zA-Z0-9_-]+)/, rules)`; `declared = Regex.scan(~r/(--[a-zA-Z0-9_-]+)\s*:/, variables <> rules)`; `assert used -- declared == []`; carried per-theme declarations |
| AC-4 | add to `theme_test.exs` | as S2 | same | S4 `"the sanitizer keeps allowed values and drops the rest"` | carried assertions |
| AC-5 | add to `theme_test.exs` | `compile/1` of `theme_rules_test.exs` | same | S5 `"the theme DSL replaces, imports and rejects rules"` | carried assertions; the five `fails compilation` tests become cases `{label, body, regex}` |

##### Carry rules
These rules apply to every row of `##### Replaced files`.
1. `file → S` means: scenario `S` makes every assertion of every test of that file, except the tests the row lists under Dropped. The old file is the source of the selectors, the input names and the drives.
2. Re-pointing an Ecto (inventory) test: a guide module becomes the `MirrorCtx` / `MirrorAsh` module of the same last name; a route becomes `mirror_path(backend, "<variant slug>", "<source>", "<suffix>")`; a seed call keeps its name and arguments (`Aurora.Uix.Test.Mirror.Seeds`); a `delete_all_*_data()` call is removed, because `each_backend/2` empties the mirror tables. Selectors, input names and element names stay as written.
3. `on :ash` in a row means the file is the Ash twin of an Ecto file in the same row: its assertions are the Ecto ones, and the scenario makes them on `:ash` by running there. A test listed as `Ash-only` has no Ecto twin: carry it with the name map the row gives, and assert it on both backends.
4. An assertion on an `auix-field-*` id, and an `=~` on rendered HTML, is rewritten as `has_element?/2` on the same element, selected by the first of these it has: its `name` attribute, its input name, its `auix-*` class.
5. Every scenario also asserts the structure its row lists, on both backends.
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing>: <what happens>`, and list it under "Library defects found" in the section log. Never change a file under `lib/`.
7. Delete each replaced file with `git rm`. Remove from `test/support/app_web/routes.ex` every registration whose module argument starts with the test module of a deleted file. A module a deleted file defines beside its test module moves as `##### Modules & components` of this section says.
8. A views variant declares only the resources and layouts its scenarios mount, and each generated module is mounted by a scenario: an unmounted generated module is a missed line in the coverage total.

##### Replaced files
| Old file (tests) | Home | Dropped, with the reason |
|---|---|---|
| `test/mix/tasks/auix/gen/stylesheet_test.exs` (10) — kept, amended | S1 | none |
| `test/cases/templates/theme_helper_test.exs` (8) | the three `split stylesheet generation` tests on the halves and the bridge test → S2; `"every opacity variable is a separately terminated numeric declaration"` → S3 | `"checkbox-group and selected-list labels keep their nowrap declaration"`, `"group-title and empty-state sizes do not resolve through the page title"`, `"declares the framing sizes"`: each restates CSS declarations (issue, Expected behaviour 7) |
| `test/cases/templates/theme_rules_test.exs` (32) | `describe "rules/0"` (3) → S2; `"both themes declare the status, selection and focus-halo colors, light and dark"`, `"is registered as :blue_graphite"`, `"declares every White Charcoal color, light and dark"`, `"leaves White Charcoal as the default theme"`, `"reaches the variables stylesheet"`, `"scopes every selector to its theme name"` → S3; `describe "theme DSL"` (8) → S5 | `"White Charcoal uses rose-500 error borders and rose-700 error text"`, `"each flash variant reads its own colors"`, `"uses a navy primary, light and dark"`, and the twelve tests of `action icon rules`, `card rules` and `sort control rules`: each restates CSS values (issue, Expected behaviour 7) |
| `test/cases/templates/theme_framing_test.exs` (22) | none | all 22: each asserts the CSS text of one rule (issue, Expected behaviour 7); that every rule is emitted with non-empty CSS is asserted by S2 |
| `test/cases/templates/css_sanitizer_test.exs` (4) | S4 | `"the text area rule keeps its resize declarations"`, `"the loading button keeps its spinner box"`: each restates the CSS of one rule; the sanitizer cases they rely on are the other two tests |

##### Modules & components
1. No views variant, no route, no theme rule, no `dt/1` string.
2. `test/cases/templates/theme_test.exs` — new, four tests (S2 to S5).

##### Green tests
1. The scenarios above pass, on both backends where the row says both (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs only this section's test files and the coverage run of AC-C3)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-12:end -->
<!-- section:UI-13:start -->
### UI-13 — UI · tests · browser; unused support retired; final count and coverage
Depends on: UI-12

#### Documentation references
- `AGENTS.md` § Testing › LiveView vs. Wallaby, › Test Case Modules
- `CONTRIBUTING.md § Creating Sample Data`, `§ Wallaby Setup` (no edit)

#### Implementation details

This section rewrites the Wallaby tests, deletes the test support nothing uses any more, and checks the whole suite. It changes no file under `lib/`. Every test passes on its first run. Layout types covered: `:index`, `:form`, `:show`, in a browser.

Target for this area: 5 features, S1 to S5, in `test/browser_cases/browser_scenarios_test.exs` (module `Aurora.UixWeb.Test.BrowserScenariosTest`, new: `ls test/browser_cases | grep -x browser_scenarios_test.exs` returns nothing). The module has `use Aurora.UixWeb.Test.UICase, :scenario_case` and `use Wallaby.Feature`. Each feature runs its body in `each_backend/2` and visits `mirror_path/4` routes.

Why Wallaby, stated in a comment above each feature: S1 and S2 drive the embeds-many JS (the add-entry modal and the entry list live in a client-managed portal); S3 sends a file through the browser's live upload channel, which `Phoenix.LiveViewTest` replaces with its own client; S4 drives the modal's client-side close (backdrop, Escape) that `Phoenix.LiveViewTest` cannot press; S5 loads the fallback routes with a full page load.

A feature depends neither on another feature's rows nor on test order: each backend run starts from `delete_all_mirror_data/0` and creates its own rows. The second old feature of `test/browser_cases/embeds_many_test.exs` fails intermittently on `main`; its rewrite waits for each element with a Wallaby query (`assert_has/2`) before it clicks, and never reads a counter id.

##### Acceptance criteria
- [ ] AC-1: S1 creates a product with no contact through the browser, on both backends, and the saved product has no contact
- [ ] AC-2: S2 creates a product, opens the embeds-many details, adds two contacts through the add-entry modal, removes one, saves, and the saved product has the one contact left
- [ ] AC-3: S3 attaches a file to the `image` field of the `Uploads` variant in the browser, sees its `.auix-upload-entry`, saves, and the stored `image` of the product is the value the `consume` callback returns; saving with no file attached keeps the stored value
- [ ] AC-4: S4 opens the edit modal, changes a field, closes with Escape, sees the discard dialog, keeps editing, then discards, and the row is unchanged
- [ ] AC-5: S5 loads `/new`, `/<id>/show`, `/<id>/show-edit` and `/<id>/edit` of the `Default` variant with a full page load, and each renders its modal over the index
- [ ] AC-6: the suite has fewer than 100 tests (mechanical — no red test; verified by `.claude/scripts/suite.sh --cover` and the summary line of `/tmp/suite-<branch>.log`: its `features` count plus its `tests` count is below 100)
- [ ] AC-7: no test file declares a views module, and no test reads a guide schema except `test/cases_live/guides_test.exs` (mechanical — no red test; verified by `grep -rln "auix_create_ui\|auix_resource_metadata" test/cases test/cases_live test/browser_cases` listing only `test/cases/generation_test.exs`, `test/cases/resource_metadata_test.exs` and `test/cases_live/mirror_fixture_test.exs`, and `grep -rln "Aurora.Uix.Guides" test/cases test/cases_live test/browser_cases` listing only `test/cases_live/guides_test.exs`)
- [ ] AC-C1: every file listed under `##### Replaced files` is deleted, with its route registrations, and `mix test` is green (mechanical — no red test; verified by `git diff --name-status origin/main...HEAD -- test` showing a `D` line for each listed file)
- [ ] AC-C2: no file under `lib/` is modified (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- lib` returning nothing)
- [ ] AC-C3: line coverage holds (mechanical — no red test; verified by `.claude/scripts/suite.sh --cover`, then `grep -E '\| Total' /tmp/suite-<branch>.log` showing at least 81.62% and the summary line showing `0 failures`; exit code 3 is the unmet 90% project threshold, as on `main`)

##### Test ports
- Mirror routes `/mirror-<ash|ctx>-embeds-products`, `/mirror-<ash|ctx>-uploads-products`, `/mirror-<ash|ctx>-form-products`, `/mirror-<ash|ctx>-default-products` (variants of `UI-9`, `UI-7`, `UI-2`) · observable: Wallaby `visit/2`, `click/2`, `fill_in/3`, `attach_file/3`, `send_keys/2`, `assert_has/2`, `refute_has/2`; persisted rows through `Aurora.Uix.Repo`

##### Red tests
Every row passes on first run. Test file for every row: `test/browser_cases/browser_scenarios_test.exs`. Placement: the first row is `new file`; the others are `add to` that file.

| AC | Variant · setup | Test name | Assertion sketch |
|---|---|---|---|
| AC-1 | `Embeds` · none | S1 `"a product is created without embeds-many entries"` | carried drives of the first feature of `test/browser_cases/embeds_many_test.exs` |
| AC-2 | `Embeds` · none | S2 `"embeds-many entries are added and removed in the browser"` | carried drives of the second feature of the same file |
| AC-3 | `Uploads` · `create_sample_products(1, :test)` | S3 `"a file chosen in the browser uploads and is consumed on save"` | visit the edit route; click save with no file and assert the stored `image` is unchanged; `attach_file/3` on the `input[type='file']` of the `image` field, located as S9 of `UI-7` locates it, with `path:` a `.png` file the feature writes under `System.tmp_dir!()` and removes with `on_exit/1`; `assert_has(session, Query.css(".auix-upload-entry"))`; click `button[name='auix-save-product']`; read the row with `Repo` |
| AC-4 | `Form` · `create_sample_products(1, :test)` | S4 `"the edit modal closes through the discard dialog"` | `send_keys(session, [:escape])`; `assert_has(session, Query.css("#auix-product-discard-confirm-modal"))`; click `[name='auix-keep-editing']`; Escape again; click `[name='auix-discard-changes']`; `refute_has` on the modal |
| AC-5 | `Default` · `create_sample_products(1, :test)` | S5 `"the default routes open their modal on a full page load"` | carried drives of the four features of `test/browser_cases/create_ui_default_layout_test.exs` |

##### Carry rules
These rules apply to every row of `##### Replaced files`.
1. `file → S` means: scenario `S` makes every assertion of every test of that file, except the tests the row lists under Dropped. The old file is the source of the selectors, the input names and the drives.
2. Re-pointing an Ecto (inventory) test: a guide module becomes the `MirrorCtx` / `MirrorAsh` module of the same last name; a route becomes `mirror_path(backend, "<variant slug>", "<source>", "<suffix>")`; a seed call keeps its name and arguments (`Aurora.Uix.Test.Mirror.Seeds`); a `delete_all_*_data()` call is removed, because `each_backend/2` empties the mirror tables. Selectors, input names and element names stay as written.
3. `on :ash` in a row means the file is the Ash twin of an Ecto file in the same row: its assertions are the Ecto ones, and the scenario makes them on `:ash` by running there. A test listed as `Ash-only` has no Ecto twin: carry it with the name map the row gives, and assert it on both backends.
4. An assertion on an `auix-field-*` id, and an `=~` on rendered HTML, is rewritten as `has_element?/2` on the same element, selected by the first of these it has: its `name` attribute, its input name, its `auix-*` class.
5. Every scenario also asserts the structure its row lists, on both backends.
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing>: <what happens>`, and list it under "Library defects found" in the section log. Never change a file under `lib/`.
7. Delete each replaced file with `git rm`. Remove from `test/support/app_web/routes.ex` every registration whose module argument starts with the test module of a deleted file. A module a deleted file defines beside its test module moves as `##### Modules & components` of this section says.
8. A views variant declares only the resources and layouts its scenarios mount, and each generated module is mounted by a scenario: an unmounted generated module is a missed line in the coverage total.

##### Replaced files
| Old file (tests) | Home | Dropped, with the reason |
|---|---|---|
| `test/browser_cases/embeds_many_test.exs` (2) | S1, S2 — names: `user` → `product`, `emails` → `contacts`, `given_name` → `reference`, `family_name` → `name` | none |
| `test/browser_cases/ash_embeds_test.exs` (2, on :ash) | S1, S2 | none |
| `test/browser_cases/create_ui_default_layout_test.exs` (4) | S5 | none |

S3 and S4 replace no file: the issue's Target suite names the upload JS and the modal for the browser area.

##### Modules & components
1. No new variant. Routes: none added.
2. Delete from `test/support/app_web/routes.ex` every registration left that names a module no file defines; after this step `load_test_routes/0` holds the `register_mirror` lines, the `auix_live_resources` lines of the `Named` and `Navigation` variants, the `ManualResource`, `Aggregates` and `ContextFunctions` lines, the `AshActorViews` line, the five `GuidesCapture` lines and the `-local-demo` block. `register_user_crud/2` in `test/support/app_web/routes_helper.ex` has no caller left and is deleted; `register_product_crud/2` stays for the `-local-demo` block and the capture routes.
3. `test/support/helper.ex` keeps `create_guides_sample_data/0`, `create_sample_products/3`, `create_sample_products_with_transactions/4`, `create_sample_product_locations/2`, `create_sample_authors/2`, `create_sample_categories/2`, `create_sample_posts/2`, `delete_all_inventory_data/0`, `delete_all_accounts_data/0`, `delete_all_blog_data/0`, `delete_all_sample_data/0` and the private functions they call. Delete `create_sample_users/2`, `create_sample_products_with_suppliers/2`, `create_sample_posts_with_topics/2`, `create_sample_products_with_barcodes/1`, `create_sample_authors_with_profiles/1` and `to_boolean/1`, with their `@doc` and `@spec`.
4. In `mix.exs`, `xref(:test)` stays as it is: every file of `test/cases_live/` still has one `defmodule … Test do` line.
5. `test/test_templates/cases_live/local-demo_test_example.exs` stays.
6. In `AGENTS.md` § Testing › Test layers, replace the row `| `test/cases/` | resource metadata, layout/blueprint generation | no |` with `| `test/cases/` | resource metadata, generation, navigation, events, theme | no |`.
7. Theme: none. `dt/1` strings: none.

##### Green tests
1. The scenarios above pass, on both backends where the row says both (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs only this section's test files and the coverage run of AC-C3)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-13:end -->

---

### Out of Scope
- Any change to library behaviour under `lib/aurora_uix/`. A defect a scenario finds is listed in its section log and becomes a separate issue.
- Judging how the UI looks: a human reviews the regenerated guide images.
- The library causes of the intermittent failures on `main`: the named ETS table of `Aurora.Uix.Templates.CssSanitizer`, the leftover PubSub subscriber, the embeds-many browser feature. The rewritten tests carry no order dependence (`UI-10`, `UI-12`, `UI-13`).
- `DOC-1` and a CHANGELOG entry: the issue delivers neither a feature nor a fix, and no file of the documentation set changes.
- The guide and demo modules (`lib/aurora_uix/guides/`, `lib/aurora_uix_web/guides/`) and the guide image capture scripts, apart from the views the layout capture script loads (`UI-5`).
- The golden-map parser tests, `test/cases/integration/fields_parser_validations_test.exs` and the doctests (`test/doctests/uix/doc_test.exs`, `test/doctests/uix/parsers_doc_test.exs`): unchanged.
- Parser sections: the issue changes no parser. The mirrored fixture and every scenario cover the Ash and the Ecto backend alike; the six backend-specific tests of `UI-11` cover what one backend alone has.
- CSS text of single theme rules: no test restates it.
<!-- enriched-spec:end -->
