defmodule Aurora.Uix.Field do
  @moduledoc """
  A module representing a configurable field in the Aurora.Uix system.

  This module defines a struct to represent field properties for UI components, such as:
    - `field` (`atom`) - The field reference in the schema.
    - `name` (`binary`) - The field's name as a binary.
    - `field_type` (`atom`) - The type of the field, it is read from the source and SHOULDN'T be change.
    - `field_html_type` (`binary`) - The HTML type of the field (e.g., `:text`, `:number`, `:date`).
    - `html_id` (`binary`) - A unique html id for the field.
    - `renderer` (`function`) - A custom rendering function for the field.
    - `data` (`any`) - A general purpose field.
        Template parser expect specific format for this data, according to any of the field value.
        Refer to the template documentation to learn special fields data structure.
    - `resource` (`atom`) - Used for associations, indicate the resource_config defining the meta data of the related element.
    - `label` (`binary`) - A display label for the field.
    - `placeholder` (`binary`) - Placeholder text for input fields.
    - `length` (`non_neg_integer`) - Maximum allowed length of input (used for validations).
    - `precision` (`non_neg_integer`) - Number of digits for numeric fields.
    - `scale` (`non_neg_integer`) - Number of digits to the right of the decimal separator, for numeric fields.
    - `hidden` (`boolean`) - If true the field should be included, but not visible.
      However, it is up to the implementation whether to include the field in the generated artifact or not.
    - `readonly` (`boolean`) - If true the field should not accept changes.
    - `required` (`boolean`) - Indicates that the field should not be empty or unused.
    - `disabled` (`boolean`) - If true, the field should not participate in form interaction.
    - `omitted` (`boolean`) - If true, the field won't be display nor interact with.
      It is equivalent to not having the field at all.

  """

  alias Aurora.Uix.CounterAgent

  defstruct [
    :field,
    :field_type,
    :field_html_type,
    :renderer,
    :data,
    :resource,
    name: "",
    label: "",
    placeholder: "",
    length: 0,
    precision: 0,
    scale: 0,
    html_id: "",
    hidden: false,
    readonly: false,
    required: false,
    disabled: false,
    omitted: false
  ]

  @type t() :: %__MODULE__{
          field: atom | nil,
          field_type: atom | nil,
          field_html_type: atom | binary | nil,
          html_id: binary,
          renderer: function | nil,
          data: any | nil,
          resource: module | nil,
          name: binary,
          label: binary,
          placeholder: binary,
          length: non_neg_integer,
          precision: non_neg_integer,
          scale: non_neg_integer,
          hidden: boolean,
          readonly: boolean,
          required: boolean,
          disabled: boolean,
          omitted: boolean
        }

  @doc """
  Creates a new Field struct with the given attributes.

  ## Parameters
    - attrs (map() | keyword()) - Initial attributes for the field struct

  The name attribute is automatically derived from the field value.

  ## Example
      iex> Aurora.Uix.Field.new(%{field: :user_name}) |> struct(%{html_id: ""})
      %Aurora.Uix.Field{
        field: :user_name,
        name: "user_name",
        data: nil,
        disabled: false,
        field_html_type: nil,
        field_type: nil,
        hidden: false,
        label: "",
        length: 0,
        omitted: false,
        placeholder: "",
        precision: 0,
        readonly: false,
        renderer: nil,
        required: false,
        resource: nil,
        scale: 0,
        html_id: ""
      }

  Returns:
    - Aurora.Uix.Field.t()
  """
  @spec new(map | keyword) :: __MODULE__.t()
  def new(attrs \\ %{}), do: change(%__MODULE__{}, attrs)

  @doc """
  Updates an existing Field struct with new attributes.

  ## Parameters
    - field (t()) - The existing field struct
    - attrs (map() | keyword()) - Attributes to update in the struct

  The name attribute is updated when field value changes.

  ## Example
      iex> field = Aurora.Uix.Field.new()
      iex> Aurora.Uix.Field.change(field, %{field: :email}) |> struct(%{html_id: ""})
      %Aurora.Uix.Field{
              field: :email,
              name: "email",
              data: nil,
              disabled: false,
              field_html_type: nil,
              field_type: nil,
              hidden: false,
              label: "",
              length: 0,
              omitted: false,
              placeholder: "",
              precision: 0,
              readonly: false,
              renderer: nil,
              required: false,
              resource: nil,
              scale: 0,
              html_id: ""
            }

  Returns:
    - Aurora.Uix.Field.t()
  """
  @spec change(__MODULE__.t(), map | keyword) :: __MODULE__.t()
  def change(field, attrs) when is_list(attrs) do
    keys = Map.keys(%__MODULE__{})

    attrs
    |> Enum.filter(&(elem(&1, 0) in keys))
    |> Map.new()
    |> then(&struct(field, &1))
    |> update_name()
    |> set_field_id()
  end

  def change(field, %{} = attrs), do: field |> struct(attrs) |> update_name()

  ## PRIVATE
  @spec update_name(__MODULE__.t()) :: __MODULE__.t()
  defp update_name(%{field: field} = field_struct) when is_atom(field),
    do: field_struct |> struct(%{name: to_string(field)}) |> set_field_id()

  defp update_name(%{field: {parent, field}} = field_struct),
    do: field_struct |> struct(%{name: "#{parent} #{field}"}) |> set_field_id()

  @doc """
  Generates or returns a unique HTML ID for a field.

  Parameters:
    - field: Field.t() - The field struct requiring an ID

  Returns:
    - Field.t() - Field with updated html_id if empty, or unchanged if ID exists
  """
  @spec set_field_id(__MODULE__.t()) :: __MODULE__.t()
  def set_field_id(%__MODULE__{field: field_name} = field) when is_nil(field_name), do: field

  def set_field_id(%__MODULE__{html_id: "", field: field_name, resource: resource} = field)
      when is_nil(resource) do
    struct(field, %{html_id: "auix-field-#{field_name}-#{CounterAgent.next_count(:auix_fields)}"})
  end

  def set_field_id(%__MODULE__{html_id: "", field: field_name, resource: resource} = field) do
    struct(field, %{
      html_id: "auix-field-#{resource}-#{field_name}-#{CounterAgent.next_count(:auix_fields)}"
    })
  end

  def set_field_id(field), do: field
end
