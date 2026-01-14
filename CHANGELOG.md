# Changelog for Aurora UIX

## [0.1.2] - 2026-01-14

**Record Navigation** - Now users can navigate back and forth while editing or viewing records.

Requires:
- Elixir `1.17+`
- Phoenix `1.7+`
- Phoenix LiveView `1.0+`
- Ecto `3.2+`


### Added

- Record navigation feature for show and edit views that added
  navigation controls to move among records without returning to index
- Option to disable record navigation when needed


### Changed

- Updated dependencies to latest versions


### Fixed

- Navigation issues by implementing fallback URI handling
- Section switching when in show record mode


## [0.1.1] - 2025-01-07

**Show Component Refactor** - In this release, the show live view is no longer generated. Instead, a show component 
(LiveComponent) is now used within the Index LiveView. This is a preparatory step towards implementing record 
navigation in show and edit modals.

Requires:
- Elixir `1.17+`
- Phoenix `1.7+`
- Phoenix LiveView `1.0+`
- Ecto `3.2+`


### Changed

- **Routing architecture**: Show and show_edit actions now route to `.Index` module instead of `.Show` module
  - `GET /path/:id/show` → `.Index` module with `:show` action (was `GET /path/:id` to `.Show` module)
  - `GET /path/:id/show-edit` → `.Index` module with `:show_edit` action (was `GET /path/:id/show/edit` to `.Show` module with `:edit` action)
- **Show implementation**: Replaced show LiveView module with ShowComponent (LiveComponent)
- **Handler behavior**: Show handler now uses `ShowComponentImpl` instead of `ShowImpl`


### Added

- `Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl` - New handler behavior for show LiveComponent
- `ShowComponent` generator for creating show LiveComponents
- Documentation updates reflecting new routing architecture


### Removed

- `ShowGenerator` - No longer generates standalone show LiveView modules
- `Aurora.Uix.Templates.Basic.Handlers.ShowImpl` - Replaced by `ShowComponentImpl`


### Breaking Changes

**If you are using Aurora UIX 0.1.0, review these potential breaking changes:**

1. **Manual Route Definitions**
   
   If you manually defined routes instead of using `auix_live_resources`, update them:
   
   ```elixir
   # OLD (0.1.0) - will break
   live "/:id", MyApp.Product.Show, :show
   live "/:id/show/edit", MyApp.Product.Show, :edit
   
   # NEW (0.1.1) - correct
   live "/:id/show", MyApp.Product.Index, :show
   live "/:id/show-edit", MyApp.Product.Index, :show_edit
   ```
   
   **Note**: If you used `auix_live_resources`, no changes needed - it generates correct routes automatically.

2. **Custom Show Handler Hooks**
   
   If you implemented a custom show handler using the old behavior:
   
   ```elixir
   # OLD (0.1.0) - will break
   defmodule MyApp.ProductShowHandler do
     use Aurora.Uix.Templates.Basic.Handlers.ShowImpl
     # ...custom implementation
   end
   ```
   
   Update to the new behavior:
   
   ```elixir
   # NEW (0.1.1) - correct
   defmodule MyApp.ProductShowHandler do
     use Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl
     # ...custom implementation
   end
   ```
   
   **Migration steps**:
   - Change `ShowImpl` to `ShowComponentImpl`
   - Update `@impl Phoenix.LiveView` to `@impl Phoenix.LiveComponent` where applicable
   - Replace `mount/3` with `update/2` if you override lifecycle callbacks
   - Handler hooks specified in layout DSL via `show_handler_module` option will continue to work

**Most users will not be affected** as these scenarios only apply if you:
- Manually defined routes (instead of using `auix_live_resources`)
- Created custom show handler implementations



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
- Query builder integration for advanced filtering
- Performance optimizations for large datasets
- GraphQL integration support
