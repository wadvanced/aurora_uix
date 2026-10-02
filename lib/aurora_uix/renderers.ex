defmodule Aurora.Uix.Renderers do
  @moduledoc """
  Resolves a field's renderer to the arity-1 function to call for a given layout type.

  This is the single, layout-type-aware entry point used by both the index and the
  field renderers. Given a field, the layout type and the HTML-type tables, it applies the slot precedence
  and always returns a function `(assigns) -> Phoenix.LiveView.Rendered.t()`:

  - `:index` → `index_renderer` → HTML-type tables → default (index is independent — no `renderer` fallback)
  - `:form`  → `edit_renderer` → `renderer` → HTML-type tables → default
  - `:show`  → `show_renderer` → `renderer` → HTML-type tables → default

  The HTML-type tables are `html_type => renderer` maps declared with `renderers:` (see
  `resolve/3`), consulted highest level first, and closed by the application config
  `config :aurora_uix, :html_type_renderers`. Association, embed, upload and hidden fields
  skip them.

  Each slot value is a function *or* a predefined-renderer atom (resolved to its
  `&render/1` via the catalog). An unknown atom or an empty slot falls through to the
  default. The catalog is `Aurora.Uix.Renderers.BuiltIn` merged with the host registrar
  configured under `config :aurora_uix, :renderers` (host keys win). Resolution happens
  at call time via `Application.get_env/2`, mirroring the component override mechanism —
  no recompile is needed when the host registrar changes.
  """

  alias Aurora.Uix.Renderers.BuiltIn

  @table_exempt_types [
    :one_to_many_association,
    :many_to_one_association,
    :one_to_one_association,
    :many_to_many_association,
    :embeds_one,
    :embeds_many
  ]

  @typedoc "An arity-1 renderer function."
  @type render_fun :: (map() -> Phoenix.LiveView.Rendered.t())

  @doc """
  Returns the render function to call for `field` in the given layout type. Same as
  `resolve(field, layout_type, [])`: the application config is the only table consulted.
  """
  @spec resolve(map(), Aurora.Uix.Renderer.layout_type()) :: render_fun()
  def resolve(field, layout_type), do: resolve(field, layout_type, [])

  @doc """
  Returns the render function to call for `field` in the given layout type.

  Order: the field's slots for the layout type, then each map of `tables` in list order
  (highest precedence first), then the application config
  `config :aurora_uix, :html_type_renderers`, then the default renderer. A table is looked up
  by `field.html_type`; an entry that resolves to no renderer is skipped. Association, embed,
  upload and hidden fields skip every table. Always returns a function.
  """
  @spec resolve(map(), Aurora.Uix.Renderer.layout_type(), [map()]) :: render_fun()
  def resolve(field, layout_type, tables),
    do: slot(field, layout_type) || table_pick(field, tables) || default_fn()

  @doc """
  Renders `assigns` with the default renderer. Used by predefined renderers to delegate
  a layout type they do not specialise.
  """
  @spec default(map()) :: Phoenix.LiveView.Rendered.t()
  def default(assigns), do: default_fn().(assigns)

  @doc """
  Returns the merged catalog of renderer name atoms to render functions (built-ins
  overridden by any host entry with the same key).
  """
  @spec all() :: %{atom() => render_fun()}
  def all, do: Map.merge(BuiltIn.renderers(), host_renderers())

  @doc """
  Returns `table` when it is a map of `html_type => renderer`; raises `ArgumentError` naming
  `level` otherwise.
  """
  @spec validate_table!(binary(), term()) :: map()
  def validate_table!(_level, %{} = table), do: table

  def validate_table!(level, other),
    do:
      raise(
        ArgumentError,
        "#{level} expected a map of html_type => renderer, got: #{inspect(other)}"
      )

  # PRIVATE

  # A slot value → a render function, or nil so the precedence chain continues.
  @spec pick(render_fun() | atom() | nil) :: render_fun() | nil
  defp pick(fun) when is_function(fun, 1), do: fun
  defp pick(name) when is_atom(name) and not is_nil(name), do: Map.get(all(), name)
  defp pick(_other), do: nil

  @spec slot(map(), Aurora.Uix.Renderer.layout_type()) :: render_fun() | nil
  defp slot(field, :index), do: pick(field.index_renderer)
  defp slot(field, :form), do: pick(field.edit_renderer) || pick(field.renderer)
  defp slot(field, :show), do: pick(field.show_renderer) || pick(field.renderer)

  @spec table_pick(map(), [map()]) :: render_fun() | nil
  defp table_pick(field, tables) do
    if table_applies?(field) do
      tables
      |> Enum.concat([app_table()])
      |> Enum.find_value(&pick(Map.get(&1, field.html_type)))
    end
  end

  @spec table_applies?(map()) :: boolean()
  defp table_applies?(%{hidden: true}), do: false
  defp table_applies?(%{type: type}) when type in @table_exempt_types, do: false
  defp table_applies?(%{data: %{upload: upload}}) when is_map(upload), do: false
  defp table_applies?(_field), do: true

  @spec app_table() :: map()
  defp app_table do
    :aurora_uix
    |> Application.get_env(:html_type_renderers, %{})
    |> then(&validate_table!("config :aurora_uix, :html_type_renderers", &1))
  end

  @spec default_fn() :: render_fun()
  defp default_fn, do: Map.get(all(), :default)

  @spec host_renderers() :: %{atom() => render_fun()}
  defp host_renderers do
    case Application.get_env(:aurora_uix, :renderers) do
      registrar when is_atom(registrar) and not is_nil(registrar) ->
        if function_exported?(registrar, :renderers, 0), do: registrar.renderers(), else: %{}

      _other ->
        %{}
    end
  end
end
