<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** high

### Overview
This issue replaces the 710 tests and 8 browser features with fewer than 100 scenario tests over one mirrored fixture: one set of tables in the PostgreSQL schema `mirror`, an Ecto schema and an Ash resource over each table, and views modules in `test/support`. Every scenario runs on `:ash` and on `:ctx`, except the backend-specific ones the issue names. `UI-2` also corrects one `order_by` in the demo views module `lib/aurora_uix_web/guides/overview.ex`, and `DOC-1` records that fix in the CHANGELOG; `AGENTS.md` and the `.claude/skills` files are outside the documentation set and are edited by `UI-3`.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | `CHANGELOG.md` § `## [0.2.1]` | none | federico/569-doc-1-changelog | docs: record the guide overview order fix (#569 · DOC-1) |
| UI-1 | UI | test support · mirrored fixture: migration, Ecto schemas and context, Ash resources and domain, seeds, fixture test | none | federico/569-ui-1-mirror-fixture | test: add the mirrored Ecto and Ash test fixture (#569 · UI-1) |
| UI-2 | UI | test support · scenario harness, views variants, mirror routes, default-layout scenario, guide pages test; the `order_by` of the demo views | UI-1, DOC-1 | federico/569-ui-2-scenario-harness | test: add the scenario harness and the mirrored views (#569 · UI-2) |
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

<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
- `CHANGELOG.md` § `## [0.2.1]`

#### Implementation details

`UI-2` corrects the `order_by` of the product transactions index in the demo views module `lib/aurora_uix_web/guides/overview.ex`. This section records that fix. It edits `CHANGELOG.md` only.

No guide owes an edit: the sample of `guides/overview/overview.md § Complete Example` has no `index_columns` call for `:product_transaction`, and every hit of `rg -n "order_by: :reference" guides` (`guides/core/layouts.md`, `guides/core/liveview.md`) is a `:product` sample, which stays correct.

##### CHANGELOG.md
1. § `## [0.2.1]` — this version has no `### Fixed` heading yet (`## [0.2.0]` and `## [0.1.7]` name theirs `### Fixed`). Directly above the line `### Build` of `## [0.2.1]`, insert verbatim, followed by one blank line:
   ```
   ### Fixed

   - **Guide overview demo**: the product transactions index of the demo views ordered its rows by `reference`,
     a column that table does not have, and raised when the page loaded. It orders them by `inserted_at`.
   ```

##### Acceptance criteria
- [x] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no
      issue-link suffix (mechanical — no red test; verified by
      `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [x] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-569-enriched-spec.md`)
- [x] AC-3: `## [0.2.1]` carries `### Fixed` between `### Changed` and `### Build`, holding the one entry above (mechanical — no red test; verified by `awk '/^## \[0.2.1\]/{f=1} /^## \[0.2.0\]/{f=0} f && /^### /' CHANGELOG.md` printing `### Added`, `### Changed`, `### Fixed`, `### Build` in that order, and `grep -c "Guide overview demo" CHANGELOG.md` printing `1`)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->
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
Depends on: UI-1, DOC-1

#### Documentation references
- `AGENTS.md` § Testing, § Phoenix / LiveView Rules
- `guides/core/layouts.md`, `guides/core/liveview.md § Using Generated Modules with Routes` (no edit)

#### Implementation details

This section adds test support and two tests, and corrects one line of one demo views module (step 7). That line is its only change under `lib/`; it changes no file under `lib/aurora_uix/`. The scenario test passes on its first run. The guides test fails until step 7 is applied, then passes.

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
- `lib/aurora_uix_web/guides/overview.ex`, inside `auix_create_ui`, holds `index_columns(:product_transaction, [:type, :quantity, :cost], order_by: :reference)`. `Aurora.Uix.Guides.Inventory.ProductTransaction` (`lib/aurora_uix/guides/inventory/product_transaction.ex`) has the fields `id`, `type`, `quantity`, `cost`, `product_id`, `inserted_at` and `updated_at`, and no `reference`. Proven on `main` at 740dfae with a probe over the 24 mounts of AC-4: the four routes of `/guides-overview/product_transactions` raise `Postgrex.Error` (`column p0.reference does not exist`) and the other 20 mount; with `order_by: :inserted_at` all 24 return `{:ok, view, _}` and render `.auix-index-container`.
- That `order_by` reaches the product transactions index only. The product transactions list inside the product show and edit views reads the `order_by` of its own field (`lib/aurora_uix/templates/basic/renderers/fields/one_to_many.ex`, `load_rows/1`), and no guide capture script visits `/guides-overview/product_transactions` (`test/guides/capture_overview_images.exs` visits `/guides-overview/products`, `test/guides/capture_ash_images.exs` visits `/guides-overview/posts`). No guide image changes.
- `lib/aurora_uix_web/` is demo code: `mix.exs` excludes it from the Hex package (`exclude_patterns`) and from the generated docs.

New names in this section (search `rg -n "Test\.Scenario|UixWeb\.Test\.Mirror(\b|Ash|Ctx)|each_backend|register_mirror|mirror_resource|mirror_path|scenario_case|GuidesTest|LayoutScenariosTest" lib test mix.exs` returns nothing): every module, macro and function below.

##### Acceptance criteria
- [x] AC-1: Given the `Default` variant, for each backend and each of `products`, `product_locations`, `product_transactions`, `product_barcodes`, `suppliers`: the index, `/new`, `/<id>/show` and `/<id>/edit` routes mount and render `.auix-index-container`; the new and edit routes render `.auix-form-container` inside `#auix-<resource>-<action>-modal`; the show route renders `.auix-show-container`
- [x] AC-2: Given an index with no row, each backend renders `.auix-index-container` and no `.auix-items-table-row`
- [x] AC-3: `Scenario.each_backend/2` deletes every mirror row before each backend runs, and a failed assertion names the backend in its message (covered by the tests of AC-1: the second backend starts from an empty index)
- [x] AC-4: Given one inventory product, one location, one author, one category and one post created with `test/support/helper.ex`, each guide route of `Aurora.UixWeb.Routes.load_routes/0` under `/guides-overview` mounts its index, `/new`, `/<id>/show` and `/<id>/edit`
- [x] AC-5: under `lib/`, the branch changes `lib/aurora_uix_web/guides/overview.ex` only, and in that file the one `index_columns(:product_transaction, …)` line of step 7; no file under `lib/aurora_uix/` is modified (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- lib` printing `lib/aurora_uix_web/guides/overview.ex` alone, and `git diff -U0 origin/main...HEAD -- lib | grep -cE '^[+-][^+-]'` printing `2`)
- [x] AC-6: line coverage holds (mechanical — no red test; verified by `.claude/scripts/suite.sh --cover`, then `grep -E '\| Total' /tmp/suite-<branch>.log` showing at least 81.62% and the summary line showing `0 failures`; exit code 3 is the unmet 90% project threshold, as on `main`)

##### Test ports
- Routes registered in `test/support/app_web/routes.ex` `load_test_routes/0` with the new `RoutesHelper.register_mirror/3` (step 4): `/mirror-<ash|ctx>-default-<source>` for the five sources of AC-1 · layout types `:index`, `:form`, `:show` · observable: `has_element?/2`
- Guide routes, existing: `/guides-overview/products`, `/guides-overview/product-locations`, `/guides-overview/product_transactions`, `/guides-overview/posts`, `/guides-overview/authors`, `/guides-overview/categories` (`lib/aurora_uix_web/routes.ex`, `load_routes/0`, mounted by `test/support/app_web/router.ex` scope `"/guides-overview"`)

##### Red tests
Row AC-1, AC-2, AC-3 passes on first run. Row AC-4 is red before step 7: the four mounts of `/guides-overview/product_transactions` raise `Postgrex.Error` (`column p0.reference does not exist`). It passes once step 7 is applied.

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

7. **Demo views.** In `lib/aurora_uix_web/guides/overview.ex`, inside `auix_create_ui`, replace the line
   `index_columns(:product_transaction, [:type, :quantity, :cost], order_by: :reference)` with
   `index_columns(:product_transaction, [:type, :quantity, :cost], order_by: :inserted_at)`.
   Every other line of the file stays. This is the one edit under `lib/` of this section. `CHANGELOG.md` is not edited here: `DOC-1` carries the entry.

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

This section edits agent guidance only: `AGENTS.md` and five files under `.claude/skills/`. None of them is in the documentation set (`CHANGELOG.md`, `README.md`, `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md`), so `DOC-1` carries none of these edits. It changes no file under `lib/` and no test. Layout types: none.

Every edit below replaces the quoted text with the given text. Text outside the quotes stays.

##### Acceptance criteria
- [x] AC-1: `AGENTS.md` § Testing › Scope and Coverage states the scenario rule and no longer says "Each test should assert one behavior clearly" (mechanical — no red test; verified by `grep -c "assert one behavior" AGENTS.md` returning `0` and `grep -c "One scenario per feature, on both backends" AGENTS.md` returning `1`)
- [x] AC-2: `AGENTS.md` names the mirrored fixture as the source of test data (mechanical — no red test; verified by `grep -c "test/support/mirror" AGENTS.md` returning at least `4`)
- [x] AC-3: no skill tells the coder to seed tests from the guide schemas, and none tells it to write one test per acceptance criterion (mechanical — no red test; verified by `grep -rn "create_sample_products/2" .claude/skills` returning nothing and `grep -c "Every Parser and UI AC has a red-test row" .claude/skills/improve-issue/SKILL.md` returning `0`)
- [x] AC-4: an edit whose quoted text is absent from its file stops the section with a spec defect, and no partial rewording is committed (mechanical — no red test; verified by `git diff --stat origin/main...HEAD` listing exactly the six files of this section and the spec file)

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
- [x] AC-1: the four golden-map tests and `fields_parser_validations_test.exs` are unchanged (mechanical — no red test; verified by `git diff origin/main...HEAD -- test/cases/integration/fields_parser_validations_test.exs` returning nothing and both `"Validate …"` tests of each parser file passing)
- [x] AC-2: S1 asserts, for the Ash parser, every enum flavour, every aggregate kind and the generated-field flags the replaced tests assert
- [x] AC-3: S2 asserts `sortable?` and `embedded_schema?/1` for both parsers, including a key the resource does not define and a module that is neither a schema nor a resource
- [x] AC-4: S3 asserts the resource defaults, the field overrides, the field order and the `generated?` loading on both backends
- [x] AC-5: S4 asserts that `resource:` and a declared resource link embedded fields and associations to resources, on both backends
- [x] AC-6: S5 is one table-driven test: each case is `{label, source body, message regex}`; each replaced compile-error test is one case; a case that compiles fails the test with its label
- [x] AC-C1: every file listed under `##### Replaced files` is deleted, with its route registrations, and `mix test` is green (mechanical — no red test; verified by `git diff --name-status origin/main...HEAD -- test` showing a `D` line for each listed file)
- [x] AC-C2: no file under `lib/` is modified (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- lib` returning nothing)
- [x] AC-C3: line coverage holds (mechanical — no red test; verified by `.claude/scripts/suite.sh --cover`, then `grep -E '\| Total' /tmp/suite-<branch>.log` showing at least 81.62% and the summary line showing `0 failures`; exit code 3 is the unmet 90% project threshold, as on `main`)

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

Facts this section builds on, proven on `main` at f6aa246 with a probe: every variant of `##### Modules & components` step 1 compiled on both backends from the DSL written there, and the replaced LiveView tests ran against those variants with their routes re-pointed.
- The default product form of the mirror renders three more `header` elements than the guide form (the `packaging`, `contacts` and `product_barcode` blocks). The page header of a modal is `div#auix-product-<action>-modal header.auix-header--top-actions`.
- The mirror `Product` has more fields than the guide `Product`. The expected field list of the two `"Check field, … order"` tests is the declaration order of `Aurora.Uix.Test.MirrorCtx.Product` (`test/support/mirror/ctx/product.ex`, `schema "products"`), with `id` first.
- A relationship no `preload` names is not loaded in an index row, on both backends: the marker of the `product_barcodes` index of the `Options` variant renders `NOT_LOADED`; the markers of its `product_transactions` and `product_locations` indexes render `LOADED`.
- The render tree of the S6 body below has the same node ids on both backends: `"auix-product-form"`, `"auix-group-identification-product-form-0"`, `"auix-sections-product-form-1"`, `"auix-section-quantities-product-form-1-0"`, `"auix-section-prices-product-form-1-1"`.
- Two resources over `MirrorCtx.Product` and `MirrorAsh.Product` in one views module give both the module hint `Product`; a module declares one of the two.
- Coverage, measured on `main` at f186ea4 with this section applied: `mix test --cover` reports `1 doctest, 8 features, 577 tests, 0 failures` and `82.81% | Total` (4681 of 5653 lines). Without step 5 of `##### Modules & components` the same run reports `80.63%` (4557 of 5652 lines): the views modules under `test/support/` compile before the run starts, so the layout DSL they call is not counted (variant rule 10).

`test/guides/capture_layout_images.exs` requires five test files this issue deletes. Step 3 of `##### Modules & components` gives the capture script its own views, over the guide schemas, so the guide images keep their content.

##### Acceptance criteria
- [ ] AC-1: S1 asserts, on both backends, that the default index, show and form render every field of the product, stacked for `Default` and inline for `DefaultInline`, and that a product created through the default form (with `product_barcode: %{code: "C-1"}` in the params, carry rule 10) appears in the index; the field order equals the declaration order on `:ctx` (on `:ash` it follows map order, `##### Backend differences`)
- [ ] AC-2: S2 asserts groups, sections and nested sections on both backends: `.auix-group-container` per group; `.auix-sections-container` with one tab button per section; clicking a tab shows its fields and hides the others (`.auix-visually-hidden`); the `default: true` section is active on mount
- [ ] AC-3: S3 asserts titles and subtitles of index, new, edit and show, the layout preload, the resource preload and the resource `where`, on both backends: the `product_transactions` index (layout `preload: [:product]`) and the `product_locations` index (resource `preload([:products])`) render the `LOADED` marker in every row, and the `product_barcodes` index, which declares no preload, renders the `NOT_LOADED` marker
- [ ] AC-4: S4 asserts named modules, `use:`, `index_live` and included layouts on both backends: a used form component serves the resource of its host; a local layout replaces the included one
- [ ] AC-5: S5 asserts, on both backends, the edit and the show layout declared with two `auix_create_layout` calls (`Manual`: the show page has no `list_price` and no `rrp` input, and `description` is an `input`) and resources taken from another module (`Separated`); on `:ctx` only, a resource map built by hand (`ManualResource`)
- [ ] AC-6: S6 asserts the generation metadata with no database: the module registry, module names, `generate:`, `use:`, cards, the layout option sets, the render tree of the body of step 4 compiled once per backend, embedded resources that generate no module on each backend, and every views definition of `@run_time_variants` and `@run_time_single_views` compiled while the test runs, with the signature of the views module the scenarios mount (variant rule 10)
- [ ] AC-7: S7 is one table-driven test over `auix_create_ui`, `auix_create_layout` and layout option declarations: each replaced compile-error test is one case `{label, source body, message regex}`; a case that compiles fails the test with its label
- [ ] AC-8: `test/guides/capture_layout_images.exs` requires no file under `test/cases_live/` (mechanical — no red test; verified by `grep -c "cases_live" test/guides/capture_layout_images.exs` returning `0` and `MIX_ENV=test mix test test/guides/capture_layout_images.exs` exiting `0`, followed by `git checkout -- guides` to discard the regenerated images)
- [ ] AC-C1: every file listed under `##### Replaced files` is deleted, with its route registrations, and `mix test` is green (mechanical — no red test; verified by `git diff --name-status origin/main...HEAD -- test` showing a `D` line for each listed file)
- [ ] AC-C2: no file under `lib/` is modified (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD -- lib` returning nothing)
- [ ] AC-C3: line coverage holds (mechanical — no red test; verified by `.claude/scripts/suite.sh --cover`, then `grep -E '\| Total' /tmp/suite-<branch>.log` showing at least 81.62% and the summary line showing `0 failures`; exit code 3 is the unmet 90% project threshold, as on `main`)

##### Test ports
- Mirror routes `/mirror-<ash|ctx>-<slug>-<source>` of the variants below · layout types `:index`, `:form`, `:show` · observable: `has_element?/2`, `element/2`, the section helpers of `test/support/section_helper.ex`
- `Aurora.Uix.Layout.CreateUI` (`module_name/3`, `default_name/2`, `schema_hint/1`, `put_defaults/1`), `auix_modules/0`, `auix_module/1`, `auix_configurations/0` of a compiled views module, as the replaced tests call them · existing
- `auix_resources/0` (`lib/aurora_uix/layout/resource_metadata.ex` `resource_functions_code/1`) and `auix_layouts/0` (`lib/aurora_uix/layout/create_ui.ex` `layouts_code/1`) of a views module; `auix_kind/0` and `auix_fields/0` (`create_ui.ex` `module_code/2`) of every module `auix_modules/0` returns · existing. A module with no `auix_resource_metadata` call exports no `auix_resources/0`, and a module with no `auix_create_ui` call exports no `auix_modules/0`

##### Red tests
Every row passes on first run.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | amend `test/cases_live/layout_scenarios_test.exs` `"default layouts mount index, new, show and edit for every resource"` | variants `Default`, `DefaultInline`; `create_sample_products(3, :test)` | same file | S1, name unchanged | carried assertions, plus `.auix-index-container`, `.auix-form-container`, `.auix-show-container`, `.auix-show-content`; the modal header is `element(view, "div#auix-product-new-modal header.auix-header--top-actions")`; the create submit is `form("#auix-product-form", product: %{reference: "test-first", name: "This is the first test", quantity_initial: 11, product_barcode: %{code: "C-1"}})`; the expected field order is the mirror list, asserted inside `if backend.name == :ctx` |
| AC-2 | add to `test/cases_live/layout_scenarios_test.exs` | variants `Groups`, `Sections`, `NestedSections`; no seed; the `/new` route, as the three old tests mount it | same file | S2 `"groups, sections and nested sections lay out the form"` | carried assertions, plus `.auix-group-container`, `.auix-sections-container`, `.auix-sections-tab-container`, `.auix-sections-content` |
| AC-3 | add to `test/cases_live/layout_scenarios_test.exs` | variant `Options`; `create_sample_products_with_transactions(2, 2, :test)`, `create_sample_product_locations(3, :test)` | same file | S3 `"layout options set titles and preloads"` | carried assertions of `create_ui_layout_test.exs` (titles and subtitles only; its create, edit and delete flows belong to `UI-7`), re-pointed to `mirror_path(backend, "options", "products", …)`; `product_transactions` index: `assert has_element?(view, ".auix-product-marker", "LOADED")`, `refute has_element?(view, ".auix-product-marker", "NOT_LOADED")`; `product_locations` index: the same two on `.auix-products-marker`, two `.auix-items-table-row` rows, and `refute has_element?(view, "td", "test-reference-test-3")`; `product_barcodes` index, after `create_sample_products_with_barcodes(1)`: `assert has_element?(view, ".auix-product-marker", "NOT_LOADED")`; then `/new` and `/<id>/show` of the three sources each return `{:ok, _, _}` (carry rule 8) |
| AC-4 | add to `test/cases_live/layout_scenarios_test.exs` | variants `NamedForms`, `Named`, `Included`; `create_sample_product_locations(1, :test)`, `create_sample_products(1, :test)` | same file | S4 `"named modules, use: and included layouts render through their host"` | carried assertions |
| AC-5 | add to `test/cases_live/layout_scenarios_test.exs` | variants `Manual`, `Separated`; the hand-built resource module of step 2; `create_sample_products_with_transactions(1, 1, :test)` | same file | S5 `"manual layouts and resources from another module render"` | `Manual`: the four tests of `manual_layouts_test.exs`; `Separated`: the four tests of `separated_multiple_resources_ui_test.exs`; a `"can&#39;t be blank"` match follows carry rule 11; the hand-built resource part is the four tests of `manual_resource_test.exs` inside `each_backend([:ctx], …)` |
| AC-6 | new file (`ls test/cases \| grep -x generation_test.exs` returns nothing) | `use ExUnit.Case, async: true`; `compile/1` and `compiled_ui/1` copied from `test/cases/create_ui_validation_test.exs`, the sample module renamed `Aurora.UixWeb.Test.GenerationSample<n>` and its `auix_resource_metadata` re-pointed to `Aurora.Uix.Test.MirrorCtx`; `compile_raw/1` of step 4; the aliases, attributes and functions of step 5; the three `named_modules_test.exs` tests read `Aurora.UixWeb.Test.MirrorCtx.Named`, `…MirrorCtx.NamedForms`, `…MirrorCtx.NamedHost` and their `MirrorAsh` twins | `test/cases/generation_test.exs` (module `Aurora.Uix.Test.Cases.GenerationTest`) | S6 `"generated modules, names, render trees and option sets"` | carried assertions, re-pointed with the name map below `##### Replaced files`; the render-tree and embedded-resource assertions of step 4; `assert_run_time_views()` of step 5 as the last call of the test |
| AC-7 | add to `test/cases/generation_test.exs` | as S6 | same file | S7 `"create_ui and layout option compile errors"` | `for {label, body, regex} <- cases`, `assert_raise(Spark.Error.DslError, regex, fn -> compile(body) end)`; a failure message starts with `label`; a case whose old test asserts another exception keeps that exception |

##### Carry rules
These rules apply to every row of `##### Replaced files`.
1. `file → S` means: scenario `S` makes every assertion of every test of that file, except the tests the row lists under Dropped. The old file is the source of the selectors, the input names and the drives.
2. Re-pointing an Ecto (inventory) test: a guide module becomes the `MirrorCtx` / `MirrorAsh` module of the same last name; a route becomes `mirror_path(backend, "<variant slug>", "<source>", "<suffix>")`; a seed call keeps its name and arguments (`Aurora.Uix.Test.Mirror.Seeds`); a `delete_all_*_data()` call is removed, because `each_backend/2` empties the mirror tables. Selectors, input names and element names stay as written.
3. `on :ash` in a row means the file is the Ash twin of an Ecto file in the same row: its assertions are the Ecto ones, and the scenario makes them on `:ash` by running there. A test listed as `Ash-only` has no Ecto twin: carry it with the name map the row gives, and assert it on both backends.
4. An assertion on an `auix-field-*` id, and an `=~` on rendered HTML, is rewritten as `has_element?/2` on the same element, selected by the first of these it has: its `name` attribute, its input name, its `auix-*` class.
5. Every scenario also asserts the structure its row lists, on both backends.
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing> (#<issue>): <what happens>`, and list it under "Library defects found" in the section log. `<issue>` is the issue of that defect: #580 for the Ash field order, #581 for the Ecto crash on a validation error of a nested record, #582 for the Ash form that shows no field error, #583 for the Ash record navigation across a page boundary, #584 for the Ash embeds-one that renders no input while empty, #585 for the DSL compile that fails after a failed compile in the same process. A defect none of the six covers is written `# Library defect on <failing> (new): <what happens>` and listed in the section log as new. Never change a file under `lib/`.
7. Delete each replaced file with `git rm`. Remove from `test/support/app_web/routes.ex` every registration whose module argument starts with the test module of a deleted file. A module a deleted file defines beside its test module moves as `##### Modules & components` of this section says.
8. A views variant declares only the resources and layouts its scenarios mount, and each generated module is mounted by a scenario: an unmounted generated module is a missed line in the coverage total.
9. An id that embeds the route (`auix-table-<route>-index`, `auix-table-<route>-index-mobile`, `auix-table-<route>-index-hook`) is rebuilt from the mirror route: `"#auix-table-mirror-#{backend.slug}-<variant slug>-<source>-index"`. For these ids this rule replaces the last sentence of rule 2.
10. Required fields and seeds. `name`, `status` and `quantity_initial` are required on both backends, and `create_sample_products/3` and `create_sample_products_with_transactions/4` set no `quantity_initial`. A form submit that must save a seeded product sets `quantity_initial`: in the seed attrs (`%{quantity_initial: 1}`) when the form has no `quantity_initial` input, in the submitted params otherwise. A form that renders the `:product_barcode` inputs (the default product form of the `Default` variant, the `OneToOne` variant) saves only with `product_barcode: %{code: "<code>"}` in the submitted params.
11. A validation message is the text of the backend: `can't be blank` on `:ctx`, `is required` on `:ash`. Assert the `.auix-error-message` element on both backends and the text of the running backend.
12. A raw SQL statement on a guide table and a `Repo` call on a guide schema become an `Aurora.Uix.Repo` call on the `MirrorCtx` schema of the same table. Persisted values are read through `MirrorCtx` schemas on both backends: the tables are shared.
13. A carried assertion that fails on both backends because the variant is not the old views module (another field list, another seed, another column position) is restated for the variant: the fact it states stays, and its selector and expected value are recomputed from the variant DSL this section gives. It is removed only when the variant no longer has the thing it asserts; each removal is listed in the section log with that reason.
14. `##### Backend differences` of this section lists what the probe measured. Each entry is asserted as the entry says. An assertion that fails on one backend only and has no entry falls under rule 6.

##### Backend differences
Measured by the probe.
- `:ash`: the fields of a default layout follow map order, not declaration order (library defect #580, logged by `UI-4`). The two `"Check field, … order"` assertions run on `:ctx` only.
- Both backends: saving the default product form with blank `product_barcode` inputs writes no row. On `:ash` the form shows `.auix-flash--error`; on `:ctx` the LiveView exits with `FunctionClauseError` in `Aurora.Uix.Templates.Basic.Helpers.process_error_detail/1` (library defect #581 on `:ctx`: a validation error on a nested child has no clause). No scenario submits that form with a blank `code`; the section log lists the defect under "Library defects found".
- A `"can&#39;t be blank"` match of a carried create flow follows carry rule 11.

##### Variant rules
1. A variant is the three files `UI-2` defines: `test/support/mirror_web/variants/<name>.ex` (module `Aurora.UixWeb.Test.Mirror.Variants.<Name>`), `test/support/mirror_web/ash/<name>.ex` and `test/support/mirror_web/ctx/<name>.ex`. Its routes are one `RoutesHelper.register_mirror(<Name>, "<slug>", [<sources>])` line in `test/support/app_web/routes.ex`, below the existing `register_mirror` lines.
2. "DSL of `<old file>`" means the `auix_resource_metadata` and `auix_create_ui` calls of that file, moved into the `quote` of the variant's `__using__/1`. `auix_resource_metadata(:x, context: …, schema: …)` and `auix_resource_metadata(:x, ash_resource: …)` become `mirror_resource(:x)`; resource options and `field` lines go in its `do` block, unchanged. For an Ash (blog) source file the row gives the resource and field names to use.
3. A function a layout references (`&__MODULE__.fun/1`) becomes a public function of the variant definition module with `@doc false`, referenced as `&Aurora.UixWeb.Test.Mirror.Variants.<Name>.fun/1`. A handler module a layout names becomes `Aurora.UixWeb.Test.Mirror.Handlers.<SameLastName>` at `test/support/mirror_web/handlers/<name>.ex`, body unchanged.
4. When two sources in one variant give the same resource the same layout type, the row says which list is kept; a positional selector (`nth-child`, `nth-of-type`) of a carried assertion is recomputed for that list.
5. When a row moves a source's DSL to another resource (for example a products test onto `:product_location`), its fields are replaced by fields of that resource with the same type, its seed call by that resource's seed function, and each carried assertion states the same fact about the new resource.
6. A variant definition module that defines function components starts with `use Aurora.Uix.CoreComponentsImporter` and `import Aurora.Uix.Templates.Basic.RoutingComponents` (`<.button>` comes from the first, `<.auix_link>` from the second; without the import the module fails to compile with `undefined function auix_link/1`). Its `__using__/1` and its functions live in the same module.
7. A function with `~H` written inside the `quote` of `__using__/1` (the `render/1` of a host LiveView) takes its argument as `var!(assigns)`: `def render(var!(assigns)) do ~H"…" end`.
8. A variant that reads another variant of its own backend gets that module from `Aurora.UixWeb.Test.Mirror.sibling/2`, called in `__using__/1` before the `quote` and unquoted inside it: `views = Aurora.UixWeb.Test.Mirror.sibling(opts[:backend], <Name>)`.
9. An `Aurora.Uix.RouteHelper.auix_live_resources/3` line of a variant goes in `test/support/app_web/routes.ex` beside the existing `auix_live_resources` lines, below `require Aurora.Uix.RouteHelper`, one line per backend.
10. Run-time compile. `mix test --cover` counts the library code that runs while a module compiles only when that module compiles during the run, and the files under `test/support/` compile before it. Every module under `test/support/` that calls any of `auix_resource_metadata`, `auix_create_ui`, `auix_create_layout` keeps that DSL in the `quote` of the `__using__/1` of a definition module, and `assert_run_time_views/0` of `test/cases/generation_test.exs` (S6 of `UI-5`) compiles the definition again under a `GenerationSample<n>` name while the suite runs and asserts that its signature (resource names, layouts, and the kind and sorted fields of every module of the registry) equals the signature of the views module the scenarios mount. A variant is one atom, its last name, in `@run_time_variants` of that file, and is compiled on both backends. Any other definition is one `{definition, backend, views module}` tuple in `@run_time_single_views`. This section writes `assert_run_time_views/0` (step 5 of `##### Modules & components`) and names the `Default` variant of `UI-2`, its own twelve variants and its two other definitions, `ManualResource` and `IncludedLayouts`. A later section adds its entries and no test.

##### Replaced files
| Old file (tests) | Home | Dropped, with the reason |
|---|---|---|
| `test/cases_live/create_ui_default_layout_test.exs` (5) | S1 | none |
| `test/cases_live/create_ui_default_layout_inline_test.exs` (1) | S1 | none |
| `test/cases_live/group_ui_layout_test.exs` (1) | S2 | none |
| `test/cases_live/section_ui_layout_test.exs` (1) | S2 | none |
| `test/cases_live/nested_sections_ui_layout_test.exs` (1) | S2 | none |
| `test/cases_live/preload_layout_test.exs` (1) | S3: the layout preload, asserted on the `product_transactions` index | none |
| `test/cases_live/preload_metadata_test.exs` (2) | S3: the resource preload and the resource `where`, asserted on the `product_locations` index | none |
| `test/cases_live/ash_preload_metadata_test.exs` (1) | S3, on :ash: the same `product_locations` assertions | none |
| `test/cases_live/named_modules_test.exs` (4) | S4 (`"a used form component serves the resource of its host"`); the other three → S6 | none |
| `test/cases_live/included_layouts_test.exs` (2) | S4 | none |
| `test/cases_live/manual_layouts_test.exs` (4) | S5, on the `Manual` variant | none |
| `test/cases_live/manual_trees_test.exs` (4) | none | all four. `"Test UI default…"`, `"Test CREATE new…"` and `"Test validate the fields displayed in NEW"` are copies of the `manual_layouts_test.exs` tests over the same `auix_create_layout` edit layout. `"Test validate the fields displayed in SHOW"` asserts the default show layout (`list_price` and `rrp` present), which contradicts the `show_layout` of `Manual`; the default show layout is asserted by S1 |
| `test/cases_live/manual_ui_test.exs` (4) | none | all four. Its layouts are declared inside `auix_create_ui`, as every other variant declares them; `field(:description, html_type: :textarea)` contradicts the `input` the `Manual` tests assert and is asserted by `UI-7` S1 on the `Form` variant; `page_subtitle:` is asserted by S3; its index mount and create flow are copies of the `manual_layouts_test.exs` ones |
| `test/cases_live/manual_resource_test.exs` (4) | S5, on `:ctx` | none |
| `test/cases_live/separated_multiple_resources_ui_test.exs` (4) | S5, on the `Separated` variant | none |
| `test/cases_live/separated_single_resource_ui_test.exs` (2) | none | both: the same index mount and create flow as the first two tests of the `separated_multiple` file, over a resources module with one resource instead of two |
| `test/cases_live/unseparated_multiple_resources_ui_test.exs` (4) | none | all four: its two resources in one module are what every variant already declares |
| `test/cases/create_ui_validation_test.exs` (39) | the tests whose name ends `fails compilation`, and `"use: rejects what it cannot take"`, `"use: takes no do block"`, `"use: takes no other option"`, `"use: on index_columns rejects what it cannot take"`, `"a one-to-many field rejects an action_icons key of another field type"`, `"a many-to-many field takes no action_icons key"`, `"a live view needs its form and show components"`, `"an imported module must be a registry entry"` → S7 cases; every other test → S6 | none |
| `test/cases/layout_options_test.exs` (6) | `"lists each option of the set with its layout type"`, `"available_options/1 reads the options of every set"`, `"a listed option is read from the layout, then from get_default/2"` → S6; the three `fails compilation` tests → S7 cases | none |
| `test/cases/render_tree_test.exs` (4) | S6, on the module `compile_raw/1` builds from the render-tree body of step 4, once per backend | none |

Name map for the compile bodies and the assertions carried from `test/cases/create_ui_validation_test.exs`, `test/cases/layout_options_test.exs` and `test/cases_live/named_modules_test.exs`: `Aurora.Uix.Guides.Inventory` → `Aurora.Uix.Test.MirrorCtx`, in module names and in the `~r/… has no layouts/` regex alike; `Aurora.UixWeb.Test.NamedModulesForms` → `…MirrorCtx.NamedForms`, `NamedModulesHost` → `…MirrorCtx.NamedHost`, `NamedModulesTest` → `…MirrorCtx.Named` (and the `MirrorAsh` twins for the second pass). The test `"an embedded resource generates no modules"` is not re-pointed by this map: step 4 gives its two bodies. A test that names no guide module is carried as written.

Partly carried here, deleted by a later section: `test/cases_live/ash_default_layout_test.exs` — `"Default layout index"` and `"Test show default behaviour"` are covered by S1 on `:ash`; `test/cases_live/create_ui_layout_test.exs` — its titles and subtitles are asserted by S3. Both files stay until `UI-7`.

##### Modules & components
1. Variants (rules above). Each block is the content of the `quote` of `__using__/1`, after `use Aurora.UixWeb.Test.Mirror, unquote(opts)`, as the probe compiled it on both backends.

   **`DefaultInline`** · slug `default-inline` · sources `products`
     ```elixir
     mirror_resource(:product)
     auix_create_ui(default_fields_layout: :inline)
     ```

   **`Groups`** · slug `groups` · sources `products` (DSL of `test/cases_live/group_ui_layout_test.exs`)
     ```elixir
     mirror_resource(:product)
     auix_create_ui do
       edit_layout :product, [] do
         inline([:reference, :name, :description])
         group "Quantities" do
           inline([:quantity_at_hand, :quantity_initial])
         end
         group "Sale Prices" do
           stacked([:list_price, :rrp])
         end
       end
     end
     ```

   **`Sections`** · slug `sections` · sources `products` (DSL of `test/cases_live/section_ui_layout_test.exs`)
     ```elixir
     mirror_resource(:product)
     auix_create_ui do
       edit_layout :product, [] do
         inline([:reference, :name, :description])
         sections do
           section "Quantities" do
             inline([:quantity_at_hand, :quantity_initial])
           end
           section "Sale Prices" do
             stacked([:list_price, :rrp])
           end
         end
       end
     end
     ```

   **`NestedSections`** · slug `nested-sections` · sources `products`: the `edit_layout :product` block of `test/cases_live/nested_sections_ui_layout_test.exs`, unchanged, after `mirror_resource(:product)`, inside `auix_create_ui do … end`.

   **`Options`** · slug `options` · sources `products`, `product_transactions`, `product_locations`, `product_barcodes`
     ```elixir
     mirror_resource(:product)
     mirror_resource :product_transaction do
       field(:type, index_renderer: &Aurora.UixWeb.Test.Mirror.Variants.Options.product_marker/1)
     end
     mirror_resource :product_location do
       preload([:products])
       where([{:reference, :between, "test-reference-test-1", "test-reference-test-2"}])
       field(:name, index_renderer: &Aurora.UixWeb.Test.Mirror.Variants.Options.products_marker/1)
     end
     mirror_resource :product_barcode do
       field(:code, index_renderer: &Aurora.UixWeb.Test.Mirror.Variants.Options.product_marker/1)
     end
     auix_create_ui do
       index_columns(:product, [:id, :reference, :name, :description, :quantity_at_hand],
         page_title: "The Products Listing"
       )
       edit_layout :product,
         new_title: "Add a Product",
         new_subtitle: &Aurora.UixWeb.Test.Mirror.Variants.Options.new_subtitle/1,
         edit_title: &Aurora.UixWeb.Test.Mirror.Variants.Options.edit_title/1,
         edit_subtitle: "Entries are validated before saving" do
         inline([:reference, :name, :description])
         inline([:quantity_at_hand, :quantity_initial])
         inline([:list_price, :rrp])
       end
       show_layout :product, page_title: &Aurora.UixWeb.Test.Mirror.Variants.Options.page_title/1, page_subtitle: nil do
         inline([:reference, :name, :description])
         inline([:quantity_at_hand, :quantity_initial])
         inline([:list_price, :rrp])
       end
       index_columns(:product_transaction, [:type, :quantity], preload: [:product])
       index_columns(:product_location, [:reference, :name])
       index_columns(:product_barcode, [:code, :symbology])
     end
     ```
   The module defines, with `use Phoenix.Component` and `@doc false`: `page_title/1`, `edit_title/1` (three clauses) and `new_subtitle/1`, copied from `test/cases_live/create_ui_layout_test.exs`; and
     ```elixir
     def product_marker(assigns) do
       assigns = assign(assigns, :marker, marker(assigns.entity.product))
       ~H"""
       <span class="auix-product-marker">{@marker}</span>
       """
     end

     def products_marker(assigns) do
       assigns = assign(assigns, :marker, marker(assigns.entity.products))
       ~H"""
       <span class="auix-products-marker">{@marker}</span>
       """
     end

     defp marker(%Ecto.Association.NotLoaded{}), do: "NOT_LOADED"
     defp marker(%Ash.NotLoaded{}), do: "NOT_LOADED"
     defp marker(_loaded), do: "LOADED"
     ```
   The `backend_opts` of the source file is not carried (`UI-11` S6 owns it). The two struct names appear in test support only.

   **`NamedForms`** · no route (the module `Aurora.UixWeb.Test.NamedModulesForms` of `test/cases_live/named_modules_test.exs`)
     ```elixir
     mirror_resource(:product)
     mirror_resource(:product_location)
     auix_create_ui generate: [:form_component, :show_component] do
       edit_layout :product, module_name: :reference_form do
         inline([:reference, :name])
       end
     end
     ```

   **`NamedHost`** · no route (the module `NamedModulesHost` of the same file); `forms = Aurora.UixWeb.Test.Mirror.sibling(opts[:backend], NamedForms)` before the `quote`
     ```elixir
     @auix_resource_metadata %{
       product_location: unquote(forms).auix_resource(:product_location)
     }

     auix_create_ui generate: [] do
       edit_layout(:product_location, use: unquote(forms).auix_module(:reference_form))
     end
     ```

   **`Named`** · slug `named` · source `product_locations` (the module `NamedModulesTest` of the same file); `forms` as in `NamedHost`
     ```elixir
     @auix_modules %{reference_form: unquote(forms).auix_module(:reference_form)}
     mirror_resource(:product_location)

     auix_create_ui do
       edit_layout(:product_location, use: :reference_form)
       index_live(:product_location, module_name: :locations)
     end
     ```
   Routes (variant rule 9): `RouteHelper.auix_live_resources("/mirror-ash-named-product_locations", MirrorAsh.Named.ProductLocation, index_live: :locations)` and the same line with `ctx` and `MirrorCtx`. The generated live view is `<Backend>.Named.ProductLocation.Locations`; no `…ProductLocation.Index` and no `…ProductLocation.FormComponent` exists, and the carried `Code.ensure_loaded?/1` assertions name the modules of the running backend.

   **`Included`** · slug `included` · sources `products`. The body of `Aurora.UixWeb.Test.IncludedLayouts` of `test/cases_live/included_layouts_test.exs` (`use Aurora.Uix` and its `auix_create_layout` block, unchanged) is the `quote` of `__using__/1` of the definition module `Aurora.UixWeb.Test.Mirror.Variants.IncludedLayouts` at `test/support/mirror_web/variants/included_layouts.ex`: `@moduledoc false`, then `@doc false`, `@spec __using__(keyword()) :: Macro.t()` and `defmacro __using__(_opts)`. `Aurora.UixWeb.Test.Mirror.IncludedLayouts` at `test/support/mirror_web/included_layouts.ex` is `@moduledoc false` and `use Aurora.UixWeb.Test.Mirror.Variants.IncludedLayouts, backend: :ctx`; the definition reads no option. `Variants.IncludedLayouts` is new (`rg -n "Variants.IncludedLayouts" test lib` returns nothing).
     ```elixir
     mirror_resource(:product)
     auix_create_ui include: Aurora.UixWeb.Test.Mirror.IncludedLayouts do
       show_layout :product do
         inline([:name])
       end
     end
     ```

   **`Manual`** · slug `manual` · sources `products`, `product_transactions`, `product_locations` (DSL of `test/cases_live/manual_layouts_test.exs`)
     ```elixir
     mirror_resource(:product)
     mirror_resource(:product_location)
     mirror_resource(:product_transaction)
     auix_create_layout do
       edit_layout :product, [] do
         inline([:reference, :name, :description])
         inline([:quantity_at_hand, :quantity_initial])
         inline([:list_price, :rrp])
         inline([:product_location_id])
         inline([:product_transactions])
       end
     end
     auix_create_layout do
       show_layout :product, [] do
         inline([:reference, :name, :description])
         inline([:quantity_at_hand, :quantity_initial])
         inline([:product_location_id])
         inline([:product_transactions])
       end
     end
     auix_create_ui do
       index_columns(:product, [:reference, :name, :description, :product_location_id],
         order_by: :name
       )
     end
     ```

   **`SeparatedResources`** · no route
     ```elixir
     mirror_resource(:product)
     mirror_resource(:product_transaction)
     ```

   **`Separated`** · slug `separated` · sources `products`, `product_transactions`; `resources = Aurora.UixWeb.Test.Mirror.sibling(opts[:backend], SeparatedResources)` before the `quote`
     ```elixir
     @auix_resource_metadata %{product: unquote(resources).auix_resource(:product)}
     @auix_resource_metadata %{
       product_transaction: unquote(resources).auix_resource(:product_transaction)
     }

     auix_create_ui do
       edit_layout :product, [] do
         inline([:reference, :name, :description])
         inline([:quantity_at_hand, :quantity_initial])
         inline([:list_price, :rrp])
       end
     end
     ```

   In `test/support/mirror_web/mirror.ex` add, above `source_lines/2`:
     ```elixir
     @doc false
     @spec sibling(:ash | :ctx, module()) :: module()
     def sibling(:ash, name), do: Module.concat([Aurora.UixWeb.Test.MirrorAsh, name])
     def sibling(:ctx, name), do: Module.concat([Aurora.UixWeb.Test.MirrorCtx, name])
     ```
   `sibling/2` is new (`rg -n "def sibling" test lib` returns nothing).

2. Hand-built resource (S5, `:ctx` only), two files (variant rule 10). `Variants.ManualResource` is new (`rg -n "Variants.ManualResource" test lib` returns nothing).
   - `Aurora.UixWeb.Test.Mirror.Variants.ManualResource` at `test/support/mirror_web/variants/manual_resource.ex`, with `@moduledoc false`. Its `resources/0` (`@doc false`, `@spec resources() :: %{atom() => Aurora.Uix.Resource.t()}`) returns the `@auix_resource_metadata` map of `test/cases_live/manual_resource_test.exs`, with `schema:` and `context:` and each `related:` re-pointed to `Aurora.Uix.Test.MirrorCtx`. The map stays in the function, outside the `quote`: `Credo.Check.Refactor.LongQuoteBlocks` rejects a `quote` that holds it. Its `__using__/1` (`@doc false`, `@spec __using__(keyword()) :: Macro.t()`, `defmacro __using__(_opts)`) quotes:
     ```elixir
     Module.register_attribute(__MODULE__, :auix_resource_metadata, persist: true)
     use Aurora.Uix

     @auix_resource_metadata Aurora.UixWeb.Test.Mirror.Variants.ManualResource.resources()

     auix_create_ui do
       index_columns(:product, [:reference, :name, :description, :product_location_id],
         order_by: :name
       )

       edit_layout :product, [] do
         inline([:reference, :name, :description])
         inline([:quantity_at_hand, :quantity_initial])
         inline([:list_price, :rrp])
         inline([:product_location_id])
         inline([:product_transactions])
       end
     end
     ```
   - `Aurora.UixWeb.Test.MirrorCtx.ManualResource` at `test/support/mirror_web/ctx/manual_resource.ex`: `@moduledoc false` and `use Aurora.UixWeb.Test.Mirror.Variants.ManualResource, backend: :ctx`.

   Routes: `RoutesHelper.register_product_crud(MirrorCtx.ManualResource, "mirror-ctx-manual-resource-")`, the form the old file's registration has; S5 mounts the index, `/new` and `/<id>/show` of its three sources (carry rule 8).

3. Capture views. Create one file per row under `test/guides/views/`, each a module that copies the views DSL of the named test file over the guide schemas, with `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test` and no test:

   | New file · module | DSL copied from | Routes |
   |---|---|---|
   | `default_layout.exs` · `Aurora.UixWeb.Test.GuidesCapture.DefaultLayout` | `test/cases_live/create_ui_default_layout_test.exs` | `RoutesHelper.register_crud(GuidesCapture.DefaultLayout.Product, "guides-capture-default-products")` |
   | `selector_layout.exs` · `…GuidesCapture.SelectorLayout` | `test/cases_live/association_many2one_selector_ui_layout_test.exs` | `RoutesHelper.register_product_crud(GuidesCapture.SelectorLayout, "guides-capture-selector-")` |
   | `group_layout.exs` · `…GuidesCapture.GroupLayout` | `test/cases_live/group_ui_layout_test.exs` | `RoutesHelper.register_crud(GuidesCapture.GroupLayout.Product, "guides-capture-group-products")` |
   | `section_layout.exs` · `…GuidesCapture.SectionLayout` | `test/cases_live/section_ui_layout_test.exs` | `RoutesHelper.register_crud(GuidesCapture.SectionLayout.Product, "guides-capture-section-products")` |
   | `nested_sections_layout.exs` · `…GuidesCapture.NestedSectionsLayout` | `test/cases_live/nested_sections_ui_layout_test.exs` | `RoutesHelper.register_crud(GuidesCapture.NestedSectionsLayout.Product, "guides-capture-nested-sections-products")` |

   In `test/guides/capture_layout_images.exs`: replace the five `Code.require_file("test/cases_live/…")` lines with five `Code.require_file("test/guides/views/<file>")` lines; replace `"/create-ui-default-layout-products"` with `"/guides-capture-default-products"`, `"/association-many_to_one_selector-layout-product_locations"` with `"/guides-capture-selector-product_locations"`, `"/association-many_to_one_selector-layout-products"` with `"/guides-capture-selector-products"`, `"group-ui-layout-products"` with `"/guides-capture-group-products"`, `"section-ui-layout-products"` with `"/guides-capture-section-products"`, `"nested-sections-ui-layout-products"` with `"/guides-capture-nested-sections-products"`. These modules are `.exs` files: they are loaded by the capture script only and are outside the compiled test support.

4. S6 bodies. `test/cases/generation_test.exs` defines, beside `compile/1` and `compiled_ui/1`:
     ```elixir
     defp compile_raw(body) do
       {mod, _binary} =
         """
         defmodule Aurora.UixWeb.Test.GenerationSample#{System.unique_integer([:positive])} do
           use Aurora.Uix
         #{body}
         end
         """
         |> Code.compile_string()
         |> Enum.find(fn {m, _} -> function_exported?(m, :auix_modules, 0) end)

       mod
     end
     ```
   - Render tree. For each of `"context: Aurora.Uix.Test.MirrorCtx, schema: Aurora.Uix.Test.MirrorCtx.Product"` and `"ash_resource: Aurora.Uix.Test.MirrorAsh.Product"`, the body is `auix_resource_metadata :product, <that source>` followed by the `auix_create_ui do … end` block of `test/cases/render_tree_test.exs`, unchanged. The four tests of that file assert on `mod.auix_configurations().product.layout_trees.form` and `.index`, with the ids they hard-code; each holds on both backends.
   - Embedded resources, `:ctx` body:
     ```elixir
     auix_resource_metadata :product, context: Aurora.Uix.Test.MirrorCtx, schema: Aurora.Uix.Test.MirrorCtx.Product
     auix_resource_metadata :product__packaging do
       schema Aurora.Uix.Test.MirrorCtx.Product.Packaging
       field :fragile, readonly: true
     end
     auix_create_ui()
     ```
     Assertions: `mod.auix_modules() |> Map.keys() |> Enum.sort() == [:product_form_component, :product_index, :product_index_component, :product_show_component]`; `Packaging.Index`, `Packaging.FormComponent`, `Packaging.ShowComponent` and `Contact.Index` under `mod` are not loaded; `mod.auix_configurations()` has the keys `:product__packaging` and `:product__contacts`; `mod.auix_resource(:product__packaging).embedded?` and `mod.auix_resource(:product__contacts).embedded?`; `mod.auix_resource(:product__packaging).fields.fragile.readonly`.
   - Embedded resources, `:ash` body:
     ```elixir
     auix_resource_metadata :product, ash_resource: Aurora.Uix.Test.MirrorAsh.Product
     auix_resource_metadata :product__packaging do
       ash_resource Aurora.Uix.Test.MirrorAsh.Packaging
       field :notes, readonly: true
     end
     auix_resource_metadata :contact_metadata, ash_resource: Aurora.Uix.Test.MirrorAsh.Contact
     auix_resource_metadata :policy_item, ash_resource: AshActorTest.PolicyItem
     auix_resource_metadata :policy_item__tags, ash_resource: AshActorTest.Tag
     auix_create_ui do
       edit_layout :product__packaging do
         stacked [:notes]
       end
     end
     ```
     Assertions: the sorted module keys are `[:policy_item_form_component, :policy_item_index, :policy_item_index_component, :policy_item_show_component, :product_form_component, :product_index, :product_index_component, :product_show_component]`; `Packaging.Index`, `Packaging.FormComponent`, `Packaging.ShowComponent`, `Contact.Index` and `Tag.Index` under `mod` are not loaded; `embedded?` holds for `:product__packaging`, `:product__contacts`, `:policy_item__tags` and `:contact_metadata`; `mod.auix_resource(:product__packaging).fields.notes.readonly`; `[%Node.Stacked{children: [%Node.Field{key: :notes}]}] = mod.auix_configurations().product__packaging.layout_trees.form.children`.
   Both bodies replace the single body of `"an embedded resource generates no modules"`; its `Accounts.User`, `Blog.Post`, `Blog.Comment` and `Blog.Tag` lines have no other home.

5. Run-time views (S6, variant rule 10). In `test/cases/generation_test.exs`:
   - below `alias Aurora.Uix.Templates.Basic.Helpers`, add
     ```elixir
     alias Aurora.UixWeb.Test.Mirror
     alias Aurora.UixWeb.Test.Mirror.Variants
     alias Aurora.UixWeb.Test.MirrorCtx
     ```
   - above the first `test`, add the module attributes
     ```elixir
     @run_time_variants ~w(Default DefaultInline Groups Sections NestedSections Options NamedForms
                           NamedHost Named Included Manual SeparatedResources Separated)a

     @run_time_single_views [
       {Variants.ManualResource, :ctx, MirrorCtx.ManualResource},
       {Variants.IncludedLayouts, :ctx, Mirror.IncludedLayouts}
     ]
     ```
   - make `assert_run_time_views()` the last call of the S6 test;
   - beside `compile_raw/1`, add
     ```elixir
     # Compiles every views definition while the suite runs and compares it with the views module
     # the scenarios mount, so the DSL a variant declares is exercised by a test.
     @spec assert_run_time_views() :: term()
     defp assert_run_time_views do
       variants =
         for name <- @run_time_variants, backend <- [:ash, :ctx] do
           {Module.concat(Variants, name), backend, Mirror.sibling(backend, name)}
         end

       signatures =
         (variants ++ @run_time_single_views)
         |> Task.async_stream(
           fn {definition, backend, twin} ->
             signature = definition |> compile_view(backend) |> signature()
             assert signature == signature(twin), "#{inspect(definition)} on #{backend}"
             {{definition, backend}, signature}
           end,
           timeout: :infinity
         )
         |> Map.new(fn {:ok, entry} -> entry end)

       assert_manual_views(signatures)
       assert_included_views(signatures)
       assert_resource_only_views(signatures)
     end

     @spec assert_manual_views(map()) :: term()
     defp assert_manual_views(signatures) do
       product_form =
         {:form_component,
          [
            :description,
            :list_price,
            :name,
            :product_location_id,
            :product_transactions,
            :quantity_at_hand,
            :quantity_initial,
            :reference,
            :rrp
          ]}

       for backend <- [:ash, :ctx] do
         manual = signatures[{Variants.Manual, backend}]

         assert manual.layouts == [
                  {Node.Form, :product},
                  {Node.Show, :product},
                  {Node.Index, :product}
                ]

         assert manual.modules.product_form_component == product_form

         assert manual.modules.product_show_component ==
                  {:show_component,
                   [
                     :description,
                     :name,
                     :product_location_id,
                     :product_transactions,
                     :quantity_at_hand,
                     :quantity_initial,
                     :reference
                   ]}

         assert manual.modules.product_index_component ==
                  {:index_component, [:description, :name, :product_location_id, :reference]}
       end

       hand_built = signatures[{Variants.ManualResource, :ctx}]
       assert hand_built.resources == []
       assert hand_built.modules.product_form_component == product_form
       assert hand_built.modules.product_show_component == put_elem(product_form, 0, :show_component)
     end

     @spec assert_included_views(map()) :: term()
     defp assert_included_views(signatures) do
       layouts = [{Node.Form, :product}, {Node.Show, :product}]

       assert signatures[{Variants.IncludedLayouts, :ctx}] ==
                %{resources: [], layouts: layouts, modules: %{}}

       for backend <- [:ash, :ctx] do
         included = signatures[{Variants.Included, backend}]
         assert included.layouts == layouts
         assert included.modules.product_form_component == {:form_component, [:name, :reference]}
         assert included.modules.product_show_component == {:show_component, [:name]}
       end
     end

     @spec assert_resource_only_views(map()) :: term()
     defp assert_resource_only_views(signatures) do
       for backend <- [:ash, :ctx] do
         assert signatures[{Variants.SeparatedResources, backend}] == %{
                  resources: [
                    :product,
                    :product__contacts,
                    :product__packaging,
                    :product_transaction
                  ],
                  layouts: [],
                  modules: %{}
                }

         assert signatures[{Variants.NamedHost, backend}] == %{
                  resources: [],
                  layouts: [{Node.Form, :product_location}],
                  modules: %{}
                }
       end
     end

     @spec compile_view(module(), :ash | :ctx) :: module()
     defp compile_view(definition, backend) do
       name = "Aurora.UixWeb.Test.GenerationSample#{System.unique_integer([:positive])}"

       Code.compile_string("""
       defmodule #{name} do
         use #{inspect(definition)}, backend: #{inspect(backend)}
       end
       """)

       Module.concat([name])
     end

     @spec signature(module()) :: map()
     defp signature(views) do
       %{
         resources: views |> exported(:auix_resources, %{}) |> Map.keys() |> Enum.sort(),
         layouts: views |> exported(:auix_layouts, []) |> Enum.map(&{&1.__struct__, &1.resource}),
         modules:
           views
           |> exported(:auix_modules, %{})
           |> Map.new(fn {name, module} ->
             {name, {module.auix_kind(), Enum.sort(module.auix_fields())}}
           end)
       }
     end

     @spec exported(module(), atom(), term()) :: term()
     defp exported(views, function, default) do
       Code.ensure_loaded!(views)

       if function_exported?(views, function, 0),
         do: apply(views, function, []),
         else: default
     end
     ```
   The atoms of `@run_time_variants` are written with `~w(…)a`: the file aliases `Options` and `Form`, so a bare `Options` in a list names `Aurora.Uix.Layout.Options`. Each expected value above was read from the compiled modules and is the same on both backends. `assert_run_time_views/0`, `assert_manual_views/1`, `assert_included_views/1`, `assert_resource_only_views/1`, `compile_view/2`, `signature/1`, `exported/3`, `@run_time_variants` and `@run_time_single_views` are new (`rg -n "run_time_variants|run_time_single_views|assert_run_time_views|compile_view|defp signature|defp exported" test lib` returns nothing).

6. Theme: none. `dt/1` strings: none.

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

Facts this section builds on, proven on `main` at f6aa246 with a probe: the five variants below compiled on both backends from the DSL written there; the replaced LiveView tests ran against them with their routes and route-bound ids re-pointed, and the assertions moved to another resource ran as the red-test rows restate them. Every one passed on `:ash` and on `:ctx`, apart from the positional selectors carry rule 13 recomputes.
- On the `Index` variant the supplier name is the second `td` of a row (`#auix-table-mirror-<backend>-index-suppliers-index tr td:nth-of-type(2)`).
- `LoadItemsOptionsHandler` adds `where: [{:reference, :lt, "item_test-06"}]` from the next sort on. It changes nothing until a sort button is clicked, and it matches no `item_test_order-…` reference.

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
| AC-2 | `Index` · the seeds of `sortable_columns_test.exs`, plus `create_sample_products_with_suppliers(1, 3)` for the forged event | S2 `"column headers sort, reverse and return to the backend order"` | carried assertions on `products`. The forged-event test of `sort_disabled_test.exs` runs on `suppliers`: read the supplier names (`td:nth-of-type(2)`), send `render_click(view, "index-sort", %{"key" => "name"})`, `render_click(view, "index-sort", %{"sort" => "name"})`, `render_click(view, "index-sort-direction", %{})`, `render_click(view, "index-sort-direction", %{"direction" => "desc"})`, and assert the names are the list read before and `refute has_element?(view, "th[aria-sort]")` |
| AC-3 | `Index` (`products`, `suppliers`, `product_locations`) · as S2, plus `create_sample_products_with_suppliers(1, 3)` | S3 `"the card sort control sorts, and is absent when sorting is off"` | carried assertions of the card sort tests on `products`. The three `sort_disabled?` tests run on `suppliers`: `refute has_element?(view, "button[name^='auix-sort-']")`, `refute has_element?(view, "th[aria-sort]")`, `refute has_element?(view, "#auix-sort-form-supplier")`, `refute has_element?(view, "[name='auix-sort_action-supplier']")`, `refute has_element?(view, "[name='auix-sort_menu']")`. The no-sortable-field test runs on `product_locations`: `refute has_element?(view, "[name='auix-sort_action-product_location']")` |
| AC-4 | `Index` for the metadata order, `IndexQuery` for the layout order and the runtime `where` · the shuffled seeds of `order_by_layout_test.exs`; then `delete_all_mirror_data()` and `create_sample_products(20, :test)` for the runtime `where` | S4 `"order_by comes from the metadata, the layout and load_items_options"` | carried assertions; the reference column of `Index` is the second `td` of a row, the name column of `IndexQuery` the fourth (carry rule 13) |
| AC-5 | `Index` · the seeds of `special_fields_ui_test.exs` | S5 `"the filter bar filters by each condition"` | carried assertions, plus `.auix-filter-card` |
| AC-6 | `IndexWhere` · the seeds of `where_filter_layout_test.exs` | S6 `"a layout where narrows with the submitted filters"` | carried assertions |
| AC-7 | `IndexQuery` (`products`) · `create_sample_products(100, :test)`; then 5 products for the one-page case | S7 `"the pages bar pages through the rows"` | carried assertions, plus `.auix-pagination-container`; S7 clicks no sort button |
| AC-8 | `IndexQuery` (`product_locations`, `pagination_disabled?: true`) · `create_sample_product_locations(Index.default_infinity_scroll_items_load() + 10, :test)` | S8 `"infinite scroll loads the first batch without a pages bar"` | `refute has_element?(view, "div[name='auix-pages_bar-product_locations']")`; the count of `LazyHTML.query(…, "#auix-table-mirror-#{backend.slug}-index-query-product_locations-index tr")` equals `Index.default_infinity_scroll_items_load()` |
| AC-9 | `Index` · the seeds of `selected_test.exs` | S9 `"rows are selected, deselected and deleted in bulk"` | carried assertions |
| AC-10 | `IndexActions` · the seeds of `selected_bulk_action_test.exs` | S10 `"a custom bulk action runs on the selection"` | carried assertions |
| AC-11 | `Index` (`products`) for the frame, `IndexCards` (`products`) for the content, `IndexCards` (`product_transactions`) for the grid, `IndexActions` (`product_locations`) for the menu · the seeds of the four card files; `create_sample_products_with_transactions(1, 3, :test)`; `create_sample_product_locations(1, :test)` | S11 `"index cards show their frame, content, grid and menu"` | carried assertions, plus `.auix-items-card-container`, `.auix-items-card-title`, `.auix-items-card-menu`. Grid, with `m` the mobile table id of the `product_transactions` route: `[name='auix-card-title']` holds `"#"`; `[name='auix-card-subtitle']` holds `"Transaction"`; no `[name='auix-items-table']`; `.auix-items-cards [name='auix-items-card']`; `.auix-index-sort-action.auix-index-sort-action--always`; `#auix-sort-form-product_transaction option[value='cost']`; the card body has the label `"Quantity"` and no label `"Product"`. Menu, on `product_locations`: the selectors of `index_card_actions_test.exs` with `auix-edit-product_location`, `auix-copy-product_location`, `auix-archive-product_location`, `auix-delete-product_location` and `auix-show-product_location` |
| AC-12 | `IndexActions` · `create_sample_products(3, :test)`, `create_sample_products_with_suppliers(1, 2)` | S12 `"index actions and their icons are replaced, added and removed"` | carried assertions of `create_ui_actions_index_test.exs` on `products`, plus `[name='auix-index-header-actions']`, `[name='auix-index-footer-actions']`, `.auix-index-row-action`. The three tests of `action_icons_index_test.exs` run on `suppliers`, each selector with `supplier` for `product` and `New Supplier` for `New Product`: `a[name='auix-new-supplier'][title='New Supplier'][aria-label='New Supplier'] span.auix-action-icon span.hero-plus`, `button[name='auix-selected_check_all-supplier']`, `a[name='auix-show-supplier']`, `a[name='auix-edit-supplier']`, `a[name='auix-delete-supplier']`, `#auix-delete-all-button-supplier` |

##### Carry rules
These rules apply to every row of `##### Replaced files`.
1. `file → S` means: scenario `S` makes every assertion of every test of that file, except the tests the row lists under Dropped. The old file is the source of the selectors, the input names and the drives.
2. Re-pointing an Ecto (inventory) test: a guide module becomes the `MirrorCtx` / `MirrorAsh` module of the same last name; a route becomes `mirror_path(backend, "<variant slug>", "<source>", "<suffix>")`; a seed call keeps its name and arguments (`Aurora.Uix.Test.Mirror.Seeds`); a `delete_all_*_data()` call is removed, because `each_backend/2` empties the mirror tables. Selectors, input names and element names stay as written.
3. `on :ash` in a row means the file is the Ash twin of an Ecto file in the same row: its assertions are the Ecto ones, and the scenario makes them on `:ash` by running there. A test listed as `Ash-only` has no Ecto twin: carry it with the name map the row gives, and assert it on both backends.
4. An assertion on an `auix-field-*` id, and an `=~` on rendered HTML, is rewritten as `has_element?/2` on the same element, selected by the first of these it has: its `name` attribute, its input name, its `auix-*` class.
5. Every scenario also asserts the structure its row lists, on both backends.
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing> (#<issue>): <what happens>`, and list it under "Library defects found" in the section log. `<issue>` is the issue of that defect: #580 for the Ash field order, #581 for the Ecto crash on a validation error of a nested record, #582 for the Ash form that shows no field error, #583 for the Ash record navigation across a page boundary, #584 for the Ash embeds-one that renders no input while empty, #585 for the DSL compile that fails after a failed compile in the same process. A defect none of the six covers is written `# Library defect on <failing> (new): <what happens>` and listed in the section log as new. Never change a file under `lib/`.
7. Delete each replaced file with `git rm`. Remove from `test/support/app_web/routes.ex` every registration whose module argument starts with the test module of a deleted file. A module a deleted file defines beside its test module moves as `##### Modules & components` of this section says.
8. A views variant declares only the resources and layouts its scenarios mount, and each generated module is mounted by a scenario: an unmounted generated module is a missed line in the coverage total.
9. An id that embeds the route (`auix-table-<route>-index`, `auix-table-<route>-index-mobile`, `auix-table-<route>-index-hook`) is rebuilt from the mirror route: `"#auix-table-mirror-#{backend.slug}-<variant slug>-<source>-index"`. For these ids this rule replaces the last sentence of rule 2.
10. Required fields and seeds. `name`, `status` and `quantity_initial` are required on both backends, and `create_sample_products/3` and `create_sample_products_with_transactions/4` set no `quantity_initial`. A form submit that must save a seeded product sets `quantity_initial`: in the seed attrs (`%{quantity_initial: 1}`) when the form has no `quantity_initial` input, in the submitted params otherwise. A form that renders the `:product_barcode` inputs (the default product form of the `Default` variant, the `OneToOne` variant) saves only with `product_barcode: %{code: "<code>"}` in the submitted params.
11. A validation message is the text of the backend: `can't be blank` on `:ctx`, `is required` on `:ash`. Assert the `.auix-error-message` element on both backends and the text of the running backend.
12. A raw SQL statement on a guide table and a `Repo` call on a guide schema become an `Aurora.Uix.Repo` call on the `MirrorCtx` schema of the same table. Persisted values are read through `MirrorCtx` schemas on both backends: the tables are shared.
13. A carried assertion that fails on both backends because the variant is not the old views module (another field list, another seed, another column position) is restated for the variant: the fact it states stays, and its selector and expected value are recomputed from the variant DSL this section gives. It is removed only when the variant no longer has the thing it asserts; each removal is listed in the section log with that reason.
14. `##### Backend differences` of this section lists what the probe measured. Each entry is asserted as the entry says. An assertion that fails on one backend only and has no entry falls under rule 6.

##### Backend differences
Measured by the probe: none. Every carried assertion of this section held on both backends.

##### Variant rules
1. A variant is the three files `UI-2` defines: `test/support/mirror_web/variants/<name>.ex` (module `Aurora.UixWeb.Test.Mirror.Variants.<Name>`), `test/support/mirror_web/ash/<name>.ex` and `test/support/mirror_web/ctx/<name>.ex`. Its routes are one `RoutesHelper.register_mirror(<Name>, "<slug>", [<sources>])` line in `test/support/app_web/routes.ex`, below the existing `register_mirror` lines.
2. "DSL of `<old file>`" means the `auix_resource_metadata` and `auix_create_ui` calls of that file, moved into the `quote` of the variant's `__using__/1`. `auix_resource_metadata(:x, context: …, schema: …)` and `auix_resource_metadata(:x, ash_resource: …)` become `mirror_resource(:x)`; resource options and `field` lines go in its `do` block, unchanged. For an Ash (blog) source file the row gives the resource and field names to use.
3. A function a layout references (`&__MODULE__.fun/1`) becomes a public function of the variant definition module with `@doc false`, referenced as `&Aurora.UixWeb.Test.Mirror.Variants.<Name>.fun/1`. A handler module a layout names becomes `Aurora.UixWeb.Test.Mirror.Handlers.<SameLastName>` at `test/support/mirror_web/handlers/<name>.ex`, body unchanged.
4. When two sources in one variant give the same resource the same layout type, the row says which list is kept; a positional selector (`nth-child`, `nth-of-type`) of a carried assertion is recomputed for that list.
5. When a row moves a source's DSL to another resource (for example a products test onto `:product_location`), its fields are replaced by fields of that resource with the same type, its seed call by that resource's seed function, and each carried assertion states the same fact about the new resource.
6. A variant definition module that defines function components starts with `use Aurora.Uix.CoreComponentsImporter` and `import Aurora.Uix.Templates.Basic.RoutingComponents` (`<.button>` comes from the first, `<.auix_link>` from the second; without the import the module fails to compile with `undefined function auix_link/1`). Its `__using__/1` and its functions live in the same module.
7. A function with `~H` written inside the `quote` of `__using__/1` (the `render/1` of a host LiveView) takes its argument as `var!(assigns)`: `def render(var!(assigns)) do ~H"…" end`.
8. A variant that reads another variant of its own backend gets that module from `Aurora.UixWeb.Test.Mirror.sibling/2`, called in `__using__/1` before the `quote` and unquoted inside it: `views = Aurora.UixWeb.Test.Mirror.sibling(opts[:backend], <Name>)`.
9. An `Aurora.Uix.RouteHelper.auix_live_resources/3` line of a variant goes in `test/support/app_web/routes.ex` beside the existing `auix_live_resources` lines, below `require Aurora.Uix.RouteHelper`, one line per backend.
10. Run-time compile. `mix test --cover` counts the library code that runs while a module compiles only when that module compiles during the run, and the files under `test/support/` compile before it. Every module under `test/support/` that calls any of `auix_resource_metadata`, `auix_create_ui`, `auix_create_layout` keeps that DSL in the `quote` of the `__using__/1` of a definition module, and `assert_run_time_views/0` of `test/cases/generation_test.exs` (S6 of `UI-5`) compiles the definition again under a `GenerationSample<n>` name while the suite runs and asserts that its signature (resource names, layouts, and the kind and sorted fields of every module of the registry) equals the signature of the views module the scenarios mount. A variant is one atom, its last name, in `@run_time_variants` of that file, and is compiled on both backends. Any other definition is one `{definition, backend, views module}` tuple in `@run_time_single_views`. This section appends its five variants to `@run_time_variants`, in this order: `Index`, `IndexQuery`, `IndexWhere`, `IndexCards`, `IndexActions`. It adds no test and no other definition. Proven with a probe on `main` at f6aa246: each of them compiled under a `GenerationSample<n>` name on both backends with the signature of its views module.

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
1. Variants (rules above). Each block is the content of the `quote` of `__using__/1`, after `use Aurora.UixWeb.Test.Mirror, unquote(opts)`, as the probe compiled it on both backends.

   **`Index`** · slug `index` · sources `products`, `product_locations`, `suppliers`. `:product` merges the resource block of `sortable_columns_test.exs` with the `status` and `product_location_id` lines of `special_fields_ui_test.exs`; `:product_location` and `:supplier` carry `sort_disabled_test.exs`.
     ```elixir
     mirror_resource :product do
       order_by(:reference)
       field(:cost, sortable?: false)
       field :image do
         sortable?(true)
         upload(allow: [accept: ~w(.png)], consume: &Function.identity/1)
       end
       field(:status,
         html_type: :select,
         data: %{
           select: %{
             opts: [
               "In stock": "in_stock",
               Discontinued: "discontinued",
               "Only available online": "online_only",
               "Only available in the store": "in_store_only"
             ],
             multiple: false
           }
         }
       )
       field(:product_location_id, option_label: :name)
     end
     mirror_resource :product_location do
       field(:reference, sortable?: false)
       field(:name, sortable?: false)
     end
     mirror_resource(:supplier)
     auix_create_ui do
       index_columns(:product, [
         :reference,
         :name,
         :cost,
         :image,
         :product_location_id,
         :status,
         :inactive,
         :quantity_at_hand,
         :labels,
         description: [sortable?: false]
       ])
       edit_layout :product do
         stacked([:reference, :name, :description, :status])
       end
       index_columns(:product_location, [:reference, :name])
       index_columns(:supplier, [:name, :country], sort_disabled?: true)
     end
     ```

   **`IndexQuery`** · slug `index-query` · sources `products`, `product_locations`
     ```elixir
     mirror_resource :product do
       order_by(:reference)
     end
     mirror_resource(:product_location)
     auix_create_ui do
       index_columns(:product, [:id, :reference, :name, :cost],
         order_by: :name,
         handler_module: Aurora.UixWeb.Test.Mirror.Handlers.LoadItemsOptionsHandler
       )
       index_columns(:product_location, [:reference, :name], order_by: :name, pagination_disabled?: true)
     end
     ```

   **`IndexWhere`** · slug `index-where` · sources `products`
     ```elixir
     mirror_resource :product do
       order_by(:reference)
     end
     auix_create_ui do
       index_columns(:product, [:reference, :name],
         order_by: :name,
         where: [{:reference, :between, "item_group_2b", "item_group_3d"}]
       )
     end
     ```

   **`IndexCards`** · slug `index-cards` · sources `products`, `product_transactions`. The grid of `index_card_grid_test.exs` sits on `:product_transaction`, whose `:product` column is a many-to-one, as `:product_location` is in the source: the card body leaves the association out. The module defines `def card_title(assigns), do: "#" <> assigns.entity.type` with `@doc false`.
     ```elixir
     mirror_resource(:product)
     mirror_resource(:product_transaction)
     auix_create_ui do
       index_columns :product, [:reference, :name, :description, :quantity_at_hand] do
         card title: :name, subtitle: :reference do
           group "Stock" do
             field(:quantity_at_hand, label: "On hand")
           end
         end
       end
       index_columns :product_transaction, [:type, :quantity, :cost, :product] do
         card title: &Aurora.UixWeb.Test.Mirror.Variants.IndexCards.card_title/1, subtitle: "Transaction", show_on: :all do
           inline([:quantity, :product])
         end
       end
     end
     ```

   **`IndexActions`** · slug `index-actions` · sources `products`, `product_locations`, `suppliers`. The module starts as variant rule 6 says and defines, with `@doc false`: the seven `custom_…` functions of `create_ui_actions_index_test.exs`, unchanged; `deactivate_selected/1` (both clauses) of `selected_bulk_action_test.exs`, unchanged; `archive_action/1` and `copy_action/1` of `index_card_actions_test.exs` with the names `auix-archive-product_location` and `auix-copy-product_location`; `def delete_icon(_assigns), do: "hero-x-mark"`.
     ```elixir
     mirror_resource(:product)
     mirror_resource(:product_location)
     mirror_resource(:supplier)
     auix_create_ui do
       index_columns(:product, [:reference, :name, :description, :quantity_at_hand, :inactive],
         remove_row_action: :default_row_edit,
         add_row_action: {:custom_row_action_replaced, &Aurora.UixWeb.Test.Mirror.Variants.IndexActions.custom_row_action_to_replace/1},
         add_row_action: {:custom_row_action_added, &Aurora.UixWeb.Test.Mirror.Variants.IndexActions.custom_row_action_to_add/1},
         insert_row_action: {:custom_row_action_inserted, &Aurora.UixWeb.Test.Mirror.Variants.IndexActions.custom_row_action_to_insert/1},
         add_header_action: {:custom_header_action_added, &Aurora.UixWeb.Test.Mirror.Variants.IndexActions.custom_header_action_added/1},
         insert_header_action: {:custom_header_action_inserted, &Aurora.UixWeb.Test.Mirror.Variants.IndexActions.custom_header_action_inserted/1},
         replace_header_action: {:default_new, &Aurora.UixWeb.Test.Mirror.Variants.IndexActions.custom_header_action_directly_replaced/1},
         add_footer_action: {:custom_footer_action, &Aurora.UixWeb.Test.Mirror.Variants.IndexActions.custom_footer_action/1},
         handler_module: Aurora.UixWeb.Test.Mirror.Handlers.SelectedBulkActionIndexHandler,
         add_selected_action: {:deactivate_selected, &Aurora.UixWeb.Test.Mirror.Variants.IndexActions.deactivate_selected/1}
       )
       edit_layout :product do
         inline([:reference, :name, :description])
         inline([:quantity_at_hand, :quantity_initial])
         inline([:list_price, :rrp])
       end
       show_layout :product do
         inline([:reference, :name, :description])
         inline([:quantity_at_hand, :quantity_initial])
         inline([:list_price, :rrp])
       end
       index_columns(:product_location, [:reference, :name],
         remove_row_action: :default_row_show,
         insert_row_action: {:archive, &Aurora.UixWeb.Test.Mirror.Variants.IndexActions.archive_action/1, destructive?: true},
         add_row_action: {:copy, &Aurora.UixWeb.Test.Mirror.Variants.IndexActions.copy_action/1}
       )
       index_columns(:supplier, [:name, :country],
         action_icons: [
           default_row_show: "★",
           default_row_edit: "/images/edit.svg",
           default_row_delete: &Aurora.UixWeb.Test.Mirror.Variants.IndexActions.delete_icon/1,
           default_selected_delete_all: "hero-archive-box-x-mark"
         ]
       )
     end
     ```

2. Handlers moved (variant rule 3): `Aurora.UixWeb.LoadItemsOptionsHandler` of `load_items_options_test.exs` becomes `Aurora.UixWeb.Test.Mirror.Handlers.LoadItemsOptionsHandler` at `test/support/mirror_web/handlers/load_items_options_handler.ex`; `Aurora.UixWeb.SelectedBulkActionIndexHandler` of `selected_bulk_action_test.exs` becomes `…Handlers.SelectedBulkActionIndexHandler` at `…/handlers/selected_bulk_action_index_handler.ex`. Bodies unchanged, `@moduledoc false` added. Inside the second, `Aurora.Uix.Guides.Inventory` becomes `Aurora.Uix.Test.MirrorCtx`; on `:ash` the handler still writes through `MirrorCtx`, and the shared table makes the change visible.
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

Facts this section builds on, proven on `main` at f6aa246 with a probe: the seven variants below compiled on both backends from the DSL written there; the replaced LiveView tests ran against them with their routes re-pointed; the S1 submit below and the four-field upload flow ran on both backends.
- `Aurora.Uix.Integration.FieldsParser.field_disabled/1` (`lib/aurora_uix/integration/fields_parser.ex`) disables the fields named `:id`, `:deleted` and `:inactive`. The `Form` variant declares `field(:inactive, disabled: false)`, so that a form can set a boolean.
- `select[name='product[grade]']` has three `option` elements, one per enum value, on both backends.
- The live file input of an upload field is `input[type='file'][name='<field>']`, and `file_input(view, "#auix-product-form", <field>, entries)` addresses it.
- An upload on the `:string` fields `description` and `status` works on both backends.

##### Acceptance criteria
- [ ] AC-1: S1 creates a product through `/new` on both backends with a value for every field type of the `Form` variant (text, textarea, integer, float, decimal, boolean, date, time, both datetimes, the string select, the enum, the multi-select, the many-to-one select), and reads every value back from the row `MirrorCtx.Product` loads; the new row appears in the index without a remount; the titles and subtitles of the `Options` variant render on the new form
- [ ] AC-2: S2 edits that product from the index and from the show view (`show-edit`), changes one field of every type, reads the values back, and deletes the row from the index
- [ ] AC-3: S3 asserts that a blank required field keeps the form open and writes no row on both backends; the new form shows `.auix-error-message` under the field on both backends (text per carry rule 11); the edit form shows it on `:ctx` (`##### Backend differences`); inputs and show inputs carry `.auix-form-field-container`; `input/1` with `copyable: true` renders its copy button, and warns when it has no `id`
- [ ] AC-4: S4 asserts `.auix-flash--success` and `.auix-flash--warning` with their icon, and no flash element without a message
- [ ] AC-5: S5 asserts the discard guard: a clean form closes; a changed form opens `#auix-product-discard-confirm-modal`; keep editing keeps the change; discard closes without saving; a second close request while the dialog is open keeps editing; with `unsaved_changes_guard_disabled?: true` a changed form closes without a prompt
- [ ] AC-6: S6 asserts the select field, the enum select with one option per enum value, and a field with `html_type: :unimplemented`: read-only value, the empty message, joined values in the index cell
- [ ] AC-7: S7 asserts the multi-select: one checkbox per value and the empty-list sentinel; stored values checked on edit; toggle all; every checked value saved; show lists the selection, and the empty message for an empty one; label, header and footer actions replaced and added
- [ ] AC-8: S8 asserts that a true boolean renders checked, a true disabled boolean disabled and checked, a false one unchecked, from the edit route, from the index and from the show view
- [ ] AC-9: S9 asserts uploads on the four upload fields of the `Uploads` variant: the live file input of each; an entry and its cancel; the `consume` result persisted for arity 1 (`image`) and arity 2 (`description`); a save without a file keeps the stored values; `{:error, reason}` (`status`) aborts the save with the reason in the flash and writes no row; a product with a stored `image` and no `thumbnail` shows no download button; a product with a stored `thumbnail` shows the button, and its click pushes `auix_download`; `:no_download`; `upload_fields/1`
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
| AC-1 | `Form`, `Options` · `create_sample_product_locations(2, :test)` | S1 `"a product is created with every field type"` | on `mirror_path(backend, "form", "products", "/new")`: `form("#auix-product-form", product: %{reference: "f-1", name: "Form one", description: "Long text", quantity_initial: "5", units_per_box: "12", margin: "0.25", list_price: "9.99", released_on: "2026-01-15", opens_at: "08:30", audited_at: "2026-01-15T10:00", discontinued_at: "2026-02-01T12:00", status: "online_only", grade: "premium", inactive: "true", labels: ["", "fragile", "hazardous"], product_location_id: <id of the first location>}) \|> render_submit()`; `Repo.get_by!(MirrorCtx.Product, reference: "f-1")` has `quantity_initial` equal to `Decimal.new("5")` (`Decimal.equal?/2`), `units_per_box: 12`, `margin: 0.25`, `list_price` equal to `9.99`, `released_on: ~D[2026-01-15]`, `opens_at: ~T[08:30:00]`, `audited_at: ~N[2026-01-15 10:00:00]`, `discontinued_at: ~U[2026-02-01 12:00:00Z]`, `status: "online_only"`, `grade: :premium`, `inactive: true`, `deleted: false`, `labels: [:fragile, :hazardous]` and the location id; the index shows `td` cells `"f-1"` and `"Fragile, Hazardous"`; `.auix-form-container`, `[name='auix-form-footer-actions']`, `textarea[name='product[description]']`. The six tests of `create_ui_layout_test.exs` run on the `Options` routes |
| AC-2 | `Form`, `Options` · `create_sample_products(3, :test, %{quantity_initial: 1})`, `create_sample_product_locations(2, :test)` | S2 `"a product is edited from the index and from the show view, then deleted"` | carried assertions of the four `create_ui_layout_test.exs` tests on the `Options` routes; on the `Form` edit route, a submit that changes one field of each type and a read of the row, as S1 reads it |
| AC-3 | `Form` · none | S3 `"a blank required field keeps the form open and marks the field"` | on `/new`: submit `product: %{reference: "r", name: ""}`; `assert has_element?(view, "#auix-product-form .auix-error-message")`; `assert Repo.aggregate(MirrorCtx.Product, :count) == 0`. Then `create_sample_products(1, :test)` and the two tests of `form_controls_test.exs` on the `Form` edit and show routes; its `.auix-error-message` assertion after the blank edit submit runs inside `if backend.name == :ctx`, and `assert has_element?(view, "#auix-product-form")` and the unchanged row are asserted on both. The five tests of `core_components_input_test.exs` run once, before `each_backend/2` |
| AC-4 | `FormOptions` · `create_sample_products(1, :test)` | S4 `"success and warning flashes render with their class and icon"` | carried assertions |
| AC-5 | `Form`, `FormOptions` · `create_sample_products(1, :test)` | S5 `"the discard guard holds a changed form"` | carried assertions |
| AC-6 | `Form`, `Renderers` · `create_sample_products(2, :test, …)` with labels on the first | S6 `"select, enum and unimplemented fields render their options and values"` | carried assertions: `"Test select field"` on the `Form` routes, the three tests of `unimplemented_field_ui_test.exs` on the `Renderers` routes; the `select[name='product[grade]'] option` count on the `Form` new route is 3 |
| AC-7 | `Form`, `FormOptions` · the seeds of `multi_select_ui_test.exs` | S7 `"a multi-select checks, toggles, saves and shows its values"` | carried assertions, plus `.auix-multi-select-container` |
| AC-8 | `Form` · the seed of `checkbox_checked_test.exs` | S8 `"booleans keep their checked state in the edit form"` | carried assertions |
| AC-9 | `Uploads` · the seeds of `upload_field_test.exs`, each `Repo.insert!(%Product{…})` on `MirrorCtx.Product` | S9 `"an upload field selects, cancels, consumes and downloads a file"` | carried assertions, plus `.auix-upload-entry`, each on the field step 2 assigns: the tests of `Aurora.UixWeb.Test.UploadFieldTest` on `image`; the tests of `DownloadUploadFieldTest` on `thumbnail` (`file_input(view, "#auix-product-form", :thumbnail, …)`, and a seed that stores `thumbnail:` where the old one stores `image:`); the test of `SocketAwareUploadFieldTest` on `description` (`product.description == "new:#{content}"`); the test of `upload_field_error_test.exs` on `status`. A no-download assertion seeds a product with `image` only. An `input[type='file']` presence assertion names the field: `input[type='file'][name='image']` |
| AC-10 | `Renderers` · the seeds of `custom_field_renderers_test.exs` | S10 `"custom renderers replace the field in index, show and form"` | carried assertions of `CustomFieldRenderersTest`; the `index_columns` test asserts `span.auix-index-cols-marker` with `"COL:This is the item test-1 as described."`, `td` with `"item_test-1"` and the header `"ZZZ_CustomRef"`; the inline-options test asserts `input[name='product[quantity_initial]'][readonly]` |
| AC-11 | `PredefinedRenderers`, `RendererModuleTable`, `RendererPrecedence`, `Renderers` · the seeds of `predefined_renderers_test.exs` | S11 `"predefined renderers and html_type tables resolve in their precedence"` | carried assertions; each `Application.put_env/3` is undone with `on_exit/1`, as the old `setup` blocks do |
| AC-12 | `FormOptions` · `create_sample_products(1, :test)` | S12 `"form and show actions and their icons are added and replaced"` | carried assertions, plus `[name='auix-form-header-actions']`, `[name='auix-show-header-actions']` |

##### Carry rules
These rules apply to every row of `##### Replaced files`.
1. `file → S` means: scenario `S` makes every assertion of every test of that file, except the tests the row lists under Dropped. The old file is the source of the selectors, the input names and the drives.
2. Re-pointing an Ecto (inventory) test: a guide module becomes the `MirrorCtx` / `MirrorAsh` module of the same last name; a route becomes `mirror_path(backend, "<variant slug>", "<source>", "<suffix>")`; a seed call keeps its name and arguments (`Aurora.Uix.Test.Mirror.Seeds`); a `delete_all_*_data()` call is removed, because `each_backend/2` empties the mirror tables. Selectors, input names and element names stay as written.
3. `on :ash` in a row means the file is the Ash twin of an Ecto file in the same row: its assertions are the Ecto ones, and the scenario makes them on `:ash` by running there. A test listed as `Ash-only` has no Ecto twin: carry it with the name map the row gives, and assert it on both backends.
4. An assertion on an `auix-field-*` id, and an `=~` on rendered HTML, is rewritten as `has_element?/2` on the same element, selected by the first of these it has: its `name` attribute, its input name, its `auix-*` class.
5. Every scenario also asserts the structure its row lists, on both backends.
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing> (#<issue>): <what happens>`, and list it under "Library defects found" in the section log. `<issue>` is the issue of that defect: #580 for the Ash field order, #581 for the Ecto crash on a validation error of a nested record, #582 for the Ash form that shows no field error, #583 for the Ash record navigation across a page boundary, #584 for the Ash embeds-one that renders no input while empty, #585 for the DSL compile that fails after a failed compile in the same process. A defect none of the six covers is written `# Library defect on <failing> (new): <what happens>` and listed in the section log as new. Never change a file under `lib/`.
7. Delete each replaced file with `git rm`. Remove from `test/support/app_web/routes.ex` every registration whose module argument starts with the test module of a deleted file. A module a deleted file defines beside its test module moves as `##### Modules & components` of this section says.
8. A views variant declares only the resources and layouts its scenarios mount, and each generated module is mounted by a scenario: an unmounted generated module is a missed line in the coverage total.
9. An id that embeds the route (`auix-table-<route>-index`, `auix-table-<route>-index-mobile`, `auix-table-<route>-index-hook`) is rebuilt from the mirror route: `"#auix-table-mirror-#{backend.slug}-<variant slug>-<source>-index"`. For these ids this rule replaces the last sentence of rule 2.
10. Required fields and seeds. `name`, `status` and `quantity_initial` are required on both backends, and `create_sample_products/3` and `create_sample_products_with_transactions/4` set no `quantity_initial`. A form submit that must save a seeded product sets `quantity_initial`: in the seed attrs (`%{quantity_initial: 1}`) when the form has no `quantity_initial` input, in the submitted params otherwise. A form that renders the `:product_barcode` inputs (the default product form of the `Default` variant, the `OneToOne` variant) saves only with `product_barcode: %{code: "<code>"}` in the submitted params.
11. A validation message is the text of the backend: `can't be blank` on `:ctx`, `is required` on `:ash`. Assert the `.auix-error-message` element on both backends and the text of the running backend.
12. A raw SQL statement on a guide table and a `Repo` call on a guide schema become an `Aurora.Uix.Repo` call on the `MirrorCtx` schema of the same table. Persisted values are read through `MirrorCtx` schemas on both backends: the tables are shared.
13. A carried assertion that fails on both backends because the variant is not the old views module (another field list, another seed, another column position) is restated for the variant: the fact it states stays, and its selector and expected value are recomputed from the variant DSL this section gives. It is removed only when the variant no longer has the thing it asserts; each removal is listed in the section log with that reason.
14. `##### Backend differences` of this section lists what the probe measured. Each entry is asserted as the entry says. An assertion that fails on one backend only and has no entry falls under rule 6.

##### Backend differences
Measured by the probe.
- `:ash`: an edit form submitted with a blank required field stays open and writes nothing, shows `.auix-flash--error`, shows no `.auix-error-message` and shows the stored value in the input (library defect #582 on `:ash`). The new form shows `.auix-error-message` on both backends.
- Validation text follows carry rule 11: `"Test CREATE new, context, basic layout"` of `create_ui_layout_test.exs` matches `can&#39;t be blank` on `:ctx` and `is required` on `:ash`.
- Every other carried assertion of this section held on both backends.

##### Variant rules
1. A variant is the three files `UI-2` defines: `test/support/mirror_web/variants/<name>.ex` (module `Aurora.UixWeb.Test.Mirror.Variants.<Name>`), `test/support/mirror_web/ash/<name>.ex` and `test/support/mirror_web/ctx/<name>.ex`. Its routes are one `RoutesHelper.register_mirror(<Name>, "<slug>", [<sources>])` line in `test/support/app_web/routes.ex`, below the existing `register_mirror` lines.
2. "DSL of `<old file>`" means the `auix_resource_metadata` and `auix_create_ui` calls of that file, moved into the `quote` of the variant's `__using__/1`. `auix_resource_metadata(:x, context: …, schema: …)` and `auix_resource_metadata(:x, ash_resource: …)` become `mirror_resource(:x)`; resource options and `field` lines go in its `do` block, unchanged. For an Ash (blog) source file the row gives the resource and field names to use.
3. A function a layout references (`&__MODULE__.fun/1`) becomes a public function of the variant definition module with `@doc false`, referenced as `&Aurora.UixWeb.Test.Mirror.Variants.<Name>.fun/1`. A handler module a layout names becomes `Aurora.UixWeb.Test.Mirror.Handlers.<SameLastName>` at `test/support/mirror_web/handlers/<name>.ex`, body unchanged.
4. When two sources in one variant give the same resource the same layout type, the row says which list is kept; a positional selector (`nth-child`, `nth-of-type`) of a carried assertion is recomputed for that list.
5. When a row moves a source's DSL to another resource (for example a products test onto `:product_location`), its fields are replaced by fields of that resource with the same type, its seed call by that resource's seed function, and each carried assertion states the same fact about the new resource.
6. A variant definition module that defines function components starts with `use Aurora.Uix.CoreComponentsImporter` and `import Aurora.Uix.Templates.Basic.RoutingComponents` (`<.button>` comes from the first, `<.auix_link>` from the second; without the import the module fails to compile with `undefined function auix_link/1`). Its `__using__/1` and its functions live in the same module.
7. A function with `~H` written inside the `quote` of `__using__/1` (the `render/1` of a host LiveView) takes its argument as `var!(assigns)`: `def render(var!(assigns)) do ~H"…" end`.
8. A variant that reads another variant of its own backend gets that module from `Aurora.UixWeb.Test.Mirror.sibling/2`, called in `__using__/1` before the `quote` and unquoted inside it: `views = Aurora.UixWeb.Test.Mirror.sibling(opts[:backend], <Name>)`.
9. An `Aurora.Uix.RouteHelper.auix_live_resources/3` line of a variant goes in `test/support/app_web/routes.ex` beside the existing `auix_live_resources` lines, below `require Aurora.Uix.RouteHelper`, one line per backend.
10. Run-time compile. `mix test --cover` counts the library code that runs while a module compiles only when that module compiles during the run, and the files under `test/support/` compile before it. Every module under `test/support/` that calls any of `auix_resource_metadata`, `auix_create_ui`, `auix_create_layout` keeps that DSL in the `quote` of the `__using__/1` of a definition module, and `assert_run_time_views/0` of `test/cases/generation_test.exs` (S6 of `UI-5`) compiles the definition again under a `GenerationSample<n>` name while the suite runs and asserts that its signature (resource names, layouts, and the kind and sorted fields of every module of the registry) equals the signature of the views module the scenarios mount. A variant is one atom, its last name, in `@run_time_variants` of that file, and is compiled on both backends. Any other definition is one `{definition, backend, views module}` tuple in `@run_time_single_views`. This section appends its seven variants to `@run_time_variants`, in this order: `Form`, `FormOptions`, `Uploads`, `Renderers`, `PredefinedRenderers`, `RendererModuleTable`, `RendererPrecedence`. It adds no test and no other definition. Proven with a probe on `main` at f6aa246: each of them compiled under a `GenerationSample<n>` name on both backends with the signature of its views module.

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
1. In `test/support/mirror_web/mirror.ex` (`UI-2`), `__using__/1` takes its options as one keyword list. Replace its head and first line with
     ```elixir
     defmacro __using__(opts) do
       backend = Keyword.fetch!(opts, :backend)
       uix_opts = Keyword.get(opts, :uix, [])
       Module.put_attribute(__CALLER__.module, :mirror_backend, backend)
     ```
   and, in its `quote`, `use Aurora.Uix` with `use Aurora.Uix, unquote(uix_opts)`. A variant passes the option from its own `__using__/1`, before the `quote`: `opts = Keyword.put(opts, :uix, quote(do: [renderers: %{checkbox: :toggle_switch}]))`, then `use Aurora.UixWeb.Test.Mirror, unquote(opts)` inside the `quote`. The value is quoted because `Aurora.UixWeb.Test.Mirror.__using__/1` receives its argument as AST: a call such as `Keyword.put(unquote(opts), …)` written in the `use` line reaches it unevaluated and `Keyword.fetch!/2` raises.

2. Variants (rules above). Each block is the content of the `quote` of `__using__/1`, after `use Aurora.UixWeb.Test.Mirror, unquote(opts)`, as the probe compiled it on both backends.

   **`Form`** · slug `form` · sources `products`, `product_locations`
     ```elixir
     mirror_resource :product do
       order_by(:reference)
       field(:deleted, disabled: true)
       field(:inactive, disabled: false)
       field(:description, html_type: :textarea)
       field(:status,
         html_type: :select,
         data: %{
           select: %{
             opts: [
               "In stock": "in_stock",
               Discontinued: "discontinued",
               "Only available online": "online_only",
               "Only available in the store": "in_store_only"
             ],
             multiple: false
           }
         }
       )
       field(:product_location_id, option_label: :name)
     end
     mirror_resource :product_location do
       field(:products, omitted: true)
     end
     auix_create_ui do
       index_columns(:product, [:reference, :name, :labels])
       edit_layout :product do
         stacked([:reference, :name, :description, :quantity_initial, :units_per_box, :margin, :list_price, :released_on, :opens_at, :audited_at, :discontinued_at, :status, :grade, :inactive, :deleted, :labels, :product_location_id])
       end
       show_layout :product do
         stacked([:reference, :name, :description, :quantity_initial, :units_per_box, :margin, :list_price, :released_on, :opens_at, :audited_at, :discontinued_at, :status, :grade, :inactive, :deleted, :labels, :product_location_id])
       end
     end
     ```

   **`FormOptions`** · slug `form-options` · sources `products`. The module starts as variant rule 6 says and defines, with `@doc false`: `custom_form_header_action/1` and `custom_form_footer_action/1` of `create_ui_actions_form_test.exs`; `custom_label_action/1`, `custom_header_action/1` and `custom_footer_action/1` of `multi_select_ui_actions_test.exs`, renamed `labels_label_action/1`, `labels_header_action/1` and `labels_footer_action/1`, bodies unchanged.
     ```elixir
     mirror_resource(:product)
     auix_create_ui do
       index_columns(:product, [:reference, :name], handler_module: Aurora.UixWeb.Test.Mirror.Handlers.FlashKindsHandlerHook)
       edit_layout :product,
         unsaved_changes_guard_disabled?: true,
         add_header_action: {:custom_header, &Aurora.UixWeb.Test.Mirror.Variants.FormOptions.custom_form_header_action/1},
         insert_footer_action: {:custom_footer, &Aurora.UixWeb.Test.Mirror.Variants.FormOptions.custom_form_footer_action/1},
         action_icons: [default_save: "hero-bolt"] do
         stacked([
           :reference,
           :name,
           :quantity_initial,
           labels: [
             remove_label_action: :default_toggle_all,
             add_label_action: {:custom_label, &Aurora.UixWeb.Test.Mirror.Variants.FormOptions.labels_label_action/1},
             add_header_action: {:custom_header, &Aurora.UixWeb.Test.Mirror.Variants.FormOptions.labels_header_action/1},
             add_footer_action: {:custom_footer, &Aurora.UixWeb.Test.Mirror.Variants.FormOptions.labels_footer_action/1}
           ]
         ])
       end
       show_layout :product, action_icons: [default_back: "←"] do
         inline([:reference, :name])
       end
     end
     ```

   **`Uploads`** · slug `uploads` · sources `products`. One upload flavour per field: `image` is `Aurora.UixWeb.Test.UploadFieldTest` (arity-1 consumer, no download), `thumbnail` is `DownloadUploadFieldTest`, `description` is `SocketAwareUploadFieldTest` (arity-2 consumer), `status` is `upload_field_error_test.exs` (a consumer that returns `{:error, "bad file"}`).
     ```elixir
     alias Aurora.UixWeb.Test.Mirror.Handlers
     mirror_resource :product do
       field :image do
         upload(allow: [accept: ~w(.png .jpg), max_entries: 1], consume: &Handlers.Consumer.consume_image/1)
       end
       field :thumbnail do
         upload(
           allow: [accept: ~w(.png .jpg), max_entries: 1],
           consume: &Handlers.Consumer.consume_image/1,
           downloadable?: &Handlers.Downloader.can_download?/1,
           download: &Handlers.Downloader.fetch/1
         )
       end
       field :description do
         upload(allow: [accept: ~w(.png .jpg), max_entries: 1], consume: &Handlers.SocketAwareConsumer.consume_with_action/2)
       end
       field :status do
         upload(allow: [accept: ~w(.png .jpg), max_entries: 1], consume: &Handlers.ErrorConsumer.fail/1)
       end
     end
     auix_create_ui do
       show_layout :product do
         stacked([:reference, :name, :quantity_initial, :image, :thumbnail, :description, :status])
       end
       edit_layout :product, [] do
         stacked([:reference, :name, :quantity_initial, :image, :thumbnail, :description, :status])
       end
     end
     ```
   `Consumer`, `Downloader` and `SocketAwareConsumer` of `upload_field_test.exs` and `ErrorConsumer` of `upload_field_error_test.exs` become `Aurora.UixWeb.Test.Mirror.Handlers.Consumer`, `…Handlers.Downloader`, `…Handlers.SocketAwareConsumer` and `…Handlers.ErrorConsumer`, one file each under `test/support/mirror_web/handlers/`, bodies unchanged, `@moduledoc false` added.

   **`Renderers`** · slug `renderers` · sources `products`. The three views modules of `custom_field_renderers_test.exs` do not fit one resource as they are: `index_columns(name: [index_renderer: …])` replaces the resource `index_renderer` of `name`, and the generic `renderer` of `reference` leaves no `input` for `readonly`. The column renderer therefore sits on `description` and the inline option on `quantity_initial`. `inactive` carries no renderer: it is the checkbox `html_type_renderers_app_config_test.exs` switches. The module starts with `use Phoenix.Component` and defines, with `@doc false`: `renderer/1` (both clauses), `index_marker/1`, `edit_marker/1`, `show_marker/1` of `CustomFieldRenderersTest`, and `index_marker/1` of `CustomFieldRenderersIndexColumnsTest` renamed `index_cols_marker/1`.
     ```elixir
     mirror_resource :product do
       field(:reference, renderer: &Aurora.UixWeb.Test.Mirror.Variants.Renderers.renderer/1)
       field(:name,
         index_renderer: &Aurora.UixWeb.Test.Mirror.Variants.Renderers.index_marker/1,
         edit_renderer: &Aurora.UixWeb.Test.Mirror.Variants.Renderers.edit_marker/1,
         show_renderer: &Aurora.UixWeb.Test.Mirror.Variants.Renderers.show_marker/1
       )
       field(:deleted, renderer: :default_checkbox)
       field(:labels, html_type: :unimplemented)
     end
     auix_create_ui do
       index_columns(:product,
         reference: [label: "ZZZ_CustomRef"],
         name: [],
         description: [index_renderer: &Aurora.UixWeb.Test.Mirror.Variants.Renderers.index_cols_marker/1],
         labels: [],
         inactive: []
       )
       edit_layout :product do
         inline([:reference, :name, {:quantity_initial, [readonly: true]}])
         stacked([:inactive, :deleted, :labels])
       end
       show_layout :product do
         stacked([:reference, :name, :inactive, :deleted, :labels])
       end
     end
     ```

   **`PredefinedRenderers`** · slug `predefined-renderers` · sources `products` (`PredefinedRenderersTest` and `PredefinedRenderersInteractiveTest` of `predefined_renderers_test.exs`, which declare different fields). Its `HostToggle` and `HostRegistrar` modules become `Aurora.UixWeb.Test.Mirror.Handlers.HostToggle` and `…Handlers.HostRegistrar`.
     ```elixir
     mirror_resource :product do
       field(:inactive, renderer: :toggle_switch, index_renderer: :toggle_switch, label: "Toggle switch")
       field(:status, renderer: :badge, index_renderer: :badge, label: "Badge")
       field(:reference, renderer: :color, index_renderer: :color, label: "Colour")
       field(:quantity_at_hand, renderer: :progress_bar, index_renderer: :progress_bar, renderer_opts: [max: 100], label: "Progress bar")
       field(:description, renderer: :url, index_renderer: :url, label: "URL")
       field(:cost, renderer: :rating, index_renderer: :rating, renderer_opts: [max: 5], label: "Rating")
     end
     auix_create_ui()
     ```

   **`RendererModuleTable`** · slug `renderer-module-table` · sources `products`; before the `quote`: `opts = Keyword.put(opts, :uix, quote(do: [renderers: %{checkbox: :toggle_switch}]))`
     ```elixir
     mirror_resource(:product)
     auix_create_ui()
     ```

   **`RendererPrecedence`** · slug `renderer-precedence` · sources `products`; before the `quote`: `opts = Keyword.put(opts, :uix, quote(do: [renderers: %{number: :progress_bar}]))`
     ```elixir
     mirror_resource :product do
       renderers(%{text: :badge, number: :rating})
       field(:deleted, show_renderer: :default_checkbox)
     end
     auix_create_ui renderers: %{checkbox: :toggle_switch, text: :default_text, number: :not_a_renderer} do
       index_columns(:product, [:reference, :inactive, :quantity_at_hand], renderers: %{checkbox: :default_checkbox})
     end
     ```

3. Handler moved (variant rule 3): `Aurora.UixWeb.FlashKindsHandlerHook` of `flash_kinds_test.exs` becomes `Aurora.UixWeb.Test.Mirror.Handlers.FlashKindsHandlerHook`.
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

Facts this section builds on, proven on `main` at f6aa246 with a probe: the two variants below compiled on both backends from the DSL written there; the three replaced files ran against them with their routes re-pointed; the S2 sketch below ran on both backends.
- In the show view of the `Show` variant, `Aurora.UixWeb.Test.SectionHelper` (`test/support/section_helper.ex`) reads the tabs as it reads them in a form: `assert_section_button_is_active/3`, `click_section_button/3` and `assert_field_is_visible_in_section/4` hold with the calls of the S2 row.
- An index page holds 40 rows: 100 products make three pages.

##### Acceptance criteria
- [ ] AC-1: S1 asserts, on both backends, that the show view of the `Form` variant (`UI-7`) renders one read-only element per field type inside `.auix-show-container .auix-show-content`, with the seeded value; that a replaced header action and an added footer action of the `Show` variant render in `[name='auix-show-header-actions']` and `[name='auix-show-footer-actions']`; that a product with no value in an optional field renders that field empty and the page still mounts
- [ ] AC-2: S2 asserts groups, sections and tabs in the show layout of the `Show` variant: one `.auix-group-container` with its title; `.auix-sections-container` with one tab button per section; clicking the second tab shows its fields and hides the first tab's
- [ ] AC-3: S3 asserts record navigation: previous on the first record and next on the last are absent; previous and next inside a page open the expected record on both backends; previous into the previous page and next into the next page open the expected record on `:ctx` (`##### Backend differences`); `record_navigator: :none`, `:top`, `:bottom` and the default place the navigator as declared
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
| AC-2 | `Show` · `create_sample_products(1, :test)`; the `/<id>/show` route | S2 `"groups, sections and tabs lay out the show view"` | `assert has_element?(view, ".auix-show-content .auix-group-container")`; `assert has_element?(view, ".auix-group-container", "Quantities")`; `assert has_element?(view, ".auix-show-content .auix-sections-container")`; `assert_section_button_is_active(view, "prices", :tab_index_1)`; `refute_section_button_is_active(view, "dimensions", :tab_index_2)`; `assert_field_is_visible_in_section(view, :product, [:list_price, :rrp], :tab_index_1)`; `refute_field_is_visible_in_section(view, :product, [:width, :height, :length], :tab_index_2)`; `click_section_button(view, "dimensions", :tab_index_2)`; `assert_section_button_is_active(view, "dimensions", :tab_index_2)`; `refute_field_is_visible_in_section(view, :product, [:list_price, :rrp], :tab_index_1)`; `assert_field_is_visible_in_section(view, :product, [:width, :height, :length], :tab_index_2)` |
| AC-3 | `Show`, `ShowNavigator` · `create_sample_products(100, :test)` once for the six tests of `record_navigation_test.exs`; `create_sample_products(10, :test)` and `create_sample_product_locations(5, :test)` for the four of `record_navigation_disable_test.exs` | S3 `"the record navigator moves across records and pages"` | carried assertions, with the references of a 100-row seed: `item_test-001` to `item_test-100`, the last page is `?page=3`, the first row of page 3 is `item_test-081` and the record before it `item_test-080`, the last row of page 2 is `item_test-080` and the record after it `item_test-081`. The two cross-page tests (`"Test previous record in previous page"`, `"Test next record in next page"`) run inside `if backend.name == :ctx` |

##### Carry rules
These rules apply to every row of `##### Replaced files`.
1. `file → S` means: scenario `S` makes every assertion of every test of that file, except the tests the row lists under Dropped. The old file is the source of the selectors, the input names and the drives.
2. Re-pointing an Ecto (inventory) test: a guide module becomes the `MirrorCtx` / `MirrorAsh` module of the same last name; a route becomes `mirror_path(backend, "<variant slug>", "<source>", "<suffix>")`; a seed call keeps its name and arguments (`Aurora.Uix.Test.Mirror.Seeds`); a `delete_all_*_data()` call is removed, because `each_backend/2` empties the mirror tables. Selectors, input names and element names stay as written.
3. `on :ash` in a row means the file is the Ash twin of an Ecto file in the same row: its assertions are the Ecto ones, and the scenario makes them on `:ash` by running there. A test listed as `Ash-only` has no Ecto twin: carry it with the name map the row gives, and assert it on both backends.
4. An assertion on an `auix-field-*` id, and an `=~` on rendered HTML, is rewritten as `has_element?/2` on the same element, selected by the first of these it has: its `name` attribute, its input name, its `auix-*` class.
5. Every scenario also asserts the structure its row lists, on both backends.
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing> (#<issue>): <what happens>`, and list it under "Library defects found" in the section log. `<issue>` is the issue of that defect: #580 for the Ash field order, #581 for the Ecto crash on a validation error of a nested record, #582 for the Ash form that shows no field error, #583 for the Ash record navigation across a page boundary, #584 for the Ash embeds-one that renders no input while empty, #585 for the DSL compile that fails after a failed compile in the same process. A defect none of the six covers is written `# Library defect on <failing> (new): <what happens>` and listed in the section log as new. Never change a file under `lib/`.
7. Delete each replaced file with `git rm`. Remove from `test/support/app_web/routes.ex` every registration whose module argument starts with the test module of a deleted file. A module a deleted file defines beside its test module moves as `##### Modules & components` of this section says.
8. A views variant declares only the resources and layouts its scenarios mount, and each generated module is mounted by a scenario: an unmounted generated module is a missed line in the coverage total.
9. An id that embeds the route (`auix-table-<route>-index`, `auix-table-<route>-index-mobile`, `auix-table-<route>-index-hook`) is rebuilt from the mirror route: `"#auix-table-mirror-#{backend.slug}-<variant slug>-<source>-index"`. For these ids this rule replaces the last sentence of rule 2.
10. Required fields and seeds. `name`, `status` and `quantity_initial` are required on both backends, and `create_sample_products/3` and `create_sample_products_with_transactions/4` set no `quantity_initial`. A form submit that must save a seeded product sets `quantity_initial`: in the seed attrs (`%{quantity_initial: 1}`) when the form has no `quantity_initial` input, in the submitted params otherwise. A form that renders the `:product_barcode` inputs (the default product form of the `Default` variant, the `OneToOne` variant) saves only with `product_barcode: %{code: "<code>"}` in the submitted params.
11. A validation message is the text of the backend: `can't be blank` on `:ctx`, `is required` on `:ash`. Assert the `.auix-error-message` element on both backends and the text of the running backend.
12. A raw SQL statement on a guide table and a `Repo` call on a guide schema become an `Aurora.Uix.Repo` call on the `MirrorCtx` schema of the same table. Persisted values are read through `MirrorCtx` schemas on both backends: the tables are shared.
13. A carried assertion that fails on both backends because the variant is not the old views module (another field list, another seed, another column position) is restated for the variant: the fact it states stays, and its selector and expected value are recomputed from the variant DSL this section gives. It is removed only when the variant no longer has the thing it asserts; each removal is listed in the section log with that reason.
14. `##### Backend differences` of this section lists what the probe measured. Each entry is asserted as the entry says. An assertion that fails on one backend only and has no entry falls under rule 6.

##### Backend differences
Measured by the probe.
- `:ash`: record navigation across a page boundary does not open the expected record: previous from the first row of a page and next from the last row of a page fail the two cross-page assertions, which hold on `:ctx` (library defect #583 on `:ash`). Navigation inside a page holds on both backends.
- Every other carried assertion of this section held on both backends.

##### Variant rules
1. A variant is the three files `UI-2` defines: `test/support/mirror_web/variants/<name>.ex` (module `Aurora.UixWeb.Test.Mirror.Variants.<Name>`), `test/support/mirror_web/ash/<name>.ex` and `test/support/mirror_web/ctx/<name>.ex`. Its routes are one `RoutesHelper.register_mirror(<Name>, "<slug>", [<sources>])` line in `test/support/app_web/routes.ex`, below the existing `register_mirror` lines.
2. "DSL of `<old file>`" means the `auix_resource_metadata` and `auix_create_ui` calls of that file, moved into the `quote` of the variant's `__using__/1`. `auix_resource_metadata(:x, context: …, schema: …)` and `auix_resource_metadata(:x, ash_resource: …)` become `mirror_resource(:x)`; resource options and `field` lines go in its `do` block, unchanged. For an Ash (blog) source file the row gives the resource and field names to use.
3. A function a layout references (`&__MODULE__.fun/1`) becomes a public function of the variant definition module with `@doc false`, referenced as `&Aurora.UixWeb.Test.Mirror.Variants.<Name>.fun/1`. A handler module a layout names becomes `Aurora.UixWeb.Test.Mirror.Handlers.<SameLastName>` at `test/support/mirror_web/handlers/<name>.ex`, body unchanged.
4. When two sources in one variant give the same resource the same layout type, the row says which list is kept; a positional selector (`nth-child`, `nth-of-type`) of a carried assertion is recomputed for that list.
5. When a row moves a source's DSL to another resource (for example a products test onto `:product_location`), its fields are replaced by fields of that resource with the same type, its seed call by that resource's seed function, and each carried assertion states the same fact about the new resource.
6. A variant definition module that defines function components starts with `use Aurora.Uix.CoreComponentsImporter` and `import Aurora.Uix.Templates.Basic.RoutingComponents` (`<.button>` comes from the first, `<.auix_link>` from the second; without the import the module fails to compile with `undefined function auix_link/1`). Its `__using__/1` and its functions live in the same module.
7. A function with `~H` written inside the `quote` of `__using__/1` (the `render/1` of a host LiveView) takes its argument as `var!(assigns)`: `def render(var!(assigns)) do ~H"…" end`.
8. A variant that reads another variant of its own backend gets that module from `Aurora.UixWeb.Test.Mirror.sibling/2`, called in `__using__/1` before the `quote` and unquoted inside it: `views = Aurora.UixWeb.Test.Mirror.sibling(opts[:backend], <Name>)`.
9. An `Aurora.Uix.RouteHelper.auix_live_resources/3` line of a variant goes in `test/support/app_web/routes.ex` beside the existing `auix_live_resources` lines, below `require Aurora.Uix.RouteHelper`, one line per backend.
10. Run-time compile. `mix test --cover` counts the library code that runs while a module compiles only when that module compiles during the run, and the files under `test/support/` compile before it. Every module under `test/support/` that calls any of `auix_resource_metadata`, `auix_create_ui`, `auix_create_layout` keeps that DSL in the `quote` of the `__using__/1` of a definition module, and `assert_run_time_views/0` of `test/cases/generation_test.exs` (S6 of `UI-5`) compiles the definition again under a `GenerationSample<n>` name while the suite runs and asserts that its signature (resource names, layouts, and the kind and sorted fields of every module of the registry) equals the signature of the views module the scenarios mount. A variant is one atom, its last name, in `@run_time_variants` of that file, and is compiled on both backends. Any other definition is one `{definition, backend, views module}` tuple in `@run_time_single_views`. This section appends its two variants to `@run_time_variants`, in this order: `Show`, `ShowNavigator`. It adds no test and no other definition. Proven with a probe on `main` at f6aa246: each of them compiled under a `GenerationSample<n>` name on both backends with the signature of its views module.

##### Replaced files
| Old file (tests) | Home | Dropped, with the reason |
|---|---|---|
| `test/cases_live/create_ui_actions_show_test.exs` (1) | S1 | none |
| `test/cases_live/record_navigation_test.exs` (6) | S3 | none |
| `test/cases_live/record_navigation_disable_test.exs` (4) | S3 | none |

S2 replaces no file: no test on `main` drives a group in a show layout, and none drives a section there. It is the scenario the issue's Target suite names for the show view.

##### Modules & components
1. Variants (rules above). Each block is the content of the `quote` of `__using__/1`, after `use Aurora.UixWeb.Test.Mirror, unquote(opts)`, as the probe compiled it on both backends.

   **`Show`** · slug `show` · sources `products`. The module starts as variant rule 6 says and defines, with `@doc false`, `custom_header_action/1` and `custom_back_footer_action/1` of `test/cases_live/create_ui_actions_show_test.exs`, bodies unchanged.
     ```elixir
     mirror_resource(:product)
     auix_create_ui do
       index_columns(:product, [:reference, :name, :quantity_initial], order_by: :reference)
       edit_layout :product, [] do
         stacked do
           inline([:reference, :name, :description])
           inline([:quantity_initial, :quantity_at_hand])
         end
       end
       show_layout :product,
         replace_header_action: {:default_edit, &Aurora.UixWeb.Test.Mirror.Variants.Show.custom_header_action/1},
         add_footer_action: {:custom_back_action, &Aurora.UixWeb.Test.Mirror.Variants.Show.custom_back_footer_action/1} do
         inline([:reference, :name, :description])
         group "Quantities" do
           inline([:quantity_at_hand, :quantity_initial])
         end
         sections do
           section "Prices" do
             stacked([:list_price, :rrp])
           end
           section "Dimensions" do
             inline([:width, :height, :length])
           end
         end
       end
     end
     ```

   **`ShowNavigator`** · slug `show-navigator` · sources `products`, `product_locations` (DSL of `test/cases_live/record_navigation_disable_test.exs`)
     ```elixir
     mirror_resource(:product)
     mirror_resource(:product_location)
     auix_create_ui do
       index_columns(:product, [:reference, :name, :quantity_initial], order_by: :reference)
       show_layout :product, record_navigator: :none do
         stacked do
           inline([:reference, :name, :description])
           inline([:quantity_initial, :quantity_at_hand])
         end
       end
       edit_layout :product, record_navigator: :bottom do
         stacked do
           inline([:reference, :name, :description])
           inline([:quantity_initial, :quantity_at_hand])
         end
       end
       show_layout :product_location, record_navigator: :top do
         stacked([:reference, :name, :type])
       end
       edit_layout :product_location do
         stacked([:reference, :name, :type])
       end
     end
     ```

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

Facts this section builds on, proven on `main` at f6aa246 with a probe: the ten variants below compiled on both backends from the DSL written there; the replaced LiveView tests ran against them with their routes re-pointed; the assertions moved to another resource and the S8 to S10 submits ran as the red-test rows state them.
- A one-to-many list renders the index columns of the related resource. With the `index_columns` lines of the `OneToMany` variant the columns are the same on both backends: for `product_transactions` the quantity is `td:nth-of-type(2)`; for the `products` list of a location the reference is `td:nth-of-type(1)` and the name `td:nth-of-type(2)`. Without those lines the column order differs on `:ash` (the map-order defect `UI-4` logged).
- On the `products` list of a location, `where: {:name, :between, "Item test-2", "Item test-4"}` with `order_by: [desc: :name]` lists `item_test-4`, `item_test-3`, `item_test-2` out of five seeded products, on both backends. Its `tbody` id is `product_location__products-form`.
- An `option_label` function of arity 1 on `product_transaction.product_id` labels each option `"The <product name>"`; one of arity 2 on `product_barcode.product_id` labels it `"form: <product name>"` in the form and `"show: <product name>"` in the show view. An index that renders such a column calls the function with the row on `:ash`; the two resources therefore declare `index_columns` without `product_id`.
- A many-to-one changed in the `ManyToOne` edit form is saved on both backends when the product has a `quantity_initial` (carry rule 10).
- The S10 params create a product with a packaging and two contacts, and the edit params leave one contact and the material `:bag`, on both backends.


##### Acceptance criteria
- [ ] AC-1: S1 asserts the many-to-one select on both backends: one option per related record; labels from an atom, from a function of the entity and from a function of the assigns and the entity; `query_opts` `order_by` and `where` order and limit the options; the selected value is saved, read back from the row
- [ ] AC-2: S2 asserts the parent record fields of a many-to-one (`{:product_location, :name}`, `product_location: :type`, `:product_location`) in the form and in the show view, and that they change when the select changes and the form is saved
- [ ] AC-3: S3 asserts the one-to-many list: `.auix-one-to-many-field` with one row per child; layout `order_by` and `where`; the empty state for a parent with no child; the list is the index component of the related resource; a parent that is not saved yet offers no new-child link
- [ ] AC-4: S4 asserts one-to-many header, row and footer actions, replaced and added, in the table and in the child cards, and the `action_icons` of the list
- [ ] AC-5: S5 asserts the one-to-one: blank nested inputs on new; pre-filled inputs and the hidden child id on edit; the child's foreign key is not rendered; parent and child are created in one submit; an edit updates the existing child and adds none; show renders the child read-only inside `.auix-one-to-one-container`, and `.auix-one-to-one-empty-msg` when there is none; the association is no index column
- [ ] AC-6: S6 asserts the many-to-many: `.auix-many-to-many-container` with one option per candidate; current members pre-selected; added members written as join rows; a removed member deletes the join row and keeps the supplier; de-selecting everything clears membership; toggle all, the mixed state, and a toggled-all membership that survives submit; show lists the members, and the empty message for none; the association is no index column
- [ ] AC-7: S7 asserts many-to-many label, header and footer actions, and option labels taken from the related resource when no `option_label` is declared
- [ ] AC-8: S8 asserts the embeds-one: `.auix-embeds-one-container` with its nested inputs (`product[packaging][material]`, `product[packaging][fragile]`, `product[packaging][notes]`) on edit on both backends and on new on `:ctx` (`##### Backend differences`), the values in show, and the embedded column in the index
- [ ] AC-9: S9 asserts the embeds-many: `.auix-embeds-many-container`; the entries of a seeded product in show and in edit; `expanded` opens the details; the header and entry action icons; a product created with no contact has none
- [ ] AC-10: S10 asserts two embeds on one schema: one submit creates a product with a packaging and two contacts; one edit changes the packaging and removes one contact; on `:ash`, an invalid contact email keeps the form open, shows `.auix-flash--error` and writes nothing (`##### Backend differences`)
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
| AC-1 | `ManyToOne`, `ManyToOneQueries` · the seeds of `association_many2one_selector_atom_test.exs`, each `create_sample_products/3` call with `quantity_initial: 1` added to its attrs; `create_sample_products_with_transactions(1, 1, :one2)`; `create_sample_products_with_barcodes(1)` | S1 `"a many-to-one select lists, labels, orders and filters its options"` | the four tests of the atom file on `ManyToOne` `products`; after the edit submit of `check_edit`, `assert Repo.get!(MirrorCtx.Product, product_id).product_location_id == location_id_2`, then the edit route is mounted again and the `option[selected][value='#{location_id_2}']` assertion is made on that view (the submit now saves and closes the form; in the source it failed validation and left the form open). Function label, on the edit route of a transaction: `assert has_element?(view, "select[name='product_transaction[product_id]'] option[selected]", "The Item one2-1")`. Assigns label, on a barcode: `select[name='product_barcode[product_id]'] option` holds `"form: <name of its product>"` on the edit route and `"show: <name of its product>"` on the show route. `where_many2one_test.exs` and `ash_many_to_one_select_test.exs` (name `post[author_id]` → `product[product_location_id]`) on `ManyToOneQueries` `products` |
| AC-2 | `ManyToOne`, `ManyToOneQueries` · the seeds of the two source files, unchanged | S2 `"parent fields of a many-to-one follow the selected record"` | `association_many2one_ui_layout_test.exs` on `ManyToOne` `products`; `association_many2one_parent_ui_layout_test.exs` on `ManyToOneQueries` `products` |
| AC-3 | `OneToMany`, `OneToManyComponent` · the seeds of `association_one2many_ui_layout_test.exs`; one product with no transaction; `create_sample_product_locations(1, :test)` and `create_sample_products(5, :test, %{product_location_id: <its id>, quantity_initial: 1})` | S3 `"a one-to-many list shows, orders and filters the children"` | carried assertions, plus `.auix-one-to-many-field`, `[name='auix-one_to_many-header-actions']`; the quantity cells of `"Test order_by"` are `tbody#product__product_transactions-show tr td:nth-of-type(2)`. `"Test where"` of `where_one2many_test.exs` and `"one-to-many where and order_by select and sort the related rows"` of `ash_where_one2many_test.exs` are restated on the location edit route: the cells `tbody#product_location__products-form tr td:nth-of-type(1)` are `["item_test-4", "item_test-3", "item_test-2"]`. The Ash-only empty state is asserted on the product with no transaction. `test/cases/templates/basic/one_to_many_rows_test.exs` runs once, before `each_backend/2` |
| AC-4 | `OneToManyActions` · `create_sample_products_with_transactions(1, 3, :test)` | S4 `"one-to-many actions and icons are replaced and added"` | carried assertions |
| AC-5 | `OneToOne` · `create_sample_products_with_barcodes(2)`, `create_sample_products(1, :test)` | S5 `"a one-to-one child is created, updated and shown with its parent"` | carried assertions |
| AC-6 | `ManyToMany` · `create_sample_products_with_suppliers(2, 4)` | S6 `"many-to-many membership is selected, toggled, saved and shown"` | carried assertions; `join_row_count/0` of the source file becomes `Repo.aggregate(MirrorCtx.ProductSupplier, :count)` (carry rule 12) |
| AC-7 | `ManyToManyActions` · as S6 | S7 `"many-to-many actions are replaced and added"` | carried assertions |
| AC-8 | `Embeds` · `create_sample_products_with_embeds(1)` | S8 `"an embeds-one renders and saves its nested fields"` | carried assertions with the name map of the row; the nested-input assertions on `/new` run inside `if backend.name == :ctx` |
| AC-9 | `Embeds`, `EmbedsExpanded` · `create_sample_products_with_embeds(1)`, `create_sample_products(1, :test)` | S9 `"an embeds-many lists its entries and opens expanded"` | carried assertions |
| AC-10 | `Embeds` · none | S10 `"two embeds on one schema save in one submit"` | `render_submit` of `product: %{reference: …, name: …, quantity_initial: 1, packaging: %{material: "box", fragile: "true", notes: "n"}, contacts: %{"0" => %{email: "a@test.com", name: "A"}, "1" => %{email: "b@test.com", name: "B"}}}`; read the row; on the edit route `render_submit` of `product: %{name: …, packaging: %{material: "bag", fragile: "true", notes: "n"}, contacts: %{"0" => %{email: "a@test.com", name: "A"}}}` and read the row; then, inside `if backend.name == :ash`, `render_submit` of `product: %{name: …, contacts: %{"0" => %{email: "not-an-email", name: "A"}}}`, `assert has_element?(view, "#auix-product-form")`, `assert has_element?(view, ".auix-flash--error")` and the row unchanged. Each submit is `view \|> form("#auix-product-form") \|> render_submit(%{product: …})`: the contact inputs do not exist before an entry is added |

##### Carry rules
These rules apply to every row of `##### Replaced files`.
1. `file → S` means: scenario `S` makes every assertion of every test of that file, except the tests the row lists under Dropped. The old file is the source of the selectors, the input names and the drives.
2. Re-pointing an Ecto (inventory) test: a guide module becomes the `MirrorCtx` / `MirrorAsh` module of the same last name; a route becomes `mirror_path(backend, "<variant slug>", "<source>", "<suffix>")`; a seed call keeps its name and arguments (`Aurora.Uix.Test.Mirror.Seeds`); a `delete_all_*_data()` call is removed, because `each_backend/2` empties the mirror tables. Selectors, input names and element names stay as written.
3. `on :ash` in a row means the file is the Ash twin of an Ecto file in the same row: its assertions are the Ecto ones, and the scenario makes them on `:ash` by running there. A test listed as `Ash-only` has no Ecto twin: carry it with the name map the row gives, and assert it on both backends.
4. An assertion on an `auix-field-*` id, and an `=~` on rendered HTML, is rewritten as `has_element?/2` on the same element, selected by the first of these it has: its `name` attribute, its input name, its `auix-*` class.
5. Every scenario also asserts the structure its row lists, on both backends.
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing> (#<issue>): <what happens>`, and list it under "Library defects found" in the section log. `<issue>` is the issue of that defect: #580 for the Ash field order, #581 for the Ecto crash on a validation error of a nested record, #582 for the Ash form that shows no field error, #583 for the Ash record navigation across a page boundary, #584 for the Ash embeds-one that renders no input while empty, #585 for the DSL compile that fails after a failed compile in the same process. A defect none of the six covers is written `# Library defect on <failing> (new): <what happens>` and listed in the section log as new. Never change a file under `lib/`.
7. Delete each replaced file with `git rm`. Remove from `test/support/app_web/routes.ex` every registration whose module argument starts with the test module of a deleted file. A module a deleted file defines beside its test module moves as `##### Modules & components` of this section says.
8. A views variant declares only the resources and layouts its scenarios mount, and each generated module is mounted by a scenario: an unmounted generated module is a missed line in the coverage total.
9. An id that embeds the route (`auix-table-<route>-index`, `auix-table-<route>-index-mobile`, `auix-table-<route>-index-hook`) is rebuilt from the mirror route: `"#auix-table-mirror-#{backend.slug}-<variant slug>-<source>-index"`. For these ids this rule replaces the last sentence of rule 2.
10. Required fields and seeds. `name`, `status` and `quantity_initial` are required on both backends, and `create_sample_products/3` and `create_sample_products_with_transactions/4` set no `quantity_initial`. A form submit that must save a seeded product sets `quantity_initial`: in the seed attrs (`%{quantity_initial: 1}`) when the form has no `quantity_initial` input, in the submitted params otherwise. A form that renders the `:product_barcode` inputs (the default product form of the `Default` variant, the `OneToOne` variant) saves only with `product_barcode: %{code: "<code>"}` in the submitted params.
11. A validation message is the text of the backend: `can't be blank` on `:ctx`, `is required` on `:ash`. Assert the `.auix-error-message` element on both backends and the text of the running backend.
12. A raw SQL statement on a guide table and a `Repo` call on a guide schema become an `Aurora.Uix.Repo` call on the `MirrorCtx` schema of the same table. Persisted values are read through `MirrorCtx` schemas on both backends: the tables are shared.
13. A carried assertion that fails on both backends because the variant is not the old views module (another field list, another seed, another column position) is restated for the variant: the fact it states stays, and its selector and expected value are recomputed from the variant DSL this section gives. It is removed only when the variant no longer has the thing it asserts; each removal is listed in the section log with that reason.
14. `##### Backend differences` of this section lists what the probe measured. Each entry is asserted as the entry says. An assertion that fails on one backend only and has no entry falls under rule 6.

##### Backend differences
Measured by the probe.
- `:ctx`: a validation error on a nested child (an embeds-many entry, the one-to-one inputs) exits the LiveView with `FunctionClauseError` in `Aurora.Uix.Templates.Basic.Helpers.process_error_detail/1` (library defect #581 on `:ctx`). The invalid-email part of S10 runs on `:ash` only, and no scenario submits a nested child that fails validation on `:ctx`. The section log lists the defect.
- `:ash`: the new form renders no `product[packaging][…]` input before the embeds-one is added (library defect #584 on `:ash`); `:ctx` renders the three inputs at once. The edit form of a product with a packaging renders them on both.
- Both backends: a seeded product without `quantity_initial` fails validation on an edit submit. `check_edit` of the many-to-one files passed on the guide schema for that reason: the form stayed open with the changed option. With carry rule 10 the submit saves; S1 asserts the row and a fresh mount.
- A one-to-many list keeps one column order on both backends only with the `index_columns` lines of the variants below.
- The other carried assertions of this section held on both backends.

##### Variant rules
1. A variant is the three files `UI-2` defines: `test/support/mirror_web/variants/<name>.ex` (module `Aurora.UixWeb.Test.Mirror.Variants.<Name>`), `test/support/mirror_web/ash/<name>.ex` and `test/support/mirror_web/ctx/<name>.ex`. Its routes are one `RoutesHelper.register_mirror(<Name>, "<slug>", [<sources>])` line in `test/support/app_web/routes.ex`, below the existing `register_mirror` lines.
2. "DSL of `<old file>`" means the `auix_resource_metadata` and `auix_create_ui` calls of that file, moved into the `quote` of the variant's `__using__/1`. `auix_resource_metadata(:x, context: …, schema: …)` and `auix_resource_metadata(:x, ash_resource: …)` become `mirror_resource(:x)`; resource options and `field` lines go in its `do` block, unchanged. For an Ash (blog) source file the row gives the resource and field names to use.
3. A function a layout references (`&__MODULE__.fun/1`) becomes a public function of the variant definition module with `@doc false`, referenced as `&Aurora.UixWeb.Test.Mirror.Variants.<Name>.fun/1`. A handler module a layout names becomes `Aurora.UixWeb.Test.Mirror.Handlers.<SameLastName>` at `test/support/mirror_web/handlers/<name>.ex`, body unchanged.
4. When two sources in one variant give the same resource the same layout type, the row says which list is kept; a positional selector (`nth-child`, `nth-of-type`) of a carried assertion is recomputed for that list.
5. When a row moves a source's DSL to another resource (for example a products test onto `:product_location`), its fields are replaced by fields of that resource with the same type, its seed call by that resource's seed function, and each carried assertion states the same fact about the new resource.
6. A variant definition module that defines function components starts with `use Aurora.Uix.CoreComponentsImporter` and `import Aurora.Uix.Templates.Basic.RoutingComponents` (`<.button>` comes from the first, `<.auix_link>` from the second; without the import the module fails to compile with `undefined function auix_link/1`). Its `__using__/1` and its functions live in the same module.
7. A function with `~H` written inside the `quote` of `__using__/1` (the `render/1` of a host LiveView) takes its argument as `var!(assigns)`: `def render(var!(assigns)) do ~H"…" end`.
8. A variant that reads another variant of its own backend gets that module from `Aurora.UixWeb.Test.Mirror.sibling/2`, called in `__using__/1` before the `quote` and unquoted inside it: `views = Aurora.UixWeb.Test.Mirror.sibling(opts[:backend], <Name>)`.
9. An `Aurora.Uix.RouteHelper.auix_live_resources/3` line of a variant goes in `test/support/app_web/routes.ex` beside the existing `auix_live_resources` lines, below `require Aurora.Uix.RouteHelper`, one line per backend.
10. Run-time compile. `mix test --cover` counts the library code that runs while a module compiles only when that module compiles during the run, and the files under `test/support/` compile before it. Every module under `test/support/` that calls any of `auix_resource_metadata`, `auix_create_ui`, `auix_create_layout` keeps that DSL in the `quote` of the `__using__/1` of a definition module, and `assert_run_time_views/0` of `test/cases/generation_test.exs` (S6 of `UI-5`) compiles the definition again under a `GenerationSample<n>` name while the suite runs and asserts that its signature (resource names, layouts, and the kind and sorted fields of every module of the registry) equals the signature of the views module the scenarios mount. A variant is one atom, its last name, in `@run_time_variants` of that file, and is compiled on both backends. Any other definition is one `{definition, backend, views module}` tuple in `@run_time_single_views`. This section appends its ten variants to `@run_time_variants`, in this order: `ManyToOne`, `ManyToOneQueries`, `OneToMany`, `OneToManyComponent`, `OneToManyActions`, `OneToOne`, `ManyToMany`, `ManyToManyActions`, `Embeds`, `EmbedsExpanded`. It adds no test and no other definition. Proven with a probe on `main` at f6aa246: each of them compiled under a `GenerationSample<n>` name on both backends with the signature of its views module.

##### Replaced files
| Old file (tests) | Home | Dropped, with the reason |
|---|---|---|
| `test/cases_live/association_many2one_selector_atom_test.exs` (4) | S1 | none |
| `test/cases_live/association_many2one_selector_function_test.exs` (3), `association_many2one_selector_assigns_test.exs` (3) | S1: the label of each, asserted on `product_transaction.product_id` and on `product_barcode.product_id` | `check_listing` of both: the same index mount as the atom file's. `check_show` and `check_edit` of both, apart from the label: the same selected-option assertions as the atom file's |
| `test/cases_live/association_many2one_selector_ui_layout_test.exs` (3) | none | all three: `check_listing` is the atom file's index mount; `check_show` and `check_edit` make the atom file's selected-option assertions with the default option label, and the `:product_location` parent field they add is asserted by S2 |
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
1. Variants (rules above). Each block is the content of the `quote` of `__using__/1`, after `use Aurora.UixWeb.Test.Mirror, unquote(opts)`, as the probe compiled it on both backends.

   **`ManyToOne`** · slug `many-to-one` · sources `products`, `product_locations`, `product_transactions`, `product_barcodes`. The module defines, with `@doc false`: `def option_label(entity), do: "The #{entity.name}"` and `def option_label(assigns, entity), do: "#{assigns.auix.layout_type}: #{entity.name}"`.
     ```elixir
     mirror_resource :product_location do
       field(:products, omitted: true)
     end
     mirror_resource :product do
       field(:product_location_id, option_label: :name, query_opts: [order_by: [desc: :name]])
     end
     mirror_resource :product_transaction do
       field(:product_id, option_label: &Aurora.UixWeb.Test.Mirror.Variants.ManyToOne.option_label/1)
     end
     mirror_resource :product_barcode do
       field(:product_id, option_label: &Aurora.UixWeb.Test.Mirror.Variants.ManyToOne.option_label/2)
     end
     auix_create_ui do
       index_columns(:product_transaction, [:type, :quantity])
       index_columns(:product_barcode, [:code, :symbology])
       edit_layout :product_location do
         inline([:reference, :name, :type])
       end
       edit_layout :product do
         stacked([:reference, :name, :description, :quantity_initial, :product_location_id, {:product_location, :name}, product_location: :type])
       end
       edit_layout :product_transaction do
         stacked([:type, :quantity, :cost, :product_id])
       end
       edit_layout :product_barcode do
         stacked([:code, :symbology, :product_id])
       end
     end
     ```

   **`ManyToOneQueries`** · slug `many-to-one-queries` · sources `products`, `product_locations` (DSL of `test/cases_live/where_many2one_test.exs`, with `:product_location` added to the edit layout)
     ```elixir
     mirror_resource :product_location do
       field(:products, omitted: true)
     end
     mirror_resource :product do
       field(:product_location_id,
         option_label: :name,
         query_opts: [order_by: [desc: :name], where: [{:name, :between, "test-name-many2-08", "test-name-many2-14"}]]
       )
     end
     auix_create_ui do
       edit_layout :product_location do
         inline([:reference, :name, :type])
       end
       edit_layout :product do
         stacked([:reference, :name, :description, :quantity_initial, :product_location_id, :product_location])
       end
     end
     ```

   **`OneToMany`** · slug `one-to-many` · sources `products`, `product_transactions`, `product_locations`
     ```elixir
     mirror_resource(:product_location)
     mirror_resource(:product_transaction)
     mirror_resource(:product)
     auix_create_ui do
       index_columns(:product_transaction, [:type, :quantity, :cost])
       index_columns(:product, [:reference, :name, :quantity_initial])
       edit_layout :product do
         stacked([:reference, :name, :description, :quantity_initial, product_transactions: [order_by: [desc: :quantity]]])
       end
       edit_layout :product_location do
         stacked([:reference, :name, products: [order_by: [desc: :name], where: {:name, :between, "Item test-2", "Item test-4"}]])
       end
     end
     ```

   **`OneToManyComponent`** · slug `one-to-many-component` · sources `products`, `product_locations` (DSL of `test/cases_live/one_to_many_component_test.exs`)
     ```elixir
     mirror_resource(:product_compact, schema: :product)
     mirror_resource(:product)
     mirror_resource :product_location do
       field(:products, resource: :product_compact)
     end
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

   **`OneToManyActions`** · slug `one-to-many-actions` · sources `products`, `product_transactions`, `product_locations`. The module starts as variant rule 6 says and defines, with `@doc false`, `custom_new_child/1`, `custom_edit_row_action/1`, `custom_footer_second_action/1` and `custom_footer_action/1` of `association_one2many_ui_actions_test.exs`, bodies unchanged. The `action_icons` of `action_icons_fields_test.exs` sit on the `products` list of a location; S4 seeds `create_sample_product_locations(1, :test)` and one product in it, and asserts the two icons on the location edit route.
     ```elixir
     mirror_resource(:product_location)
     mirror_resource(:product_transaction)
     mirror_resource(:product)
     auix_create_ui do
       edit_layout :product do
         stacked([
           :reference,
           :name,
           :description,
           :quantity_initial,
           product_transactions: [
             add_header_action: {:custom_action, &Aurora.UixWeb.Test.Mirror.Variants.OneToManyActions.custom_new_child/1},
             replace_row_action: {:default_row_edit, &Aurora.UixWeb.Test.Mirror.Variants.OneToManyActions.custom_edit_row_action/1},
             add_footer_action: {:custom_footer_second_action, &Aurora.UixWeb.Test.Mirror.Variants.OneToManyActions.custom_footer_second_action/1},
             insert_footer_action: {:custom_footer_action, &Aurora.UixWeb.Test.Mirror.Variants.OneToManyActions.custom_footer_action/1}
           ]
         ])
       end
       edit_layout :product_location do
         stacked([:reference, :name, products: [action_icons: [default_new: "hero-sparkles", default_row_edit: "hero-pencil-square"]]])
       end
     end
     ```

   **`OneToOne`** · slug `one-to-one` · sources `products`, `product_barcodes` (DSL of `test/cases_live/association_one2one_ui_layout_test.exs`)
     ```elixir
     mirror_resource(:product)
     mirror_resource(:product_barcode)
     auix_create_ui do
       edit_layout :product do
         stacked([:reference, :name, :quantity_initial, :product_barcode])
       end
       edit_layout :product_barcode do
         stacked([:code, :symbology, :registered_at, :product_id])
       end
       show_layout :product do
         stacked([:reference, :name, :product_barcode])
       end
       show_layout :product_barcode do
         stacked([:code, :symbology, :registered_at])
       end
     end
     ```

   **`ManyToMany`** · slug `many-to-many` · sources `products`, `suppliers` (DSL of `test/cases_live/association_many2many_ui_layout_test.exs`)
     ```elixir
     mirror_resource :product do
       field(:suppliers, option_label: :name)
     end
     mirror_resource(:supplier)
     auix_create_ui do
       edit_layout :product do
         stacked([:reference, :name, :quantity_initial, :suppliers])
       end
       show_layout :product do
         stacked([:reference, :name, :suppliers])
       end
     end
     ```

   **`ManyToManyActions`** · slug `many-to-many-actions` · sources `products`, `suppliers`. The module starts as variant rule 6 says and defines, with `@doc false`, `custom_label_action/1`, `custom_header_action/1` and `custom_footer_action/1` of `association_many2many_ui_actions_test.exs`, bodies unchanged. It declares no `option_label` on `suppliers`: the Ash-only default-label test asserts here.
     ```elixir
     mirror_resource(:product)
     mirror_resource(:supplier)
     auix_create_ui do
       edit_layout :product do
         stacked([
           :reference,
           :name,
           suppliers: [
             remove_label_action: :default_toggle_all,
             add_label_action: {:custom_label, &Aurora.UixWeb.Test.Mirror.Variants.ManyToManyActions.custom_label_action/1},
             add_header_action: {:custom_header, &Aurora.UixWeb.Test.Mirror.Variants.ManyToManyActions.custom_header_action/1},
             add_footer_action: {:custom_footer, &Aurora.UixWeb.Test.Mirror.Variants.ManyToManyActions.custom_footer_action/1}
           ]
         ])
       end
     end
     ```

   **`Embeds`** · slug `embeds` · sources `products`
     ```elixir
     mirror_resource(:product)
     auix_create_ui do
       index_columns(:product, [:reference, :name, :packaging, :contacts])
       edit_layout :product, new_title: "Embeds" do
         stacked do
           inline([:reference, :name])
           inline([:quantity_initial])
           stacked([:packaging, :contacts])
         end
       end
     end
     ```

   **`EmbedsExpanded`** · slug `embeds-expanded` · sources `products`. The module defines `def always_expanded(_assigns), do: true` with `@doc false` (from `test/cases_live/ash_embeds_test.exs`).
     ```elixir
     mirror_resource :product do
       field(:contacts, expanded: &Aurora.UixWeb.Test.Mirror.Variants.EmbedsExpanded.always_expanded/1)
     end
     auix_create_ui do
       edit_layout :product do
         stacked([:reference, :name, :quantity_initial, contacts: [action_icons: [default_header_enable_add_entry: "hero-sparkles", default_remove_entry: "hero-x-mark"]]])
       end
       show_layout :product do
         stacked([:reference, :name, :contacts])
       end
     end
     ```

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

Facts this section builds on, proven on `main` at f6aa246 with a probe: the variants and the two host variants below compiled on both backends from the DSL written there; `navigation_test.exs`, the three `handler_hooks_*` files, `events_test.exs` and `gettext_domain_test.exs` ran against them with their routes re-pointed; both hosts mounted with `live_isolated/3`, saved and listed on both backends.
- The three hook handlers do not share one resource: with the index hook, the form hook and the show hook on one `:product`, seven of the thirteen hook tests fail on each backend. Each hook has its own variant.
- `ComponentsIndexViews` and `ComponentsIndexHandled` each declare `index_columns(:product, …)`; one module takes one index layout per resource. The handled index has its own variant.
- An event carries the schema module of the backend: `Aurora.Uix.Test.MirrorAsh.Product` on `:ash`, `Aurora.Uix.Test.MirrorCtx.Product` on `:ctx`. With the module of the running backend in `Events.topic/1`, in the expected `%Event{schema: …}` and in the `entities:` pattern, 16 of the 19 tests of `events_test.exs` hold on `:ash` as they are; the other three hand `Events.updated/1`, `Events.created/1` and `Events.deleted/2` a struct, which must be the backend's own.

##### Acceptance criteria
- [ ] AC-1: S1 asserts the `Aurora.Uix.Navigation` functions with no database: the five paths, `resolve_uri_path/2`, the stack round trip, `forward/2`, `back/1`, `back_to_edit/2`, and the raise for an unknown key and for a missing current path
- [ ] AC-2: S2 asserts the routing stack on both backends: the index opens show, edit and new with the index pushed twice; show to show-edit and back unwinds the stack; closing and saving return to the index; a directly loaded form and a directly loaded show each return to the index with an empty stack; the discard guard holds navigation
- [ ] AC-3: S3 asserts child navigation on both backends: a new child navigates to the child route and back to the parent form; child show and edit links carry the parent on the stack; a new parent with a child list continues on its edit form
- [ ] AC-4: S4 asserts route options: `only:` and `except:` limit the mounted routes; a forwarded `routing_stack` is honoured on back; pagination pushes the index and closing a form drops the page; record navigation patches without a stack (the patched record is asserted on `:ctx`, `##### Backend differences`); index links keep their anchor attributes; the flash of a form follows the redirect
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
| AC-5 | new file (`ls test/cases_live \| grep -x extension_scenarios_test.exs` returns nothing) | `HooksIndex`, `HooksForm`, `HooksShow`, each for the tests of its source file · `create_sample_products_with_transactions(2, 2, :test)` | `test/cases_live/extension_scenarios_test.exs` (module `Aurora.UixWeb.Test.ExtensionScenariosTest`) | S5 `"handler hooks run in the index, the form and the show view"` | carried assertions |
| AC-6 | add to that file | `Components`, `ComponentsPaired`, `ComponentsHandled`, `PairedIndexHost` · `create_sample_products(12, :test)`, `create_sample_product_locations(2, :test)` | same | S6 `"an embedded index component pages, sorts and reports its intents"` | carried assertions, plus `[name='auix-index-component']` |
| AC-7 | add to that file | `Components`, `ComponentsPaired`, `PairedFormHost` · `create_sample_products(1, :test, %{quantity_initial: 1})`, `create_sample_product_locations(1, :test)` | same | S7 `"embedded form and show components save, load and report"` | carried assertions |
| AC-8 | add to that file | `Components` · `create_sample_products(12, :test)` | same | S8 `"component hooks forward events to every instance"` | carried assertions |
| AC-9 | amend `test/cases/events_test.exs`: its eight tests become one | `use ExUnit.Case` (not async: it reads the application environment) | same file | S9 `"Events names topics, builds payloads and honours the pubsub configuration"` | carried assertions, with the cleanup this section states; `Aurora.Uix.Guides.Inventory.Product` becomes `Aurora.Uix.Test.MirrorCtx.Product` and `Aurora.Uix.Guides.Blog.Author` becomes `Aurora.Uix.Test.MirrorAsh.ProductLocation`, in the aliases and in the expected topic strings (`"auix:Aurora.Uix.Test.MirrorCtx.Product"`, `"auix:Aurora.Uix.Test.MirrorAsh.ProductLocation"`) |
| AC-10 | add to `extension_scenarios_test.exs` | `Events` · the seeds of `test/cases_live/events_test.exs` | same | S10 `"events from one view update the index, the show and the form of another"` | carried assertions, with the schema module and the structs of the running backend (step 5) |
| AC-11 | add to `extension_scenarios_test.exs` | `Gettext` · `create_sample_products(1, :test)` | same | S11 `"labels and buttons render through dt and the gettext domain"` | carried assertions |

##### Carry rules
These rules apply to every row of `##### Replaced files`.
1. `file → S` means: scenario `S` makes every assertion of every test of that file, except the tests the row lists under Dropped. The old file is the source of the selectors, the input names and the drives.
2. Re-pointing an Ecto (inventory) test: a guide module becomes the `MirrorCtx` / `MirrorAsh` module of the same last name; a route becomes `mirror_path(backend, "<variant slug>", "<source>", "<suffix>")`; a seed call keeps its name and arguments (`Aurora.Uix.Test.Mirror.Seeds`); a `delete_all_*_data()` call is removed, because `each_backend/2` empties the mirror tables. Selectors, input names and element names stay as written.
3. `on :ash` in a row means the file is the Ash twin of an Ecto file in the same row: its assertions are the Ecto ones, and the scenario makes them on `:ash` by running there. A test listed as `Ash-only` has no Ecto twin: carry it with the name map the row gives, and assert it on both backends.
4. An assertion on an `auix-field-*` id, and an `=~` on rendered HTML, is rewritten as `has_element?/2` on the same element, selected by the first of these it has: its `name` attribute, its input name, its `auix-*` class.
5. Every scenario also asserts the structure its row lists, on both backends.
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing> (#<issue>): <what happens>`, and list it under "Library defects found" in the section log. `<issue>` is the issue of that defect: #580 for the Ash field order, #581 for the Ecto crash on a validation error of a nested record, #582 for the Ash form that shows no field error, #583 for the Ash record navigation across a page boundary, #584 for the Ash embeds-one that renders no input while empty, #585 for the DSL compile that fails after a failed compile in the same process. A defect none of the six covers is written `# Library defect on <failing> (new): <what happens>` and listed in the section log as new. Never change a file under `lib/`.
7. Delete each replaced file with `git rm`. Remove from `test/support/app_web/routes.ex` every registration whose module argument starts with the test module of a deleted file. A module a deleted file defines beside its test module moves as `##### Modules & components` of this section says.
8. A views variant declares only the resources and layouts its scenarios mount, and each generated module is mounted by a scenario: an unmounted generated module is a missed line in the coverage total.
9. An id that embeds the route (`auix-table-<route>-index`, `auix-table-<route>-index-mobile`, `auix-table-<route>-index-hook`) is rebuilt from the mirror route: `"#auix-table-mirror-#{backend.slug}-<variant slug>-<source>-index"`. For these ids this rule replaces the last sentence of rule 2.
10. Required fields and seeds. `name`, `status` and `quantity_initial` are required on both backends, and `create_sample_products/3` and `create_sample_products_with_transactions/4` set no `quantity_initial`. A form submit that must save a seeded product sets `quantity_initial`: in the seed attrs (`%{quantity_initial: 1}`) when the form has no `quantity_initial` input, in the submitted params otherwise. A form that renders the `:product_barcode` inputs (the default product form of the `Default` variant, the `OneToOne` variant) saves only with `product_barcode: %{code: "<code>"}` in the submitted params.
11. A validation message is the text of the backend: `can't be blank` on `:ctx`, `is required` on `:ash`. Assert the `.auix-error-message` element on both backends and the text of the running backend.
12. A raw SQL statement on a guide table and a `Repo` call on a guide schema become an `Aurora.Uix.Repo` call on the `MirrorCtx` schema of the same table. Persisted values are read through `MirrorCtx` schemas on both backends: the tables are shared.
13. A carried assertion that fails on both backends because the variant is not the old views module (another field list, another seed, another column position) is restated for the variant: the fact it states stays, and its selector and expected value are recomputed from the variant DSL this section gives. It is removed only when the variant no longer has the thing it asserts; each removal is listed in the section log with that reason.
14. `##### Backend differences` of this section lists what the probe measured. Each entry is asserted as the entry says. An assertion that fails on one backend only and has no entry falls under rule 6.

##### Backend differences
Measured by the probe.
- `:ash`: `"record navigation patches without a routing stack"` patches to another record than the one `:ctx` opens (the cross-page defect #583, which `UI-8` logs). Its `decoded_patch/1` assertion runs inside `if backend.name == :ctx`; the absence of a routing stack is asserted on both.
- Events: the schema module and the structs are the backend's own (step 5). This is the contract of `Aurora.Uix.Events`, not a defect.
- `ash_navigation_test.exs`, `ash_components_index_test.exs`, `ash_components_form_show_test.exs` and `ash_events_test.exs` show each flow passing on Ash; an assertion of their Ecto twin that still fails on `:ash` falls under rule 6.

##### Variant rules
1. A variant is the three files `UI-2` defines: `test/support/mirror_web/variants/<name>.ex` (module `Aurora.UixWeb.Test.Mirror.Variants.<Name>`), `test/support/mirror_web/ash/<name>.ex` and `test/support/mirror_web/ctx/<name>.ex`. Its routes are one `RoutesHelper.register_mirror(<Name>, "<slug>", [<sources>])` line in `test/support/app_web/routes.ex`, below the existing `register_mirror` lines.
2. "DSL of `<old file>`" means the `auix_resource_metadata` and `auix_create_ui` calls of that file, moved into the `quote` of the variant's `__using__/1`. `auix_resource_metadata(:x, context: …, schema: …)` and `auix_resource_metadata(:x, ash_resource: …)` become `mirror_resource(:x)`; resource options and `field` lines go in its `do` block, unchanged. For an Ash (blog) source file the row gives the resource and field names to use.
3. A function a layout references (`&__MODULE__.fun/1`) becomes a public function of the variant definition module with `@doc false`, referenced as `&Aurora.UixWeb.Test.Mirror.Variants.<Name>.fun/1`. A handler module a layout names becomes `Aurora.UixWeb.Test.Mirror.Handlers.<SameLastName>` at `test/support/mirror_web/handlers/<name>.ex`, body unchanged.
4. When two sources in one variant give the same resource the same layout type, the row says which list is kept; a positional selector (`nth-child`, `nth-of-type`) of a carried assertion is recomputed for that list.
5. When a row moves a source's DSL to another resource (for example a products test onto `:product_location`), its fields are replaced by fields of that resource with the same type, its seed call by that resource's seed function, and each carried assertion states the same fact about the new resource.
6. A variant definition module that defines function components starts with `use Aurora.Uix.CoreComponentsImporter` and `import Aurora.Uix.Templates.Basic.RoutingComponents` (`<.button>` comes from the first, `<.auix_link>` from the second; without the import the module fails to compile with `undefined function auix_link/1`). Its `__using__/1` and its functions live in the same module.
7. A function with `~H` written inside the `quote` of `__using__/1` (the `render/1` of a host LiveView) takes its argument as `var!(assigns)`: `def render(var!(assigns)) do ~H"…" end`.
8. A variant that reads another variant of its own backend gets that module from `Aurora.UixWeb.Test.Mirror.sibling/2`, called in `__using__/1` before the `quote` and unquoted inside it: `views = Aurora.UixWeb.Test.Mirror.sibling(opts[:backend], <Name>)`.
9. An `Aurora.Uix.RouteHelper.auix_live_resources/3` line of a variant goes in `test/support/app_web/routes.ex` beside the existing `auix_live_resources` lines, below `require Aurora.Uix.RouteHelper`, one line per backend.
10. Run-time compile. `mix test --cover` counts the library code that runs while a module compiles only when that module compiles during the run, and the files under `test/support/` compile before it. Every module under `test/support/` that calls any of `auix_resource_metadata`, `auix_create_ui`, `auix_create_layout` keeps that DSL in the `quote` of the `__using__/1` of a definition module, and `assert_run_time_views/0` of `test/cases/generation_test.exs` (S6 of `UI-5`) compiles the definition again under a `GenerationSample<n>` name while the suite runs and asserts that its signature (resource names, layouts, and the kind and sorted fields of every module of the registry) equals the signature of the views module the scenarios mount. A variant is one atom, its last name, in `@run_time_variants` of that file, and is compiled on both backends. Any other definition is one `{definition, backend, views module}` tuple in `@run_time_single_views`. This section appends its eleven variants to `@run_time_variants`, in this order: `Navigation`, `HooksIndex`, `HooksForm`, `HooksShow`, `Components`, `ComponentsPaired`, `ComponentsHandled`, `Events`, `Gettext`, `PairedFormHost`, `PairedIndexHost`. It adds no test and no other definition. Proven with a probe on `main` at f6aa246: each of them compiled under a `GenerationSample<n>` name on both backends with the signature of its views module.

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
1. Variants (rules above). Each block is the content of the `quote` of `__using__/1`, after `use Aurora.UixWeb.Test.Mirror, unquote(opts)`, as the probe compiled it on both backends.

   **`Navigation`** · slug `navigation` · sources `products`, `product_transactions` (DSL of `test/cases_live/navigation_test.exs`)
     ```elixir
     mirror_resource(:product_transaction)
     mirror_resource(:product)
     auix_create_ui do
       index_columns(:product, [:reference, :name, :quantity_initial], order_by: :reference)
       edit_layout :product do
         stacked([:reference, :name, :description, :quantity_initial, :product_transactions])
       end
     end
     ```
   Routes beside its `register_mirror` line (variant rule 9), for each backend: `RouteHelper.auix_live_resources("/mirror-<ash|ctx>-navigation-only-products", <Backend>.Navigation.Product, only: [:index, :show])` and `RouteHelper.auix_live_resources("/mirror-<ash|ctx>-navigation-except-products", <Backend>.Navigation.Product, except: [:new, :edit])`. In the scenario these two paths are written as literals: `"/mirror-#{backend.slug}-navigation-only-products"`.

   **`HooksIndex`** · slug `hooks-index` · sources `products` (DSL of `handler_hooks_index_test.exs`)
     ```elixir
     mirror_resource(:product)
     auix_create_ui do
       index_columns(:product, [:id, :reference, :name, :description, :quantity_at_hand], handler_module: Aurora.UixWeb.Test.Mirror.Handlers.IndexHandlerHook)
       edit_layout :product do
         inline([:reference, :name, :description])
         inline([:quantity_at_hand, :quantity_initial])
         inline([:list_price, :rrp])
       end
       show_layout :product do
         inline([:reference, :name, :description])
         inline([:quantity_at_hand, :quantity_initial])
         inline([:list_price, :rrp])
       end
     end
     ```

   **`HooksForm`** · slug `hooks-form` · sources `products` (DSL of `handler_hooks_form_test.exs`). The module starts as variant rule 6 says and defines `hooks_footer_action/1` of that file with `@doc false`.
     ```elixir
     mirror_resource(:product)
     auix_create_ui do
       index_columns(:product, [:id, :reference, :name, :description, :quantity_at_hand])
       show_layout :product do
         inline([:reference, :name, :description])
         inline([:quantity_at_hand, :quantity_initial])
         inline([:list_price, :rrp])
       end
       edit_layout :product,
         edit_handler_module: Aurora.UixWeb.Test.Mirror.Handlers.FormHandlerHook,
         add_footer_action: {:hooks_hide_description, &Aurora.UixWeb.Test.Mirror.Variants.HooksForm.hooks_footer_action/1} do
         inline([:reference, :name, :description])
         inline([:quantity_at_hand, :quantity_initial])
         inline([:list_price, :rrp])
       end
     end
     ```

   **`HooksShow`** · slug `hooks-show` · sources `products`, `product_transactions` (DSL of `handler_hooks_show_test.exs`, without its `:product_location` resource, which no test mounts)
     ```elixir
     mirror_resource(:product_transaction)
     mirror_resource(:product)
     auix_create_ui do
       edit_layout :product, show_handler_module: Aurora.UixWeb.Test.Mirror.Handlers.ShowHandlerHook do
         stacked([:reference, :name, :description, :quantity_initial, :product_transactions])
       end
     end
     ```

   **`Components`** · slug `components` · sources `products` (DSL of `ComponentsIndexTest` and of `component_hooks_test.exs`, which are the same; `ComponentsFormShowTest` declares `auix_create_ui()`, whose form and show components this variant generates from the same default layouts)
     ```elixir
     mirror_resource(:product)
     auix_create_ui do
       index_columns(:product, [:reference, :name], pagination_items_per_page: 5)
     end
     ```

   **`ComponentsPaired`** · no route (`ComponentsPairedViews` of `components_form_show_test.exs` and `ComponentsIndexViews` of `components_index_test.exs`: one edit layout and one index layout)
     ```elixir
     mirror_resource(:product)
     mirror_resource(:product_location)
     auix_create_ui generate: [:index_component, :form_component, :show_component] do
       index_columns(:product, [:reference, :name], module_name: :index_compact)
       edit_layout :product, module_name: :reference_form do
         inline([:reference, :name])
       end
     end
     ```

   **`ComponentsHandled`** · no route (`ComponentsIndexHandled` of `components_index_test.exs`)
     ```elixir
     mirror_resource(:product)
     auix_create_ui generate: [:index_component] do
       index_columns(:product, [:reference], component_handler_module: Aurora.UixWeb.Test.Mirror.Handlers.ComponentsIndexHandler)
     end
     ```

   **`Events`** · slug `events` · sources `products`, `product_locations`, `product_transactions` (DSL of `test/cases_live/events_test.exs`; its route `/events-product-locations` becomes the `product_locations` source)
     ```elixir
     mirror_resource(:product_location)
     mirror_resource(:product_transaction)
     mirror_resource(:product)
     auix_create_ui do
       index_columns(:product, [:reference, :name], handler_module: Aurora.UixWeb.Test.Mirror.Handlers.EventsProbeIndexHandler)
       edit_layout :product do
         stacked([:reference, :name, :quantity_initial, :product_transactions])
       end
       show_layout :product do
         stacked([:reference, :name])
       end
     end
     ```

   **`Gettext`** · slug `gettext` · sources `products` (DSL of `test/cases_live/gettext_domain_test.exs`)
     ```elixir
     mirror_resource(:product)
     auix_create_ui do
       index_columns(:product, [:id, :reference, :name])
       edit_layout :product do
         inline([:reference, :name])
       end
       show_layout :product do
         inline([:reference, :name])
       end
     end
     ```

2. Host LiveViews. A host declares a pairing against a views module when it compiles, so each host is a variant with one module per backend. `ComponentsPairedHostLive` and `ComponentsIndexPairedHostLive` of the two components files become:

   **`PairedFormHost`** · no route · `test/support/mirror_web/variants/paired_form_host.ex`, with `Aurora.UixWeb.Test.MirrorAsh.PairedFormHost` and `…MirrorCtx.PairedFormHost`. `__using__/1`:
     ```elixir
     defmacro __using__(opts) do
       views = Aurora.UixWeb.Test.Mirror.sibling(opts[:backend], ComponentsPaired)

       quote do
         use Aurora.UixWeb.Test, :live_view
         use Aurora.UixWeb.Test.Mirror, unquote(opts)

         @auix_resource_metadata %{
           product_location: unquote(views).auix_resource(:product_location)
         }

         auix_create_ui generate: [] do
           edit_layout(:product_location, use: unquote(views).auix_module(:reference_form))
         end

         @impl true
         def mount(_params, session, socket) do
           {:ok,
            socket
            |> assign(:entity_id, Map.fetch!(session, "entity_id"))
            |> assign(:form_module, unquote(views).auix_module(:reference_form))
            |> assign(:saved, nil)}
         end

         @impl true
         def render(var!(assigns)) do
           ~H"""
           <div id="auix-paired-host">
             <.live_component
               module={@form_module}
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
     end
     ```

   **`PairedIndexHost`** · no route · `test/support/mirror_web/variants/paired_index_host.ex`, with its two backend modules. The same shape: `auix_create_ui generate: [] do index_columns(:product_location, use: unquote(views).auix_module(:index_compact)) end`; `mount/3` returns `{:ok, assign(socket, :index_module, unquote(views).auix_module(:index_compact))}`; `render(var!(assigns))` renders `<div id="auix-paired-host"><.live_component module={@index_module} id="locations" resource={:product_location} /></div>`.

   A scenario mounts the host of the running backend with `live_isolated/3`, picked by a two-clause private function of the test module on `backend.name`. `Aurora.UixWeb.Test.ComponentHostLive` (`test/support/app_web/component_host_live.ex`) stays unchanged: a scenario passes the component modules of the running backend in the `"components"` session key. `Aurora.UixWeb.Test.ComponentsIndexHandler` moves under variant rule 3.
3. Handlers moved (variant rule 3): `Aurora.UixWeb.IndexHandlerHook`, `Aurora.UixWeb.FormHandlerHook`, `Aurora.UixWeb.ShowHandlerHook` and `Aurora.UixWeb.EventsProbeIndexHandler` become `Aurora.UixWeb.Test.Mirror.Handlers.<SameLastName>`.
4. Theme: none. `dt/1` strings: none added; S11 asserts existing msgids only.
5. Events on both backends (S9, S10). The test module defines a two-clause private function that returns the schema module of the running backend for `Product`, `ProductLocation` and `ProductTransaction` (`Aurora.Uix.Test.MirrorAsh.<X>` on `:ash`, `Aurora.Uix.Test.MirrorCtx.<X>` on `:ctx`). That module is the argument of `Events.topic/1` and `Events.subscribe/1`, the `schema:` of each expected `%Event{}` and the struct name of each `entities:` pattern. A struct handed to `Events.created/1`, `Events.updated/1` and `Events.deleted/2` is read with the API of the running backend: `Ash.get!(Aurora.Uix.Test.MirrorAsh.Product, id)` on `:ash`, `Aurora.Uix.Repo.get!(Aurora.Uix.Test.MirrorCtx.Product, id)` on `:ctx`. Row writes the test makes itself stay on `MirrorCtx`.

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

Facts this section builds on, proven on `main` at f6aa246 with a probe: the two views modules of step 2 compiled from the DSL written there and mounted their routes; the S5 values below were read from them.
- On `Aurora.UixWeb.Test.MirrorAsh.Aggregates`: `summary` is `type: :string`, `html_type: :text`, label `"Summary"`, disabled; `products_count` is `type: :integer`, `html_type: :number`, label `"Products Count"`, disabled; `latest_product_name` is `type: :string`, `html_type: :text`; `last_discontinued_at` is `type: :utc_datetime`; `product_names` is `type: :string`, `html_type: :unimplemented`. `auix_preloads()` holds `:summary` for `:product` and `:products_count`, `:latest_product_name` and `:product_names` for `:product_location`.
- With three products `Item test-1` to `Item test-3` in one location, inserted in that order: the locations index has the header `"Latest Product Name"` and the cells `"Item test-3"` and `"3"`; the location show view has `input[name='latest_product_name'][value='Item test-3'][disabled]`; the show view of a product has `div.auix-show-container input[name='summary'][value='<name> is <status>'][disabled]`.
- `/mirror-ctx-context-functions-products` lists the three seeded references.
- The default product form saves only with a `product_barcode` code (carry rule 10 of `UI-5`): S6 submits `product_barcode: %{code: "C-1"}` with its create.

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
| AC-2 | amend `test/cases/integration/ash/crud_policy_test.exs`: its ten tests become one | the resources that file declares | same file | S2 `"Ash CRUD forwards the actor and returns Forbidden without one"` | carried assertions of the five files in the S2 rows below, with `Aurora.Uix.Guides.Blog.Author` → `Aurora.Uix.Test.MirrorAsh.ProductLocation` and the resource name `:author` → `:product_location` in `context_parser_defaults_actor_test.exs`; the file declares no views module |
| AC-3 | amend `test/cases/integration/ash/query_parser_test.exs`: its seven tests become one | as the file has it | same file | S3 `"the Ash query parser translates order_by and where"` | carried assertions, with `Aurora.Uix.Guides.Blog.Post` → `Aurora.Uix.Test.MirrorAsh.Product`, `title` → `name`, `content` → `description` |
| AC-4 | amend `test/cases/integration/crud_test.exs`: its four tests become one | as the file has it | same file | S4 `"the CRUD dispatcher picks the backend module"` | carried assertions, plus the one of `test/cases/integration/ctx/crud_test.exs` |
| AC-5 | new file (`ls test/cases_live \| grep -x ash_aggregates_test.exs` returns nothing) | `use Aurora.UixWeb.Test.UICase, :scenario_case`; `each_backend([:ash], …)`; `create_sample_product_locations(1, :test)` and three products in that location with `discontinued_at` set | `test/cases_live/ash_aggregates_test.exs` (module `Aurora.UixWeb.Test.AshAggregatesTest`) | S5 `"Ash calculations and aggregates are typed fields that render in index, form and show"` | carried assertions, with the values of the facts above; the products are `create_sample_products(3, :test, fn i -> %{product_location_id: <location id>, quantity_initial: 1, discontinued_at: DateTime.add(~U[2026-01-01 00:00:00Z], i, :day)} end)`; the `/new` and `/<id>/edit` routes of both sources are mounted once (carry rule 8) — names: `author` → `product_location`, `posts` → `products`, `posts_count` → `products_count`, `latest_post_title` → `latest_product_name`, `post_titles` → `product_names`, `last_published_at` → `last_discontinued_at`, `post` → `product`, `summary` → `summary` |
| AC-6 | new file (`ls test/cases_live \| grep -x ctx_context_functions_test.exs` returns nothing) | `use Aurora.UixWeb.Test.UICase, :scenario_case`; `each_backend([:ctx], …)`; `create_sample_products(3, :test)` | `test/cases_live/ctx_context_functions_test.exs` (module `Aurora.UixWeb.Test.CtxContextFunctionsTest`) | S6 `"a ctx resource runs its CRUD through the context functions"` | on `/mirror-ctx-default-products`: three rows; create through `/new` with `product: %{reference: "c-1", name: "Ctx one", quantity_initial: 1, product_barcode: %{code: "C-1"}}`, edit that product with `product: %{name: "Renamed"}`, delete it from the index, each read back with `Repo`; on `/mirror-ctx-context-functions-products`: the three seeded references |

##### Carry rules
These rules apply to every row of `##### Replaced files`.
1. `file → S` means: scenario `S` makes every assertion of every test of that file, except the tests the row lists under Dropped. The old file is the source of the selectors, the input names and the drives.
2. Re-pointing an Ecto (inventory) test: a guide module becomes the `MirrorCtx` / `MirrorAsh` module of the same last name; a route becomes `mirror_path(backend, "<variant slug>", "<source>", "<suffix>")`; a seed call keeps its name and arguments (`Aurora.Uix.Test.Mirror.Seeds`); a `delete_all_*_data()` call is removed, because `each_backend/2` empties the mirror tables. Selectors, input names and element names stay as written.
3. `on :ash` in a row means the file is the Ash twin of an Ecto file in the same row: its assertions are the Ecto ones, and the scenario makes them on `:ash` by running there. A test listed as `Ash-only` has no Ecto twin: carry it with the name map the row gives, and assert it on both backends.
4. An assertion on an `auix-field-*` id, and an `=~` on rendered HTML, is rewritten as `has_element?/2` on the same element, selected by the first of these it has: its `name` attribute, its input name, its `auix-*` class.
5. Every scenario also asserts the structure its row lists, on both backends.
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing> (#<issue>): <what happens>`, and list it under "Library defects found" in the section log. `<issue>` is the issue of that defect: #580 for the Ash field order, #581 for the Ecto crash on a validation error of a nested record, #582 for the Ash form that shows no field error, #583 for the Ash record navigation across a page boundary, #584 for the Ash embeds-one that renders no input while empty, #585 for the DSL compile that fails after a failed compile in the same process. A defect none of the six covers is written `# Library defect on <failing> (new): <what happens>` and listed in the section log as new. Never change a file under `lib/`.
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
1. Actor views. The `auix_resource_metadata` and `auix_create_ui` calls of `test/cases_live/ash_actor_policy_test.exs` move, below a `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test` line, into the `quote` of `__using__/1` of the definition module `Aurora.UixWeb.Test.AshActorViewsDefinition` at `test/support/ash_actor/views_definition.ex` (`@moduledoc false`; `@doc false`, `@spec __using__(keyword()) :: Macro.t()`, `defmacro __using__(_opts)`). `Aurora.UixWeb.Test.AshActorViews` at `test/support/ash_actor/views.ex` is `@moduledoc false` and `use Aurora.UixWeb.Test.AshActorViewsDefinition, backend: :ash`; the definition reads no option. `AshActorViewsDefinition` is new (`rg -n "AshActorViewsDefinition" test lib` returns nothing). In `test/support/app_web/router.ex` and `test/support/app_web/routes.ex`, each `AshActorPolicyTest.` module prefix becomes `AshActorViews.`. The test module keeps its name and its tests.
2. Backend views, each one definition module and one views module on its one backend:
   - `Aurora.UixWeb.Test.Mirror.Variants.Aggregates` at `test/support/mirror_web/variants/aggregates.ex`, the DSL of `test/cases_live/ash_embeds_test.exs` with the names of the S5 row, without its `tags` and `comment` fields. `Aurora.UixWeb.Test.MirrorAsh.Aggregates` at `test/support/mirror_web/ash/aggregates.ex` is `@moduledoc false` and `use Aurora.UixWeb.Test.Mirror.Variants.Aggregates, backend: :ash`.
     ```elixir
     defmodule Aurora.UixWeb.Test.Mirror.Variants.Aggregates do
       @moduledoc false

       @doc false
       @spec __using__(keyword()) :: Macro.t()
       defmacro __using__(opts) do
         quote do
           use Aurora.UixWeb.Test.Mirror, unquote(opts)

           mirror_resource(:product_location)

           mirror_resource :product do
             order_by(discontinued_at: :desc)
           end

           auix_create_ui do
             index_columns(:product_location, [:name, :products_count, :latest_product_name, :last_discontinued_at])

             edit_layout :product_location do
               stacked([:name, :reference, :products, :products_count, :latest_product_name, :product_names])
             end

             edit_layout :product, new_title: "Aggregates" do
               stacked do
                 inline([:status])
                 stacked([:name, :description])
                 stacked([:summary])
               end
             end
           end
         end
       end
     end
     ```
     Route lines: `RoutesHelper.register_crud(MirrorAsh.Aggregates.ProductLocation, "mirror-ash-aggregates-product_locations")` and `RoutesHelper.register_crud(MirrorAsh.Aggregates.Product, "mirror-ash-aggregates-products")`.
   - `Aurora.UixWeb.Test.Mirror.Variants.ContextFunctions` at `test/support/mirror_web/variants/context_functions.ex` (`@moduledoc false`; `@doc false`, `@spec __using__(keyword()) :: Macro.t()`, `defmacro __using__(_opts)`), whose `quote` holds: `Module.register_attribute(__MODULE__, :auix_resource_metadata, persist: true)`, `use Aurora.Uix`, `auix_resource_metadata(:product, context: Aurora.Uix.Test.MirrorCtx, schema: Aurora.Uix.Test.MirrorCtx.Product, backend_opts: [list_function_paginated: &Aurora.Uix.Test.MirrorCtx.list_products_paginated/1])`, `auix_create_ui do index_columns(:product, [:reference, :name]) end`. `Aurora.UixWeb.Test.MirrorCtx.ContextFunctions` at `test/support/mirror_web/ctx/context_functions.ex` is `@moduledoc false` and `use Aurora.UixWeb.Test.Mirror.Variants.ContextFunctions, backend: :ctx`. Route line: `RoutesHelper.register_crud(MirrorCtx.ContextFunctions.Product, "mirror-ctx-context-functions-products")`.
3. Run-time compile. `mix test --cover` counts the library code that runs while a module compiles only when that module compiles during the run, and the files under `test/support/` compile before it. In `test/cases/generation_test.exs` (`UI-5`), append to `@run_time_single_views`:
     ```elixir
     {Variants.Aggregates, :ash, Aurora.UixWeb.Test.MirrorAsh.Aggregates},
     {Variants.ContextFunctions, :ctx, MirrorCtx.ContextFunctions},
     {Aurora.UixWeb.Test.AshActorViewsDefinition, :ash, Aurora.UixWeb.Test.AshActorViews}
     ```
   `assert_run_time_views/0` of that file compiles each definition again while the suite runs and asserts that its signature equals the signature of its views module. This section adds no test for it. Proven with a probe on `main` at f186ea4: the three definitions compiled under a `GenerationSample<n>` name with the signature of their views module. `Variants.Aggregates` and `Variants.ContextFunctions` are new (`rg -n "Variants.Aggregates|Variants.ContextFunctions" test lib` returns nothing).
4. Theme: none. `dt/1` strings: none.

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

The rewritten tests must not depend on test order: no test creates the named ETS table of `Aurora.Uix.Templates.CssSanitizer`, and none assumes it exists; the test file is not `async`, and no test calls `:ets.new/2`, `:ets.delete/1` and `:ets.info/1` on that table. S2 and S3 reach the sanitizer through `ThemeHelper` and the theme modules; S4 calls `Aurora.Uix.Templates.CssSanitizer.sanitize_css/1`, as `test/cases/templates/css_sanitizer_test.exs` calls it.

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
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing> (#<issue>): <what happens>`, and list it under "Library defects found" in the section log. `<issue>` is the issue of that defect: #580 for the Ash field order, #581 for the Ecto crash on a validation error of a nested record, #582 for the Ash form that shows no field error, #583 for the Ash record navigation across a page boundary, #584 for the Ash embeds-one that renders no input while empty, #585 for the DSL compile that fails after a failed compile in the same process. A defect none of the six covers is written `# Library defect on <failing> (new): <what happens>` and listed in the section log as new. Never change a file under `lib/`.
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
1. No views variant, no route, no theme rule, no `dt/1` string. This section adds no module that calls `auix_resource_metadata`, `auix_create_ui` and `auix_create_layout`: `@run_time_variants` and `@run_time_single_views` of `test/cases/generation_test.exs` stay as they are. The theme DSL of S5 compiles inside the test, so `mix test --cover` counts it.
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

A feature depends neither on another feature's rows nor on test order: each backend run starts from `delete_all_mirror_data/0` and creates its own rows. The second old feature of `test/browser_cases/embeds_many_test.exs` fails intermittently on `main`; its rewrite waits for each element with a Wallaby query (`assert_has/2`) before it clicks, and never reads a counter id. An element that must disappear is awaited with `assert_has(session, Query.css("<selector>", count: 0))`.

Facts this section builds on, proven on `main` at f6aa246 with a Wallaby probe on both backends: the S3 drive attaches the file, shows `.auix-upload-entry`, saves and stores the bytes in `image`; the S4 drive opens the discard dialog on Escape, keeps editing, and discards. `refute_has/2` on the form right after the click failed in the probe while the form was still closing; the `count: 0` query waited for it.

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
| AC-1 | `Embeds` · none | S1 `"a product is created without embeds-many entries"` | carried drives of the first feature of `test/browser_cases/embeds_many_test.exs`; the form also fills `quantity_initial`, which the mirror requires |
| AC-2 | `Embeds` · none | S2 `"embeds-many entries are added and removed in the browser"` | carried drives of the second feature of the same file |
| AC-3 | `Uploads` · `create_sample_products(1, :test)` | S3 `"a file chosen in the browser uploads and is consumed on save"` | visit the edit route; click save with no file and assert the stored `image` is unchanged; `attach_file(session, Query.css("input[type='file'][name='image']", visible: :any), path: …)`, with `path:` a `.png` file the feature writes under `System.tmp_dir!()` and removes with `on_exit/1`; `assert_has(session, Query.css(".auix-upload-entry"))`; click `button[name='auix-save-product']`; `assert_has(session, Query.css("#auix-product-form", count: 0))`; read the row with `Repo` |
| AC-4 | `Form` · `create_sample_products(1, :test, %{quantity_initial: 1})` | S4 `"the edit modal closes through the discard dialog"` | visit the edit route; `fill_in(session, Query.css("input[name='product[name]']"), with: "Changed")`; `send_keys(session, [:escape])`; `assert_has(session, Query.css("#auix-product-discard-confirm-modal"))`; click `button[name='auix-keep-editing']`; `assert_has(session, Query.css("#auix-product-form"))`; Escape again; click `button[name='auix-discard-changes']`; `assert_has(session, Query.css("#auix-product-form", count: 0))`; the name of the row is the seeded one |
| AC-5 | `Default` · `create_sample_products(1, :test)` | S5 `"the default routes open their modal on a full page load"` | carried drives of the four features of `test/browser_cases/create_ui_default_layout_test.exs` |

##### Carry rules
These rules apply to every row of `##### Replaced files`.
1. `file → S` means: scenario `S` makes every assertion of every test of that file, except the tests the row lists under Dropped. The old file is the source of the selectors, the input names and the drives.
2. Re-pointing an Ecto (inventory) test: a guide module becomes the `MirrorCtx` / `MirrorAsh` module of the same last name; a route becomes `mirror_path(backend, "<variant slug>", "<source>", "<suffix>")`; a seed call keeps its name and arguments (`Aurora.Uix.Test.Mirror.Seeds`); a `delete_all_*_data()` call is removed, because `each_backend/2` empties the mirror tables. Selectors, input names and element names stay as written.
3. `on :ash` in a row means the file is the Ash twin of an Ecto file in the same row: its assertions are the Ecto ones, and the scenario makes them on `:ash` by running there. A test listed as `Ash-only` has no Ecto twin: carry it with the name map the row gives, and assert it on both backends.
4. An assertion on an `auix-field-*` id, and an `=~` on rendered HTML, is rewritten as `has_element?/2` on the same element, selected by the first of these it has: its `name` attribute, its input name, its `auix-*` class.
5. Every scenario also asserts the structure its row lists, on both backends.
6. An assertion that holds on one backend and fails on the other is a library defect. Keep it for the passing backend inside `if backend.name == <passing> do … end`, with the comment `# Library defect on <failing> (#<issue>): <what happens>`, and list it under "Library defects found" in the section log. `<issue>` is the issue of that defect: #580 for the Ash field order, #581 for the Ecto crash on a validation error of a nested record, #582 for the Ash form that shows no field error, #583 for the Ash record navigation across a page boundary, #584 for the Ash embeds-one that renders no input while empty, #585 for the DSL compile that fails after a failed compile in the same process. A defect none of the six covers is written `# Library defect on <failing> (new): <what happens>` and listed in the section log as new. Never change a file under `lib/`.
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
1. No new variant. Routes: none added. `@run_time_variants` and `@run_time_single_views` of `test/cases/generation_test.exs` stay as they are: the features of this section visit variants that earlier sections named there.
2. Delete from `test/support/app_web/routes.ex` every registration left that names a module no file defines; after this step `load_test_routes/0` holds the `register_mirror` lines, the `auix_live_resources` lines of the `Named` and `Navigation` variants, the `ManualResource` (`register_product_crud`), `Aggregates` and `ContextFunctions` lines, the `AshActorViews` line, the five `GuidesCapture` lines and the `-local-demo` block. `register_user_crud/2` in `test/support/app_web/routes_helper.ex` has no caller left and is deleted; `register_product_crud/2` stays for the `-local-demo` block, the `ManualResource` line and the capture routes.
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
- Any change to library behaviour under `lib/aurora_uix/`. A defect a scenario finds is listed in its section log and becomes a separate issue. No section changes a file under `lib/`, with one exception: the demo views line of `UI-2` step 7, in `lib/aurora_uix_web/guides/overview.ex`.
- Judging how the UI looks: a human reviews the regenerated guide images.
- The library causes of the intermittent failures on `main`: the named ETS table of `Aurora.Uix.Templates.CssSanitizer`, the leftover PubSub subscriber, the embeds-many browser feature. The rewritten tests carry no order dependence (`UI-10`, `UI-12`, `UI-13`).
- Documentation edits beyond the CHANGELOG entry of `DOC-1`: no text of `README.md`, `CONTRIBUTING.md`, `ROADMAP.md` and `guides/**/*.md` changes.
- The guide and demo modules (`lib/aurora_uix/guides/`, `lib/aurora_uix_web/guides/`) and the guide image capture scripts, apart from the views the layout capture script loads (`UI-5`) and from one exception: `UI-2` step 7 corrects the `order_by` of the product transactions index in `lib/aurora_uix_web/guides/overview.ex`, so that every guide page loads.
- The golden-map parser tests, `test/cases/integration/fields_parser_validations_test.exs` and the doctests (`test/doctests/uix/doc_test.exs`, `test/doctests/uix/parsers_doc_test.exs`): unchanged.
- Parser sections: the issue changes no parser. The mirrored fixture and every scenario cover the Ash and the Ecto backend alike; the six backend-specific tests of `UI-11` cover what one backend alone has.
- CSS text of single theme rules: no test restates it.
<!-- enriched-spec:end -->
