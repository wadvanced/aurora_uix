defmodule Aurora.Uix.Test.Cases.IntegrationCtxTest do
  use ExUnit.Case
  alias Aurora.Uix.Integration.Ctx

  defmodule AllTypes do
    use Ecto.Schema

    schema "test_all_types" do
      field :field_binary_id, :binary_id
      field :field_integer, :integer
      field :field_float, :float
      field :field_boolean, :boolean
      field :field_string, :string
      field :field_binary, :binary
      field :field_bitstring, :bitstring
      field :field_decimal, :decimal
      field :field_date, :date
      field :field_time, :time
      field :field_time_usec, :time_usec
      field :field_naive_datetime, :naive_datetime
      field :field_naive_datetime_usec, :naive_datetime_usec
      field :field_utc_datetime, :utc_datetime
      field :field_utc_datetime_usec, :utc_datetime_usec
      field :field_duration, :duration
    end
  end

  test "Validate fields_parser" do
    validations = %{
      id: %{
        data: %{},
        disabled: true,
        hidden: false,
        label: "Id",
        name: "id",
        type: :id,
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
        length: 255,
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
      }
    }

    parsed_fields =
      AllTypes
      |> Ctx.FieldsParser.parse_fields(:all_types)
      |> Map.new(&{&1.key, &1})

    assert validations
           |> Map.keys()
           |> Enum.map(fn key ->
             validation = Map.get(validations, key)
             parsed = Map.get(parsed_fields, key)

             validation
             |> Map.keys()
             |> Enum.filter(&(Map.get(validation, &1) != Map.get(parsed, &1)))
             |> Enum.map(
               &"#{key} on field: #{&1} got: #{inspect(Map.get(parsed, &1))}, expected: #{inspect(Map.get(validation, &1))}"
             )
           end)
           |> Enum.reject(&(&1 == []))
           |> List.flatten() == []
  end
end
