# improve-issue · Schema sections

Read by `improve-issue` **Draft** when a Schema section is in scope. A Schema section changes the
**guide schemas** the library ships as demo host code and test fixtures — `lib/aurora_uix/guides/`
(`blog/` is Ash, `inventory/` is Ecto) — and the migrations behind them. A change confined to
`lib/aurora_uix/integration/`, `layout/` or `templates/` has no Schema section.

## Rules

1. One Schema section per guide backend whose persisted entities change — Ecto (`inventory/`,
   `accounts/`) or Ash (`blog/`), never both in one section.
2. A Schema section prescribes no documentation edit; `DOC-1` owns them all.
3. Attributes, associations and embeds match the metadata the section's dependants will assert.
   State each with its exact type and constraints.
4. Host-side write wiring lives here and only here: `cast_assoc` / `cast_embed` in an Ecto
   changeset, `argument` + `change manage_relationship(...)` in an Ash action. These are the only
   `cast_*` / `manage_relationship` calls the repository may carry; the library itself never
   builds a changeset.
5. Migrations:
   - Ecto: hand-written, `mix ecto.gen.migration <name>`, in `priv/repo/migrations/`.
   - Ash: `mix ash_postgres.generate_migrations --name <name>`; the migration **and** its
     `priv/resource_snapshots/` snapshot are committed.
   - A new foreign key carries an index; a one-to-one relationship carries a UNIQUE index.
6. `mix test` does not run migrations: the section's Green checks include `mix ecto.migrate`.
7. Fixture helpers in `test/support/helper.ex` that the section's dependants need are prescribed
   here, by exact function name and arity.
8. AC-1 and AC-2 of the template are present in every Schema section. Issue-specific ACs are
   numbered from AC-3.

## Template

```markdown
<!-- section:SCH-k:start -->
### SCH-k — Schema · <Ecto|Ash> · <guide schema group>
Depends on: <DOC-1 for the first Schema section; otherwise the sibling ids it follows>

#### Documentation references
<the guides § sections describing the demo schema>

#### Implementation details
##### Schemas
1. `Aurora.Uix.Guides.<Group>.<Schema>` at
   `lib/aurora_uix/guides/<group>/<schema>.ex` — new | modified
   - Fields:
     | Field | Type | Constraints |
     |---|---|---|
   - Associations / embeds: <destination + key names>
   - Changeset / action wiring: <`cast_assoc` / `cast_embed` / `manage_relationship`, exact lines>
2. Migration: <`mix ecto.gen.migration <name>` | `mix ash_postgres.generate_migrations --name <name>`
   + the snapshot file>
3. Fixtures: <`test/support/helper.ex` function/arity, new | modified>

##### Acceptance criteria
- [ ] AC-1: table and columns exist exactly as prescribed (mechanical — no red test; verified by
      `mix ecto.migrate` followed by <the `psql`/`mix run` check>)
- [ ] AC-2: `mix compile --warnings-as-errors` clean; `mix test` green; for Ash, the
      `priv/resource_snapshots/` snapshot is in the diff (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD`)

##### Green checks
1. `mix ecto.migrate`; `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:SCH-k:end -->
```
