# Customizing & Extending Aurora UIX

Aurora UIX generates complete CRUD UIs out of the box — this hub catalogs every mechanism for making that generated UI **look and behave like your application**. Each section gives you just enough to recognize the right tool; depth lives in the linked guides.

## At a glance

| I want to… | Mechanism | Guide |
|---|---|---|
| Change colors, spacing, fonts | `--auix-*` variable overrides | [Styling](styling.md) |
| Follow my design system's theme (daisyUI, Material, …) | Style bridge | [Writing a Style Bridge](writing_a_style_bridge.md) |
| Ship a reusable, switchable theme | Registered theme module | [Theming](theming.md) |
| Replace a button/input/modal implementation | Runtime component override | [Overriding Components](overriding_components.md) |
| Render one field differently | Field `renderer:` option | [Resource Metadata](../core/resource_metadata.md#custom-field-types-and-rendering) |
| Add/remove/replace action buttons | Action operations | [Custom Actions](custom_actions.md) |
| Hook into mount/save/events | Handler modules (`auix_*` callbacks) | [LiveView Integration](../core/liveview.md#customizing-behavior) |
| Replace the whole generation pipeline | Custom templates / backends | [Advanced Usage](../advanced/advanced_usage.md) |

## 1. Theming & Styling

### 1.1 CSS variable overrides

**What it is:** every generated component is styled exclusively through `--auix-*` CSS custom properties, organized in cascade layers (`auix.baseline → auix.variables → auix.bridge → auix.rules`).
**When to use it:** quick visual alignment — colors, radii, spacing, fonts — without touching any library file.

```css
@layer auix.bridge {
  :root, :host {
    --auix-border-radius-default: 0.75rem;
    --auix-color-focus-ring: #7C3AED;
  }
}
```

→ **See:** [Styling Aurora UIX in a Host Application](styling.md)

### 1.2 Custom theme modules

**What it is:** themes are Elixir modules (`use Aurora.Uix.Templates.Theme`) that emit CSS rules via pattern-matched `rule/1` functions and compose by delegation.
**When to use it:** you want a named, switchable theme (light/dark variants, brand palettes) rather than ad-hoc overrides.

```elixir
defmodule MyApp.Themes.Ocean do
  use Aurora.Uix.Templates.Theme, theme_name: :ocean
  def rule(:root_colors), do: "..."             # your palette
  def rule(rule), do: BaseVariables.rule(rule)  # inherit the rest
end
# config/config.exs
config :aurora_uix, theme_name: :ocean
```

→ **See:** [Creating Custom Registered Themes](theming.md)

### 1.3 Style bridges

**What it is:** a plain CSS file mapping your design system's tokens (daisyUI, Bootstrap, your own `--ds-*` set) onto `--auix-*` variables, so Aurora UIX follows your theme automatically.
**When to use it:** your host app already has a token-based design system and you want dark mode / theme switching to "just work".

```css
@layer auix.bridge {
  :root, :host {
    --auix-color-bg-default: var(--ds-surface);
    --auix-color-focus-ring: var(--ds-primary);
  }
}
```

→ **See:** [Writing a Style Bridge](writing_a_style_bridge.md)

### 1.4 Semantic class overrides (escape hatch)

**What it is:** overriding `.auix-*` component class rules directly — a semi-public API that may change between releases.
**When to use it:** only when no variable can express the change (e.g. restructuring flex layout). Prefer 1.1–1.3.

→ **See:** [Styling → Escape hatch](styling.md#escape-hatch-semantic-class-overrides)

## 2. Replacing Components at Runtime

**What it is:** four Application-env slots let you swap component modules without forking the library: `:core_components`, `:basic_components`, `:basic_filtering_components`, `:basic_routing_components`. Overrides are **partial** — define only the functions you replace; everything else falls back to the defaults.
**When to use it:** the markup of a specific component (button, input, modal, table…) must change, not just its styling.

```elixir
# config/config.exs
config :aurora_uix, :core_components, MyApp.MyCoreComponents

defmodule MyApp.MyCoreComponents do
  use Phoenix.Component
  def button(assigns), do: ~H"<button class=\"my-button\" {@rest}>{render_slot(@inner_block)}</button>"
end
```

→ **See:** [Overriding Components](overriding_components.md)

## 3. Custom Field Rendering

**What it is:** per-field control over how a value is rendered.
**When to use it:** one field needs special display (avatar, badge, computed format) while the rest of the UI stays generated.

```elixir
auix_resource_metadata :product, schema: MyApp.Product do
  field :avatar, html_type: :image, renderer: &MyAppWeb.Helpers.render_avatar/1
end
```

Three places to attach it:

- **Resource metadata** (applies everywhere the field appears) → [Resource Metadata](../core/resource_metadata.md#custom-field-types-and-rendering)
- **Layout DSL field options** (per-layout: `name: [renderer: ...]`) → [Layouts → Field-Level Options](../core/layouts.md#field-level-options)
- **Template-level renderers** (whole-view generation) → [Advanced Usage](../advanced/advanced_usage.md#how-templates-work)

> #### Copyable inputs in custom renderers {: .warning}
> A custom `renderer:` function bypasses Aurora UIX's automatic field-id wiring. If your
> renderer uses `<.input copyable>`, two things are required:
>
> 1. Render through Aurora UIX core components (or `use Aurora.Uix.CoreComponentsImporter`)
>    so the `AuixCopyToClipboard` JS hook and markup are present.
> 2. Pass a valid, non-empty `id` to the input — without it the copy button silently does
>    nothing. A `Logger.warning` is logged at render time when `:copyable_show_warnings?`
>    is enabled (the default). See `Aurora.Uix.Templates.Basic.CoreComponents.input/1`.

## 4. Customizing Actions

**What it is:** actions are the buttons/links Aurora UIX renders in headers, footers, rows, and selection bars. Four operation verbs — `add_`, `insert_`, `replace_`, `remove_` — combined with a position suffix customize any group from layout options. (These are **UI actions**, not Ash resource actions.)
**When to use it:** add an Export button, swap the Edit icon, remove Delete from a read-only view, etc.

```elixir
index_columns :product, [:name, :price],
  add_header_action: {:export, &MyViews.export_action/1},
  remove_row_action: :default_row_show
```

Positions by context: index (row / header / footer / filters / selected / selected-all), form (header / footer), show (header / footer), one-to-many (row / header / footer), embeds-many (header / footer / new-entry / existing).

→ **See:** [Custom Actions](custom_actions.md)

## 5. Customizing LiveView Behavior

**What it is:** generated LiveViews delegate to handler modules. Provide your own (`handler_module`, `edit_handler_module`, `show_handler_module`) and override `auix_*` callbacks (`auix_mount`, `auix_handle_event`, `save_entity`, …), calling `super` for the default behavior. Phoenix callbacks remain overridable for advanced cases.
**When to use it:** custom save logic, authorization, extra assigns, custom events — anything behavioral rather than visual.

```elixir
defmodule MyApp.ProductFormHandler do
  use Aurora.Uix.Templates.Basic.Handlers.FormImpl

  @impl FormImpl
  def auix_handle_event("preview", _params, socket),
    do: {:noreply, assign(socket, :preview_mode, true)}

  def auix_handle_event(event, params, socket), do: super(event, params, socket)
end
```

→ **See:** [LiveView Integration → Customizing Behavior](../core/liveview.md#customizing-behavior)

## 6. Field & Resource Options Reference

The most-used field options, all configured in `auix_resource_metadata` (some also accepted inline in layouts):

| Option | Effect | Details |
|---|---|---|
| `readonly` | Rendered but not editable | [Field Properties](../core/resource_metadata.md#presentation-state) |
| `hidden` | Included but not visible | [Field Properties](../core/resource_metadata.md#presentation-state) |
| `disabled` | Appears disabled, no form interaction | [Field Properties](../core/resource_metadata.md#presentation-state) |
| `omitted` | Completely excluded from the UI | [Field Properties](../core/resource_metadata.md#presentation-state) |
| `label` | Display label (auto-generated otherwise) | [Display and Interaction](../core/resource_metadata.md#display-and-interaction) |
| `placeholder` | Input placeholder text | [Display and Interaction](../core/resource_metadata.md#display-and-interaction) |
| `renderer` | Custom rendering function/component | [Custom Field Types](../core/resource_metadata.md#custom-field-types-and-rendering) |
| `option_label` | Label source for select dropdowns (atom or function) | [Many-to-One](../core/resource_metadata.md#many-to-one-belongs_to) |
| `order_by` | Sort order for association options / lists | [Query Options](../core/resource_metadata.md#query-options-for-many-to-one) |
| `where` | Filter for association options / lists | [Query Options](../core/resource_metadata.md#query-options-for-many-to-one) |
| `data: %{upload: …}` | Turn a field into a managed LiveView upload | [Field Data](../core/resource_metadata.md#field-data) |

## 7. Deep Extension Points

**What it is:** the generation pipeline itself is replaceable — custom templates (implement `Aurora.Uix.Template`), custom layout trees, custom data backends (implement `Aurora.Uix.Integration.Crud`), and metadata/UI module separation for reuse across views.
**When to use it:** the built-in Basic template or the Ecto/Ash backends fundamentally don't fit (different markup architecture, GraphQL/REST data source, multi-representation metadata).

```elixir
config :aurora_uix, :template, MyApp.CustomTemplate
config :aurora_uix, :crud_integration_modules, custom: MyApp.CustomBackend.Crud
```

→ **See:** [Advanced Usage](../advanced/advanced_usage.md) — templates, macro conversions, metadata separation, custom backends

## 8. Internationalization

**What it is:** all generated labels and messages pass through a configurable Gettext backend — translating the UI is itself a customization point (custom domain, custom backend, POT auto-generation).
**When to use it:** translating the generated UI, or enforcing translation completeness in CI.

```elixir
config :aurora_uix, gettext_domain: "aurora_uix"
```

→ **See:** [Internationalization](../core/internationalization.md)

## Related guides

- [Styling Aurora UIX in a Host Application](styling.md)
- [Creating Custom Registered Themes](theming.md)
- [Writing a Style Bridge](writing_a_style_bridge.md)
- [Overriding Components](overriding_components.md)
- [Custom Actions](custom_actions.md)
- [Advanced Usage](../advanced/advanced_usage.md)
