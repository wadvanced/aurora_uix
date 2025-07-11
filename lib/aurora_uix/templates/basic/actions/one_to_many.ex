defmodule Aurora.Uix.Web.Templates.Basic.Actions.OneToMany do
  @moduledoc """
  Provides helpers for managing one-to-many association actions in Aurora UIX index layouts.

  This module sets up and modifies actions for header, footer, and row elements in index layouts
  that represent one-to-many associations. It ensures that default actions are present and
  allows for further customization via the `Actions.modify_actions/2` function.

  ## Key Features

    - Adds default actions for headers, footers, and rows in one-to-many association tables.
    - Integrates with the Aurora UIX action modification pipeline.
    - Provides helpers for rendering "new", "show", "edit", and "delete" child links in form layouts.

  ## Key Constraints

    - Expects the `assigns` map to include an `:auix` key with required subkeys for actions.
    - Designed for use within Phoenix LiveView templates and Aurora UIX layouts.
  """

  use Aurora.Uix.Web.CoreComponentsImporter

  import Phoenix.Component, only: [sigil_H: 2, link: 1]

  alias Aurora.Uix.Action
  alias Aurora.Uix.Web.Templates.Basic.Actions
  alias Aurora.Uix.Web.Templates.Basic.Helpers, as: BasicHelpers
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered

  @actions Action.available_actions(:one_to_many)

  @doc """
  Sets up actions for the one to many field rendering layout by adding defaults and applying modifications.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and context.
    - Must include `:auix` key with required subkeys.

  ## Returns
  map() - The updated assigns with actions set.

  ## Examples

      iex> assigns = %{auix: %{row_info: {:user, %{id: 1}}, module: "User"}}
      iex> Aurora.Uix.Web.Templates.Basic.Actions.OneToMany.set_actions(assigns)
      %{auix: %{row_info: {:user, %{id: 1}}, module: "User", one_to_many_row_actions: %{}, one_to_many_header_actions: %{}, one_to_many_footer_actions: %{}}, ...}
  """
  @spec set_actions(map()) :: map()
  def set_actions(assigns) do
    assigns
    |> add_default_row_actions()
    |> add_default_header_actions()
    |> add_default_footer_actions()
    |> Actions.modify_actions(@actions)
  end

  @doc """
  Renders a link for adding a new child entity in a one-to-many association form.

  The link is only shown if the index new link is enabled, the layout type is `:form`, and the
  parent entity has a non-nil ID.

  ## Parameters
  - `assigns` (map()) - Assigns map containing association and entity context.
    - Must include `:auix` key with `:association`, `:entity`, `:layout_type`, and `:field`.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered link component.

  ## Examples

      iex> assigns = %{
      ...>   auix: %{
      ...>     association: %{
      ...>       related_parsed_opts: %{index_new_link: "/users/new"},
      ...>       related_key: "user_id",
      ...>       owner_key: :id,
      ...>       parsed_opts: %{module: "User"}
      ...>     },
      ...>     entity: %{id: 123},
      ...>     layout_type: :form
      ...>   },
      ...>   field: %{key: "users"}
      ...> }
      iex> Aurora.Uix.Web.Templates.Basic.Actions.OneToMany.add_new_child(assigns)
      #=> %Phoenix.LiveView.Rendered{...}
  """
  @spec add_new_child(map()) :: Rendered.t()
  def add_new_child(assigns) do
    ~H"""
      <.auix_link :if={@auix[:layout_type] == :form
            && BasicHelpers.primary_key_value(@auix.entity, @auix.primary_key) != nil}
          navigate={"#{@auix.association.related_parsed_opts.index_new_link}?related_key=#{@auix.association.related_key}&parent_id=#{Map.get(@auix.entity, @auix.association.owner_key)}"}
          name={"auix-new-#{@auix.association.parsed_opts.module}__#{@field.key}-#{@auix.layout_type}"}>
        <.icon name="hero-plus" />
      </.auix_link>
    """
  end

  @doc """
  Renders a link for showing a child entity in a one-to-many association.

  ## Parameters
  - `assigns` (map()) - Assigns map containing association and row info.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered link component.
  """
  @spec show_child_action(map()) :: Rendered.t()
  def show_child_action(assigns) do
    ~H"""
      <.auix_link navigate={"/#{@auix.association.related_parsed_opts.link_prefix}#{@auix.association.related_parsed_opts.source}/#{elem(@auix.row_info, 0)}"}
        name={"auix-show-#{@auix.association.parsed_opts.module}__#{@auix.association.related_parsed_opts.module}-#{elem(@auix.row_info, 0)}"}>
          <.icon name="hero-eye" />
      </.auix_link>
    """
  end

  @doc """
  Renders a link for editing a child entity in a one-to-many association.

  ## Parameters
  - `assigns` (map()) - Assigns map containing association and row info.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered link component.
  """
  @spec edit_child_action(map()) :: Rendered.t()
  def edit_child_action(assigns) do
    ~H"""
      <.auix_link navigate={"/#{@auix.association.related_parsed_opts.link_prefix}#{@auix.association.related_parsed_opts.source}/#{elem(@auix.row_info, 0)}/edit"}
      name={"auix-edit-#{@auix.association.parsed_opts.module}__#{@auix.association.related_parsed_opts.module}-#{elem(@auix.row_info, 0)}"}>
          <.icon name="hero-pencil" />
      </.auix_link>
    """
  end

  @doc """
  Renders a link for deleting a child entity in a one-to-many association.

  ## Parameters
  - `assigns` (map()) - Assigns map containing association and row info.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered link component.
  """
  @spec delete_child_action(map()) :: Rendered.t()
  def delete_child_action(assigns) do
    ~H"""
      <.link
        phx-click={JS.push("delete",
            value: %{id: elem(@auix.row_info, 0),
              context: @auix.association.related_resource_config.context,
              get_function: inspect(@auix.association.related_parsed_opts.get_function),
              delete_function: inspect(@auix.association.related_parsed_opts.delete_function)}
          )
          |> hide("##{elem(@auix.row_info, 0)}")}
        name={"auix-delete-#{@auix.association.parsed_opts.module}__#{@auix.association.related_parsed_opts.module}-#{elem(@auix.row_info, 0)}"}
        data-confirm="Are you sure?"
      >
        <.icon name="hero-trash" />
      </.link>
    """
  end

  ## PRIVATE

  @spec add_default_row_actions(map()) :: map()
  defp add_default_row_actions(assigns) do
    Actions.add_actions(assigns, :one_to_many_row_actions,
      default_row_show: &show_child_action/1,
      default_row_edit: &edit_child_action/1,
      default_row_delete: &delete_child_action/1
    )
  end

  @spec add_default_footer_actions(map()) :: map()
  defp add_default_footer_actions(%{auix: %{one_to_many_footer_actions: _}} = assigns),
    do: assigns

  # Adds an empty one_to_many_footer_actions map if not present.
  defp add_default_footer_actions(assigns),
    do: put_in(assigns, [:auix, :one_to_many_footer_actions], [])

  @spec add_default_header_actions(map()) :: map()
  defp add_default_header_actions(assigns) do
    Actions.add_actions(assigns, :one_to_many_header_actions, default_new: &add_new_child/1)
  end
end
