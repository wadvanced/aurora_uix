# improve-issue · Parser sections

Read by `improve-issue` **Draft** when a Parser section is in scope. A Parser section changes what
one backend hands to everything downstream: `lib/aurora_uix/integration/<backend>/` (`ash` or
`ctx`) — `fields_parser`, `crud`, `query_parser`, `context_parser_defaults` — and the normalized
`%Aurora.Uix.Field{}` it produces.

## Rules

1. One Parser section per backend per capability. `ash` code lives only in
   `lib/aurora_uix/integration/ash/`, `ctx` code only in `.../integration/ctx/`. A feature is not
   complete until both parsers support it: a capability that spans backends is two sections
   (`PAR-1` for `ctx`, `PAR-2` for `ash`, sideways-independent), or `### Out of Scope` states why
   only one applies.
2. Subsection order is fixed, and is the TDD order: acceptance criteria → test ports → red
   tests → parser changes → normalized `%Field{}` shape → green tests.
3. Every test port carries its in and out shapes, and is marked `existing` (with its citation)
   or `new` (with its search evidence).
4. Clause order is stated. For each parser function touched, name the clause the new one goes
   before, and whether the function has a catch-all. Several `ash/fields_parser.ex` functions
   have none: a missing clause raises `FunctionClauseError` at blueprint-compile time, so the
   section states that the clause must exist at all.
5. A **new `%Field{}` type atom** makes the section carry `##### Type-atom audit`, extracted with
   `rg -n ':<sibling_atom>' lib/` (a sibling such as `:one_to_many_association`). One row per hit:
   `file.ex` + function/arity · verdict `add` or `do-NOT-add` · one-line justification. Every
   `add` row names the section that edits the site. Silent omission — a missing `filter_preloads/1`
   or `replace_related_field_data/2` clause — fails far from the change, so a hit with no row is a
   defect of the section.
6. The parser output for the change is asserted twice: in the backend's own parser test
   (`test/cases/integration/<backend>/fields_parser_test.exs`) and in the shared golden metadata
   (`test/cases/integration/fields_parser_validations_test.exs`). Name both files.
7. The library is transport-only for writes. A Parser section never builds a changeset;
   `cast_assoc` / `manage_relationship` belong to the Schema section.
8. At least three ACs, at least one of them an error path (an unregistered related resource, an
   unloaded association, an unsupported option surfacing loudly).
9. Parser tests are pure introspection — no database, no `Process.sleep/1`, no mocks.

## Template

```markdown
<!-- section:PAR-k:start -->
### PAR-k — Parser · <ash|ctx> · <capability>
Depends on: <ids>

#### Documentation references
<the guides § sections specifying this behaviour>

#### Implementation details
##### Acceptance criteria
- [ ] AC-1: Given <schema or resource>, when `<Backend>.FieldsParser.<function>/<arity>` parses
      it, then the `%Field{}` has `type: :<atom>`, `html_type: :<atom>`, `data: %{…}`

##### Test ports
- `Aurora.Uix.Integration.<Ash|Ctx>.FieldsParser.<function>/<arity>` ·
  in: <shape> · out: <`%Field{}` shape> · existing (`file.ex`, `fun/arity`) | new

##### Red tests (write first; each must fail before implementation)
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | amend \| add to \| new file | <schema declared in the test module> | test/cases/integration/<backend>/fields_parser_test.exs | "<name>" | `assert Validations.compare_maps(validations, parsed) == []` |

##### Parser changes
1. `lib/aurora_uix/integration/<backend>/<file>.ex` `<function>/<arity>` — new clause
   `<exact head>` placed before `<clause>`; catch-all: present | none
2. <the `data` map keys the clause fills>

##### Type-atom audit   (only when a new `%Field{}` type atom is introduced)
| Site | Verdict | Justification |
|---|---|---|
| `lib/aurora_uix/<path>.ex` `<function>/<arity>` | add (section <SEC-ID>) \| do-NOT-add | <why> |

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:PAR-k:end -->
```
