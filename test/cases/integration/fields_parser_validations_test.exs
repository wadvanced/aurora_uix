defmodule Aurora.Uix.Test.Cases.Integration.FieldsParserValidations do
  @moduledoc """
  Field validation fixtures for integration testing.

  Provides expected field configurations for various Ecto/Ash types to validate field
  parser implementations. Contains fixture data representing all standard field types
  with their expected metadata, labels, placeholders, and display properties.

  ## Key Features

  - Comprehensive field type fixtures (all Ecto/Ash types)
  - Validation map comparison utilities
  - Module prefix replacement for dynamic schema testing
  - Field metadata expectations for integration tests

  ## Key Constraints

  - Designed specifically for test validations
  - Returns predefined fixture data, not dynamic values
  - Module prefixes must be valid Elixir module names
  """

  @doc """
  Retrieves validation fixtures for a specific field type set.

  Returns a map of expected field configurations for testing field parser implementations.
  Supports dynamic module prefix replacement via options.

  ## Parameters

  - `type` (atom()) - The fixture type to retrieve (e.g., `:all_types`).
  - `opts` (keyword()) - Options for customization:
    * `:owner_prefix` (binary()) - Prefix for owner module in association data.
    * `:related_prefix` (binary()) - Prefix for related module in association data.

  ## Returns

  map() - Map of field keys to their expected configuration maps.
  """
  @spec get(atom(), keyword()) :: map()
  def get(type, opts \\ [])

  def get(:all_types, opts) do
    apply_opts(
      %{
        id: %{
          data: %{},
          disabled: true,
          hidden: false,
          label: "Id",
          name: "id",
          type: :integer,
          length: 10,
          key: :id,
          precision: 10,
          resource: :all_types,
          required: false,
          readonly: false,
          placeholder: "0",
          scale: 0,
          filterable?: true,
          html_type: :number,
          omitted: false,
          renderer: nil
        },
        field_binary_id: %{
          data: %{},
          disabled: false,
          hidden: false,
          label: "Field Binary Id",
          name: "field_binary_id",
          type: :binary_id,
          length: 36,
          key: :field_binary_id,
          precision: 0,
          resource: :all_types,
          required: false,
          readonly: false,
          placeholder: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA",
          scale: 0,
          filterable?: true,
          html_type: :text,
          omitted: false,
          renderer: nil
        },
        field_integer: %{
          data: %{},
          disabled: false,
          hidden: false,
          label: "Field Integer",
          name: "field_integer",
          type: :integer,
          length: 10,
          key: :field_integer,
          precision: 10,
          resource: :all_types,
          required: false,
          readonly: false,
          placeholder: "0",
          scale: 0,
          filterable?: true,
          html_type: :number,
          omitted: false,
          renderer: nil
        },
        field_float: %{
          data: %{},
          disabled: false,
          hidden: false,
          label: "Field Float",
          name: "field_float",
          type: :float,
          length: 12,
          key: :field_float,
          precision: 10,
          resource: :all_types,
          required: false,
          readonly: false,
          placeholder: "0",
          scale: 2,
          filterable?: true,
          html_type: :number,
          omitted: false,
          renderer: nil
        },
        field_boolean: %{
          data: %{},
          disabled: false,
          hidden: false,
          label: "Field Boolean",
          name: "field_boolean",
          type: :boolean,
          length: 5,
          key: :field_boolean,
          precision: 0,
          resource: :all_types,
          required: false,
          readonly: false,
          placeholder: "",
          scale: 0,
          filterable?: true,
          html_type: :checkbox,
          omitted: false,
          renderer: nil
        },
        field_string: %{
          data: %{},
          disabled: false,
          hidden: false,
          label: "Field String",
          name: "field_string",
          type: :string,
          length: 255,
          key: :field_string,
          precision: 0,
          resource: :all_types,
          required: false,
          readonly: false,
          placeholder: "Field String",
          scale: 0,
          filterable?: true,
          html_type: :text,
          omitted: false,
          renderer: nil
        },
        field_binary: %{
          data: %{},
          disabled: false,
          hidden: false,
          label: "Field Binary",
          name: "field_binary",
          type: :binary,
          length: 255,
          key: :field_binary,
          precision: 0,
          resource: :all_types,
          required: false,
          readonly: false,
          placeholder: "Field Binary",
          scale: 0,
          filterable?: true,
          html_type: :text,
          omitted: false,
          renderer: nil
        },
        field_bitstring: %{
          data: %{},
          disabled: false,
          hidden: false,
          label: "Field Bitstring",
          name: "field_bitstring",
          type: :bitstring,
          length: 255,
          key: :field_bitstring,
          precision: 0,
          resource: :all_types,
          required: false,
          readonly: false,
          placeholder: "Field Bitstring",
          scale: 0,
          filterable?: true,
          html_type: :text,
          omitted: false,
          renderer: nil
        },
        field_decimal: %{
          data: %{},
          disabled: false,
          hidden: false,
          label: "Field Decimal",
          name: "field_decimal",
          type: :decimal,
          length: 12,
          key: :field_decimal,
          precision: 10,
          resource: :all_types,
          required: false,
          readonly: false,
          placeholder: "0",
          scale: 2,
          filterable?: true,
          html_type: :number,
          omitted: false,
          renderer: nil
        },
        field_date: %{
          data: %{},
          disabled: false,
          hidden: false,
          label: "Field Date",
          name: "field_date",
          type: :date,
          length: 50,
          key: :field_date,
          precision: 0,
          resource: :all_types,
          required: false,
          readonly: false,
          placeholder: "",
          scale: 0,
          filterable?: true,
          html_type: :date,
          omitted: false,
          renderer: nil
        },
        field_time: %{
          data: %{},
          disabled: false,
          hidden: false,
          label: "Field Time",
          name: "field_time",
          type: :time,
          length: 10,
          key: :field_time,
          precision: 0,
          resource: :all_types,
          required: false,
          readonly: false,
          placeholder: "",
          scale: 0,
          filterable?: true,
          html_type: :time,
          omitted: false,
          renderer: nil
        },
        field_time_usec: %{
          data: %{step: 1},
          disabled: false,
          hidden: false,
          label: "Field Time Usec",
          name: "field_time_usec",
          type: :time_usec,
          length: 10,
          key: :field_time_usec,
          precision: 0,
          resource: :all_types,
          required: false,
          readonly: false,
          placeholder: "",
          scale: 0,
          filterable?: true,
          html_type: :time,
          omitted: false,
          renderer: nil
        },
        field_naive_datetime: %{
          data: %{},
          disabled: false,
          hidden: false,
          label: "Field Naive Datetime",
          name: "field_naive_datetime",
          type: :naive_datetime,
          length: 17,
          key: :field_naive_datetime,
          precision: 0,
          resource: :all_types,
          required: false,
          readonly: false,
          placeholder: "",
          scale: 0,
          filterable?: true,
          html_type: :"datetime-local",
          omitted: false,
          renderer: nil
        },
        field_naive_datetime_usec: %{
          data: %{step: 1},
          disabled: false,
          hidden: false,
          label: "Field Naive Datetime Usec",
          name: "field_naive_datetime_usec",
          type: :naive_datetime_usec,
          length: 20,
          key: :field_naive_datetime_usec,
          precision: 0,
          resource: :all_types,
          required: false,
          readonly: false,
          placeholder: "",
          scale: 0,
          filterable?: true,
          html_type: :"datetime-local",
          omitted: false,
          renderer: nil
        },
        field_utc_datetime: %{
          data: %{},
          disabled: false,
          hidden: false,
          label: "Field Utc Datetime",
          name: "field_utc_datetime",
          type: :utc_datetime,
          length: 17,
          key: :field_utc_datetime,
          precision: 0,
          resource: :all_types,
          required: false,
          readonly: false,
          placeholder: "",
          scale: 0,
          filterable?: true,
          html_type: :"datetime-local",
          omitted: false,
          renderer: nil
        },
        field_utc_datetime_usec: %{
          data: %{step: 1},
          disabled: false,
          hidden: false,
          label: "Field Utc Datetime Usec",
          name: "field_utc_datetime_usec",
          type: :utc_datetime_usec,
          length: 20,
          key: :field_utc_datetime_usec,
          precision: 0,
          resource: :all_types,
          required: false,
          readonly: false,
          placeholder: "",
          scale: 0,
          filterable?: true,
          html_type: :"datetime-local",
          omitted: false,
          renderer: nil
        },
        field_duration: %{
          data: %{},
          disabled: false,
          hidden: false,
          label: "Field Duration",
          name: "field_duration",
          type: :duration,
          length: 50,
          key: :field_duration,
          precision: 0,
          resource: :all_types,
          required: false,
          readonly: false,
          placeholder: "",
          scale: 0,
          filterable?: true,
          html_type: :text,
          omitted: false,
          renderer: nil
        },
        field_status: %{
          key: :field_status,
          type: :string,
          html_type: :select,
          renderer: nil,
          resource: :all_types,
          name: "field_status",
          label: "Field Status",
          placeholder: "",
          length: 9,
          precision: 0,
          scale: 0,
          hidden: false,
          readonly: false,
          required: false,
          disabled: false,
          omitted: false,
          filterable?: true,
          data: %{
            select: %{
              opts: [
                {"Draft", :draft},
                {"Published", :published},
                {"Archived", :archived}
              ],
              multiple: false
            }
          }
        },
        embeds_many: %{
          key: :embeds_many,
          type: :embeds_many,
          html_type: :unimplemented,
          renderer: nil,
          resource: :all_types,
          name: "embeds_many",
          label: "All Types Embeds Many",
          placeholder: "",
          length: 50,
          precision: 0,
          scale: 0,
          hidden: false,
          readonly: false,
          required: false,
          disabled: false,
          omitted: false,
          filterable?: true,
          data: %{
            owner: Aurora.Uix.Test.Cases.Integration.Ctx.FieldsParserTest.AllTypes,
            resource: :all_types__embeds_many,
            related: Aurora.Uix.Test.Cases.Integration.Ctx.FieldsParserTest.AllTypes.EmbedsMany
          }
        },
        embeds_one: %{
          key: :embeds_one,
          type: :embeds_one,
          html_type: :unimplemented,
          renderer: nil,
          resource: :all_types,
          name: "embeds_one",
          label: "All Types Embeds One",
          placeholder: "",
          length: 50,
          precision: 0,
          scale: 0,
          hidden: false,
          readonly: false,
          required: false,
          disabled: false,
          omitted: false,
          filterable?: true,
          data: %{
            owner: Aurora.Uix.Test.Cases.Integration.Ctx.FieldsParserTest.AllTypes,
            resource: :all_types__embeds_one,
            related: Aurora.Uix.Test.Cases.Integration.Ctx.FieldsParserTest.AllTypes.EmbedsOne
          }
        }
      },
      opts
    )
  end

  def get(:with_associations, opts) do
    :all_types
    |> get()
    |> Map.merge(%{
      belongs_to_field_id: %{
        key: :belongs_to_field_id,
        type: :binary_id,
        html_type: :text,
        renderer: nil,
        resource: :all_types,
        name: "belongs_to_field_id",
        label: "Belongs To Field Id",
        placeholder: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA",
        length: 36,
        precision: 0,
        scale: 0,
        hidden: false,
        readonly: false,
        required: false,
        disabled: false,
        omitted: false,
        filterable?: true,
        data: %{}
      },
      has_many_field: %{
        key: :has_many_field,
        type: :one_to_many_association,
        html_type: :unimplemented,
        renderer: nil,
        resource: :all_types,
        name: "has_many_field",
        label: "",
        placeholder: "",
        length: 0,
        precision: 0,
        scale: 0,
        hidden: false,
        readonly: false,
        required: false,
        disabled: false,
        omitted: false,
        filterable?: false,
        data: %{
          resource: nil,
          owner_key: :id,
          related: Aurora.Uix.Test.Cases.Integration.Ctx.FieldsParserTest.HasManyRelationship,
          related_key: :all_types_id
        }
      },
      belongs_to_field: %{
        key: :belongs_to_field,
        type: :many_to_one_association,
        html_type: :unimplemented,
        renderer: nil,
        resource: :all_types,
        name: "belongs_to_field",
        label: "",
        placeholder: "",
        length: 0,
        precision: 0,
        scale: 0,
        hidden: false,
        readonly: false,
        required: false,
        disabled: false,
        omitted: false,
        filterable?: false,
        data: %{
          resource: nil,
          owner_key: :belongs_to_field_id,
          related: Aurora.Uix.Test.Cases.Integration.Ctx.FieldsParserTest.BelongsToRelationship,
          related_key: :id
        }
      }
    })
    |> apply_opts(opts)
  end

  @doc """
  Compares validation fixtures against generated field maps.

  Validates that generated fields match expected fixture data, reporting all differences
  found between expected and actual values.

  ## Parameters

  - `validations` (map()) - Expected field configurations from fixtures.
  - `generated` (map()) - Generated field configurations to validate.

  ## Returns

  list(binary()) - List of error messages for mismatches, or empty list if all match.
  """
  @spec compare_maps(map(), map()) :: list(binary())
  def compare_maps(validations, generated) do
    validations
    |> Map.keys()
    |> Enum.map(fn key ->
      validation = Map.get(validations, key)
      current = Map.get(generated, key)

      if is_nil(current) do
        ["#{key} does not exist in the generated artifact"]
      else
        validation
        |> Map.keys()
        |> Enum.filter(&(Map.get(validation, &1) != Map.get(current, &1)))
        |> Enum.map(
          &"#{key} on field: #{&1} got: #{inspect(Map.get(current, &1))}, expected: #{inspect(Map.get(validation, &1))}"
        )
      end
    end)
    |> Enum.reject(&(&1 == []))
    |> List.flatten()
  end

  ## PRIVATE

  # Applies option transformations to validation fixtures.
  @spec apply_opts(map(), keyword()) :: map()
  defp apply_opts(validations, opts) do
    Enum.reduce(opts, validations, &apply_opt/2)
  end

  # Applies a single option transformation to validation fixtures.
  @spec apply_opt({atom(), term()}, map()) :: map()
  defp apply_opt({:owner_prefix, prefix}, validations),
    do: replace_data_key(validations, :owner, prefix)

  defp apply_opt({:related_prefix, prefix}, validations),
    do: replace_data_key(validations, :related, prefix)

  defp apply_opt(_opts, validations), do: validations

  # Replaces module references in data key with new prefix.
  @spec replace_data_key(map(), atom(), binary()) :: map()
  defp replace_data_key(validations, data_key, prefix) do
    validations
    |> Enum.map(fn {key, validation} ->
      new_validation =
        if validation[:data][data_key] do
          replace_module(validation, data_key, prefix)
        else
          validation
        end

      {key, new_validation}
    end)
    |> Map.new()
  end

  # Replaces module name in validation data with prefixed version.
  @spec replace_module(map(), atom(), binary()) :: map()
  defp replace_module(validation, data_key, prefix) do
    validation
    |> get_in([Access.key!(:data), data_key])
    |> Module.split()
    |> Enum.reverse()
    |> List.first()
    |> append_prefix(prefix)
    |> then(&put_in(validation, [Access.key!(:data), data_key], &1))
  end

  # Appends prefix to module name, handling empty prefix case.
  @spec append_prefix(binary(), binary()) :: module()
  defp append_prefix(module, "") do
    {result, _} = Code.eval_string(module)
    result
  end

  defp append_prefix(module, prefix), do: Module.concat(prefix, module)
end
