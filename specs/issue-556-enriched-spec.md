<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** high

### Overview
A resource named for an embedded field (`<parent>__<field>`) is an embedded resource both when the
library creates it and when the module declares it: it is `embedded?: true` and generates no
modules, and its declared field options and layouts apply to the embedded field in the parent's
form and show. The fix is one backend-agnostic function in the layout layer. One existing test is
amended with declared Ash embedded-field resources; #557 covers the Ecto (`ctx`) backend.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | `CHANGELOG.md § [0.2.1] › Changed`, `guides/whats_new/0.2.1.md § Upgrading from 0.2.0` | none | federico/556-doc-1-embedded-field-resource | docs: a resource named for an embedded field generates no modules (#556 · DOC-1) |
| UI-1 | UI | layout · `add_embedded_resources/1` flags declared embedded-field resources | DOC-1 | federico/556-ui-1-declared-embedded-resource | fix: a declared embedded-field resource generates no modules (#556 · UI-1) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
- `CHANGELOG.md § [0.2.1] › Changed`, entry **Generated module names (breaking)**
- `guides/whats_new/0.2.1.md § Upgrading from 0.2.0`, second bullet of the list under "Two cases
  need a change:"

#### Implementation details

Both edits reword existing text. No entry, bullet, heading and note is added.

##### CHANGELOG.md
1. § `## [0.2.1]` › `### Changed` — replace the entry

   ```
   - **Generated module names (breaking)**: a duplicate generated module name fails compilation, and an
     embedded field generates no modules (What's New in 0.2.1, "Upgrading from 0.2.0").
   ```

   with, verbatim:

   ```
   - **Generated module names (breaking)**: a duplicate generated module name fails compilation, and a
     resource named for an embedded field (`<parent>__<field>`) generates no modules, created by the
     library or declared (What's New in 0.2.1, "Upgrading from 0.2.0").
   ```

##### guides/whats_new/0.2.1.md
1. § Upgrading from 0.2.0 — replace the bullet

   ```
   - A resource created for an embedded field generates no modules. Remove any reference to
     `<Module>.<EmbeddedSchema>.Index`, `.FormComponent` and `.ShowComponent`.
   ```

   with, verbatim:

   ```
   - A resource named for an embedded field (`<parent>__<field>`) generates no modules, whether the library
     creates it or the module declares it. Remove any reference to `<Module>.<EmbeddedSchema>.Index`,
     `.FormComponent` and `.ShowComponent`.
   ```

##### Acceptance criteria
- [ ] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no
      issue-link suffix (mechanical — no red test; verified by
      `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [ ] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-556-enriched-spec.md`)
- [ ] AC-3: `guides/whats_new/0.2.1.md § Upgrading from 0.2.0` reads as prescribed (mechanical — no
      red test; verified by `grep -c 'A resource named for an embedded field' guides/whats_new/0.2.1.md`
      returning `1` and `grep -c 'A resource created for an embedded field' guides/whats_new/0.2.1.md`
      returning `0`)
- [ ] AC-4: the **Generated module names (breaking)** entry reads as prescribed and the `### Changed`
      list of `## [0.2.1]` has the same number of entries as on `main` (mechanical — no red test;
      verified by `grep -c 'resource named for an embedded field' CHANGELOG.md` returning `1` and
      `git diff origin/main...HEAD --stat -- CHANGELOG.md` showing 3 insertions and 2 deletions)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->
<!-- section:UI-1:start -->
### UI-1 — UI · layout unit: embedded-field resources
Depends on: DOC-1

#### Documentation references
- `guides/whats_new/0.2.1.md § Upgrading from 0.2.0` — the behaviour, as DOC-1 words it.
- `guides/core/resource_metadata.md § Embedded Resource Naming` — the `<parent>__<field>` name.

#### Implementation details

Layout types: none of `:index`, `:form`, `:show` changes its markup. The section changes which
resources generate modules. No renderer, theme rule, component and `dt/1` string changes.

Backends: the fix is in `lib/aurora_uix/layout/`, which is backend-agnostic. It adds no reference to
`Ecto.*` and `Ash.Resource.*`. The Ash and the `ctx` parser are not edited: each already returns the
resources it creates for embedded fields from `embedded_resource/2`. The declarations this section
adds to the test are Ash resources only (Out of Scope, the `ctx` coverage entry).

Tests: this section adds no test, no test file, no support fixture and no route. It amends one
existing test. Test layer: `test/cases/` (layout generation, no DB), because the observable is which
modules a views module generates.

##### Acceptance criteria
- [ ] AC-1: Given a views module declaring the Ash resources `:post`
      (`Aurora.Uix.Guides.Blog.Post`) and `:post__comment` (`Aurora.Uix.Guides.Blog.Comment`), then
      `auix_resource(:post__comment).embedded?` is `true`, `auix_modules/0` holds no `:comment_*`
      name, and no `<Module>.Comment.Index`, `.FormComponent` and `.ShowComponent` module is
      generated.
- [ ] AC-2: Given that module also declaring `:policy_item` (`AshActorTest.PolicyItem`),
      `:post__tags` (`Aurora.Uix.Guides.Blog.Tag`) and `:policy_item__tags` (`AshActorTest.Tag`),
      two declared embedded-field resources whose schemas give the same module names, then the
      module compiles, both are `embedded?: true`, `auix_modules/0` holds no `:tag_*` name, and no
      `<Module>.Tag.Index` module is generated.
- [ ] AC-3: Given that module, with `field :description, readonly: true` on `:post__comment` and an
      `edit_layout :post__comment` placing only `:description`, then
      `auix_resource(:post__comment).fields.description.readonly` is `true` and the `:form` layout
      tree of `auix_configurations().post__comment` places the one field `:description`.
- [ ] AC-4 (error path, guard kept): two ordinary resources on one schema still fail compilation
      with the unchanged message `module name :product_form_component is taken more than once`
      (mechanical — no red test; verified by the existing test
      `test/cases/create_ui_validation_test.exs` "two resources on one schema need their own module
      names" passing unmodified)
- [ ] AC-5: the two moduledoc lines read as prescribed in Modules & components 2 and 3
      (mechanical — no red test; verified by
      `grep -rn 'created for an embedded field' lib/` returning nothing and
      `grep -c 'named for an embedded field' lib/aurora_uix/layout/create_ui.ex lib/aurora_uix/resource.ex`
      returning `1` for each file)

##### Test ports
- Compile-time ports, no route: `auix_resource/1`, `auix_modules/0`, `auix_configurations/0` and
  `Code.ensure_loaded?/1` on the module that `compiled_ui/1` of
  `test/cases/create_ui_validation_test.exs` returns.
- Load guarantee for AC-3: the parent form renders an embedded field from that configuration.
  `lib/aurora_uix/templates/basic/renderers/embeds_one_renderer.ex` `render/1` reads it with
  `BasicHelpers.get_layout(assigns, embed_resource_name, :form)`.

##### Test amendment

`test/cases/create_ui_validation_test.exs`, test "an embedded resource generates no modules".
Replace the whole test with the text below. The test keeps its name, its `:user` declaration and its
six `Profile` / `Email` / `auix_configurations` assertions. `compiled_ui/1` and the `Node` alias are
already in the file. Every schema it names is an existing fixture:
`lib/aurora_uix/guides/blog/post.ex` (attributes `comment` and `tags`),
`lib/aurora_uix/guides/blog/comment.ex`, `lib/aurora_uix/guides/blog/tag.ex`,
`test/support/ash_actor/policy_item.ex` (attribute `tags`) and `test/support/ash_actor/tag.ex`.

```elixir
  test "an embedded resource generates no modules" do
    mod =
      compiled_ui("""
        auix_resource_metadata :user,
          context: Aurora.Uix.Guides.Accounts,
          schema: Aurora.Uix.Guides.Accounts.User

        auix_resource_metadata :post, ash_resource: Aurora.Uix.Guides.Blog.Post
        auix_resource_metadata :policy_item, ash_resource: AshActorTest.PolicyItem

        auix_resource_metadata :post__comment do
          ash_resource Aurora.Uix.Guides.Blog.Comment
          field :description, readonly: true
        end

        auix_resource_metadata :post__tags, ash_resource: Aurora.Uix.Guides.Blog.Tag
        auix_resource_metadata :policy_item__tags, ash_resource: AshActorTest.Tag

        auix_create_ui do
          edit_layout :post__comment do
            stacked [:description]
          end
        end
      """)

    assert mod.auix_modules() |> Map.keys() |> Enum.sort() == [
             :policy_item_form_component,
             :policy_item_index,
             :policy_item_index_component,
             :policy_item_show_component,
             :post_form_component,
             :post_index,
             :post_index_component,
             :post_show_component,
             :product_form_component,
             :product_index,
             :product_index_component,
             :product_show_component,
             :user_form_component,
             :user_index,
             :user_index_component,
             :user_show_component
           ]

    refute mod |> Module.concat(Profile.Index) |> Code.ensure_loaded?()
    refute mod |> Module.concat(Profile.FormComponent) |> Code.ensure_loaded?()
    refute mod |> Module.concat(Profile.ShowComponent) |> Code.ensure_loaded?()
    refute mod |> Module.concat(Email.Index) |> Code.ensure_loaded?()
    assert Map.has_key?(mod.auix_configurations(), :user__profile)
    assert Map.has_key?(mod.auix_configurations(), :user__emails)

    refute mod |> Module.concat(Comment.Index) |> Code.ensure_loaded?()
    refute mod |> Module.concat(Comment.FormComponent) |> Code.ensure_loaded?()
    refute mod |> Module.concat(Comment.ShowComponent) |> Code.ensure_loaded?()
    refute mod |> Module.concat(Tag.Index) |> Code.ensure_loaded?()

    for name <- [:post__comment, :post__tags, :policy_item__tags] do
      assert mod.auix_resource(name).embedded?
    end

    assert mod.auix_resource(:post__comment).fields.description.readonly

    assert [%Node.Stacked{children: [%Node.Field{key: :description}]}] =
             mod.auix_configurations().post__comment.layout_trees.form.children
  end
```

Red state on `main`: `compiled_ui/1` raises `Spark.Error.DslError` with
`module name :tag_form_component is taken more than once (:policy_item__tags, :post__tags)`, so the
test fails ahead of its first assertion. Run the amended test with `resource_metadata.ex` unedited:
it fails with that message.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | amend `test/cases/create_ui_validation_test.exs` "an embedded resource generates no modules" | the amended body of Test amendment; no data, no route | `test/cases/create_ui_validation_test.exs` | "an embedded resource generates no modules" | the sorted `auix_modules/0` keys hold no `:comment_*` name; the three `refute`s on `Comment.Index`, `Comment.FormComponent`, `Comment.ShowComponent`; `assert mod.auix_resource(:post__comment).embedded?` |
| AC-2 | amend the same test | the same body: `:post__tags` and `:policy_item__tags` declared | `test/cases/create_ui_validation_test.exs` | "an embedded resource generates no modules" | `compiled_ui/1` returns a module; the sorted `auix_modules/0` keys hold no `:tag_*` name; `refute` on `Tag.Index`; `assert mod.auix_resource(name).embedded?` for `:post__tags` and `:policy_item__tags` |
| AC-3 | amend the same test | the same body: `field :description, readonly: true` and `edit_layout :post__comment` | `test/cases/create_ui_validation_test.exs` | "an embedded resource generates no modules" | `assert mod.auix_resource(:post__comment).fields.description.readonly`; the match of `[%Node.Stacked{children: [%Node.Field{key: :description}]}]` on `mod.auix_configurations().post__comment.layout_trees.form.children` |

##### Modules & components
1. `Aurora.Uix.Layout.ResourceMetadata` at `lib/aurora_uix/layout/resource_metadata.ex` — modified,
   private function `add_embedded_resources/1` only. Each parser's `embedded_resource/2` prepends the
   resources it creates to the accumulator, so the first
   `length(with_embedded) - length(resources)` entries of `with_embedded` are the created ones.
   Replace the last two lines of the function body

   ```elixir
       {created, declared} = Enum.split(with_embedded, length(with_embedded) - length(resources))
       Enum.map(created, &struct(&1, %{embedded?: true})) ++ declared
   ```

   with

   ```elixir
       embedded_names =
         with_embedded
         |> Enum.take(length(with_embedded) - length(resources))
         |> Enum.map(& &1.name)

       Enum.map(with_embedded, fn resource ->
         if resource.name in embedded_names,
           do: struct(resource, %{embedded?: true}),
           else: resource
       end)
   ```

   The `@spec` and the list order are unchanged. `resolve_resources/2` still ends in `Map.new/1`,
   where the declared resource replaces the created one of the same name; both now carry
   `embedded?: true`.

2. `Aurora.Uix.Layout.CreateUI` at `lib/aurora_uix/layout/create_ui.ex` — modified, `@moduledoc`
   `## Key Constraints` only. Replace the line

   ```
     - A resource created for an embedded field generates no modules.
   ```

   with

   ```
     - A resource named for an embedded field (`<parent>__<field>`) generates no modules, whether
       the library creates it or the module declares it.
   ```

   No function of this module is edited. Its consumers of the flag stay as they are:
   `target?/1` (through it `targets/2`, `module_names/5`, `validate_index_lives/4` and
   `used_component/5`) and the clause of `build_resource_layouts/3` that returns `[]` for
   `resource_config.embedded?`. `build_configurations/5` does not read the flag: it builds the
   layout trees and keeps the field options of an embedded resource, and the embeds renderers read
   them through `BasicHelpers.get_layout/3`
   (`lib/aurora_uix/templates/basic/renderers/embeds_one_renderer.ex` `render/1`).

3. `Aurora.Uix.Resource` at `lib/aurora_uix/resource.ex` — modified, `@moduledoc` only. Replace the
   line

   ```
     - `embedded?` (`boolean`) - `true` for a resource the library created for an embedded field.
   ```

   with

   ```
     - `embedded?` (`boolean`) - `true` for a resource named for an embedded field
       (`<parent>__<field>`), created by the library or declared.
   ```

4. Contract change — the value of `Resource.embedded?` for a declared embedded-field resource
   changes from `false` to `true`. No `@spec` changes. Callers and their new handling:

   | Site | Handling |
   |---|---|
   | `create_ui.ex` `target?/1` | no edit; a declared embedded-field resource is no longer a target |
   | `create_ui.ex` `build_resource_layouts/3` | no edit; returns `[]` for it |
   | `lib/aurora_uix_web/guides/ash_overview.ex` (`:post__comment` declared) | no edit; the module stops generating `Aurora.UixWeb.Guides.AshOverview.Comment.*`. `rg -n "AshOverview\.Comment" lib test guides` returns nothing, and `lib/aurora_uix_web/routes.ex` routes only `Post`, `Author`, `Category` and `Tag` |
   | `lib/aurora_uix_web/guides/overview.ex` (`:product__product_barcode`) and `ash_overview.ex` (`:author__author_profile`) | no edit; unaffected: `product_barcode` and `author_profile` are associations, so the library creates no resource with those names |

5. Components: none new, none extended.
6. Theme: none.
7. `dt/1` strings: none.

##### Green tests
1. The amended test passes as prescribed, and the other tests of its file pass with no edit
   (code-issue runs these, targeted): `mix test test/cases/create_ui_validation_test.exs`
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-1:end -->

---

### Out of Scope
- Upgrade notes and workaround notes: 0.2.1-rc.1 is not released, so no published version has the
  problem. No file gains a migration note, and the CHANGELOG gains no entry.
- `ctx` coverage of a declared embedded-field resource: #557, together with declaring one without
  `context:` and CRUD functions. This issue declares no `ctx` embedded-field resource in a test.
  The `ctx` declaration and assertions of the amended test (`:user`, `Profile`, `Email`,
  `:user__profile`, `:user__emails`) stay as they are.
- New tests, test files, support fixtures and routes: none. One existing test is amended.
- A schema with two embedded fields of one embedded resource: no fixture has one, and none is added.
  The amended test reaches the same duplicate-name error on `main` with two existing embedded
  resources named `Tag`.
- A LiveView assertion on the parent form: on `main` the form already renders the declared options
  and layout of one declared embedded-field resource, so no such assertion is red.
- Two ordinary resources on one schema: the duplicate-name compile error and its message stay.
- The errors an embedded resource raises for `use:` and `index_live` keep their text; no
  documentation describes them.
- Parser sections: neither parser changes. Each already returns the embedded-field resources from
  `embedded_resource/2`.
<!-- enriched-spec:end -->
