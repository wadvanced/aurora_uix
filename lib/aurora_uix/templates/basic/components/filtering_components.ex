defmodule Aurora.Uix.Templates.Basic.Components.FilteringComponents do
  @moduledoc """
  Provides filter input components with standardized styling and behavior.

  Key features:
  - Automatically handles filterable? fields with consistent styling
  - Falls back to empty render for non-filterable? fields
  - Applies standardized focus styles and responsive sizing
  """

  use Aurora.Uix.CoreComponentsImporter
  import Phoenix.Component

  alias Aurora.Uix.Filter
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Phoenix.LiveView.Rendered

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
    <div class="auix-filter-field">
      <div class="auix-filter-field-content">
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
    assigns = Map.put(assigns, :select_opts, BasicHelpers.get_select_options(assigns))

    ~H"""
      <div>
        <.input
            id={"#{@field.html_id}#{@infix}-filter_from"}
            name={"filter_from__#{@infix}#{@field.key}"}
            value={(@filter.from)}
            type={"#{@field.html_type}"}
            options={@select_opts[:options]}
            class="auix-filter-input"
            fieldset_class="auix-filter-fieldset"
            input_class="auix-filter-input-field"
            omit_label?={true}
          />
        <.input
            id={"#{@field.html_id}#{@infix}-filter_to"}
            name={"filter_to__#{@infix}#{@field.key}"}
            value={(@filter.to)}
            type={"#{@field.html_type}"}
            options={@select_opts[:options]}
            class="auix-filter-input"
            fieldset_class="auix-filter-fieldset"
            input_class={if @filter.condition != :between, do: "auix-filter-input-field--disabled", else: "auix-filter-input-field"}
            readonly={@filter.condition != :between}
            disabled={@filter.condition != :between}
            omit_label?={true}
          />
        </div>
    """
  end

  @spec render_filter_condition(map()) :: Rendered.t()
  defp render_filter_condition(assigns) do
    ~H"""
      <.label for={"#{@field.html_id}#{@infix}-filter_condition"} class="auix-filter-condition-label">{@field.label}</.label>
      <.input
          id={"#{@field.html_id}#{@infix}-filter_condition"}
          name={"filter_condition__#{@infix}#{@field.key}"}
          value={(@filter.condition)}
          type="select"
          options={Filter.conditions(@field)}
          fieldset_class="auix-filter-fieldset"
          input_class="auix-filter-condition-input"
          omit_label?={true}
        />
    """
  end
end
