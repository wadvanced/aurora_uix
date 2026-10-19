defmodule Aurora.Uix.Field.Override do
  @moduledoc """
  One `field` entry of `auix_resource_metadata`: the options a host sets on a field.

  Every option has its own key, and `nil` means the option was not given, so applying an
  override changes only what the host wrote. `:order_by` and `:where` become the field's
  `query_opts`, and `data: %{upload: ...}` is moved into `upload`.

  ## Key Features
  - One key per field option, so the declaration has a fixed shape.
  - `merge/2` and `to_field_changes/1` give the resolution step one way to combine and apply
    overrides.

  ## Key Constraints
  - Options outside the known set are ignored, as they were before this struct existed.
  - An option explicitly set to `nil` is indistinguishable from an unset one.
  """

  alias Aurora.Uix.Field.Upload

  @field_keys [
    :type,
    :html_type,
    :renderer,
    :index_renderer,
    :edit_renderer,
    :show_renderer,
    :resource,
    :label,
    :placeholder,
    :length,
    :precision,
    :scale,
    :hidden,
    :readonly,
    :required,
    :disabled,
    :omitted,
    :filterable?,
    :sortable?,
    :option_label,
    :expanded,
    :upload,
    :data
  ]

  defstruct [:key, :order_by, :where | @field_keys]

  @type t() :: %__MODULE__{
          key: atom() | tuple(),
          type: atom() | nil,
          html_type: atom() | binary() | nil,
          renderer: function() | atom() | nil,
          index_renderer: function() | atom() | nil,
          edit_renderer: function() | atom() | nil,
          show_renderer: function() | atom() | nil,
          resource: atom() | nil,
          label: binary() | nil,
          placeholder: binary() | nil,
          length: non_neg_integer() | nil,
          precision: non_neg_integer() | nil,
          scale: non_neg_integer() | nil,
          hidden: boolean() | nil,
          readonly: boolean() | nil,
          required: boolean() | nil,
          disabled: boolean() | nil,
          omitted: boolean() | nil,
          filterable?: boolean() | nil,
          sortable?: boolean() | nil,
          option_label: atom() | function() | nil,
          order_by: term(),
          where: term(),
          expanded: boolean() | function() | nil,
          upload: Upload.t() | nil,
          data: term()
        }

  @doc """
  Builds a field override from the options of a `field` entry.

  ## Parameters
  - `key` (atom() | tuple()) - The field the override applies to.
  - `opts` (keyword()) - The field options.

  ## Returns
  `Aurora.Uix.Field.Override.t()` - The override.

  ## Examples
  ```elixir
  Aurora.Uix.Field.Override.new(:name, required: true, label: "Name")
  # => %Aurora.Uix.Field.Override{key: :name, required: true, label: "Name", ...}
  ```
  """
  @spec new(atom() | tuple(), keyword()) :: t()
  def new(key, opts) do
    {special, options} = Keyword.split(opts, [:data, :upload])

    __MODULE__
    |> struct(options)
    |> struct(%{key: key})
    |> put_upload(special[:upload])
    |> put_data(special[:data])
  end

  @doc """
  Merges two overrides of the same field; the options set in `override` win.

  ## Parameters
  - `base` (t()) - The earlier override.
  - `override` (t()) - The later override.

  ## Returns
  `Aurora.Uix.Field.Override.t()` - The combined override.
  """
  @spec merge(t(), t()) :: t()
  def merge(%__MODULE__{} = base, %__MODULE__{} = override) do
    override
    |> Map.from_struct()
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> then(&struct(base, &1))
  end

  @doc """
  Returns the changes the override makes to an `Aurora.Uix.Field`, as a map of field keys.

  ## Parameters
  - `field_override` (t()) - The override.

  ## Returns
  `map()` - The set options, with `:order_by` and `:where` folded into `:query_opts`.
  """
  @spec to_field_changes(t()) :: map()
  def to_field_changes(%__MODULE__{} = field_override) do
    query_opts =
      Enum.reject([order_by: field_override.order_by, where: field_override.where], fn
        {_key, value} -> is_nil(value)
      end)

    field_override
    |> Map.take(@field_keys)
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
    |> maybe_put_query_opts(query_opts)
  end

  ## PRIVATE

  @spec put_data(t(), term()) :: t()
  defp put_data(field_override, nil), do: field_override

  defp put_data(field_override, %{upload: upload} = data) do
    rest = Map.delete(data, :upload)

    field_override
    |> put_upload(upload)
    |> put_data(if rest == %{}, do: nil, else: rest)
  end

  defp put_data(field_override, data), do: struct(field_override, %{data: data})

  @spec put_upload(t(), map() | keyword() | Upload.t() | nil) :: t()
  defp put_upload(field_override, nil), do: field_override

  defp put_upload(field_override, %Upload{} = upload),
    do: struct(field_override, %{upload: upload})

  defp put_upload(field_override, upload),
    do: struct(field_override, %{upload: Upload.new(upload)})

  @spec maybe_put_query_opts(map(), keyword()) :: map()
  defp maybe_put_query_opts(changes, []), do: changes
  defp maybe_put_query_opts(changes, query_opts), do: Map.put(changes, :query_opts, query_opts)
end
