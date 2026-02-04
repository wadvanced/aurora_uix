Code.require_file("test/cases/integration/fields_parser_validations_test.exs")

defmodule Aurora.Uix.Test.Cases.Integration.Ctx.FieldsParserTest do
  use ExUnit.Case
  alias Aurora.Uix.Integration.Ctx

  alias Aurora.Uix.Test.Cases.Integration.FieldsParserValidations, as: Validations

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
      field :field_status, Ecto.Enum, values: [:draft, :published, :archived]

      embeds_many :embeds_many, EmbedsMany, on_replace: :delete do
        field(:name, :string)
      end

      embeds_one :embeds_one, EmbedsOne do
        field(:event_date, :date)
        field(:note, :string)
      end
    end
  end

  test "Validate fields_parser" do
    validations =
      Validations.get(:all_types)

    parsed_fields =
      AllTypes
      |> Ctx.FieldsParser.parse_fields(:all_types)
      |> Map.new(&{&1.key, &1})

    assert Validations.compare_maps(validations, parsed_fields) == []
  end
end
