# Overriding Components

Aurora UIX ships with a full set of UI components used by its Basic template. Every
public component supports **runtime override**: your application can replace any component
with its own implementation without forking the library or writing a custom template.

## How it works

Each component module uses `Aurora.Uix.ComponentsResolver` to declare an Application
env key. At render time, if that key resolves to a module that exports the matching
function, the call is forwarded there. Otherwise the built-in default runs.

The override check happens at **runtime**, so you can configure different overrides per
environment (e.g., test vs. production) without recompiling the library.

## Partial overrides

Your override module only needs to define the specific components you want to replace.
Any function not exported by the override module falls back to the Aurora UIX default
automatically — you do not need to implement the full interface.

## Configuration

Add one or more of the following to your `config/config.exs` (or an environment-specific
config file):

```elixir
# Replace Phoenix-compatible base components (modal, input, button, etc.)
config :aurora_uix, :core_components, MyApp.MyCoreComponents

# Replace Aurora-specific collection and form components
config :aurora_uix, :basic_components, MyApp.MyComponents

# Replace filter input components
config :aurora_uix, :basic_filtering_components, MyApp.MyFilteringComponents

# Replace routing link components
config :aurora_uix, :basic_routing_components, MyApp.MyRoutingComponents
```

## Implementing an override module

Define a module with the same function names and arity (`/1`) as the defaults.
A minimal example that only replaces the `button` component:

```elixir
defmodule MyApp.MyCoreComponents do
  use Phoenix.Component

  # Only the functions you want to override are needed.
  # Aurora UIX falls back to its defaults for everything else.
  def button(assigns) do
    ~H"""
    <button type={@type} class={["my-custom-button", @class]} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end
end
```

```elixir
# config/config.exs
config :aurora_uix, :core_components, MyApp.MyCoreComponents
```

## Overridable components reference

The table below lists every overridable component, grouped by override key.

### `:core_components` — `Aurora.Uix.Templates.Basic.CoreComponents`

Phoenix-compatible base components, equivalent to a standard `core_components.ex`.

| Function | Description |
|---|---|
| `modal/1` | Modal dialog with focus trap and close button |
| `flash/1` | Single flash notice (info or error) |
| `flash_group/1` | Grouped flash notices including disconnected states |
| `simple_form/1` | Form wrapper with action slot |
| `button/1` | Submit/action button |
| `input/1` | Text, select, checkbox, textarea, and other input types with label and errors |
| `label/1` | Form label |
| `error/1` | Inline field error message |
| `header/1` | Page header with title, subtitle, and actions slots |
| `list/1` | Definition list (`<dl>`) for key/value display |
| `back/1` | Back navigation link with arrow icon |
| `icon/1` | Heroicon rendered as a CSS `<span>` |

### `:basic_components` — `Aurora.Uix.Templates.Basic.Components`

Aurora UIX-specific components for collection views and record navigation.

| Function | Description |
|---|---|
| `auix_simple_form/1` | Form wrapper used in index layout forms |
| `auix_items/1` | Responsive switcher: renders `auix_items_table` on desktop, `auix_items_card` on mobile |
| `auix_items_table/1` | Desktop table view for collections with sorting, filtering, and actions |
| `auix_items_card/1` | Mobile card view for collections with filtering and actions |
| `pages_selection/1` | Pagination bar with page numbers, ellipsis, and selected-item counts |
| `record_navigator_bar/1` | Previous/next record navigation shown on form and show views |

### `:basic_filtering_components` — `Aurora.Uix.Templates.Basic.Components.FilteringComponents`

| Function | Description |
|---|---|
| `filter_field/1` | Renders condition selector and from/to inputs for a filterable field; no-ops for non-filterable fields |

### `:basic_routing_components` — `Aurora.Uix.Templates.Basic.RoutingComponents`

| Function | Description |
|---|---|
| `auix_link/1` | Anchor tag that fires `auix_route_forward` for `navigate:` or `patch:` targets |
| `auix_link_back/1` | Anchor tag that fires `auix_route_back` (unstyled) |
| `auix_back/1` | Styled back link with a left-arrow icon that fires `auix_route_back` |

## LiveComponents

`Aurora.Uix.Templates.Basic.ConfirmButton` and
`Aurora.Uix.Templates.Basic.EmbedsManyComponent` are Phoenix LiveComponents and are
**not overridable** through this mechanism. To customise their behaviour, define custom
actions using `Aurora.Uix.Templates.Basic.Actions` and supply your own LiveComponent
module.
