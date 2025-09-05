defmodule Aurora.Uix.Templates.Basic.Components.FilteringComponents do
  @moduledoc """
  Provides filter input components with standardized styling and behavior.

  Key features:
  - Automatically handles filterable? fields with consistent styling
  - Falls back to empty render for non-filterable? fields
  - Applies standardized focus styles and responsive sizing

  |||elixir
  # Example usage in HEEx templates:
  <.filter_field field={%{filterable?: true, name: :search}} />
  """

  use Aurora.Uix.CoreComponentsImporter
  import Phoenix.Component

  alias Aurora.Uix.Filter
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Phoenix.LiveView.Rendered

  @class_for_input "block w-full pb-0 pt-0 mt-1 rounded-sm border-zinc-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"

  @doc """
  Renders a styled filter input field for filterable? fields.

  ## Parameters
  - `assigns` (map): Phoenix LiveView assigns containing:
    - `field` (map): Field configuration with:
      - `:filterable?` (boolean): Required flag to enable filtering
      - Other field attributes are passed through to input

  ## Returns
  - `Phoenix.LiveView.Rendered`: The styled filter input component

  Only renders when `field.filterable?` is true, otherwise returns empty content.
  """
  @spec filter_field(map()) :: Rendered.t()
  def filter_field(%{field: %{filterable?: true}} = assigns) do
    ~H"""
    <div class="flex flex-col gap-0 items-center">
      <div class="w-full text-center pb-2">
        <div>
          <.render_filter_condition field={@field} filter={@filter} infix={@infix}/>
        </div>
        <div>
          <.render_filter_input field={@field} filter={@filter} auix={@auix} infix={@infix}/>
        </div>
      </div>
    </div>

    """
  end

  @spec filter_field(map()) :: Rendered.t()
  def filter_field(assigns) do
    ~H"""
    """
  end

  ## PRIVATE
  @spec render_filter_input(map()) :: Rendered.t()
  defp render_filter_input(%{filter: %Filter{}} = assigns) do
    assigns =
      assigns
      |> Map.put(:class, @class_for_input)
      |> Map.put(:input_class, "!h-50 !pb-0 !pt-0 !mt-1 ")
      |> Map.put(
        :select_opts,
        BasicHelpers.get_select_options(assigns)
      )

    ~H"""
      <div>
        <.input
            id={"#{@field.html_id}#{@infix}-filter_from"}
            name={"filter_from__#{@infix}#{@field.key}"}
            value={(@filter.from)}
            type={"#{@field.html_type}"}
            options={@select_opts[:options]}
            class={@class}
            input_class={@input_class}
          />
        <.input
            id={"#{@field.html_id}#{@infix}-filter_to"}
            name={"filter_to__#{@infix}#{@field.key}"}
            value={(@filter.to)}
            type={"#{@field.html_type}"}
            options={@select_opts[:options]}
            class={@class}
            input_class={@input_class <> if @filter.condition != :between, do: "!bg-zinc-400", else: ""}
            readonly={@filter.condition != :between}
            disabled={@filter.condition != :between}
          />
        </div>
    """
  end

  @spec render_filter_condition(map()) :: Rendered.t()
  defp render_filter_condition(assigns) do
    input_class =
      "w-full bg-zinc-100 block pb-0 pt-0 rounded-sm border-zinc-100 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"

    assigns = Map.put(assigns, :input_class, input_class)

    ~H"""
      <.input
          id={"#{@field.html_id}#{@infix}-filter_condition"}
          name={"filter_condition__#{@infix}#{@field.key}"}
          value={(@filter.condition)}
          type="select"
          options={Filter.conditions()}
          input_class={@input_class}
        />
    """
  end
end
