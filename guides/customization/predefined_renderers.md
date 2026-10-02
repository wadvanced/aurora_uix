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
`Aurora.Uix.Renderers.resolve/3` picks which one to call, per layout type:

| Layout | Slot precedence |
|--------|-----------------|
| `:index` | `index_renderer` → HTML-type tables → default *(index is independent — no `renderer` fallback)* |
| `:form`  | `edit_renderer` → `renderer` → HTML-type tables → default |
| `:show`  | `show_renderer` → `renderer` → HTML-type tables → default |

So `renderer:` covers **show and form**; to render a widget in the **index** as well,
set `index_renderer:` too (e.g. `renderer: :badge, index_renderer: :badge`).

When no slot names a renderer, the field's `html_type` is looked up in the HTML-type tables —
see [Renderers by HTML type](#renderers-by-html-type).

## Built-in catalog

A renderer defines a `render/1` clause only for the layout types it specialises. For a
layout type where the default rendering is adequate it delegates to the default (so the
field just gets its normal input).

| Atom | Value | index | show | form |
|------|-------|:-----:|:----:|:----:|
| `:toggle_switch` | boolean | switch | switch | toggle switch |
| `:color` | hex / rgb / named string | swatch | swatch | native colour picker |
| `:badge` | enum / status string | pill | pill | default input |
| `:progress_bar` | number (`data: %{max: n}`, default 100) | bar | bar | default input |
| `:url` | string | text | link | default input |
| `:rating` | number (`data: %{max: n}`, default 5) | stars | stars | interactive stars |

The catalog also holds one named default per common HTML type: `:default_checkbox`,
`:default_date`, `:default_datetime_local`, `:default_number`, `:default_select`,
`:default_text`, `:default_textarea` and `:default_time`. Each renders the field's default
rendering — the same as the reserved `:default` key, including a host override of it. Use one in
an HTML-type table to undo a lower level's entry for that type.

## Renderers by HTML type

A `renderers:` option maps an HTML type to a renderer, so every field of that type gets it
without a per-field slot. Keys are matched against the field's `html_type` (`:checkbox`,
`:text`, `:textarea`, `:number`, `:select`, `:date`, `:time`, `:"datetime-local"`, …), not its
Elixir type. Values are what a slot accepts: a renderer atom, or an arity-1 function.

```elixir
# config/config.exs — the whole application
config :aurora_uix, :html_type_renderers, %{checkbox: :toggle_switch}

defmodule MyAppWeb.UserUi do
  # every resource of this module
  use Aurora.Uix, renderers: %{checkbox: :toggle_switch}

  # one resource
  auix_resource_metadata :user,
    context: MyApp.Accounts,
    schema: MyApp.Accounts.User,
    renderers: %{textarea: :url, checkbox: :badge}

  # every layout this auix_create_ui generates, and one layout of it
  auix_create_ui renderers: %{checkbox: :default_checkbox} do
    index_columns :user, [:name, :active], renderers: %{checkbox: :toggle_switch}
  end
end
```

A table entry covers the index, show and form layouts alike. A renderer that has no clause for
one of them crashes there, as it does from a slot. `index_columns` sets the index table,
`edit_layout` the form table and `show_layout` the show table; with no `show_layout`, the show
layout reuses the `edit_layout` declaration, `renderers:` included.

Precedence, highest first:

| Level | Declared with |
|-------|---------------|
| Field slot | `renderer`, `index_renderer`, `edit_renderer`, `show_renderer` |
| Layout | `index_columns`, `edit_layout`, `show_layout` — `renderers:` |
| UI | `auix_create_ui renderers:` |
| Resource | `auix_resource_metadata renderers:` |
| Module | `use Aurora.Uix, renderers:` |
| Application | `config :aurora_uix, :html_type_renderers` |
| Default | the default rendering |

An entry whose atom names no registered renderer is skipped, and the next level down is
consulted. A `renderers:` value that is not a map raises `ArgumentError`: at compile time for
the module, resource, UI and layout levels, at render time for the application config.

Association, embed, upload and hidden fields ignore the tables and keep their own rendering;
give one of them a slot to change it. The index row-selection checkbox ignores them too.

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
