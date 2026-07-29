defmodule Aurora.Uix.Templates.Basic.Renderers.DefaultRenderer do
  @moduledoc """
  The default field renderer — what a field renders when no renderer slot selects a
  more specific one.

  It is a single `render/1` that pattern-matches `@auix.layout_type`:

  - `:index` — the table-cell value: `:select` option labels, the `:selected_check__`
    row control, or the plain field value.
  - `:show` — the read-only `<.input disabled>` display.
  - `:form` — the `<.input>` form control, delegating association / embed / upload
    fields to their dedicated renderers.

  It is registered under the reserved `:default` key in `Aurora.Uix.Renderers.BuiltIn`
  and reached via `Aurora.Uix.Renderers.default/1`. It intentionally does **not**
  `use Aurora.Uix.Renderer`: it covers every layout type itself and must never
  delegate back to the default.
  """

  use Aurora.Uix.CoreComponentsImporter
  use Aurora.Uix.Gettext

  alias Aurora.Uix.Counter
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.Uix.Templates.Basic.Renderers.EmbedsManyRenderer
  alias Aurora.Uix.Templates.Basic.Renderers.EmbedsOneRenderer
  alias Aurora.Uix.Templates.Basic.Renderers.ManyToMany
  alias Aurora.Uix.Templates.Basic.Renderers.ManyToOne
  alias Aurora.Uix.Templates.Basic.Renderers.OneToMany
  alias Aurora.Uix.Templates.Basic.Renderers.OneToOne
  alias Aurora.Uix.Templates.Basic.Renderers.UploadRenderer

  alias Phoenix.HTML.Form

  @doc """
  Renders a field with its default rendering for the current `@auix.layout_type`.
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(%{auix: %{layout_type: :index}} = assigns), do: index_value(assigns)

  def render(%{field: %{type: :one_to_many_association}} = assigns),
    do: OneToMany.render(assigns)

  def render(%{field: %{type: :many_to_one_association}} = assigns),
    do: ManyToOne.render(assigns)

  def render(%{field: %{type: :one_to_one_association}} = assigns),
    do: OneToOne.render(assigns)

  def render(%{field: %{type: :many_to_many_association}} = assigns),
    do: ManyToMany.render(assigns)

  def render(%{field: %{type: :embeds_one}} = assigns),
    do: EmbedsOneRenderer.render(assigns)

  def render(%{field: %{type: :embeds_many}} = assigns),
    do: EmbedsManyRenderer.render(assigns)

  def render(%{field: %{data: %{upload: upload_data}}} = assigns)
      when is_map(upload_data),
      do: UploadRenderer.render(assigns)

  # Standard :show / :form field.
  def render(assigns) do
    assigns =
      assigns
      |> assign(:input_classes, "auix-form-field-input")
      |> assign(:select_opts, BasicHelpers.get_select_options(assigns))

    ~H"""
    <%= if @field.hidden do %>
      <input type="hidden" id={"#{@field.html_id}-#{@auix.layout_type}"}
        {if @auix.layout_type == :form, do: %{name: @auix.form[@field.key].name, value: @auix.form[@field.key].value},
         else: %{name: @field.key, value: @auix.entity[@field.key]}} />
    <% else %>
      <div class="auix-form-field-container">
        <.default_render_input
            auix={@auix}
            field={@field}
            input_classes={@input_classes}
            select_opts={@select_opts}
        />
      </div>
    <% end %>
    """
  end

  # PRIVATE

  # --- index cell values ---

  @spec index_value(map()) :: Phoenix.LiveView.Rendered.t()
  defp index_value(%{field: %{html_type: :select, data: %{option_label: label_field}}} = assigns)
       when is_atom(label_field) do
    ~H"""
      {Map.get(@entity, @field.data.option_label)}
    """
  end

  defp index_value(%{field: %{html_type: :select, data: %{option_label: option_label}}} = assigns)
       when is_function(option_label, 1) do
    ~H"""
    {@field.data.option_label.(@entity)}
    """
  end

  defp index_value(%{field: %{html_type: :select, data: %{option_label: option_label}}} = assigns)
       when is_function(option_label, 2) do
    ~H"""
      {@field.data.option_label.(assigns, @entity)}
    """
  end

  # A multi-value select holds a list, and `Phoenix.HTML.Safe` raises on a list of atoms, so the
  # generic clause below cannot render one. Labels are joined the same way the form shows them.
  defp index_value(%{field: %{html_type: :select, data: %{select: %{multiple: true}}}} = assigns) do
    assigns = Map.put(assigns, :multi_select_labels, multi_select_labels(assigns))

    ~H"""
      {@multi_select_labels}
    """
  end

  defp index_value(%{field: %{key: :selected_check__}, entity: entity, auix: auix} = assigns) do
    assigns =
      Map.put(assigns, :selected_id, BasicHelpers.primary_key_value(entity, auix.primary_key))

    ~H"""
      <.input
          name={"#{@field.key}#{@selected_id}"}
          value={Map.get(@entity, @field.key)}
          type={"#{@field.html_type}"}
          label={dt(@field.label)}
          disabled={@auix.selection.toggle_all_mode != :none}
        />
    """
  end

  defp index_value(assigns) do
    ~H"""
    {Map.get(@entity, @field.key)}
    """
  end

  # Maps every selected value of a multi-value select to its option label, falling back to the raw
  # value when the entity holds something the options no longer offer.
  @spec multi_select_labels(map()) :: binary()
  defp multi_select_labels(%{field: %{key: key, data: %{select: %{opts: opts}}}, entity: entity}) do
    labels = Map.new(opts, fn {label, value} -> {to_string(value), label} end)

    entity
    |> Map.get(key)
    |> List.wrap()
    |> Enum.map_join(", ", &Map.get(labels, to_string(&1), to_string(&1)))
  end

  # --- show / form inputs ---

  @spec default_render_input(map()) :: Phoenix.LiveView.Rendered.t()
  defp default_render_input(%{auix: %{layout_type: :form, primary_key: primary_key}} = assigns) do
    primary_key = if is_list(primary_key), do: List.first(primary_key), else: primary_key

    assigns =
      assigns
      |> BasicHelpers.assign_auix(:primary_key, primary_key)
      |> maybe_set_one_to_many_relation_to_readonly(assigns.auix[:one_to_many_related_key])

    ~H"""
      <div class="auix-form-field-container">
        <.input
          id={field_id(@auix.form, @field, @auix.primary_key, @auix.layout_type)}
          field={@auix.form[@field.key]}
          type={"#{@field.html_type}"}
          label={dt(@field.label)}
          options={@select_opts[:options]}
          multiple={@select_opts[:multiple]}
          readonly={@field.readonly}
          disabled={@field.disabled}
          class={@input_classes}
        />
      </div>
      <.maybe_create_hidden_field_for_one_to_many_field auix={@auix} field={@field}
        one_to_many_related_key={@auix[:one_to_many_related_key]} />
    """
  end

  defp default_render_input(%{auix: %{layout_type: :show, primary_key: primary_key}} = assigns) do
    primary_key = if is_list(primary_key), do: List.first(primary_key), else: primary_key
    assigns = BasicHelpers.assign_auix(assigns, :primary_key, primary_key)

    ~H"""
      <div class="auix-form-field-container">
        <.input
          id={field_id(@auix.entity, @field, @auix.primary_key, @auix.layout_type)}
          name={@field.key}
          value={Map.get(@auix.entity || %{}, @field.key)}
          type={"#{@field.html_type}"}
          label={dt(@field.label)}
          options={@select_opts[:options]}
          multiple={@select_opts[:multiple]}
          readonly={@field.readonly}
          disabled={true}
          class={@input_classes}
        />
      </div>
    """
  end

  @spec maybe_set_one_to_many_relation_to_readonly(map(), nil | atom()) :: map()
  defp maybe_set_one_to_many_relation_to_readonly(
         %{field: %{key: one_to_many_related_key} = field} = assigns,
         one_to_many_related_key
       ) do
    field
    |> struct(%{disabled: true, readonly: true})
    |> then(&Map.put(assigns, :field, &1))
  end

  defp maybe_set_one_to_many_relation_to_readonly(assigns, _one_to_many_related_key), do: assigns

  @spec maybe_create_hidden_field_for_one_to_many_field(map()) :: Phoenix.LiveView.Rendered.t()
  defp maybe_create_hidden_field_for_one_to_many_field(
         %{
           field: %{key: one_to_many_related_key},
           one_to_many_related_key: one_to_many_related_key
         } = assigns
       ) do
    ~H"""
      <.input
        field={@auix.form[@field.key]}
        type="hidden"
      />
    """
  end

  defp maybe_create_hidden_field_for_one_to_many_field(assigns), do: ~H""

  @spec field_id(struct() | map(), map(), atom(), atom()) :: binary()
  defp field_id(entity, field, primary_key, :show = layout_type) do
    "#{field.html_id}--#{Counter.next_count(:auix_fields_id)}--#{Map.get(entity || %{}, primary_key)}--#{layout_type}"
  end

  defp field_id(form, field, primary_key, :form = layout_type) do
    "#{field.html_id}--#{Form.input_id(form, field.key)}--#{form[primary_key].value}--#{layout_type}"
  end
end
