defmodule Aurora.Uix.Renderer do
  @moduledoc """
  Behaviour for predefined field renderers selectable by a single atom.

  A renderer is **one arity-1 `render/1` function**. It receives the LiveView
  `assigns` and decides what to draw by pattern-matching `@auix.layout_type` — one of
  `:index`, `:show` or `:form`. It defines a clause per layout type it supports; for a
  layout type where the field's default rendering is adequate it delegates explicitly
  (`Aurora.Uix.Renderers.default/1`); a layout type it neither handles nor delegates
  simply crashes — a misplaced renderer is a bug, surfaced loudly.

  A field selects a renderer by atom name in any of its renderer slots:

  ```elixir
  field :active, renderer: :toggle_switch
  field :stock, index_renderer: :progress_bar
  ```

  The atom is resolved to its `render/1` function through `Aurora.Uix.Renderers`, which
  applies a per-layout-type slot precedence (see that module). Built-in renderers are
  listed by `Aurora.Uix.Renderers.BuiltIn`; host applications add their own via a
  registrar module (see `Aurora.Uix.RendererRegistrar`).

  ## Reading the field value

  The value lives in a different assign per layout type; use the helpers:

  | `@auix.layout_type` | Value source | Helper |
  |---------------------|--------------|--------|
  | `:index` | `@entity[@field.key]` | `display_value/1` |
  | `:show` | `@auix.entity[@field.key]` | `display_value/1` |
  | `:form` | `@auix.form[@field.key]` | `form_field/1` (bind) / `display_value/1` (value) |

  ## Writing a renderer

  `use Aurora.Uix.Renderer` injects the behaviour, the Aurora UIX core components,
  gettext, and the value helpers. Define a `render/1` clause per layout type you
  support:

  ```elixir
  defmodule MyApp.Renderers.Uppercase do
    use Aurora.Uix.Renderer

    @impl true
    def render(%{auix: %{layout_type: lt}} = assigns) when lt in [:index, :show] do
      assigns = assign(assigns, :value, display_value(assigns))

      ~H\"\"\"
      <span class="my-upper">{String.upcase(to_string(@value || ""))}</span>
      \"\"\"
    end

    # Editing is not special for this renderer — fall back to the default input.
    @impl true
    def render(%{auix: %{layout_type: :form}} = assigns),
      do: Aurora.Uix.Renderers.default(assigns)
  end
  ```
  """

  alias Phoenix.LiveView.Rendered

  @type layout_type :: :index | :show | :form

  @doc """
  Renders the field for the current layout type (`@auix.layout_type`).

  Define one clause per layout type the renderer supports; delegate to
  `Aurora.Uix.Renderers.default/1` where the default rendering is adequate.
  """
  @callback render(assigns :: map()) :: Rendered.t()

  @doc """
  Reads the field's display value for the current layout type: `@entity[key]` in
  `:index`, `@auix.entity[key]` in `:show`, and `@auix.form[key].value` in `:form`.
  """
  @spec display_value(map()) :: term()
  def display_value(%{auix: %{layout_type: :form}} = assigns), do: form_field(assigns).value

  def display_value(%{auix: %{layout_type: :show}, field: %{key: key}} = assigns),
    do: Map.get(assigns.auix.entity || %{}, key)

  def display_value(%{field: %{key: key}} = assigns), do: Map.get(assigns.entity || %{}, key)

  @doc """
  Returns the `Phoenix.HTML.FormField` for the field in the `:form` layout, suitable
  for binding to `<.input field={...} />`.
  """
  @spec form_field(map()) :: Phoenix.HTML.FormField.t() | nil
  def form_field(%{auix: %{form: form}, field: %{key: key}}), do: form[key]

  @doc false
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(_opts) do
    quote do
      @behaviour Aurora.Uix.Renderer

      use Aurora.Uix.CoreComponentsImporter
      use Aurora.Uix.GettextResolver

      import Aurora.Uix.Renderer, only: [display_value: 1, form_field: 1]
    end
  end
end
