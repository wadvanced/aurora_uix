defmodule Aurora.Uix.Renderers do
  @moduledoc """
  Resolves a field's renderer to the arity-1 function to call for a given layout type.

  This is the single, layout-type-aware entry point used by both the index and the
  field renderers. Given a field and the layout type, it applies the slot precedence
  and always returns a function `(assigns) -> Phoenix.LiveView.Rendered.t()`:

  - `:index` → `index_renderer` → default (index is independent — no `renderer` fallback)
  - `:form`  → `edit_renderer` → `renderer` → default
  - `:show`  → `show_renderer` → `renderer` → default

  Each slot value is a function *or* a predefined-renderer atom (resolved to its
  `&render/1` via the catalog). An unknown atom or an empty slot falls through to the
  default. The catalog is `Aurora.Uix.Renderers.BuiltIn` merged with the host registrar
  configured under `config :aurora_uix, :renderers` (host keys win). Resolution happens
  at call time via `Application.get_env/2`, mirroring the component override mechanism —
  no recompile is needed when the host registrar changes.
  """

  alias Aurora.Uix.Renderers.BuiltIn

  @typedoc "An arity-1 renderer function."
  @type render_fun :: (map() -> Phoenix.LiveView.Rendered.t())

  @doc """
  Returns the render function to call for `field` in the given layout type, applying the
  slot precedence. Always returns a function (the default renderer when no slot matches).
  """
  @spec resolve(map(), Aurora.Uix.Renderer.layout_type()) :: render_fun()
  def resolve(field, :index), do: pick(field.index_renderer) || default_fn()
  def resolve(field, :form), do: pick(field.edit_renderer) || pick(field.renderer) || default_fn()
  def resolve(field, :show), do: pick(field.show_renderer) || pick(field.renderer) || default_fn()

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

  # PRIVATE

  # A slot value → a render function, or nil so the precedence chain continues.
  @spec pick(render_fun() | atom() | nil) :: render_fun() | nil
  defp pick(fun) when is_function(fun, 1), do: fun
  defp pick(name) when is_atom(name) and not is_nil(name), do: Map.get(all(), name)
  defp pick(_other), do: nil

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
