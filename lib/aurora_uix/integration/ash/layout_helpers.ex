defmodule Aurora.Uix.Integration.Ash.LayoutHelpers do
  @moduledoc """
  Provides helper functions for converting Ash Framework types to Ecto types.

  This module facilitates type mapping between Ash resources and Ecto schemas,
  enabling proper field type resolution for layout and form generation.

  ## Key Features

  - Comprehensive mapping of Ash types to Ecto-compatible types
  - Support for both parameterized Ash types and their EctoType variants
  - Fallback handling for unknown or custom types
  - Direct passthrough for native Ecto types

  ## Key Constraints

  - Only handles parameterized Ash types in tuple format `{:parameterized, {type, opts}}`
  - Unknown parameterized types default to `:string`
  - Requires Ash Framework type structure
  """

  alias Aurora.Uix.Helpers.Common, as: CommonHelper

  @doc """
  Converts an Ash type to its corresponding Ecto type.

  ## Parameters
  - `type` (tuple() | atom()) - The Ash type to convert.
  - `_ass_emb` (map() | nil) - Association or embedding metadata (currently unused).

  ## Returns
  atom() - The corresponding Ecto type atom.

  ## Examples
      iex> field_type({:parameterized, {Ash.Type.String, []}}, nil)
      :string

      iex> field_type({:parameterized, {Ash.Type.Integer, []}}, nil)
      :integer

      iex> field_type({:parameterized, {Ash.Type.UUID, []}}, nil)
      :binary_id

      iex> field_type(:string, nil)
      :string
  """
  @spec field_type(tuple() | atom(), map() | nil) :: atom()
  def field_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [
             Ash.Type.String,
             Ash.Type.String.EctoType,
             Ash.Type.CiString,
             Ash.Type.CiString.EctoType,
             Ash.Type.Atom,
             Ash.Type.Atom.EctoType,
             Ash.Type.DurationName,
             Ash.Type.DurationName.EctoType,
             Ash.Type.Enum,
             Ash.Type.Enum.EctoType
           ],
      do: :string

  def field_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [Ash.Type.UUID, Ash.Type.UUID.EctoType],
      do: :binary_id

  def field_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [
             Ash.Type.Integer,
             Ash.Type.Integer.EctoType
           ],
      do: :integer

  def field_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [Ash.Type.Float, Ash.Type.Float.EctoType],
      do: :float

  def field_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [Ash.Type.Decimal, Ash.Type.Decimal.EctoType],
      do: :decimal

  def field_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [Ash.Type.Boolean, Ash.Type.Boolean.EctoType],
      do: :boolean

  def field_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [Ash.Type.Date, Ash.Type.Date.EctoType],
      do: :date

  def field_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [Ash.Type.Time, Ash.Type.Time.EctoType],
      do: :time

  def field_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [
             Ash.Type.DateTime,
             Ash.Type.DateTime.EctoType,
             Ash.Type.UtcDatetime,
             Ash.Type.UtcDatetime.EctoType
           ],
      do: :utc_datetime

  def field_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [
             Ash.Type.UtcDatetimeUsec,
             Ash.Type.UtcDatetimeUsec.EctoType
           ],
      do: :utc_datetime_usec

  def field_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [
             Ash.Type.NaiveDatetime,
             Ash.Type.NaiveDatetime.EctoType
           ],
      do: :naive_datetime

  def field_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [Ash.Type.Binary, Ash.Type.Binary.EctoType],
      do: :binary

  def field_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [
             Ash.Type.UrlEncodedBinary,
             Ash.Type.UrlEncodedBinary.EctoType
           ],
      do: :binary

  def field_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [
             Ash.Type.Map,
             Ash.Type.Map.EctoType,
             Ash.Type.Keyword,
             Ash.Type.Keyword.EctoType,
             Ash.Type.Term,
             Ash.Type.Term.EctoType,
             Ash.Type.Tuple,
             Ash.Type.Tuple.EctoType,
             Ash.Type.Struct,
             Ash.Type.Struct.EctoType,
             Ash.Type.Union,
             Ash.Type.Union.EctoType
           ],
      do: :map

  # Fallback for other parameterized types
  def field_type({:parameterized, {_other_types, _opts}}, _ass_emb), do: :string

  # Direct type passthrough
  def field_type(type, nil), do: type

  @doc """
  Maps an Ash type to an HTML input type.

  ## Parameters
  - `type` (tuple() | atom()) - The Ash type to map.
  - `_ass_emb` (map() | nil) - Association or embedding metadata (currently unused).

  ## Returns
  atom() - The HTML5 input type.

  ## Examples
      iex> field_html_type({:parameterized, {Ash.Type.String, []}}, nil)
      :text

      iex> field_html_type({:parameterized, {Ash.Type.Integer, []}}, nil)
      :number

      iex> field_html_type({:parameterized, {Ash.Type.Boolean, []}}, nil)
      :checkbox

      iex> field_html_type({:parameterized, {Ash.Type.DateTime, []}}, nil)
      :"datetime-local"
  """
  @spec field_html_type(tuple() | atom(), map() | nil) :: atom()
  def field_html_type({:parameterized, {type, opts}}, _ass_emb)
      when type in [
             Ash.Type.Atom,
             Ash.Type.Atom.EctoType,
             Ash.Type.String,
             Ash.Type.String.EctoType
           ] do
    if Keyword.has_key?(opts, :one_of), do: :select, else: :text
  end

  def field_html_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [
             Ash.Type.CiString,
             Ash.Type.CiString.EctoType,
             Ash.Type.UUID,
             Ash.Type.UUID.EctoType,
             Ash.Type.Binary,
             Ash.Type.Binary.EctoType,
             Ash.Type.UrlEncodedBinary,
             Ash.Type.UrlEncodedBinary.EctoType,
             Ash.Type.DurationName,
             Ash.Type.DurationName.EctoType
           ],
      do: :text

  def field_html_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [
             Ash.Type.Integer,
             Ash.Type.Integer.EctoType,
             Ash.Type.Float,
             Ash.Type.Float.EctoType,
             Ash.Type.Decimal,
             Ash.Type.Decimal.EctoType
           ],
      do: :number

  def field_html_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [Ash.Type.Boolean, Ash.Type.Boolean.EctoType],
      do: :checkbox

  def field_html_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [Ash.Type.Date, Ash.Type.Date.EctoType],
      do: :date

  def field_html_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [Ash.Type.Time, Ash.Type.Time.EctoType],
      do: :time

  def field_html_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [
             Ash.Type.DateTime,
             Ash.Type.DateTime.EctoType,
             Ash.Type.UtcDatetime,
             Ash.Type.UtcDatetime.EctoType,
             Ash.Type.UtcDatetimeUsec,
             Ash.Type.UtcDatetimeUsec.EctoType,
             Ash.Type.NaiveDatetime,
             Ash.Type.NaiveDatetime.EctoType
           ],
      do: :"datetime-local"

  def field_html_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [Ash.Type.Enum, Ash.Type.Enum.EctoType],
      do: :select

  def field_html_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [
             Ash.Type.Map,
             Ash.Type.Map.EctoType,
             Ash.Type.Keyword,
             Ash.Type.Keyword.EctoType,
             Ash.Type.Term,
             Ash.Type.Term.EctoType,
             Ash.Type.Tuple,
             Ash.Type.Tuple.EctoType,
             Ash.Type.Struct,
             Ash.Type.Struct.EctoType,
             Ash.Type.Union,
             Ash.Type.Union.EctoType
           ],
      do: :textarea

  # Fallback for other parameterized types
  def field_html_type({:parameterized, {_other_types, _opts}}, _ass_emb), do: :text

  # Direct type passthrough
  def field_html_type(type, nil), do: type

  @doc """
  Determines the display length for an Ash field based on its type.

  ## Parameters
  - `type` (tuple() | atom()) - The Ash type to determine the length for.

  ## Returns
  integer() - The suggested display length in characters.

  ## Examples
      iex> field_length({:parameterized, {Ash.Type.String, []}})
      255

      iex> field_length({:parameterized, {Ash.Type.Integer, []}})
      10

      iex> field_length({:parameterized, {Ash.Type.Boolean, []}})
      5
  """
  @spec field_length(tuple() | atom()) :: integer()
  def field_length({:parameterized, {type, _opts}})
      when type in [
             Ash.Type.String,
             Ash.Type.String.EctoType,
             Ash.Type.CiString,
             Ash.Type.CiString.EctoType,
             Ash.Type.Atom,
             Ash.Type.Atom.EctoType,
             Ash.Type.Binary,
             Ash.Type.Binary.EctoType
           ],
      do: 255

  def field_length({:parameterized, {type, _opts}})
      when type in [Ash.Type.UUID, Ash.Type.UUID.EctoType],
      do: 36

  def field_length({:parameterized, {type, _opts}})
      when type in [Ash.Type.Integer, Ash.Type.Integer.EctoType],
      do: 10

  def field_length({:parameterized, {type, _opts}})
      when type in [
             Ash.Type.Float,
             Ash.Type.Float.EctoType,
             Ash.Type.Decimal,
             Ash.Type.Decimal.EctoType
           ],
      do: 12

  def field_length({:parameterized, {type, _opts}})
      when type in [
             Ash.Type.DateTime,
             Ash.Type.DateTime.EctoType,
             Ash.Type.UtcDatetime,
             Ash.Type.UtcDatetime.EctoType,
             Ash.Type.UtcDatetimeUsec,
             Ash.Type.UtcDatetimeUsec.EctoType,
             Ash.Type.NaiveDatetime,
             Ash.Type.NaiveDatetime.EctoType
           ],
      do: 20

  def field_length({:parameterized, {type, _opts}})
      when type in [Ash.Type.Time, Ash.Type.Time.EctoType],
      do: 10

  def field_length({:parameterized, {type, _opts}})
      when type in [Ash.Type.Date, Ash.Type.Date.EctoType],
      do: 10

  def field_length({:parameterized, {type, _opts}})
      when type in [Ash.Type.Boolean, Ash.Type.Boolean.EctoType],
      do: 5

  def field_length({:parameterized, {_type, _opts}}), do: 50

  def field_length(_type), do: 50

  @doc """
  Gets the numeric precision for Ash number fields.

  ## Parameters
  - `type` (tuple() | atom()) - The Ash field type to check.

  ## Returns
  integer() - The numeric precision, or `0` for non-numeric types.

  ## Examples
      iex> field_precision({:parameterized, {Ash.Type.Integer, []}})
      10

      iex> field_precision({:parameterized, {Ash.Type.Decimal, []}})
      10

      iex> field_precision({:parameterized, {Ash.Type.String, []}})
      0
  """
  @spec field_precision(tuple() | atom()) :: integer()
  def field_precision({:parameterized, {type, _opts}})
      when type in [
             Ash.Type.Integer,
             Ash.Type.Integer.EctoType,
             Ash.Type.Float,
             Ash.Type.Float.EctoType,
             Ash.Type.Decimal,
             Ash.Type.Decimal.EctoType
           ],
      do: 10

  def field_precision({:parameterized, {_type, _opts}}), do: 0

  def field_precision(_type), do: 0

  @doc """
  Gets the numeric scale for Ash decimal/float fields.

  ## Parameters
  - `type` (tuple() | atom()) - The Ash field type to check.

  ## Returns
  integer() - The numeric scale, or `0` for non-decimal types.

  ## Examples
      iex> field_scale({:parameterized, {Ash.Type.Float, []}})
      2

      iex> field_scale({:parameterized, {Ash.Type.Decimal, []}})
      2

      iex> field_scale({:parameterized, {Ash.Type.Integer, []}})
      0
  """
  @spec field_scale(tuple() | atom()) :: integer()
  def field_scale({:parameterized, {type, _opts}})
      when type in [
             Ash.Type.Float,
             Ash.Type.Float.EctoType,
             Ash.Type.Decimal,
             Ash.Type.Decimal.EctoType
           ],
      do: 2

  def field_scale({:parameterized, {_type, _opts}}), do: 0

  def field_scale(_type), do: 0

  @doc """
  Determines if an Ash field should be filterable in queries.

  ## Parameters
  - `type` (tuple() | atom()) - The Ash field type to check.

  ## Returns
  boolean() - Returns `true` if the field supports filtering, otherwise `false`.

  ## Examples
      iex> field_filterable({:parameterized, {Ash.Type.String, []}})
      true

      iex> field_filterable({:parameterized, {Ash.Type.Map, []}})
      false
  """
  @spec field_filterable(tuple() | atom()) :: boolean()
  def field_filterable({:parameterized, {type, _opts}})
      when type in [
             Ash.Type.Map,
             Ash.Type.Map.EctoType,
             Ash.Type.Term,
             Ash.Type.Term.EctoType,
             Ash.Type.Tuple,
             Ash.Type.Tuple.EctoType,
             Ash.Type.Struct,
             Ash.Type.Struct.EctoType,
             Ash.Type.Union,
             Ash.Type.Union.EctoType
           ],
      do: false

  def field_filterable({:parameterized, {_type, _opts}}), do: true

  def field_filterable(_type), do: true

  @doc """
  Extracts metadata for Ash field types.

  ## Parameters
  - `_association_or_embed` (map() | nil) - Association or embed metadata (unused).
  - `_resource_name` (atom() | nil) - The resource name (unused).
  - `type` (tuple() | atom()) - The Ash field type.

  ## Returns
  map() - A metadata map with select options for constrained types, empty map otherwise.

  ## Examples
      iex> field_data(nil, nil, {:parameterized, {Ash.Type.Atom, [one_of: [:active, :inactive]]}})
      %{select: %{opts: [active: "Active", inactive: "Inactive"], multiple: false}}

      iex> field_data(nil, nil, {:parameterized, {Ash.Type.String, [one_of: ["red", "blue"]]}})
      %{select: %{opts: [{"red", "Red"}, {"blue", "Blue"}], multiple: false}}

      iex> field_data(nil, nil, {:parameterized, {Ash.Type.Integer, []}})
      %{}
  """
  @spec field_data(map() | nil, atom() | nil, tuple() | atom()) :: map()
  def field_data(_association_or_embed, _resource_name, {:parameterized, {type, opts}})
      when type in [
             Ash.Type.Atom,
             Ash.Type.Atom.EctoType,
             Ash.Type.String,
             Ash.Type.String.EctoType
           ] do
    if Keyword.has_key?(opts, :one_of) do
      opts[:one_of]
      |> Enum.map(&{&1, CommonHelper.capitalize(&1)})
      |> then(&%{select: %{opts: &1, multiple: false}})
    else
      %{}
    end
  end

  def field_data(_association_or_embed, _resource_name, _type), do: %{}
end
