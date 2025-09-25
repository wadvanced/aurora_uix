# Changelog for v0.x

## v0.1.0

Requires Elixir v1.17+
Compatible with Ecto 3.2+
Compatible with Phoenix v1.7+
Compatible with Phoenix LiveView v1.0+

### Features

- **Resource Metadata**
  - `auix_resource_metadata/3` — Declarative resource and field configuration with field-level options and association support.

- **Layout System**
  - `edit_layout/3`, `show_layout/3`, `index_columns/3` — Macros for defining form, show, and index layouts.
  - Sub-layouts: `group/3`, `inline/2`, `stacked/2`, `sections/3`, and `section/3` for flexible UI composition.

- **Compile-Time UI Generation**
  - `use Aurora.Uix` — Generates LiveView modules and templates at compile time for index, form, and show views.

- **Extensibility**
  - Support for custom templates, field renderers, and layout containers.
  - Integrated i18n support via configurable Gettext backend.

- **Development**
  - Minimal runtime overhead due to compile-time generation.
  - Designed for extensibility and customization.
