<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** high

### Overview
Each backend says whether a schema is embedded-only, and that answer sets a resource's embedded status and decides whether an Ecto resource needs `context:`. `resource:` on an embedded field and on an association sets `field.data.resource` on both backends, is checked at compile time, and leaves `field.resource` alone. No view changes what it preloads: an association with `resource:` keeps the nested preloads of the named resource, and an association without it keeps none.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | CHANGELOG.md § [0.2.1]; guides/advanced/advanced_usage.md § Key Considerations; guides/advanced/troubleshooting.md § Embedded and Associated Resources Metadata; guides/core/ash_integration.md § Step 3, § Step 4, § Embedded Resources; guides/core/components.md § Two resources on one schema; guides/core/liveview.md § Preloading Associations; guides/core/resource_metadata.md § Ash Framework Resources, § Embedded Resource Naming, § Context-based Resources, § Field Metadata, § Selector, Embed and Upload Options, § Field Data; guides/whats_new/0.2.1.md § Upgrading from 0.2.0 | none | federico/557-doc-1-embedded-status-and-resource-link | docs: embedded status from the backend and the field resource link (#557 · DOC-1) |
| PAR-1 | Parser | ctx · `embedded_schema?/1` | DOC-1 | federico/557-par-1-ctx-embedded-schema | feat: the Ecto parser says whether a schema is embedded-only (#557 · PAR-1) |
| PAR-2 | Parser | ash · `embedded_schema?/1` | DOC-1 | federico/557-par-2-ash-embedded-schema | feat: the Ash parser says whether a schema is embedded-only (#557 · PAR-2) |
| UI-1 | UI | layout · embedded status and the context check from the backend | PAR-1, PAR-2 | federico/557-ui-1-embedded-status-from-backend | feat: backends decide whether a resource is embedded (#557 · UI-1) |
| UI-3 | UI | layout · `resource:` links a field to its resource | UI-1 | federico/557-ui-3-field-resource-link | feat: resource: links an embedded field and an association (#557 · UI-3) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
- `CHANGELOG.md § [0.2.1]` › `### Changed`
- `guides/advanced/advanced_usage.md § Key Considerations`
- `guides/advanced/troubleshooting.md § Embedded and Associated Resources Metadata`
- `guides/core/ash_integration.md § Step 3: Configure Aurora UIX Resource Metadata`, `§ Step 4: Add to Router`, `§ Embedded Resources`
- `guides/core/components.md § Two resources on one schema`
- `guides/core/liveview.md § Preloading Associations`
- `guides/core/resource_metadata.md § Ash Framework Resources` (under `## Metadata Generation Process`), `§ Embedded Resource Naming`, `§ Context-based Resources` (under `## Defining Resource Metadata`), `§ Field Metadata`, `§ Selector, Embed and Upload Options`, `§ Field Data`
- `guides/whats_new/0.2.1.md` opening paragraph, `§ Upgrading from 0.2.0`

Rules for this section:
- 0.2.1-rc.1 is unreleased. No edit adds a migration note for behaviour that exists only in the release candidate. Every note describes a change from released 0.2.0.
- No CHANGELOG entry carries an issue link.

#### Implementation details

##### CHANGELOG.md
1. § `## [0.2.1]`, opening paragraph — replace `It has two compile-time breaking` with `It has three compile-time breaking`.
2. § `## [0.2.1]` › `### Changed` — replace the bullet that starts `- **Generated module names (breaking)**` (three lines) with, verbatim:
   ```
   - **Generated module names (breaking)**: a duplicate generated module name fails compilation, and a
     resource on an embedded-only schema (an Ash embedded resource, an Ecto schema without a table)
     generates no modules, whatever its name (What's New in 0.2.1, "Upgrading from 0.2.0").
   - **Field `resource:` option (breaking)**: `resource:` on an embedded field or on an association
     names the resource that renders it, on both backends. An unknown name, a resource on another
     schema, and `resource:` on any other field fail compilation (What's New in 0.2.1, "Upgrading from
     0.2.0").
   - **Embedded resources on the Ecto backend**: a resource declared on a schema without a table
     needs no `context:` and no CRUD functions.
   ```

##### guides/advanced/advanced_usage.md
1. § Key Considerations › **Field Parsing:** — replace the line ``- Use the `__` naming convention for nested resources`` with, verbatim:
   ```
   - Define `embedded_schema?/1` in the fields parser: `true` for a schema that exists only embedded
     in another one, so that its resources generate no modules
   ```

##### guides/advanced/troubleshooting.md
1. § Embedded and Associated Resources Metadata — replace the whole section, from the heading `## Embedded and Associated Resources Metadata` up to the line before the heading `## Ash Policy-Protected Resource Shows No Rows`, with, verbatim (keep one blank line before the next heading):
   ````
   ## Embedded and Associated Resources Metadata

   **Symptoms:** Field options declared for an embedded record, or for the entries of an
   association, are ignored.

   **Cause:** The field is rendered with another resource than the one that holds the options.

   - An embedded field uses the resource named `<parent>__<field>` (`:post__comment` for the `comment`
     field of `:post`), unless the field names one with `resource:`.
   - An association uses the latest resource declared for the related schema, unless the field names
     one with `resource:`.

   **Solution:** Name the resource on the field:

   ```elixir
   auix_resource_metadata :post do
     ash_resource Post
     field :comment, resource: :comment_form
   end

   auix_resource_metadata :comment_form do
     ash_resource Comment
     field :description, html_type: :textarea
   end
   ```

   A resource declared as `:post__comment` is used without `resource:`.

   **Compilation fails after adding `resource:`:**

   - `links to the unknown resource`: the name matches no resource of the module, declared or
     imported.
   - `whose schema is ...; the field relates to ...`: the named resource describes another schema
     than the one the field relates to.
   - `only an embedded field or an association links to a resource`: the field is a plain column. On
     the foreign-key column of a many-to-one, put `resource:` on the association field.
   - ``requires the `:context` option``: the resource is declared on an Ecto schema that has a table.
     Give `context:` with its CRUD functions, or remove the declaration to use the resource the
     library creates.
   ````

##### guides/core/ash_integration.md
1. § Step 3: Configure Aurora UIX Resource Metadata — in the code sample, replace the line `  auix_resource_metadata(:post, ash_resource: Post, order_by: :title)` with, verbatim:
   ```
     auix_resource_metadata :post do
       ash_resource Post
       order_by :title
       field :tags, resource: :tag
     end
   ```
2. § Step 4: Add to Router — delete the line `    auix_live_resources("/tags", AshOverview.Tag)` from the code sample. Reason: `Tag` is an embedded resource and generates no modules.
3. § Embedded Resources — after the list item ``- `embeds_many` - List of nested forms with add/remove actions``, insert a blank line and, verbatim:
   ```
   A resource declared on an embedded resource generates no modules and no routes. Name it on the
   parent field with `resource:` to render the embedded record with its field options; without
   `resource:` the field uses the resource named `<parent>__<field>`. See
   [Embedded Resources](resource_metadata.md#embedded-resources).
   ```

##### guides/core/components.md
1. § Two resources on one schema — in the paragraph that starts `Two generated modules with one name do not compile.`, replace the sentence ``A field needs `resource:` only then.`` with ``An association needs `resource:` only then.``

##### guides/core/liveview.md
1. § Preloading Associations — after the paragraph that ends ``[Index Query Options](resource_metadata.md#index-query-options)).``, insert a blank line and, verbatim:
   ```
   An association field that names its resource with `resource:` also loads, for each related
   record, the association fields that the layouts of the named resource render, one level deep.
   Without `resource:` it loads the related records alone.
   ```

##### guides/core/resource_metadata.md
1. § Ash Framework Resources (under `## Metadata Generation Process`) — replace the line ``   - Embedded resources → Nested Ash resources (rendered inline with `__` naming convention)`` with ``   - Embedded resources → Nested Ash resources, rendered inline (see [Embedded Resources](#embedded-resources))``.
2. § Embedded Resource Naming — replace the heading `### Embedded Resource Naming` and the text under it, down to and including the line ``- Nested embedded: `:post__comment__reply` (continues the pattern)``, with, verbatim. The paragraph that starts `This compile-time generation ensures` stays below it.
   ````
   ### Embedded Resources

   An embedded field (`embeds_one`, `embeds_many`, an Ash attribute whose type is an embedded
   resource) is rendered with a resource that describes the embedded schema. The library creates one
   for every embedded field, named `<parent>__<field>`:

   - Parent resource: `:post`
   - Resource created for its `comment` field: `:post__comment`

   To set field options for the embedded record, declare a resource on the embedded schema and name
   it in the parent with `resource:`:

   ```elixir
   auix_resource_metadata :employer do
     ash_resource Employer
     field :legal_rep, resource: :legal_contact
     field :hr_manager, resource: :hr_contact
   end

   auix_resource_metadata :legal_contact do
     ash_resource Contact
     field :phone, required: true
   end

   auix_resource_metadata :hr_contact, ash_resource: Contact
   ```

   Without `resource:` an embedded field uses the resource named `<parent>__<field>`: the one the
   module declares under that name, else the one the library creates.

   The backend decides whether a schema is embedded-only: an Ash resource with
   `data_layer: :embedded`, and an Ecto schema without a table (`embedded_schema`, and the inline
   schema of `embeds_one` and `embeds_many`). A resource on such a schema generates no modules,
   whatever its name, and on the Ecto backend it needs no `context:`.

   An Ecto schema with a table can also be embedded. A resource declared on it is a standalone
   resource: it needs `context:` with its CRUD functions and generates its modules. Remove the
   declaration to use the resource the library creates.

   `resource:` is checked when the module compiles: the name must be a resource of the module,
   declared or imported; that resource must describe the schema the field relates to; and the field
   must be an embedded field or an association.
   ````
3. § Context-based Resources (under `## Defining Resource Metadata`) — replace the line ``- `:context` (module()) - Required. Context module with CRUD functions`` with ``- `:context` (module()) - Context module with CRUD functions. Required unless the schema has no table (see [Embedded Resources](#embedded-resources))``.
4. § Field Metadata — replace the line ``- `resource` - Reference to the resource this field belongs to`` with ``- `resource` - Name of the resource that owns the field. The `resource:` field option does not change it: it sets `data.resource` (see [Field Data](#field-data))``.
5. § Selector, Embed and Upload Options — directly above the bullet that starts ``- `upload` - An `Aurora.Uix.Field.Upload` ``, insert, verbatim:
   ```
   - `resource` - (embedded fields and associations) The name of the resource that renders the
     related entries, kept in `data.resource`. On an association it also preloads the association
     fields that the layouts of the named resource render (see
     [Preloading Associations](liveview.md#preloading-associations)). See
     [Embedded Resources](#embedded-resources) and
     [Two resources on one schema](components.md#two-resources-on-one-schema)
   ```
6. § Field Data — replace three lines:

   | Under | Current line | New line |
   |---|---|---|
   | **For many-to-one associations** | ``- `resource` - The resource name of the related entity`` | ``- `resource` - The resource name of the related entity: the one `resource:` names, else the latest resource declared for the related schema`` |
   | **For one-to-many associations** | ``- `resource` - The resource name of the related entities (may be `nil` if not configured)`` | ``- `resource` - The resource name of the related entities: the one `resource:` names, else the latest resource declared for the related schema (`nil` when there is none)`` |
   | **For embedded schemas** | ``- `resource` - The embedded resource name (follows `parent__embed` naming pattern)`` | ``- `resource` - The name of the resource that renders the embedded record: the one `resource:` names, else `<parent>__<field>` `` |

##### guides/whats_new/0.2.1.md
1. Opening paragraph — replace `0.2.1 has two compile-time changes that can stop a module from compiling` with `0.2.1 has three compile-time changes that can stop a module from compiling`.
2. § Upgrading from 0.2.0 — replace the line `Two cases need a change:` with `Four cases need a change:`.
3. § Upgrading from 0.2.0 — replace the bullet that starts ``- A resource named for an embedded field (`<parent>__<field>`) generates no modules`` (three lines) with, verbatim:
   ```
   - A resource on an embedded-only schema generates no modules, whatever its name: an Ash resource
     with `data_layer: :embedded`, an Ecto schema declared with `embedded_schema`, and the inline
     schema of `embeds_one` and `embeds_many`. The resource the library creates for an embedded field
     (`<parent>__<field>`) generates none either. Remove any reference to
     `<Module>.<EmbeddedSchema>.Index`, `.FormComponent` and `.ShowComponent`, and their routes.
   - `resource:` on a field now takes effect. An embedded field or an association with `resource:` is
     rendered with the named resource; in 0.2.0 the option was accepted and the field kept its default
     resource. A name that matches no resource, a resource that describes another schema, and
     `resource:` on a field that is neither embedded nor an association no longer compile. On the
     foreign-key column of a many-to-one, move `resource:` to the association field.
   - A custom fields parser defines `embedded_schema?/1`, returning `true` for a schema that exists
     only embedded in another one. Without it the views module does not compile.
   ```

##### Acceptance criteria
- [x] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no
      issue-link suffix (mechanical — no red test; verified by
      `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [x] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-557-enriched-spec.md`)
- [x] AC-3: `guides/advanced/advanced_usage.md § Key Considerations` names `embedded_schema?/1` (mechanical — no red test; verified by `grep -c 'embedded_schema?/1' guides/advanced/advanced_usage.md` returning `1`)
- [x] AC-4: `guides/advanced/troubleshooting.md § Embedded and Associated Resources Metadata` reads as prescribed (mechanical — no red test; verified by `grep -c 'WRONG - This' guides/advanced/troubleshooting.md` returning `0` and `grep -c 'links to the unknown resource' guides/advanced/troubleshooting.md` returning `1`)
- [x] AC-5: `guides/core/ash_integration.md` has no `/tags` route and links `:tags` to `:tag` (mechanical — no red test; verified by `grep -c 'AshOverview.Tag' guides/core/ash_integration.md` returning `0` and `grep -c 'field :tags, resource: :tag' guides/core/ash_integration.md` returning `1`)
- [x] AC-6: `guides/core/components.md § Two resources on one schema` reads as prescribed (mechanical — no red test; verified by `grep -c 'An association needs .resource:. only then' guides/core/components.md` returning `1`)
- [x] AC-7: `guides/core/liveview.md § Preloading Associations` says that `resource:` also loads the association fields of the named resource (mechanical — no red test; verified by `grep -c 'one level deep' guides/core/liveview.md` returning `1`)
- [x] AC-8: `guides/core/resource_metadata.md` has `### Embedded Resources`, no `### Embedded Resource Naming`, and links the `resource` option to the preload rule (mechanical — no red test; verified by `grep -c '^### Embedded Resources$' guides/core/resource_metadata.md` returning `1`, `grep -c 'Embedded Resource Naming' guides/core/resource_metadata.md` returning `0` and `grep -c 'liveview.md#preloading-associations' guides/core/resource_metadata.md` returning `1`)
- [x] AC-9: `guides/whats_new/0.2.1.md § Upgrading from 0.2.0` lists four cases and no preload note (mechanical — no red test; verified by `grep -c 'Four cases need a change' guides/whats_new/0.2.1.md` returning `1`, `grep -c 'A custom fields parser defines' guides/whats_new/0.2.1.md` returning `1` and `grep -ci 'preload' guides/whats_new/0.2.1.md` returning `0`)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->
<!-- section:PAR-1:start -->
### PAR-1 — Parser · ctx · `embedded_schema?/1`
Depends on: DOC-1

#### Documentation references
- `guides/core/resource_metadata.md § Embedded Resources`
- `guides/advanced/advanced_usage.md § Key Considerations`

#### Implementation details
The section adds one public function to the Ecto fields parser. It produces no `%Field{}` and changes no existing clause. The mirrored section for the Ash backend is PAR-2.

##### Acceptance criteria
- [x] AC-1: Given an Ecto schema without a table (the inline `embeds_one` schema `AllTypes.EmbedsOne` of the test module), when `Ctx.FieldsParser.embedded_schema?/1` receives it, then it returns `true`
- [x] AC-2: Given an Ecto schema with a table (`AllTypes`, source `"test_all_types"`), when `Ctx.FieldsParser.embedded_schema?/1` receives it, then it returns `false`
- [x] AC-3: Given a module that is not an Ecto schema (`String`), when `Ctx.FieldsParser.embedded_schema?/1` receives it, then it returns `false` and does not raise

##### Test ports
- `Aurora.Uix.Integration.Ctx.FieldsParser.embedded_schema?/1` · in: `module()` · out: `boolean()` · new (`rg -n 'embedded_schema\?' lib test guides` returns nothing)

##### Red tests (write first; each must fail before implementation)
No existing test covers this function: the search above returns nothing in `test/`.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | add to, new `describe "embedded_schema?/1"` | the `AllTypes` schema already declared in the test module; its `embeds_one :embeds_one, EmbedsOne do` block defines `AllTypes.EmbedsOne` | test/cases/integration/ctx/fields_parser_test.exs | "a schema without a table is embedded-only" | `assert Ctx.FieldsParser.embedded_schema?(AllTypes.EmbedsOne)` |
| AC-2 | add to, same `describe` | `AllTypes` | test/cases/integration/ctx/fields_parser_test.exs | "a schema with a table is not embedded-only" | `refute Ctx.FieldsParser.embedded_schema?(AllTypes)` |
| AC-3 | add to, same `describe` | none | test/cases/integration/ctx/fields_parser_test.exs | "a module that is not a schema is not embedded-only" | `refute Ctx.FieldsParser.embedded_schema?(String)` |

`test/cases/integration/fields_parser_validations_test.exs` gets no row: the function returns a boolean and no golden `%Field{}` changes.

##### Parser changes
1. `lib/aurora_uix/integration/ctx/fields_parser.ex` — add the public function `embedded_schema?/1` directly after `embedded_resource/2` and before the `## PRIVATE` marker:
   ```elixir
   @doc """
   Tells whether a schema is embedded-only: an Ecto schema without a table.

   ## Parameters

   - `schema` (module()) - The schema module of a resource.

   ## Returns

   boolean() - `true` when `schema.__schema__(:source)` is `nil`; `false` for a schema with a
   table and for a module that is not an Ecto schema.
   """
   @spec embedded_schema?(module()) :: boolean()
   def embedded_schema?(schema) do
     Code.ensure_compiled(schema)

     function_exported?(schema, :__schema__, 1) and is_nil(schema.__schema__(:source))
   end
   ```
   The function has one clause and no catch-all. `Code.ensure_compiled/1` followed by `function_exported?(schema, :__schema__, 1)` is the guard `parse_fields/2` of the same file already uses.
2. `lib/aurora_uix/integration/ctx/fields_parser.ex` `@moduledoc` › `## Key Features` — add the bullet `- Tells whether a schema is embedded-only (no table)`.
3. No `%Field{}` key and no `data` key changes. No new type atom: no type-atom audit.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:PAR-1:end -->
<!-- section:PAR-2:start -->
### PAR-2 — Parser · ash · `embedded_schema?/1`
Depends on: DOC-1

#### Documentation references
- `guides/core/resource_metadata.md § Embedded Resources`
- `guides/core/ash_integration.md § Embedded Resources`

#### Implementation details
The section adds one public function to the Ash fields parser. It produces no `%Field{}` and changes no existing clause. The mirrored section for the Ecto backend is PAR-1.

##### Acceptance criteria
- [x] AC-1: Given an Ash resource with `data_layer: :embedded` (`EmbedsOne` of the test file), when `Ash.FieldsParser.embedded_schema?/1` receives it, then it returns `true`
- [x] AC-2: Given an Ash resource with a table (`AggregatedRelationship`, `data_layer: AshPostgres.DataLayer`), when `Ash.FieldsParser.embedded_schema?/1` receives it, then it returns `false`
- [x] AC-3: Given a module that is not an Ash resource (`String`), when `Ash.FieldsParser.embedded_schema?/1` receives it, then it returns `false` and does not raise

##### Test ports
- `Aurora.Uix.Integration.Ash.FieldsParser.embedded_schema?/1` · in: `module()` · out: `boolean()` · new (`rg -n 'embedded_schema\?' lib test guides` returns nothing)

##### Red tests (write first; each must fail before implementation)
No existing test covers this function: the search above returns nothing in `test/`.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | add to, new `describe "embedded_schema?/1"` | the top-level `EmbedsOne` resource of the test file | test/cases/integration/ash/fields_parser_test.exs | "an embedded resource is embedded-only" | `assert Ash.FieldsParser.embedded_schema?(EmbedsOne)` |
| AC-2 | add to, same `describe` | the top-level `AggregatedRelationship` resource of the test file | test/cases/integration/ash/fields_parser_test.exs | "a resource with a table is not embedded-only" | `refute Ash.FieldsParser.embedded_schema?(AggregatedRelationship)` |
| AC-3 | add to, same `describe` | none | test/cases/integration/ash/fields_parser_test.exs | "a module that is not a resource is not embedded-only" | `refute Ash.FieldsParser.embedded_schema?(String)` |

`test/cases/integration/fields_parser_validations_test.exs` gets no row: the function returns a boolean and no golden `%Field{}` changes.

##### Parser changes
1. `lib/aurora_uix/integration/ash/fields_parser.ex` — add the public function `embedded_schema?/1` directly after `embedded_resource/2` and before the first `## PRIVATE` marker:
   ```elixir
   @doc """
   Tells whether a schema is embedded-only: an Ash resource with the embedded data layer.

   ## Parameters

   - `schema` (module()) - The schema module of a resource.

   ## Returns

   boolean() - `true` for an embedded Ash resource; `false` for any other resource and for a
   module that is not an Ash resource.
   """
   @spec embedded_schema?(module()) :: boolean()
   def embedded_schema?(schema),
     do: AshResourceInfo.resource?(schema) and AshResourceInfo.embedded?(schema)
   ```
   The function has one clause and no catch-all. `AshResourceInfo` is the alias of `Ash.Resource.Info` the file already declares; the private `embedded_resource?/1` of the same file calls the same two functions.
2. `lib/aurora_uix/integration/ash/fields_parser.ex` `@moduledoc` › `## Key Features` — add the bullet `- Tells whether a schema is embedded-only (an embedded Ash resource)`.
3. No `%Field{}` key and no `data` key changes. No new type atom: no type-atom audit.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:PAR-2:end -->
<!-- section:UI-1:start -->
### UI-1 — UI · layout · embedded status and the context check from the backend
Depends on: PAR-1, PAR-2

#### Documentation references
- `guides/core/resource_metadata.md § Embedded Resources`, `§ Context-based Resources`
- `guides/whats_new/0.2.1.md § Upgrading from 0.2.0`
- `guides/core/ash_integration.md § Step 3: Configure Aurora UIX Resource Metadata`, `§ Step 4: Add to Router`

#### Implementation details
Layout types: none of `:index`, `:form`, `:show` is touched; the section changes resource resolution only. The layout code stays backend-agnostic: it calls `embedded_schema?/1` on the parser module `LayoutHelpers.get_fields_parser_module/1` returns and names no `Ecto.*` and no `Ash.*` module.

The order in which resources are validated and resolved does not change: the context check stays in `prepare_resource/2`, before `resolve_resources/2`.

##### Acceptance criteria
- [x] AC-1: Given `auix_resource_metadata :user__profile, schema: Aurora.Uix.Guides.Accounts.User.Profile` with no `context:` and no CRUD functions, next to `:user` and an `auix_create_ui`, then the module compiles, `auix_resource(:user__profile).embedded?` is `true` and no `Profile.*` module exists
- [x] AC-2: Given an Ash embedded resource declared under a free name (`auix_resource_metadata :tag_metadata, ash_resource: Aurora.Uix.Guides.Blog.Tag`), then `auix_resource(:tag_metadata).embedded?` is `true` and `auix_modules/0` has no `:tag_*` key
- [x] AC-3: Given a resource declared on an Ecto schema with a table and no `context:`, then compilation raises `Spark.Error.DslError` whose message contains ``requires the `:context` option``, the schema, the cause (`has a table`) and the solution
- [x] AC-4: Given a parent Ecto schema that embeds a schema with a table, and `auix_resource_metadata :person__address` declared on that schema with `context:`, then `auix_resource(:person__address).embedded?` is `false`; without the declaration the resource the library creates under the same name has `embedded?: true`
- [x] AC-5: Given a resource that declares `context:` and whose context has no CRUD functions for it, then `auix_create_ui` raises `Function reference error in option ':list_function'` as before (mechanical — no red test; verified by `git diff origin/main...HEAD -- lib/aurora_uix/integration/ctx/context_parser_defaults.ex` returning nothing)
- [x] AC-6: The demo app compiles with no route to `AshOverview.Tag` (mechanical — no red test; verified by `mix compile --warnings-as-errors` and `grep -c 'AshOverview.Tag' lib/aurora_uix_web/routes.ex` returning `0`)

##### Test ports
- `auix_resource/1` and `auix_modules/0` of a module compiled inside the test with `Code.compile_string/1` · no route · observable: the `%Aurora.Uix.Resource{}` `embedded?` key, the keys of `auix_modules/0`, `Code.ensure_loaded?/1`, and the `Spark.Error.DslError` message. Mount type: compiled module, not a LiveViewTest view.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1, AC-2 | amend | `compiled_ui/1` of the file. In the body: (a) add `auix_resource_metadata :user__profile do` / `schema Aurora.Uix.Guides.Accounts.User.Profile` / `field :online, readonly: true` / `end` after the `:user` declaration; (b) replace `auix_resource_metadata :post__tags, ash_resource: Aurora.Uix.Guides.Blog.Tag` with `auix_resource_metadata :tag_metadata, ash_resource: Aurora.Uix.Guides.Blog.Tag` | test/cases/create_ui_validation_test.exs | "an embedded resource generates no modules" | the expected `auix_modules/0` key list stays as written; the `for name <- [...]` list becomes `[:post__comment, :post__tags, :policy_item__tags, :tag_metadata, :user__profile]` with `assert mod.auix_resource(name).embedded?`; add `assert mod.auix_resource(:user__profile).fields.online.readonly`. Before the change the body fails to compile (``requires the `:context` option``) |
| AC-3 | amend | `compile/1` of the file, body unchanged | test/cases/resource_metadata_validation_test.exs | "a context resource without :context fails compilation" | replace the regex with ``~r/requires the `:context` option: Aurora\.Uix\.Guides\.Inventory\.Product has a table, so :product is a standalone resource\. Give `context:` with its CRUD functions/`` |
| AC-4 | add to (no existing test embeds a schema with a table: `rg -n '^\s+embeds_(one\|many) :' test` hits only the two inline schemas of `test/cases/integration/ctx/fields_parser_test.exs`) | two schemas nested in the test module, as `test/cases/integration/ctx/fields_parser_test.exs` nests its own: `Address` (`use Ecto.Schema`, `schema "addresses" do field :street, :string end`) and `Person` (`schema "people" do field :name, :string; embeds_one :address, Aurora.Uix.Test.Cases.ResourceMetadataValidationTest.Address end`). Compile twice with `compile/1`: body A is `auix_resource_metadata :person, schema: Aurora.Uix.Test.Cases.ResourceMetadataValidationTest.Person, context: Aurora.Uix.Guides.Inventory`; body B is body A plus `auix_resource_metadata :person__address, schema: Aurora.Uix.Test.Cases.ResourceMetadataValidationTest.Address, context: Aurora.Uix.Guides.Inventory` | test/cases/resource_metadata_validation_test.exs | "a declared resource on a schema with a table is not embedded" | `[{a, _}] = compile(body_a)`; `assert a.auix_resource(:person__address).embedded?`; `[{b, _}] = compile(body_b)`; `refute b.auix_resource(:person__address).embedded?` |

##### Modules & components
1. `Aurora.Uix.Integration.Default.FieldsParser` at `lib/aurora_uix/integration/default/fields_parser.ex` — modified. Add after `embedded_resource/2`:
   ```elixir
   @doc """
   Tells whether a schema is embedded-only. A schema of an unknown backend never is.

   ## Parameters

   - `schema` (module()) - The schema module of a resource.

   ## Returns

   boolean() - Always `false`.
   """
   @spec embedded_schema?(module()) :: boolean()
   def embedded_schema?(_schema), do: false
   ```
   It gets no test (house convention H-3).
2. `Aurora.Uix.Layout.ResourceMetadata` at `lib/aurora_uix/layout/resource_metadata.ex` — modified:
   1. New private function, placed after `validate_context/2` (`rg -n 'schema_embedded\?' lib test` returns nothing):
      ```elixir
      @spec schema_embedded?(Resource.t()) :: boolean()
      defp schema_embedded?(%Resource{} = resource) do
        resource.type
        |> LayoutHelpers.get_fields_parser_module()
        |> then(& &1.embedded_schema?(resource.schema))
      end
      ```
   2. `validate_context/2`, clause `defp validate_context(%Resource{type: :ctx, context: nil} = resource, module) do` — replace its body: return `resource` when `schema_embedded?(resource)` is `true`; else raise the `DslError` with the `module:`, `path:` and `location:` the clause has now and this `message:`:
      ```elixir
      "context resource #{inspect(resource.name)} requires the `:context` option: " <>
        "#{inspect(resource.schema)} has a table, so #{inspect(resource.name)} is a standalone " <>
        "resource. Give `context:` with its CRUD functions, or remove the declaration to use " <>
        "the resource the library creates for an embedded field"
      ```
      The clause `defp validate_context(%Resource{schema: nil} = resource, _module), do: resource` stays first, and the catch-all stays last.
   3. `add_embedded_resources/1` — keep the `with_embedded` reduce. Replace everything after it (the `embedded_names` binding and the final `Enum.map`) with:
      ```elixir
      {created, declared} = Enum.split(with_embedded, length(with_embedded) - length(resources))

      Enum.map(created, &struct(&1, %{embedded?: true})) ++
        Enum.map(declared, &put_embedded_status/1)
      ```
      `embedded_resource/2` of both parsers prepends, so the created resources are the head of `with_embedded`; the order of the list does not change.
   4. New private function, placed after `add_embedded_resources/1` (`rg -n 'put_embedded_status' lib test` returns nothing):
      ```elixir
      @spec put_embedded_status(Resource.t()) :: Resource.t()
      defp put_embedded_status(%Resource{schema: nil} = resource), do: resource

      defp put_embedded_status(%Resource{} = resource),
        do: struct(resource, %{embedded?: schema_embedded?(resource)})
      ```
   5. `@moduledoc` › `## Key Constraints` — replace ``- A context (`:ctx`) resource requires `:context`.`` with ``- A context (`:ctx`) resource requires `:context`, unless its schema is embedded-only (no table).``
   6. `prepare_resource/2` `@doc` — replace ``Raises `Spark.Error.DslError` for a context resource without `:context` or invalid`` with ``Raises `Spark.Error.DslError` for a context resource on a schema with a table and no `:context`, and for invalid``. The next line (`` `:backend_opts`. ``) stays.
3. `Aurora.Uix.Layout.ResourceMetadata.Dsl` at `lib/aurora_uix/layout/resource_metadata/dsl.ex` — `@resource_schema`, entry `context:` — replace the `doc:` string with ``"Context module of an Ecto resource. Required unless the schema is embedded-only (no table)."``
4. `Aurora.Uix.Resource` at `lib/aurora_uix/resource.ex` `@moduledoc` — replace the two-line `embedded?` entry with:
   ```
     - `embedded?` (`boolean`) - `true` for a resource on an embedded-only schema (the backend
       decides) and for a resource the library creates for an embedded field.
   ```
5. `Aurora.Uix.Layout.CreateUI` at `lib/aurora_uix/layout/create_ui.ex` `@moduledoc` › `## Key Constraints` — replace the two-line bullet that starts ``- A resource named for an embedded field (`<parent>__<field>`) generates no modules`` with:
   ```
     - A resource on an embedded-only schema generates no modules, whatever its name; neither does
       a resource the library creates for an embedded field.
   ```
   `target?/1` and `build_resource_layouts/3` of the same file keep reading `embedded?`; neither changes.
6. `Aurora.UixWeb.Routes` at `lib/aurora_uix_web/routes.ex` `load_routes/0` — delete the line `auix_live_resources("/tags", AshOverview.Tag)`. `:tag` in `lib/aurora_uix_web/guides/ash_overview.ex` is declared on the embedded resource `Aurora.Uix.Guides.Blog.Tag`, so `AshOverview.Tag.Index` is no longer generated. The `:tag` declaration and the `Tag` alias of `ash_overview.ex` stay. `rg -n '/tags' test lib` hits only that route line: no test visits it.
7. Components: none. Theme: none. `dt/1` strings: none (the new text is a compile error, not UI text).

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-1:end -->
<!-- section:UI-3:start -->
### UI-3 — UI · layout · `resource:` links a field to its resource
Depends on: UI-1

#### Documentation references
- `guides/core/resource_metadata.md § Embedded Resources`, `§ Field Metadata`, `§ Selector, Embed and Upload Options`, `§ Field Data`
- `guides/core/components.md § Two resources on one schema`
- `guides/advanced/troubleshooting.md § Embedded and Associated Resources Metadata`
- `guides/core/liveview.md § Preloading Associations`
- `guides/whats_new/0.2.1.md § Upgrading from 0.2.0`

#### Implementation details
Layout types: `:index`, `:form` and `:show` are all served by the same resolved field; no renderer changes.

The section works on `%Field{}` atoms only and names no `Ecto.*` and no `Ash.*` module. Both backends are covered by one code path: both parsers fill `data.related` and `data.resource` for embedded fields and associations.

Load guarantee for `data.related`: `field_data/2` of `lib/aurora_uix/integration/ctx/fields_parser.ex` sets `related:` in its `Ecto.Embedded` clause, its `%AssociationManyToMany{}` clause and its generic association clause; `field_data/2` of `lib/aurora_uix/integration/ash/fields_parser.ex` sets `related:` in its `BelongsTo`, `HasMany`, `HasOne` and `ManyToMany` clauses and in its `embedded?: true` clause. For an embedded field `data.related` equals the `schema` of the resource the library creates for it.

The order of resolution does not change. The link is applied inside `resolve_fields/2`, after `parse_associations/4` and before `configure_many_to_one_selectors/1`, so the foreign-key column of a many-to-one copies the re-pointed `data`.

The library still creates `<parent>__<field>` for an embedded field that names another resource.

Decision recorded for this section: no view changes what it preloads. An association that declares `resource:` nests the association keys of the named resource, as on 0.2.0; an association without `resource:` nests nothing, as on 0.2.0. On 0.2.0 `extract_resource_preloads/1` of `lib/aurora_uix/layout/create_ui.ex` takes the named resource from `field.resource`, which `resource:` overwrites. This section stops that overwrite and, in the same section, makes `extract_resource_preloads/1` take the name from the declaration (`Resource.field_overrides`). No key is added to `%Field{}` and none to `data`.

Load guarantee for the declaration: `build_configurations/5` of `create_ui.ex` puts each resource under `resource_config:` in its configuration, and `extract_resource_preloads/1` receives those configurations. `field_overrides` holds the `field` entries as declared, one per key after `expand_keys/1` of `resource_metadata.ex`; `put_fields/2` of `resource_metadata.ex` and `Resource.resolve/1` keep it. An imported resource carries the `field_overrides` of the module that declares it. A hand-written resource has `field_overrides: []`.

##### Acceptance criteria
- [x] AC-1: Given `field :products, resource: :product_compact` on `:product_location`, with `:product_compact` declared before `:product` on the same schema, then the one-to-many list of the location show page is the index component of `:product_compact`
- [x] AC-2: Given `field :comment, resource: :my_comment` on an Ash `:post` and `:my_comment` declared on `Aurora.Uix.Guides.Blog.Comment`, then `fields.comment.data.resource` is `:my_comment` and `fields.comment.resource` is `:post`
- [x] AC-3: Given `field :profile, resource: :profile_card` on an Ecto `:user` and `:profile_card` declared on `Aurora.Uix.Guides.Accounts.User.Profile` with no `context:`, then `fields.profile.data.resource` is `:profile_card` and `fields.profile.resource` is `:user`
- [x] AC-4: Given `field :author, resource: :writer` on `:post`, with `:writer` and then `:author` declared on `Aurora.Uix.Guides.Blog.Author`, then `fields.author.data.resource` and `fields.author_id.data.resource` are both `:writer`, and `fields.author.resource` is `:post`
- [x] AC-5: Given `resource:` naming a resource the module imports with `@auix_resource_metadata`, then the field links to it
- [x] AC-6: Given `resource:` with a name that matches no resource, then compilation raises `Spark.Error.DslError` naming the field, its resource and the unknown name
- [x] AC-7: Given `resource:` naming a resource on another schema, then compilation raises `Spark.Error.DslError` naming the field, the resource and both schemas
- [x] AC-8: Given `resource:` on a field that is neither embedded nor an association, then compilation raises `Spark.Error.DslError` naming the field and its type; on the foreign-key column of a many-to-one the message says to put `resource:` on the association field
- [x] AC-9: Given a field without `resource:`, then `data.resource` and `resource` are what they are before this section (mechanical — no red test; verified by the unmodified tests "a declared resource links its associations to imported resources" and "a declared Ash resource links its associations to imported resources" of `test/cases/resource_metadata_validation_test.exs`)
- [x] AC-10: Given `field :products, resource: :product` on `:product_location`, a `:product_location` layout that shows `:products`, and `:product` layouts that show `:product_location` and `:product_transactions`, then `fields.products.resource` is `:product_location` and `auix_preloads().product_location` nests `:product_location` and `:product_transactions` under `:products`, as before this section
- [x] AC-11: Given the same module, then the associations without `resource:` nest nothing: `auix_preloads().product` holds `{:product_location, []}` and `{:product_transactions, []}`

##### Test ports
- Route `"/one-to-many-component-product_locations"`, already registered in `test/support/app_web/routes.ex` (prefixes `"one-to-many-component-products"` and `"one-to-many-component-product_locations"`); no registration changes · layout type `:show` · observable: `has_element?/2` on the selectors the test already uses
- `auix_resource/1` of a module compiled inside the test with `Code.compile_string/1` · observable: `%Field{}` `resource` and `data.resource`, and the `Spark.Error.DslError` message. Mount type: compiled module, not a LiveViewTest view.
- `auix_preloads/0` of a module compiled inside the test · no route · observable: the keyword list per resource. Mount type: compiled module, not a LiveViewTest view.

##### Red tests
`rg -n 'field\(?\s*:\w+, resource:' test` hits only `test/cases_live/one_to_many_component_test.exs`: no existing test covers `resource:` on an embedded field, on a many-to-one, with an imported resource, and none covers its three compile errors. `rg -n 'auix_preloads' test` hits only `test/cases_live/ash_embeds_test.exs` and `test/cases/generated_field_test.exs`, and both assert generated fields: no existing test covers a nested preload.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | amend | swap the two declarations at the top of the module: `auix_resource_metadata(:product_compact, context: Inventory, schema: Product)` first, `auix_resource_metadata(:product, context: Inventory, schema: Product)` second. Nothing else changes | test/cases_live/one_to_many_component_test.exs | "the child list is an index component of the related resource" | assertions unchanged. Before the change the list is the index of `:product` and `refute has_element?(view, "div[name='auix-one_to_many-product_location'] th[name='auix-column-label']", "Description")` fails |
| AC-2, AC-4 | add to | `compile/1` of the file. Body: `auix_resource_metadata :post do` / `ash_resource Aurora.Uix.Guides.Blog.Post` / `field :comment, resource: :my_comment` / `field :author, resource: :writer` / `end`, then `auix_resource_metadata :my_comment, ash_resource: Aurora.Uix.Guides.Blog.Comment`, `auix_resource_metadata :writer, ash_resource: Aurora.Uix.Guides.Blog.Author`, `auix_resource_metadata :author, ash_resource: Aurora.Uix.Guides.Blog.Author` | test/cases/resource_metadata_validation_test.exs | "resource: links an Ash embedded field and a many-to-one" | `fields = mod.auix_resource(:post).fields`; `assert {fields.comment.resource, fields.comment.data.resource} == {:post, :my_comment}`; `assert {fields.author.resource, fields.author.data.resource} == {:post, :writer}`; `assert fields.author_id.data.resource == :writer`. Before the change the three tuples read `{:my_comment, :post__comment}`, `{:writer, :author}` and `:author` |
| AC-3 | add to | `compile/1`. Body: `auix_resource_metadata :user do` / `schema Aurora.Uix.Guides.Accounts.User` / `context Aurora.Uix.Guides.Accounts` / `field :profile, resource: :profile_card` / `end`, then `auix_resource_metadata :profile_card, schema: Aurora.Uix.Guides.Accounts.User.Profile` | test/cases/resource_metadata_validation_test.exs | "resource: links an Ecto embedded field" | `field = mod.auix_resource(:user).fields.profile`; `assert {field.resource, field.data.resource} == {:user, :profile_card}` |
| AC-5 | add to | `compile_meta/0` of the file, then `compile/1` with `@auix_resource_metadata %{product_location: #{inspect(meta)}.auix_resource(:product_location)}` followed by `auix_resource_metadata :catalog_product do` / `schema Aurora.Uix.Guides.Inventory.Product` / `context Aurora.Uix.Guides.Inventory` / `field :product_location, resource: :product_location` / `end` | test/cases/resource_metadata_validation_test.exs | "resource: links to an imported resource" | `field = mod.auix_resource(:catalog_product).fields.product_location`; `assert {field.resource, field.data.resource} == {:catalog_product, :product_location}`. Before the change `field.resource` is `:product_location` |
| AC-6 | add to | `compile/1`. Body: `:product` on `Aurora.Uix.Guides.Inventory.Product` with `context Aurora.Uix.Guides.Inventory` and `field :product_location, resource: :nowhere` | test/cases/resource_metadata_validation_test.exs | "resource: with an unknown name fails compilation" | `assert_raise DslError, ~r/field :product_location of :product links to the unknown resource :nowhere/, fn -> ... end` |
| AC-7 | add to | `compile/1`. Body: the `:product` block with `field :product_location, resource: :movement`, then `auix_resource_metadata :movement, context: Aurora.Uix.Guides.Inventory, schema: Aurora.Uix.Guides.Inventory.ProductTransaction` | test/cases/resource_metadata_validation_test.exs | "resource: with a resource on another schema fails compilation" | `assert_raise DslError, ~r/field :product_location of :product links to the resource :movement, whose schema is Aurora\.Uix\.Guides\.Inventory\.ProductTransaction; the field relates to Aurora\.Uix\.Guides\.Inventory\.ProductLocation/, fn -> ... end` |
| AC-8 | add to | `compile/1`, two bodies, each the `:product` block plus `auix_resource_metadata :product_location, context: Aurora.Uix.Guides.Inventory, schema: Aurora.Uix.Guides.Inventory.ProductLocation`: body A has `field :name, resource: :product_location`; body B has `field :product_location_id, resource: :product_location` | test/cases/resource_metadata_validation_test.exs | "resource: on a plain field fails compilation" | body A: ``assert_raise DslError, ~r/`resource:` on field :name of :product is not allowed: its type is :string, and only an embedded field or an association links to a resource/``; body B: ``assert_raise DslError, ~r/`resource:` on field :product_location_id of :product is not allowed: .* Put `resource:` on the association field :product_location/`` |
| AC-10, AC-11 | add to | `compiled_ui/1` of the file (its `compile/1` already declares `:product`). Body: `auix_resource_metadata :product_location do` / `context Aurora.Uix.Guides.Inventory` / `schema Aurora.Uix.Guides.Inventory.ProductLocation` / `field :products, resource: :product` / `end`, then `auix_create_ui do` with `index_columns :product, [:reference, :product_location]`; `edit_layout :product do stacked [:reference, :product_location] end`; `show_layout :product do stacked [:reference, :product_location, :product_transactions] end`; `index_columns :product_location, [:name]`; `edit_layout :product_location do stacked [:name] end`; `show_layout :product_location do stacked [:name, :products] end`; `end` | test/cases/create_ui_validation_test.exs | "a field with resource: keeps its nested preload" | `assert mod.auix_resource(:product_location).fields.products.resource == :product_location`; `preloads = mod.auix_preloads()`; `assert Enum.sort(Keyword.fetch!(preloads.product_location, :products)) == [:product_location, :product_transactions]`; `assert Keyword.fetch!(preloads.product, :product_location) == []`; `assert Keyword.fetch!(preloads.product, :product_transactions) == []`. Before the change the first assertion fails (`:product`); the three preload assertions hold before and after |

##### Modules & components
1. `Aurora.Uix.Layout.ResourceMetadata` at `lib/aurora_uix/layout/resource_metadata.ex` — modified.
   1. Contract change — `resolve_resources/2` becomes `resolve_resources/3`:
      ```elixir
      @spec resolve_resources([Resource.t()], [{atom(), Resource.t()}], module()) ::
              %{atom() => Resource.t()}
      def resolve_resources(resources, imported, module) do
      ```
      Its body passes `module` on: `Enum.map(parsed, &resolve_fields(&1, parsed ++ imported, module))`. Add to its `@doc` `## Parameters` the line ``- `module` (module()) - The module declaring the resources, for error reporting.`` and, after `## Returns`, the line ``Raises `Spark.Error.DslError` for a `resource:` field option that names no resource, names a resource on another schema, or sits on a field that is neither embedded nor an association.``
      Callers: one, `transform/1` of `lib/aurora_uix/layout/resource_metadata/resolve_resources.ex`. Its call `|> ResourceMetadata.resolve_resources(imported_resources(module))` becomes `|> ResourceMetadata.resolve_resources(imported_resources(module), module)`. `rg -n 'resolve_resources\(' lib test` shows no other caller.
   2. `resolve_fields/2` becomes `resolve_fields/3` (`@spec resolve_fields({atom(), Resource.t()}, [{atom(), Resource.t()}], module()) :: {atom(), Resource.t()}`). The clause for `%Resource{schema: nil}` ignores the new argument. The second clause becomes:
      ```elixir
      defp resolve_fields({name, %Resource{} = resource}, resources, module) do
        fields_parser = LayoutHelpers.get_fields_parser_module(resource.type)
        overrides = merge_overrides(resource.field_overrides)
        owner_overrides = Map.new(overrides, fn {key, override} -> {key, struct(override, %{resource: nil})} end)

        resource.schema
        |> fields_parser.parse_associations(name, resources, resource.fields)
        |> Enum.reverse()
        |> link_resources(overrides, %{module: module, owner: name, resources: resources})
        |> configure_many_to_one_selectors()
        |> apply_overrides(owner_overrides)
        |> append_declared_fields(resource.field_overrides, owner_overrides, name)
        |> then(&{name, put_fields(resource, &1)})
      end
      ```
      `owner_overrides` carries no `resource`, and `Field.merge/2` skips `nil` keys, so `field.resource` keeps the owner name. `Field.merge/2` itself does not change.
   3. New module attribute, above `resolve_fields/3`:
      ```elixir
      @linkable_types [
        :embeds_one,
        :embeds_many,
        :many_to_one_association,
        :one_to_many_association,
        :one_to_one_association,
        :many_to_many_association
      ]
      ```
      These six atoms exist; no type atom is new.
   4. New private functions, placed after `append_declared_fields/4` (`rg -n 'link_resources|link_resource|link_error|linkable_types|owner_overrides' lib test` returns nothing):
      - `link_resources/3`, `@spec link_resources([Field.t()], map(), map()) :: [Field.t()]` — takes the overrides whose `resource` is not `nil` (`overrides |> Map.values() |> Enum.reject(&is_nil(&1.resource))`) and reduces `fields` with `link_resource/3`.
      - `link_resource/3`, `@spec link_resource(Field.t(), [Field.t()], map()) :: [Field.t()]`, arguments `(override, fields, context)`. Steps, in this order:
        1. `field = Enum.find(fields, &(&1.key == override.key))`.
        2. When `field` is `nil`, and when `field.type not in @linkable_types`: raise with the *not linkable* message. The type in the message is `field.type` when `field` exists, else `override.type || :string`.
        3. `linked = List.keyfind(context.resources, override.resource, 0)`. When it is `nil`: raise with the *unknown* message.
        4. When `elem(linked, 1).schema != field.data.related`: raise with the *schema* message.
        5. Else return `fields` with that field replaced by `struct(field, %{data: Map.put(field.data, :resource, override.resource)})`.
      - `link_error/3`, `@spec link_error(Field.t(), map(), binary()) :: no_return()`, arguments `(override, context, message)`:
        ```elixir
        raise DslError,
          module: context.module,
          path: [:auix_resource_metadata, context.owner, :field, override.key],
          location: Entity.anno(override),
          message: message
        ```
        `override` is the declared `field` entry, which carries the Spark annotation; a resolved field does not.
      - Messages, exact (`key` is `override.key`, `owner` is `context.owner`, `link` is `override.resource`):

        | Case | Message |
        |---|---|
        | not linkable | ``"`resource:` on field #{inspect(key)} of #{inspect(owner)} is not allowed: its type is #{inspect(type)}, and only an embedded field or an association links to a resource"`` |
        | not linkable, foreign key | the message above followed by ``". Put `resource:` on the association field #{inspect(association.key)}"``, when `association = Enum.find(fields, &(&1.type == :many_to_one_association and &1.data.owner_key == key))` is not `nil` |
        | unknown | `"field #{inspect(key)} of #{inspect(owner)} links to the unknown resource #{inspect(link)}"` |
        | schema | `"field #{inspect(key)} of #{inspect(owner)} links to the resource #{inspect(link)}, whose schema is #{inspect(elem(linked, 1).schema)}; the field relates to #{inspect(field.data.related)}"` |
      - No check that the linked resource is embedded: an ordinary resource on an Ecto schema with a table renders an embedded field of that schema.
   5. `@moduledoc` › `## Key Features` — add the bullet ``- `resource:` on an embedded field and on an association names the resource that renders it; the name and its schema are checked at compile time.``
2. `Aurora.Uix.Layout.CreateUI` at `lib/aurora_uix/layout/create_ui.ex` — modified. `Field` and `Resource` are aliases the file already declares.
   1. `extract_resource_preloads/1` — replace the `associations` binding with:
      ```elixir
      associations =
        fields_by_resource
        |> Enum.map(fn {resource_name, resource_fields} ->
          links = declared_links(Map.fetch!(configurations, resource_name).resource_config)

          resource_fields
          |> Enum.reject(&generated?/1)
          |> Enum.map(&{&1.key, preload_resource(&1, resource_name, links)})
          |> then(&{resource_name, &1})
        end)
        |> expand_associations()
      ```
      The `fields_by_resource` binding, the `generated` binding and the final `Map.merge/3` stay. `expand_associations/1`, `do_expand_associations/1` and `build_resource_preload_option/2` do not change.
   2. New private functions, placed after `generated?/1` (`rg -n 'declared_links|preload_resource' lib test` returns nothing):
      ```elixir
      # The `resource:` links a resource declares for its fields, by field key.
      @spec declared_links(Resource.t()) :: %{(atom() | tuple()) => atom()}
      defp declared_links(%Resource{field_overrides: field_overrides}) do
        field_overrides
        |> Enum.reject(&is_nil(&1.resource))
        |> Map.new(&{&1.key, &1.resource})
      end

      # The resource whose association keys are nested under an association. A field that keeps
      # the name of its own resource nests nothing, unless the resource declares `resource:` for it.
      @spec preload_resource(Field.t(), atom(), map()) :: atom() | nil
      defp preload_resource(%Field{resource: resource_name} = field, resource_name, links),
        do: Map.get(links, field.key, resource_name)

      defp preload_resource(%Field{resource: resource}, _resource_name, _links), do: resource
      ```
      `Map.new/2` keeps the last entry of a key, so the later `field` entry wins, as in `merge_overrides/1` of `resource_metadata.ex`. The second clause of `preload_resource/3` returns `field.resource` as `extract_resource_preloads/1` does today: it serves a field of a hand-written resource and a field whose `resource` a layout sets inline.
   3. The values `expand_associations/1` receives are the ones it receives today: the declared name for an association with `resource:` (today through the overwritten `field.resource`), the name of the owning resource for any other (clause `{field, ^resource_name} -> {field, []}`).
3. `Aurora.Uix.Layout.ResourceMetadata.Dsl` at `lib/aurora_uix/layout/resource_metadata/dsl.ex` — `@field_schema`, entry `resource:` — replace the `doc:` string with ``"For embedded fields and associations: the name of the resource that renders the related entries. It must describe the field's related schema. On an association it also preloads the association fields the named resource's layouts render."``
4. `Aurora.Uix.Field` at `lib/aurora_uix/field.ex` `@moduledoc` — replace the line that starts ``- `resource` (`atom`) - Used for associations`` with:
   ```
       - `resource` (`atom`) - The name of the resource that owns the field. The `resource:` field
         option does not set it: it sets `data.resource`, the resource that renders the related entries.
   ```
5. `Aurora.UixWeb.Guides.AshOverview` at `lib/aurora_uix_web/guides/ash_overview.ex` — in the `auix_resource_metadata :post do` block, add `field :tags, resource: :tag` after `field :topics, label: "Topics"`. `:tag` is declared below it on `Aurora.Uix.Guides.Blog.Tag`, the schema `post.tags` relates to.
6. Readers of `field.resource` and `field.data.resource`, each checked; one is edited (item 2):

   | Site | Reads | Verdict |
   |---|---|---|
   | `resource_metadata.ex` `configure_many_to_one_selectors/1` | `data.resource`, copies `data` to the owner-key field | no change; it runs after the link |
   | `create_ui.ex` `extract_resource_preloads/1` | `field.resource`, as the name of the resource whose association keys it nests | edited in item 2: the name comes from the declared `resource:` |
   | `templates/basic/renderers/fields/many_to_one.ex` `render/1`, `get_association_paths/3`, `get_many_to_one_field/3` | `data.resource` | no change |
   | `templates/basic/renderers/fields/many_to_one.ex` `set_many_to_one_resource/1` | `parent_field_struct.resource`, `field.resource` as the owner name | no change; the owner name is now always what it reads |
   | `templates/basic/renderers/fields/one_to_many.ex` `render/1`, `get_association_fields/2` | `data.resource` | no change |
   | `templates/basic/renderers/fields/one_to_one.ex`, `many_to_many.ex` `render/1` | `data.resource` | no change |
   | `templates/basic/renderers/embeds_one_renderer.ex` `render/1`, `templates/basic/components/embeds_many_component.ex` | `data.resource` | no change |
   | `templates/basic/helpers.ex` select helpers (`data: %{resource: _}` matches), `get_field/3` | `data.resource`; owner name for a new field | no change |
   | `field.ex` `set_field_id/1`, `layout/render_tree.ex` `resolve_field/2` | owner name | no change |
7. Components: none. Theme: none. `dt/1` strings: none (the new texts are compile errors, not UI text).

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-3:end -->

---

### Out of Scope
- Any change in `aurora_ctx`.
- Moving the context check after association parsing.
- A schema check for the conventional name: a resource declared as `<parent>__<field>` is used by that field without comparing schemas.
- A check that a resource linked to an embedded field is embedded-only.
- `resource:` written inline on a field of a layout (`stacked [products: [resource: :x]]`): it is not read as a link and this issue does not change how it is handled.
- Any change to what a view preloads: nested preloads for an association without `resource:`, pruning the nested preloads of an association with it (for example the association that points back to the parent), and nesting deeper than one level.
- Any other upgrade note: a 0.2.0 source without `resource:` on a field compiles and behaves as before.
<!-- enriched-spec:end -->
