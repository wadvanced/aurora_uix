defmodule Aurora.UixWeb.Test.Mirror.Variants.IndexActions do
  @moduledoc """
  The `index-actions` views variant: custom row, header, footer and selected actions, and action
  icons.

  ## Key Features

  - Declares a product index whose row, header, footer and filter actions are removed, replaced,
    added and inserted, with a bulk action on the selection
  - Declares a product locations index with a destructive and a plain added row action
  - Declares a suppliers index with replaced action icons

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.IndexActions` and
    `Aurora.UixWeb.Test.MirrorCtx.IndexActions`
  """

  use Aurora.Uix.CoreComponentsImporter

  import Aurora.Uix.Templates.Basic.RoutingComponents

  alias Aurora.UixWeb.Test.Mirror.Variants.IndexActions
  alias Phoenix.LiveView.Rendered

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

      mirror_resource(:product)
      mirror_resource(:product_location)
      mirror_resource(:supplier)

      auix_create_ui do
        index_columns(:product, [:reference, :name, :description, :quantity_at_hand, :inactive],
          remove_row_action: :default_row_edit,
          add_row_action:
            {:custom_row_action_replaced, &IndexActions.custom_row_action_to_replace/1},
          add_row_action: {:custom_row_action_added, &IndexActions.custom_row_action_to_add/1},
          insert_row_action:
            {:custom_row_action_inserted, &IndexActions.custom_row_action_to_insert/1},
          add_header_action:
            {:custom_header_action_added, &IndexActions.custom_header_action_added/1},
          insert_header_action:
            {:custom_header_action_inserted, &IndexActions.custom_header_action_inserted/1},
          replace_header_action:
            {:default_new, &IndexActions.custom_header_action_directly_replaced/1},
          add_footer_action: {:custom_footer_action, &IndexActions.custom_footer_action/1},
          add_filters_action: {:custom_filter_added, &IndexActions.custom_filter_added/1},
          add_filters_action: {:custom_filter_removed, &IndexActions.custom_filter_removed/1},
          insert_filters_action:
            {:custom_filter_inserted, &IndexActions.custom_filter_inserted/1},
          replace_filters_action: {:custom_filter_added, &IndexActions.custom_filter_replaced/1},
          remove_filters_action: :custom_filter_removed,
          handler_module: Aurora.UixWeb.Test.Mirror.Handlers.SelectedBulkActionIndexHandler,
          add_selected_action: {:deactivate_selected, &IndexActions.deactivate_selected/1}
        )

        edit_layout :product do
          inline([:reference, :name, :description])
          inline([:quantity_at_hand, :quantity_initial])
          inline([:list_price, :rrp])
        end

        show_layout :product do
          inline([:reference, :name, :description])
          inline([:quantity_at_hand, :quantity_initial])
          inline([:list_price, :rrp])
        end

        index_columns(:product_location, [:reference, :name],
          remove_row_action: :default_row_show,
          insert_row_action: {:archive, &IndexActions.archive_action/1, destructive?: true},
          add_row_action: {:copy, &IndexActions.copy_action/1}
        )

        index_columns(:supplier, [:name, :country],
          action_icons: [
            default_row_show: "★",
            default_row_edit: "/images/edit.svg",
            default_row_delete: &IndexActions.delete_icon/1,
            default_selected_delete_all: "hero-archive-box-x-mark"
          ]
        )
      end
    end
  end

  @doc false
  @spec custom_row_action_to_add(map()) :: Rendered.t()
  def custom_row_action_to_add(assigns) do
    ~H"""
      <.auix_link patch={"/#{@auix.uri_path}/#{elem(@auix.row_info, 1).id}/edit"} name={"auix-edit-#{@auix.module}-added"}>Custom Added</.auix_link>
    """
  end

  @doc false
  @spec custom_row_action_to_replace(map()) :: Rendered.t()
  def custom_row_action_to_replace(assigns) do
    ~H"""
      <.auix_link patch={"/#{@auix.uri_path}/#{elem(@auix.row_info, 1).id}/edit"} name={"auix-edit-#{@auix.module}"}>Custom Removed and Added</.auix_link>
    """
  end

  @doc false
  @spec custom_row_action_to_insert(map()) :: Rendered.t()
  def custom_row_action_to_insert(assigns) do
    ~H"""
      <.auix_link patch={"/#{@auix.uri_path}/#{elem(@auix.row_info, 1).id}/edit"} name={"auix-edit-#{@auix.module}-inserted"}>Custom Inserted</.auix_link>
    """
  end

  @doc false
  @spec custom_header_action_added(map()) :: Rendered.t()
  def custom_header_action_added(assigns) do
    ~H"""
    <.auix_link patch={"#{@auix[:index_new_link]}"} name={"auix-new-#{@auix.module}-added"}>
      <.button>Added {@auix.name}</.button>
    </.auix_link>
    """
  end

  @doc false
  @spec custom_header_action_inserted(map()) :: Rendered.t()
  def custom_header_action_inserted(assigns) do
    ~H"""
    <.auix_link patch={"#{@auix[:index_new_link]}"} name={"auix-new-#{@auix.module}-inserted"}>
      <.button>Inserted {@auix.name}</.button>
    </.auix_link>
    """
  end

  @doc false
  @spec custom_header_action_directly_replaced(map()) :: Rendered.t()
  def custom_header_action_directly_replaced(assigns) do
    ~H"""
    <.auix_link patch={"#{@auix[:index_new_link]}"} name={"auix-new-#{@auix.module}"}>
      <.button>New Replaced {@auix.name}</.button>
    </.auix_link>
    """
  end

  @doc false
  @spec custom_footer_action(map()) :: Rendered.t()
  def custom_footer_action(assigns) do
    ~H"""
    <.auix_link patch={"#{@auix[:index_new_link]}"} name={"auix-new-#{@auix.module}-footer"}>
      <.button>Footer {@auix.name}</.button>
    </.auix_link>
    """
  end

  @doc false
  @spec custom_filter_added(map()) :: Rendered.t()
  def custom_filter_added(assigns) do
    ~H"""
    <a href="#" name="auix-filter-action-added">Added filter action</a>
    """
  end

  @doc false
  @spec custom_filter_inserted(map()) :: Rendered.t()
  def custom_filter_inserted(assigns) do
    ~H"""
    <a href="#" name="auix-filter-action-inserted">Inserted filter action</a>
    """
  end

  @doc false
  @spec custom_filter_replaced(map()) :: Rendered.t()
  def custom_filter_replaced(assigns) do
    ~H"""
    <a href="#" name="auix-filter-action-replaced">Replaced filter action</a>
    """
  end

  @doc false
  @spec custom_filter_removed(map()) :: Rendered.t()
  def custom_filter_removed(assigns) do
    ~H"""
    <a href="#" name="auix-filter-action-removed">Removed filter action</a>
    """
  end

  @doc false
  @spec deactivate_selected(map()) :: Rendered.t()
  def deactivate_selected(
        %{auix: %{selection: %{selected_count: count, toggle_all_mode: :none}}} = assigns
      )
      when count > 0 do
    ~H"""
    <.button
      type="button"
      class="auix-index-all-action-button"
      phx-click="deactivate_selected"
      name={"auix-selected-deactivate-#{@auix.module}"}
    >
      Deactivate selected
    </.button>
    """
  end

  def deactivate_selected(assigns), do: ~H""

  @doc false
  @spec archive_action(map()) :: Rendered.t()
  def archive_action(assigns) do
    ~H"""
    <a href="#" name="auix-archive-product_location">A</a>
    """
  end

  @doc false
  @spec copy_action(map()) :: Rendered.t()
  def copy_action(assigns) do
    ~H"""
    <a href="#" name="auix-copy-product_location">C</a>
    """
  end

  @doc false
  @spec delete_icon(map()) :: binary()
  def delete_icon(_assigns), do: "hero-x-mark"
end
