# Aurora UIX Roadmap

This roadmap groups planned work into milestones, one per minor version, followed by ideas that are not
scheduled yet. It is not a commitment to dates: priorities follow community feedback, adoption and
real-world use cases.

## Current Status: v0.2.1


Aurora UIX v0.2.1 lets the index, form and show UIs be embedded as components in any LiveView, adds action icons and a card layout for the index list, refreshes the look of every theme and fixes a set of form, index and Ash backend bugs. It has three compile-time breaking changes; see the What's New guide.

**Recent Changes (v0.2.1)**:
- `IndexComponent`, `FormComponent` and `ShowComponent` for reusable components
- Action icons on default actions
- Card layout for the index list, with a header menu, tap-to-show and an icon sort menu
- Theme-driven menus and classes for the sort control and index cards
- Refreshed look in every theme and the Blue Graphite theme
- `resource:` on embedded fields and associations
- Fixes for Ash forms (field errors, embeds), Ash pagination and field order, and nested Ecto errors

---

## Milestones

Planned work is grouped by minor version. Each milestone has a theme; patch releases (0.2.2, 0.2.3, ...)
ship within their minor version's milestone. Issues are tracked in the
[GitHub milestones](https://github.com/wadvanced/aurora_uix/milestones). Several items are inspired by
[OpenXava](https://www.openxava.org/), the project that originally inspired Aurora UIX.

Scope and order inside a milestone can change; a feature moves to a later milestone rather than delay a
release.

### 0.2 - Remaining 0.2.x releases

**Theme**: additive, non-breaking improvements on the 0.2 DSL.

- Bug fixes and documentation alignment
  ([#646](https://github.com/wadvanced/aurora_uix/issues/646))
- `auix_save_entity` handler callback, with `save_entity` deprecated until 0.3
  ([#661](https://github.com/wadvanced/aurora_uix/issues/661))
- Real `href`s on index links, so open in new tab and copy link work
  ([#469](https://github.com/wadvanced/aurora_uix/issues/469))
- **Wizard** layout grouping with ordered steps, Back / Next and per-step validation
  ([#415](https://github.com/wadvanced/aurora_uix/issues/415))
- **Summary + detail** layout grouping ([#416](https://github.com/wadvanced/aurora_uix/issues/416))
- **Filter presets**: named one-click filters on the index
  ([#280](https://github.com/wadvanced/aurora_uix/issues/280))
- Layout shorthand with primitives:

  ```elixir
  # Lists are inline fields, a tuple of tuples holds sections and a map holds a group
  [
    [:reference, :description], # <- Inline
    [:quantity, :price],
    {{"Section 1", [:valid, :invalid]}, {"Section 2", [:state]}}, # <- Sections
    %{"Text" => [:one, :two]} # <- Groups
  ]
  ```

- An `AGENTS.md` guide for host applications, so AI coding assistants write correct Aurora UIX code

### 0.3 - Plugins and templates

**Theme**: make templates and extensions first-class. Breaking changes are allowed.

- Templates own their built-in renderer catalog; `Aurora.Uix.Renderers.BuiltIn` is removed
  ([#459](https://github.com/wadvanced/aurora_uix/issues/459))
- Removal of the APIs deprecated during 0.2.x (such as `save_entity`)
- Template scaffold generator (`mix auix.gen.template`)
- Template composition: inherit from a template and override only some parts (for example, how
  sections render)
- Complete documentation of the template callbacks
- A plugin API for packaging field types, renderers, themes and layout groupings, designed together with
  the 0.5 field types
- Custom component injection points in generated layouts
- Theme packaging, preview and testing utilities, generated theme documentation, a community theme
  registry

### 0.4 - Lists and data

**Theme**: the index becomes a working tool for the data it shows.

- **Totalizer lines**: totals and subtotals on index columns and one-to-many collections (sum, count,
  average), using Ash aggregates where they exist
- **Configurable columns**: users show, hide and reorder columns, and the choice is remembered
- **Export and import**: CSV and Excel export of the filtered list, Excel import, PDF reports
- **Editable collections**: spreadsheet-style inline row editing, with row actions on hover
- **Associations**: polymorphic associations, batch updates of related records, inline editing of
  associated records, association previews
- **Scale**: lazy-loading of nested associations, virtual scrolling for large lists, metadata caching
- Advanced filtering: saved filters, filter export and import, full-text search, visual query builder
- Query optimization and render profiling tools

### 0.5 - Rich fields and dashboards

**Theme**: new kinds of fields and views, shipped as plugins where possible.

- **Charts**: a chart view of the current index query (grouped or over time) and chart widgets
- **Dashboards**: pages of charts and key figures built from resource metadata
- **Maps**: a geographic field shown on a map, and a map view of the list
- **Photo gallery**: several images per record, built on file uploads
- **Discussion threads**: a comments field per record, updated live through PubSub
- Additional inputs: date and time pickers, rich text editor
- Advanced table features: sub-rows
- Modal and sidebar components with customizable triggers

### 0.6 - Workflows

**Theme**: applications with state and process.

- State machine integration (for example `AshStateMachine`), with actions per state
- Conditional field visibility based on the record's state
- Workflow follow-ups to the wizard: step indicators on show, conditional steps
- Approval workflows
- Audit trail generation

### 0.7 - AI assistant

**Theme**: natural-language access to the data behind the generated UI.

- An in-app chat that queries data, changes records and answers questions alongside the normal UI
- Ash backend through Ash AI; Ecto backend through a tool layer over the context functions
- Respects the same authorization as the UI (Ash policies, host-provided checks)

### 1.0 - Stable API

**Theme**: a stable, documented public API.

- DSL frozen; remaining deprecations removed
- The [version support policy](#version-support-policy) applies from this release

---

## Ideas Not Yet Scheduled

These have no milestone yet. They are scheduled when there is demand and a clear use case.

- **API and headless**: REST or JSON:API scaffolding from metadata, GraphQL through Absinthe, headless
  (unstyled) components, mobile app scaffolding
- **Integrations**: authentication and role-based access helpers, telemetry hooks, advanced Gettext
  features
- **Additional CSS frameworks**: Bootstrap or Bulma templates and themes
- **Hot reload** for template development
- **Exploratory**: metadata and layouts generated from natural language, a visual drag-and-drop layout
  builder, real-time collaborative editing, offline support, complete admin panels from schema
  definitions alone

---

## Release History

**Previous Release (v0.2.0)**:
- Resource metadata, layout, theme and layout option DSLs moved to Spark
- Reusable layouts (`auix_create_ui include:`)

**Earlier Release (v0.1.7)**:
- Card view sort control and `sort_disabled?` index option
- Attribute-based id selectors for ids starting with a digit

**Earlier Release (v0.1.6)**:
- Sortable index column headers
- Predefined field renderers (`:toggle_switch`, `:color`, `:badge`, `:progress_bar`, `:url`, `:rating`) and a `renderers:` map by HTML type
- Live updates across sessions through Phoenix PubSub (`Aurora.Uix.Events`)
- Unsaved-changes guard on the form modal
- `contains` filter condition for text fields
- Multi-value selects as checkbox groups; read-only scalar arrays
- Guide recipe for custom bulk actions on selected rows

**Earlier Release (v0.1.5)**:
- `has_one` and `many_to_many` association support (both backends)
- Runtime component override mechanism (`Aurora.Uix.ComponentsResolver`)
- Per-layout custom field renderers (`index_renderer`, `edit_renderer`, `show_renderer`)
- Ash calculations and aggregates auto-discovered and auto-loaded
- Copyable inputs (copy-to-clipboard for text/textarea fields)

**Earlier Release (v0.1.4)**:
- Improved Ash framework compatibility

**Earlier Release (v0.1.3)**:
- Ash Framework integration with full CRUD support
- Automatic adapter detection for Ash resources
- Support for Ash actions and changesets

**Earlier Release (v0.1.2)**:
- Record navigation feature with next/previous controls
- Option to disable record navigation when needed

**Earlier Release (v0.1.1)**:
- Show view now uses LiveComponent instead of standalone LiveView module
- Updated routing to handle show/edit actions through Index module
- Foundation for implementing record navigation in modals

**Initial Release (v0.1.0)**:
- Core low-code CRUD UI generation framework
- Metadata-driven configuration
- Compile-time code generation
- Extensible template system

---

## How to Contribute

Aurora UIX is open-source and welcomes contributions. If you're interested in working on any feature from this wishlist:

1. **Open an Issue**: Discuss your implementation approach
2. **Check for PRs**: Make sure no one is already working on it
3. **Follow Guidelines**: See CONTRIBUTING.md for development standards
4. **Start Small**: Tackle smaller features before complex ones

**Contribution priorities**:
- Community-requested features with active use cases
- Bug fixes and stability improvements
- Documentation improvements
- Performance enhancements

---

## Prioritization Process

Features will be prioritized based on:

1. **Community Demand**: Number and strength of feature requests
2. **Use Case Validation**: Real-world problems the feature solves
3. **Implementation Effort**: Estimated complexity and resource requirements
4. **Strategic Alignment**: Fit with Aurora UIX's core mission
5. **Ecosystem Impact**: Benefits to the broader Elixir/Phoenix community

---

## Feedback & Feature Requests

Have ideas or requests? We'd love to hear from you:

- **GitHub Issues**: For feature requests and discussions
- **GitHub Discussions**: For broader topic conversations
- **Email**: suggestions@wadvanced.com

Your feedback helps shape the future of Aurora UIX!

---

## Version Support Policy

- **v0.x**: Active development, breaking changes possible based on feedback
- **v1.x**: Stable API, backwards compatibility maintained where practical
- **Security fixes**: Applied to current and previous minor versions
- **Bug fixes**: Applied to current minor version, critical bugs to previous version

Thank you for using Aurora UIX! 🚀
