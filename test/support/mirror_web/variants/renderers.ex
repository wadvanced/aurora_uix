defmodule Aurora.UixWeb.Test.Mirror.Variants.Renderers do
  @moduledoc """
  The `renderers` views variant: custom field renderers, a column renderer, an inline field
  option and a field the library cannot edit.

  ## Key Features

  - `reference` has a generic renderer; `name` has an index, an edit and a show renderer
  - The `description` column has an index renderer threaded through `index_columns`
  - `quantity_initial` is read-only through an inline field option
  - `labels` is declared `:unimplemented`; `deleted` keeps the default checkbox renderer

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.Renderers` and
    `Aurora.UixWeb.Test.MirrorCtx.Renderers`
  """

  use Phoenix.Component

  alias Aurora.UixWeb.Test.Mirror.Variants.Renderers

  @doc """
  Declares the variant's resources and UI in the caller.

  ## Parameters
  - `opts` (keyword()) - `backend: :ash | :ctx`.

  ## Returns
  Macro.t() - The quoted variant.
  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts) do
    quote do
      use Aurora.UixWeb.Test.Mirror, unquote(opts)

      mirror_resource :product do
        field(:reference, renderer: &Renderers.renderer/1)

        field(:name,
          index_renderer: &Renderers.index_marker/1,
          edit_renderer: &Renderers.edit_marker/1,
          show_renderer: &Renderers.show_marker/1
        )

        field(:deleted, renderer: :default_checkbox)
        field(:labels, html_type: :unimplemented)
      end

      auix_create_ui do
        index_columns(:product,
          reference: [label: "ZZZ_CustomRef"],
          name: [],
          description: [index_renderer: &Renderers.index_cols_marker/1],
          labels: [],
          inactive: []
        )

        edit_layout :product do
          inline([:reference, :name, {:quantity_initial, [readonly: true]}])
          stacked([:inactive, :deleted, :labels])
        end

        show_layout :product do
          stacked([:reference, :name, :inactive, :deleted, :labels])
        end
      end
    end
  end

  @doc false
  @spec renderer(map()) :: Phoenix.LiveView.Rendered.t()
  def renderer(%{auix: %{layout_type: :form}} = assigns) do
    ~H"""
    <span class="auix-generic-renderer">GENERIC:{@auix.form[@field.key].value}</span>
    """
  end

  def renderer(assigns) do
    ~H"""
    <span class="auix-generic-renderer">GENERIC:{Map.get(@auix.entity || %{}, @field.key)}</span>
    """
  end

  @doc false
  @spec index_marker(map()) :: Phoenix.LiveView.Rendered.t()
  def index_marker(assigns) do
    ~H"""
    <span class="auix-index-marker">IDX:{Map.get(@entity, @field.key)}</span>
    """
  end

  @doc false
  @spec edit_marker(map()) :: Phoenix.LiveView.Rendered.t()
  def edit_marker(assigns) do
    ~H"""
    <span class="auix-edit-marker">EDIT:{@auix.form[@field.key].value}</span>
    """
  end

  @doc false
  @spec show_marker(map()) :: Phoenix.LiveView.Rendered.t()
  def show_marker(assigns) do
    ~H"""
    <span class="auix-show-marker">SHOW:{Map.get(@auix.entity || %{}, @field.key)}</span>
    """
  end

  @doc false
  @spec index_cols_marker(map()) :: Phoenix.LiveView.Rendered.t()
  def index_cols_marker(assigns) do
    ~H"""
    <span class="auix-index-cols-marker">COL:{Map.get(@entity, @field.key)}</span>
    """
  end
end
