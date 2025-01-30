defmodule AuroraUix.Metadata do
  @moduledoc """
  Provides a structure and functions to manage metadata for schemas and contexts.

  The `AuroraUix.Metadata` module defines a struct that holds metadata information
  about a schema, its context, and additional fields. It also provides functions
  to create and update this metadata.
  """

  defstruct [:schema, :context, fields: %{}]

  @type t() :: %__MODULE__{
      schema: module,
      context: module | nil,
      fields: map
    }

  @doc """
  Creates a new `AuroraUix.Metadata` struct with the given attributes.

  ## Parameters

  - `attrs`: A map or keyword list containing the attributes to initialize the metadata.
    The allowed keys are `:schema`, `:context`, and `:fields`.

  ## Examples

      iex> AuroraUix.Metadata.new()
      %AuroraUix.Metadata{schema: nil, context: nil, fields: %{}}

      iex> AuroraUix.Metadata.new(%{schema: MySchema, fields: %{custom_field: "value"}})
      %AuroraUix.Metadata{
        schema: MySchema,
        context: nil,
        fields: %{custom_field: "value"}
      }
  """
  @spec new(map | keyword) :: __MODULE__.t()
  def new(attrs \\ %{}), do: change(%__MODULE__{}, attrs)

  @doc """
  Updates an existing `AuroraUix.Metadata` struct with the given attributes.

  ## Parameters

  - `metadata`: The existing `AuroraUix.Metadata` struct to be updated.
  - `attrs`: A map or keyword list containing the attributes to update the metadata.
    The allowed keys are `:schema`, `:context`, and `:fields`.

  ## Examples

      iex> metadata = %AuroraUix.Metadata{schema: MySchema, context: MyContext, fields: %{}}
      iex> AuroraUix.Metadata.change(metadata, context: nil, fields: %{new_field: "value"})
      %AuroraUix.Metadata{
        schema: MySchema,
        context: nil,
        fields: %{new_field: "value"}
      }

      iex> metadata = %AuroraUix.Metadata{schema: MySchema, context: MyContext, fields: %{}}
      iex> AuroraUix.Metadata.change(metadata, %{fields: %{updated_field: "new_value"}})
      %AuroraUix.Metadata{
        schema: MySchema,
        context: MyContext,
        fields: %{updated_field: "new_value"}
      }
  """
  @spec change(__MODULE__.t(), map | keyword) :: __MODULE__.t()
  def change(metadata, attrs) when is_list(attrs) do
    keys = Map.keys(%__MODULE__{})

    attrs
    |> Enum.filter(&(elem(&1, 0) in keys))
    |> Map.new()
    |> then(&struct(metadata, &1))
  end

  def change(metadata, %{} = attrs), do: struct(metadata, attrs)
end
