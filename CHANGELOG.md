# Changelog for Aurora UIX

## [unreleased]
- Process by primitives

```elixir
# Option 1: Groups and sections are shown with very similar syntax
# Sections are enclose within a parent curly brackets, and contains only tuples
# Groups are just a tuple
[
  [:reference, :description], # <- Inline
  [:quantity, :price],
  {{"Section 1", [:valid, :invalid]}, {"Section 2", [:state]}}, # <- Sections
  {"Text" => [:one, :two]} # <- Groups
]

# Option 2: Easier to parse
[
  [:reference, :description], # <- Inline
  [:quantity, :price],
  {{"Section 1", [:valid, :invalid]}, {"Section 2", [:state]}}, # <- Sections
  %{"Text" => [:one, :two]} # <- Groups?
]
```

- Compatibility with Ash framework?

## [0.1.1] unreleased

### Added

- Show component instead of view 
- Edit / Show navigation buttons (previous, next)


## [0.1.0] - 2024-12-11

**Initial Release** - Aurora UIX 0.1.0 is the first stable release, providing a complete low-code CRUD UI generation framework for Elixir's Phoenix LiveView.

Requires:
- Elixir `1.17+`
- Phoenix `1.7+`
- Phoenix LiveView `1.0+`
- Ecto `3.2+`

### Added

#### Core Features
- **Resource Metadata System** (`auix_resource_metadata/3`)
  - Declarative resource and field configuration
  - Field-level customization: labels, placeholders, validation rules
  - Association support: `belongs_to`, `has_many`, `embeds_one`, `embeds_many`
  - Field attributes: type, precision, scale, required, readonly, hidden, disabled
  - Per-field HTML type overrides and custom rendering options

- **Layout System**
  - Layout macros: `edit_layout/3`, `show_layout/3`, `index_columns/3`
  - Layout containers: `inline/2`, `stacked/2`, `group/3`, `sections/3`, `section/3`
  - Support for complex, nested layouts
  - Flexible field organization and UI composition

- **Compile-Time Code Generation**
  - `use Aurora.Uix` macro for automatic LiveView module generation
  - Generates index, show, and edit views
  - Template generation from layout definitions
  - Zero-runtime-overhead through compile-time processing

- **View Features**
  - **Index Views**: Pagination, sorting, filtering, selection, bulk actions
  - **Show Views**: Display with read-only fields, navigation
  - **Edit Views**: Form handling, validation, error display, real-time updates

- **Association Handling**
  - One-to-many inline tables with edit/delete/add actions
  - Embeds-many collections with dynamic entry management
  - Many-to-one select fields with related data loading

- **Action System**
  - Customizable actions for index, show, form, and association layouts
  - Action groups: header, footer, row, selected, filters
  - Support for add, insert, replace, remove action operations
  - Extensible action component system

#### UI & Theming
- **Built-in Templates**
  - Basic template with Phoenix components
  - Responsive, mobile-first design
  - Light and dark theme variants

- **Core Components**
  - Form inputs with validation feedback
  - Tables with responsive behavior
  - Modals for confirmations
  - Buttons with various styles
  - Navigation components
  - Icon support via Heroicons

#### Developer Experience
- **Internationalization (i18n)**
  - Configurable Gettext backend
  - Automatic translation of UI strings
  - Support for multiple languages

- **Extensibility**
  - Custom template support via `Aurora.Uix.Template` behaviour
  - Customizable core components
  - Field renderer overrides
  - Layout container customization
  - Theme customization

- **Documentation**
  - Comprehensive guides: Overview, Getting Started, Core Concepts
  - Advanced usage documentation
  - Troubleshooting guide
  - Real-world examples

#### Infrastructure
- **Development Tools**
  - Stylesheet generator task (`mix auix.gen.stylesheet`)
  - Icon asset generator task (`mix auix.gen.icons`)
  - Development server with hot reload

- **Testing**
  - UICase test helper
  - WebCase test helper
  - Fixtures and test utilities

#### API Highlights
- **Metadata Module Functions**
  - `auix_resources/0` - Retrieve all configured resources
  - `auix_resource/1` - Get specific resource metadata
  - Metadata export for separation of concerns

- **Template API**
  - Template behavior with required callbacks
  - Module name generation helpers
  - Field omission support

- **Action API**
  - `Aurora.Uix.Action` - Action creation and management
  - `Aurora.Uix.Templates.Basic.Actions` - Action manipulation helpers
  - Helper functions: `add_auix_action`, `insert_auix_action`, `replace_auix_action`, `remove_auix_action`

### Known Limitations

- Templates currently support compile-time generation only (no dynamic template creation at runtime)
- Limited to Ecto-based schemas (other data sources require custom integration)
- CSS themes are basic and designed for light customization
- Some advanced Phoenix features (plugs, channels) require manual setup

### Fixed

- N/A (initial release)

### Security

- Form validations run both client-side and server-side
- CSRF protection via Phoenix's standard mechanisms
- No sensitive data logged or exposed in templates

---

## Future Roadmap

**Future releases may include:**
- Additional rendering components and theme options
- Simplified template creation with better hooks for customization
- Enhanced theme adoption and customization
- Page navigation from within show/edit views
- Query builder integration for advanced filtering
- Performance optimizations for large datasets
- GraphQL integration support
