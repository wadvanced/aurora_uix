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
    layout_classes = "auix-#{mode}-container p-4 border rounded-lg shadow bg-white"
    ~s(<div class="#{layout_classes}" data-layout="#{name}">\n)
  end

  def parse_layout(%{tag: mode, state: :end}, mode) when mode in [:form, :show] do
    "</div>\n"
  end

  def parse_layout(%{tag: :group, state: :start, config: config}, mode)
      when mode in [:form, :show] do
    group_classes = "p-3 border rounded-md bg-gray-100"
    group_title_classes = "font-semibold text-lg"

    ~s(<div id="#{config[:group_id]}" class="#{group_classes}">\n  <h3 class="#{group_title_classes}">#{config[:title]}</h3>\n)
  end

  def parse_layout(%{tag: :group, state: :end}, mode) when mode in [:form, :show] do
    "</div>\n"
  end

  def parse_layout(%{tag: :inline, state: :start, config: {:fields, fields}}, mode)
      when is_list(fields) and mode in [:form, :show] do
    fields_classes = "flex flex-col gap-2 sm:flex-row"
    fields_html = Enum.map_join(fields, "\n", &render_field(&1, mode))
    ~s(<div class="#{fields_classes}">\n#{fields_html}\n)
  end

  def parse_layout(%{tag: :inline, state: :end}, mode) when mode in [:form, :show] do
    "</div>\n"
  end

  def parse_layout(%{tag: :stacked, state: :start, config: {:fields, fields}}, mode)
      when mode in [:form, :show] do
    fields_classes = "flex flex-col gap-2"
    fields_html = Enum.map_join(fields, "\n", &render_field(&1, mode))
    ~s(<div class="#{fields_classes}">\n#{fields_html}\n)
  end

  def parse_layout(%{tag: :stacked, state: :end}, mode) when mode in [:form, :show] do
    "</div>\n"
  end

  def parse_layout(%{tag: :sections, state: :start, config: config}, mode)
      when mode in [:form, :show] do
    target = if mode == :form, do: "phx-target={@myself}", else: ""
    unique = :erlang.unique_integer([:positive])

    active_classes =
      "auix-tab-button active px-4 py-2 text-sm font-semibold transition-all duration-200
        text-zinc-800 bg-zinc-100 border-b-2 border-transparent
        rounded-t-md"

    inactive_classes =
      "auix-tab-button px-4 py-2 text-sm font-medium transition-all duration-200
        text-zinc-400 bg-zinc-50 hover:bg-zinc-200 border-b-2 border-transparent
        rounded-t-md"

    button_container_classes = "auix-button-tabs-container mt-2 flex flex-col sm:flex-row"

    section_container_classes =
      "auix-sections-content p-4 border border-gray-300 rounded-tr-lg rounded-br-lg rounded-bl-lg"

    buttons_html =
      Enum.map_join(config[:tabs], "\n", fn tab_config ->
        %{
          label: label,
          tab_id: tab_id,
          tab_index: tab_index,
          sections_id: sections_id,
          sections_index: sections_index,
          active: active
        } = tab_config

        active_state =
          ~s|if (@_auix_sections["#{sections_id}"] == "#{tab_id}" or (@_auix_sections["#{sections_id}"] == nil
              and #{active || false})), do: "#{active_classes}", else: "#{inactive_classes}" |

        ~s(<button type="button" class={"tab-button " <> #{active_state}}
          data-button-sections-index="#{sections_index}"
          data-button-tab-index="#{tab_index}"
          phx-click="switch_section"
          phx-value-tab-id={Jason.encode!%{sections_id: "#{sections_id}", tab_id: "#{tab_id}"}}
              #{target}>#{label}</button>)
      end)

    ~s(<div id="sections-#{unique}-#{mode}" class="" data-sections-index="#{config[:index]}">\n
        <div id="tabs-container-#{unique}-#{mode}"
            class="#{button_container_classes}">\n#{buttons_html}</div>\n
          <div id="sections-content-#{unique}-#{mode}" class="#{section_container_classes}">\n)
  end

  def parse_layout(%{tag: :sections, state: :end}, mode)
      when mode in [:form, :show] do
    "</div></div>\n"
  end

  def parse_layout(%{tag: :section, state: :start, config: config}, mode)
      when mode in [:form, :show] do
    active_state =
      ~s|if @_auix_sections["#{config[:sections_id]}"] == "#{config[:tab_id]}"
          or (@_auix_sections["#{config[:sections_id]}"] == nil and #{config[:active] || false}), do: "", else: "hidden"|

    data_active_state =
      ~s|if @_auix_sections["#{config[:sections_id]}"] == "#{config[:tab_id]}"
          or (@_auix_sections["#{config[:sections_id]}"] == nil and #{config[:active] || false}), do: "active", else: "inactive"|

    ~s(<div class={"auix-section-tab " <> #{active_state}}
        id="#{config[:tab_id]}"
        data-tab-label="#{config[:label]}"
        data-tab-sections-id="#{config[:sections_id]}"
        data-tab-parent-id="#{config[:tab_parent_id]}"
        data-tab-sections-index="#{config[:sections_index]}"
        data-tab-index="#{config[:tab_index]}"
        data-tab-active={#{data_active_state}}
        >\n)
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
    input_classes = ~s"block w-full rounded-md border-zinc-300 shadow-sm focus:border-indigo-500
      focus:ring-indigo-500 sm:text-sm"

    opts = %{
      id: "auix-field-#{field.field}",
      input_class: "#{input_classes}",
      readonly: if(field.readonly, do: " readonly", else: ""),
      disabled: if(field.disabled, do: " disabled", else: "")
    }

    do_default_field_render(field, opts, mode)
  end

  defp do_default_field_render(%{hidden: true} = field, opts, :form = mode),
    do:
      ~s(<input type="hidden" id="#{opts.id}-#{mode}" name={@form[:#{field.field}].name} value={@form[:#{field.field}].value}  />)

  defp do_default_field_render(%{hidden: true} = field, opts, :show = mode),
    do:
      ~s(<input type="hidden" id="#{opts.id}-#{mode}" name="#{field.field}" value={@_entity.#{field.field}} />)

  defp do_default_field_render(%{hidden: false} = field, opts, :form = mode) do
    input_field_classes = "flex flex-col"
    ~s(
      <div class="#{input_field_classes}">
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
    input_field_classes = "flex flex-col"
    ~s(
      <div class="#{input_field_classes}">
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
