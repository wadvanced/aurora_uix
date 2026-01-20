defmodule Aurora.Uix.Layout.AshHelper do
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

  @doc """
  Converts an Ash type to its corresponding Ecto type.

  ## Parameters

  - `type` (tuple() | atom()) - The Ash type to convert. Can be a parameterized type tuple
    `{:parameterized, {Ash.Type.*, opts}}` or a direct atom type.
  - `_ass_emb` (map() | nil) - Association or embedding metadata (currently unused).

  ## Returns

  atom() - The corresponding Ecto type atom (e.g., `:string`, `:integer`, `:map`).

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
  @spec field_type(atom() | tuple(), map() | nil) :: atom()
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

  Provides appropriate HTML5 input types based on the Ash data type, enabling proper
  browser validation and input handling for forms generated from Ash resources.

  ## Parameters

  - `type` (tuple() | atom()) - The Ash type to map. Can be a parameterized type tuple
    `{:parameterized, {Ash.Type.*, opts}}` or a direct atom type.
  - `_ass_emb` (map() | nil) - Association or embedding metadata (currently unused).

  ## Returns

  atom() - The HTML5 input type (e.g., `:text`, `:number`, `:checkbox`).

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
  @spec field_html_type(atom() | tuple(), map() | nil) :: atom()
  def field_html_type({:parameterized, {type, _opts}}, _ass_emb)
      when type in [
             Ash.Type.String,
             Ash.Type.String.EctoType,
             Ash.Type.CiString,
             Ash.Type.CiString.EctoType,
             Ash.Type.UUID,
             Ash.Type.UUID.EctoType,
             Ash.Type.Atom,
             Ash.Type.Atom.EctoType,
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

  Sets sensible default length constraints that work well for most UI scenarios,
  considering typical data ranges for each Ash type.

  ## Parameters

  - `type` (tuple() | atom()) - The Ash type to determine the length for. Can be a
    parameterized type tuple `{:parameterized, {Ash.Type.*, opts}}` or a direct atom type.

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
  @spec field_length(atom() | tuple()) :: integer()
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

  Returns the total number of significant digits for numeric types.

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
  @spec field_precision(atom() | tuple()) :: integer()
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

  Returns the number of digits after the decimal point.

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
  @spec field_scale(atom() | tuple()) :: integer()
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

  boolean() - `true` if the field supports filtering, otherwise `false`.

  ## Examples

      iex> field_filterable({:parameterized, {Ash.Type.String, []}})
      true

      iex> field_filterable({:parameterized, {Ash.Type.Map, []}})
      false
  """
  @spec field_filterable(atom() | tuple()) :: boolean()
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
end
