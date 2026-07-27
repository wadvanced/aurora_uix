# Predefined Renderers

Aurora UIX lets a field supply its own rendering through the `renderer`,
`index_renderer`, `edit_renderer` and `show_renderer` options. Each accepts an arity-1
function **or** a **predefined renderer selected by a single atom** — a ready-made
widget for a common value shape:

```elixir
auix_resource_metadata :product, context: Inventory, schema: Product do
  field :active, renderer: :toggle_switch
  field :brand_color, renderer: :color
  field :status, index_renderer: :badge, show_renderer: :badge
  field :stock_level, renderer: :progress_bar, data: %{max: 100}
end
```

## How a renderer is chosen

A renderer is one arity-1 `render/1` function that reads `@auix.layout_type`
(`:index`, `:show` or `:form`) and pattern-matches to decide what to draw.
`Aurora.Uix.Renderers.resolve/2` picks which one to call, per layout type:

| Layout | Slot precedence |
|--------|-----------------|
| `:index` | `index_renderer` → default *(index is independent — no `renderer` fallback)* |
| `:form`  | `edit_renderer` → `renderer` → default |
| `:show`  | `show_renderer` → `renderer` → default |

So `renderer:` covers **show and form**; to render a widget in the **index** as well,
set `index_renderer:` too (e.g. `renderer: :badge, index_renderer: :badge`).

## Built-in catalog

A renderer defines a `render/1` clause only for the layout types it specialises. For a
layout type where the default rendering is adequate it delegates to the default (so the
field just gets its normal input).

| Atom | Value | index | show | form |
|------|-------|:-----:|:----:|:----:|
| `:toggle_switch` | boolean | pill | pill | toggle checkbox |
| `:color` | hex / rgb / named string | swatch | swatch | native colour picker |
| `:badge` | enum / status string | pill | pill | default input |
| `:progress_bar` | number (`data: %{max: n}`, default 100) | bar | bar | default input |
| `:url` | string | link | link | default input |
| `:image` | url / data-URL string | thumbnail | image | default input |
| `:rating` | number (`data: %{max: n}`, default 5) | stars | stars | interactive stars |
| `:canvas` | base64 / data-URL string | image | image | drawing / signature pad |

### The `:canvas` JS hook

`:canvas` uses the `AuixCanvas` hook shipped in `AuroraUix.Hooks`. Hosts that already
merge `AuroraUix.Hooks` into their `LiveSocket` (see the getting-started guide) need no
extra wiring. The pad writes its drawing into a hidden input bound to the field, so the
value is submitted with the form; a Clear button empties it. Size it per field with
`data: %{width: 400, height: 200}`.

## Writing your own renderer

`use Aurora.Uix.Renderer` injects the behaviour, the Aurora UIX components, gettext, and
the value helpers `display_value/1` (the field value for the current layout type) and
`form_field/1` (the `FormField` for `:form` binding). Define a `render/1` clause per
layout type; delegate to `Aurora.Uix.Renderers.default/1` where the default is adequate:

```elixir
defmodule MyApp.Renderers.Uppercase do
  use Aurora.Uix.Renderer

  @impl true
  def render(%{auix: %{layout_type: lt}} = assigns) when lt in [:index, :show] do
    assigns = assign(assigns, :value, display_value(assigns))

    ~H"""
    <span class="my-upper">{String.upcase(to_string(@value || ""))}</span>
    """
  end

  @impl true
  def render(%{auix: %{layout_type: :form}} = assigns),
    do: Aurora.Uix.Renderers.default(assigns)
end
```

A layout type the renderer neither handles nor delegates simply crashes — a misplaced
renderer is a bug, surfaced loudly.

## Registering your own renderers

Renderers are resolved through `Aurora.Uix.Renderers`, which merges the built-in catalog
(`Aurora.Uix.Renderers.BuiltIn`) with a **host registrar** you configure. Host entries
win on collision, so you can add new renderers or replace a built-in wholesale (the
reserved `:default` key even lets you replace the default rendering).

```elixir
# config/config.exs
config :aurora_uix, :renderers, MyApp.Renderers
```

Implement `Aurora.Uix.RendererRegistrar` — a single `renderers/0` returning a map of
`atom => &render/1`:

```elixir
defmodule MyApp.Renderers do
  @behaviour Aurora.Uix.RendererRegistrar

  @impl true
  def renderers do
    %{
      uppercase: &MyApp.Renderers.Uppercase.render/1,
      toggle_switch: &MyApp.Renderers.FancyToggle.render/1
    }
  end
end
```

Then use it like any built-in: `field :sku, renderer: :uppercase`. Resolution happens at
render time via `Application.get_env/2`, so changing the registrar does not require
recompiling the library.
