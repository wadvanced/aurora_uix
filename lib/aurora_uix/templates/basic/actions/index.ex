defmodule Aurora.Uix.Templates.Basic.Actions.Index do
  @moduledoc """
  Renders default row and header action links (show, edit, delete, new) for entities in index layouts.

  ## Key Features

  - Provides LiveView-compatible components for "show", "edit", "delete", and "new" actions.
  - Generates links using assigns context for entity and module information.
  - Supplies helpers to add all default row and header actions to assigns.
  - Supports dynamic modification of actions via layout tree options.

  ## Key Constraints

  - Assumes assigns contain `:auix` with `:row_info`, `:link_prefix`, `:source`, and `:module`.
  - Only intended for use in index page layouts.
  """

  use Aurora.Uix.Gettext
  use Aurora.Uix.CoreComponentsImporter

  import Phoenix.Component, only: [sigil_H: 2, link: 1]

  alias Aurora.Uix.Action
  alias Aurora.Uix.Templates.Basic.Actions
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered

  @actions Action.available_actions(:index)
  @filters_button_class "!bg-zinc-100 !text-zinc-500 border border-zinc-800"

  @doc """
  Sets up actions for the index layout by adding defaults and applying modifications.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.
    - Must include `:auix` key with required subkeys.

  ## Returns

  map - The updated assigns with actions set including row, header, footer, and filter actions.



  """
  @spec set_actions(map()) :: map()
  def set_actions(assigns) do
    assigns
    |> add_default_row_actions()
    |> add_default_header_actions()
    |> add_default_footer_actions()
    |> add_default_filters_actions()
    |> Actions.modify_actions(@actions)
  end

  @doc """
  Renders the "show" action link for an entity in the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.
    - Must include `:auix` with `:link_prefix`, `:source`, `:row_info`, and `:module`.

  ## Returns
  Rendered.t() - The rendered "show" action link.


  """
  @spec show_row_action(map()) :: Rendered.t()
  def show_row_action(assigns) do
    ~H"""
      <div class="sr-only">
        <.auix_link navigate={"/#{@auix.link_prefix}#{@auix.source}/#{row_info_id(@auix)}"} name={"auix-show-#{@auix.module}"}>Show</.auix_link>
      </div>
    """
  end

  @doc """
  Renders the "edit" action link for an entity in the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.
    - Must include `:auix` with `:link_prefix`, `:source`, `:row_info`, and `:module`.

  ## Returns
  Rendered.t() - The rendered "edit" action link.


  """
  @spec edit_row_action(map()) :: Rendered.t()
  def edit_row_action(assigns) do
    ~H"""
      <.auix_link patch={"/#{@auix.link_prefix}#{@auix.source}/#{row_info_id(@auix)}/edit"} name={"auix-edit-#{@auix.module}"}>Edit</.auix_link>
    """
  end

  @doc """
  Renders the "delete" action link for an entity in the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.
    - Must include `:auix` with `:row_info` and `:module`.

  ## Returns
  Rendered.t() - The rendered "delete" action link.


  ## Edge Cases

  - If `@auix.row_info` is missing or malformed, the link may not render correctly.
  """
  @spec remove_row_action(map()) :: Rendered.t()
  def remove_row_action(assigns) do
    ~H"""
      <.link
            phx-click={JS.push("delete", value: %{id: row_info_id(@auix)}) |> hide("##{row_info_id(@auix)}")}
            name={"auix-delete-#{@auix.module}"}
            data-confirm="Are you sure?"
          >
            Delete
      </.link>
    """
  end

  @doc """
  Renders the "new" action link for the header in the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.
    - Must include `:auix` with `:index_new_link`, `:module`, and `:name`.

  ## Returns
  Rendered.t() - The rendered "new" action link.


  """
  @spec new_header_action(map()) :: Rendered.t()
  def new_header_action(assigns) do
    ~H"""
    <.auix_link patch={"#{@auix[:index_new_link]}"} name={"auix-new-#{@auix.module}"}>
      <.button>New {@auix.name}</.button>
    </.auix_link>
    """
  end

  @doc """
  Renders a button to clear all applied filters in the index layout.

  ## Parameters

  - `assigns` (map()) - Assigns map (no specific requirements for this action)

  ## Returns

  Phoenix.LiveView.Rendered.t() - The rendered clear filters button

  """
  @spec clear_filters_action(map()) :: Rendered.t()
  def clear_filters_action(assigns) do
    assigns = Map.put(assigns, :filters_button_class, @filters_button_class)

    ~H"""
    <.button type="button" class={@filters_button_class} phx-click="filters-clear" name={"auix-filters_clear-#{@auix.module}"}>{gettext("Clear Filters")}</.button>
    """
  end

  @doc """
  Renders a button to submit current filter selections in the index layout.

  ## Parameters

  - `assigns` (map) - Assigns map (no specific requirements for this action)

  ## Returns

  Phoenix.LiveView.Rendered.t() - The rendered submit filters button

  """
  @spec submit_filters_action(map()) :: Rendered.t()
  def submit_filters_action(assigns) do
    assigns = Map.put(assigns, :filters_button_class, @filters_button_class)

    ~H"""
    <.button type="button" class={@filters_button_class} phx-click="filters-submit" name={"auix-filters_submit-#{@auix.module}"}>Submit</.button>
    """
  end

  @doc """
  Renders pagination controls for the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.
    - Must include `:auix` with `:layout_options`, `:pagination`, `:link_prefix`, `:source`, and `:resource_name`.

  ## Returns
  Rendered.t() - The rendered pagination controls with responsive breakpoints.

  """
  @spec pagination_action(map()) :: Rendered.t()
  def pagination_action(
        %{
          auix: %{
            layout_options: %{disable_pagination: false},
            pagination: %{page: _page, pages_count: pages_count}
          }
        } = assigns
      )
      when pages_count > 1 do
    ~H"""
      <div name={"auix-pages_bar-#{@auix.source}"} class="mt-10">
        <hr class="mb-4"/>
        <div class="h-0 invisible 2xl:visible" name={"auix-pages_bar-#{@auix.source}-xl2"}>
          <.pages_selection pagination={@auix.pagination} pages_bar_range_offset={@auix.layout_options.pages_bar_range_offset.(nil, :xl2)} />
        </div>
        <div class="h-0 invisible xl:visible 2xl:invisible" name={"auix-pages_bar-#{@auix.source}-xl"}>
          <.pages_selection pagination={@auix.pagination} pages_bar_range_offset={@auix.layout_options.pages_bar_range_offset.(nil, :xl)} />
        </div>
        <div class="h-0 invisible lg:visible xl:invisible" name={"auix-pages_bar-#{@auix.source}-lg"}>
          <.pages_selection pagination={@auix.pagination} pages_bar_range_offset={@auix.layout_options.pages_bar_range_offset.(nil, :lg)} />
        </div>
        <div class="h-0 invisible md:visible lg:invisible text-sm" name={"auix-pages_bar-#{@auix.source}-md"}>
          <.pages_selection pagination={@auix.pagination} pages_bar_range_offset={@auix.layout_options.pages_bar_range_offset.(nil, :md)} />
        </div>
        <div class="h-0 sm:visible md:invisible text-sm" name={"auix-pages_bar-#{@auix.source}-sm"}>
          <.pages_selection pagination={@auix.pagination} pages_bar_range_offset={@auix.layout_options.pages_bar_range_offset.(nil, :sm)} />
        </div>
      </div>
    """
  end

  def pagination_action(assigns) do
    ~H""
  end

  ## PRIVATE

  # Adds default row actions (show, edit, delete) to the assigns
  @spec add_default_row_actions(map()) :: map()
  defp add_default_row_actions(assigns) do
    Actions.add_actions(assigns, :index_row_actions,
      default_row_show: &show_row_action/1,
      default_row_edit: &edit_row_action/1,
      default_row_delete: &remove_row_action/1
    )
  end

  # Returns assigns unchanged if index_footer_actions already exists

  # Adds default header actions (new) to the assigns
  @spec add_default_header_actions(map()) :: map()
  defp add_default_header_actions(assigns) do
    Actions.add_actions(assigns, :index_header_actions, default_new: &new_header_action/1)
  end

  # Adds default footer actions (pagination) to the assigns
  @spec add_default_footer_actions(map()) :: map()
  defp add_default_footer_actions(assigns),
    do:
      Actions.add_actions(assigns, :index_footer_actions,
        default_pagination: &pagination_action/1
      )

  # Adds default filter actions (clear, submit) to the assigns
  @spec add_default_filters_actions(map()) :: map()
  defp add_default_filters_actions(assigns) do
    Actions.add_actions(assigns, :index_filters_actions,
      default_clear: &clear_filters_action/1,
      default_submit: &submit_filters_action/1
    )
  end

  # Extracts the primary key value from row_info for use in links and actions
  @spec row_info_id(map()) :: term() | nil
  defp row_info_id(%{row_info: {_, row_entity}, primary_key: primary_key}) do
    BasicHelpers.primary_key_value(row_entity, primary_key)
  end
end
