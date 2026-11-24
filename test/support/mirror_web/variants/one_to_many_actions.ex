defmodule Aurora.UixWeb.Test.Mirror.Variants.OneToManyActions do
  @moduledoc """
  The `one-to-many-actions` views variant: header, row and footer actions of a one-to-many list,
  replaced and added, and the action icons of a list.

  ## Key Features

  - Declares the product transactions list with a custom header, row and footer actions
  - Declares the products list of a location with replaced action icons

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.OneToManyActions` and
    `Aurora.UixWeb.Test.MirrorCtx.OneToManyActions`
  """

  use Aurora.Uix.CoreComponentsImporter

  import Aurora.Uix.Templates.Basic.RoutingComponents

  alias Aurora.UixWeb.Test.Mirror.Variants.OneToManyActions
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

      mirror_resource(:product_location)
      mirror_resource(:product_transaction)
      mirror_resource(:product)

      auix_create_ui do
        edit_layout :product do
          stacked([
            :reference,
            :name,
            :description,
            :quantity_initial,
            product_transactions: [
              add_header_action: {:custom_action, &OneToManyActions.custom_new_child/1},
              replace_row_action: {:default_row_edit, &OneToManyActions.custom_edit_row_action/1},
              add_footer_action:
                {:custom_footer_second_action, &OneToManyActions.custom_footer_second_action/1},
              insert_footer_action:
                {:custom_footer_action, &OneToManyActions.custom_footer_action/1}
            ]
          ])
        end

        edit_layout :product_location do
          stacked([
            :reference,
            :name,
            products: [
              action_icons: [default_new: "hero-sparkles", default_row_edit: "hero-pencil-square"]
            ]
          ])
        end
      end
    end
  end

  @doc false
  @spec custom_new_child(map()) :: Rendered.t()
  def custom_new_child(assigns) do
    ~H"""
      <.auix_link :if={@auix[:layout_type] == :form && @auix.entity.id != nil}
          navigate={"#{@auix.association.related_parsed_opts.index_new_link}?related_key=#{@auix.association.related_key}&parent_id=#{Map.get(@auix.entity, @auix.association.owner_key)}"}
          name={"auix-new-#{@auix.association.parsed_opts.module}__#{@field.key}-#{@auix.layout_type}"}>
        custom new
      </.auix_link>
    """
  end

  @doc false
  @spec custom_edit_row_action(map()) :: Rendered.t()
  def custom_edit_row_action(assigns) do
    ~H"""
      <.auix_link navigate={"/#{@auix.association.related_parsed_opts.uri_path}/#{elem(@auix.row_info, 0)}"}
        name={"auix-edit-#{@auix.association.parsed_opts.module}__#{@auix.association.related_parsed_opts.module}-#{elem(@auix.row_info, 0)}"}>
          Custom edit
      </.auix_link>
    """
  end

  @doc false
  @spec custom_footer_action(map()) :: Rendered.t()
  def custom_footer_action(assigns) do
    ~H"""
      <.auix_link :if={@auix.entity.id != nil}
          navigate={"#{@auix.association.related_parsed_opts.index_new_link}?related_key=#{@auix.association.related_key}&parent_id=#{Map.get(@auix.entity, @auix.association.owner_key)}"}
          name={"auix-new-#{@auix.association.parsed_opts.module}__#{@field.key}-#{@auix.layout_type}"}>
        Custom footer
      </.auix_link>
    """
  end

  @doc false
  @spec custom_footer_second_action(map()) :: Rendered.t()
  def custom_footer_second_action(assigns) do
    ~H"""
      <.auix_link :if={@auix.entity.id != nil}
          navigate={"#{@auix.association.related_parsed_opts.index_new_link}?related_key=#{@auix.association.related_key}&parent_id=#{Map.get(@auix.entity, @auix.association.owner_key)}"}
          name={"auix-new-#{@auix.association.parsed_opts.module}__#{@field.key}-#{@auix.layout_type}"}>
        Custom footer second
      </.auix_link>
    """
  end
end
