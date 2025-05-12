# Changelog for v0.x

## v0.1.0

Requires Elixir v1.17+
Compatible with Ecto 3.2+
Compatible with Phoenix v1.7+
Compatible with Phoenix LiveView v1.0+

### Features
* Resource Configuration
  - `auix_resource_config/3` - Define schema-based resource configurations with field customizations
  - `auix_register_resource/3` - Register resources for automatic CRUD function generation

* Layout System
  - `edit_layout/3` - Define editable form layouts
  - `show_layout/3` - Create read-only display layouts
  - `index_columns/3` - Configure resource list view columns

* Layout Components
  - `group/3` - Create visual field groupings with titles
  - `inline/2` - Arrange fields horizontally
  - `stacked/2` - Organize fields in vertical layouts
  - `sections/3` - Group content in tab-like structures

* UI Generation
  - Compile-time UI generation through `use Aurora.Uix.Web.Uix.CreateUI`
  - Dynamic template generation with HEEx support
  - Integrated i18n support via configurable Gettext backend

* Development Features
  - Minimal runtime overhead through compile-time generation
  - Extensible through custom parsing and rendering strategies
  - Automatic module generation for index, form, and show views
