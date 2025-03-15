defmodule AuroraUixWeb.Templates.Basic.LayoutParser do
  @moduledoc """
  Provides functionality to parse and render layout structures for UI templates.

  This module is responsible for generating HTML structures for layouts, groups, and fields
  based on configuration and mode (`:form` or `:show`). It supports dynamic rendering of
  fields, including custom renderers, and handles disabled or hidden fields appropriately.

  ## Key Features
  - Parses and renders layouts, groups, and fields into HTML.
  - Supports inline and stacked field arrangements.
  - Handles custom field renderers and default rendering logic.
  - Skips disabled fields and manages hidden fields gracefully.
  """

  @doc """
  Parses a layout configuration and returns the corresponding HTML.

  This function handles various layout configurations, including:
  - Layouts (start and end).
  - Groups (start and end).
  - Inline fields (start and end).
  - Stacked fields (start and end).

  ## Parameters
  - `config` (`map`): A map containing layout configuration (e.g., `:tag`, `:state`, `:config`).
  - `mode` (`atom`): The rendering mode (`:form` or `:show`).

  ## Returns
  - `binary`: The generated HTML string.
  """
  @spec parse_layout(map, atom) :: binary
  def parse_layout(%{tag: mode, state: :start, name: name}, mode) when mode in [:form, :show] do
    ~s(<div class="p-4 border rounded-lg shadow bg-white" data-layout="#{name}">\n)
  end

  def parse_layout(%{tag: mode, state: :end}, mode) when mode in [:form, :show] do
    "</div>\n"
  end

  def parse_layout(%{tag: :group, state: :start, config: config}, mode)
      when mode in [:form, :show] do
    ~s(<div id="#{config[:group_id]}" class="p-3 border rounded-md bg-gray-100">\n  <h3 class="font-semibold text-lg">#{config[:title]}</h3>\n)
  end

  def parse_layout(%{tag: :group, state: :end}, mode) when mode in [:form, :show] do
    "</div>\n"
  end

  def parse_layout(%{tag: :inline, state: :start, config: {:fields, fields}}, mode)
      when is_list(fields) and mode in [:form, :show] do
    fields_html = Enum.map_join(fields, "\n", &render_field(&1, mode))
    "<div class=\"flex gap-2\">\n#{fields_html}\n"
  end

  def parse_layout(%{tag: :inline, state: :end}, mode) when mode in [:form, :show] do
    "</div>\n"
  end

  def parse_layout(%{tag: :stacked, state: :start, config: {:fields, fields}}, mode)
      when mode in [:form, :show] do
    fields_html = Enum.map_join(fields, "\n", &render_field(&1, mode))
    "<div class=\"flex flex-col gap-2\">\n#{fields_html}\n"
  end

  def parse_layout(%{tag: :stacked, state: :end}, mode) when mode in [:form, :show] do
    "</div>\n"
  end

  def parse_layout(%{tag: :sections, state: :start, config: config}, mode)
      when mode in [:form, :show] do
    target = if mode == :form, do: "phx-target={@myself}", else: ""
    monotonic = :erlang.unique_integer([:monotonic, :positive])

    buttons_html =
      Enum.map_join(config, "\n", fn %{
                                       label: label,
                                       tab_id: tab_id,
                                       sections_id: sections_id,
                                       active: active
                                     } ->
        active_state =
          ~s|if (@_auix_sections["#{sections_id}"] == "#{tab_id}" or (@_auix_sections["#{sections_id}"] == nil and #{active || false})), do: "active", else: "" |

        ~s(<button type="button" class={"tab-button " <> #{active_state}}
          phx-click="switch_section" phx-value-tab-id={Jason.encode!%{sections_id: "#{sections_id}", tab_id: "#{tab_id}"}} #{target}>#{label}</button>)
      end)

    ~s(<div id="tabs-container-#{monotonic}-#{mode}" class="tabs-container">\n#{buttons_html}\n<div id="sections-content-#{monotonic}-#{mode}" class="sections-content">\n)
  end

  def parse_layout(%{tag: :sections, state: :end}, mode)
      when mode in [:form, :show] do
    "</div></div>\n"
  end

  def parse_layout(%{tag: :section, state: :start, config: config}, mode)
      when mode in [:form, :show] do
    active_state =
      ~s|@_auix_sections["#{config[:sections_id]}"] == "#{config[:tab_id]}" or (@_auix_sections["#{config[:sections_id]}"] == nil and #{config[:active] || false})|

    ~s(<div :if={#{active_state}} class="section-tab active px-4 py-2 text-sm font-medium focus:outline-none border-b-2 transition-all duration-200" data-tab-id="#{config[:tab_id]}" data-tab-label="#{config[:label]}">\n)
  end

  def parse_layout(%{tag: :section, state: :end}, mode) when mode in [:form, :show] do
    "</div>\n"
  end

  def parse_layout(%{tag: :index, state: :start, config: {:fields, fields}}, :index) do
    Enum.map_join(fields, "\n", fn field ->
      "<:col :let={{_id, entity}} label=\"#{field.label}\">{entity.#{field.name}}</:col>"
    end)
  end

  def parse_layout(%{tag: :index, state: :end}, :index) do
    ""
  end

  # Renders individual fields
  # Skip disabled fields
  defp render_field(%AuroraUix.Field{omitted: true}, _mode), do: ""

  defp render_field(%AuroraUix.Field{} = field, mode) do
    case field.renderer do
      custom_renderer when is_function(custom_renderer, 1) -> custom_renderer.(field)
      _ -> default_field_render(field, mode)
    end
  end

  defp default_field_render(field, mode) do
    opts = %{
      id: "auix-field-#{field.field}",
      input_class:
        "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
      readonly: if(field.readonly, do: " readonly", else: ""),
      disabled: if(field.disabled, do: " disabled", else: "")
    }

    do_default_field_render(field, opts, mode)
  end

  defp do_default_field_render(%{hidden: true} = field, opts, :form = mode),
    do: ~s(<.input type="hidden" id="#{opts.id}-#{mode}" field={@form[:#{field.field}]}  />)

  defp do_default_field_render(%{hidden: true} = field, opts, :show = mode),
    do:
      ~s(<.input type="hidden" id="#{opts.id}-#{mode}" name="#{field.field}" value={@_entity.#{field.field}} />)

  defp do_default_field_render(%{hidden: false} = field, opts, :form = mode) do
    ~s(
      <div class="flex flex-col">
        <.input
          id="#{opts.id}-#{mode}"
          field={@form[:#{field.field}]}
          type="#{field.html_type}"
          label="#{field.label}"
          #{opts.readonly}
          #{opts.disabled}
          class="#{opts.input_class}"/>
      </div>
      )
  end

  defp do_default_field_render(%{hidden: false} = field, opts, :show = mode) do
    ~s(
      <div class="flex flex-col">
        <.input
          id="#{opts.id}-#{mode}"
          name="#{field.field}"
          type="#{field.html_type}"
          label="#{field.label}"
          value={@_entity.#{field.field}}
          #{opts.readonly}
          #{opts.disabled}
          class="#{opts.input_class}"/>
      </div>
      )
  end
end
