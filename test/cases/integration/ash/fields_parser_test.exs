Code.require_file("test/cases/integration/fields_parser_validations_test.exs")

defmodule EmbedsMany do
  use Ash.Resource,
    data_layer: :embedded,
    domain: nil

  attributes do
    attribute :name, :binary
  end
end

defmodule EmbedsOne do
  use Ash.Resource,
    data_layer: :embedded,
    domain: nil

  attributes do
    attribute :event_date, :date
    attribute :note, :string
  end
end

defmodule BelongsToRelationship do
  use Ash.Resource,
    domain: nil

  attributes do
    uuid_primary_key :id
    attribute :first_field, :integer
    attribute :second_field, :string
  end
end

defmodule HasManyRelationship do
  use Ash.Resource,
    domain: nil

  attributes do
    uuid_primary_key :id
    attribute :first_field, :integer
    attribute :second_field, :string
    attribute :all_types_id, :integer
  end
end

defmodule AllTypes do
  use Ash.Resource,
    domain: nil

  ## :bitstring is not handled by ash
  ## :field_naive_datetime_usec is not handled by ash
  attributes do
    integer_primary_key :id
    attribute :field_binary_id, :uuid
    attribute :field_integer, :integer
    attribute :field_float, :float
    attribute :field_boolean, :boolean
    attribute :field_string, :string
    attribute :field_binary, :binary
    attribute :field_bitstring, :binary
    attribute :field_decimal, :decimal
    attribute :field_date, :date
    attribute :field_time, :time
    attribute :field_time_usec, :time_usec
    attribute :field_naive_datetime, :naive_datetime
    attribute :field_naive_datetime_usec, :naive_datetime
    attribute :field_utc_datetime, :utc_datetime
    attribute :field_utc_datetime_usec, :utc_datetime_usec
    attribute :field_duration, :duration

    attribute :field_status, :atom do
      constraints one_of: [:draft, :published, :archived]
      default :draft
    end

    attribute :embeds_many, {:array, EmbedsMany}
    attribute :embeds_one, EmbedsOne
  end

  relationships do
    belongs_to :belongs_to_field, BelongsToRelationship
    has_many :has_many_field, HasManyRelationship
  end

  actions do
    defaults [:read, :create, :update, :destroy]
  end
end

defmodule Aurora.Uix.Test.Cases.Integration.Ash.FieldsParserTest do
  use ExUnit.Case
  alias Aurora.Uix.Integration.Ash

  alias Aurora.Uix.Test.Cases.Integration.FieldsParserValidations, as: Validations

  test "Validate fields_parser" do
    validations =
      :all_types
      |> Validations.get(owner_prefix: "", related_prefix: "")
      |> put_in([:field_naive_datetime_usec, :type], :naive_datetime)
      |> put_in([:field_naive_datetime_usec, :length], 17)
      |> put_in([:field_naive_datetime_usec, :data], %{})
      |> put_in([:field_bitstring, :type], :binary)

    parsed_fields =
      AllTypes
      |> Ash.FieldsParser.parse_fields(:all_types)
      |> Map.new(&{&1.key, &1})

    assert Validations.compare_maps(validations, parsed_fields) == []
  end

  test "Validate association_parser" do
    validations =
      :with_associations
      |> Validations.get(owner_prefix: "", related_prefix: "")
      |> put_in([:field_naive_datetime_usec, :type], :naive_datetime)
      |> put_in([:field_naive_datetime_usec, :length], 17)
      |> put_in([:field_naive_datetime_usec, :data], %{})
      |> put_in([:field_bitstring, :type], :binary)

    parsed_schema =
      AllTypes
      |> Ash.FieldsParser.parse_fields(:all_types)
      |> then(&Ash.FieldsParser.parse_associations(AllTypes, :all_types, %{}, &1))
      |> Map.new(&{&1.key, &1})

    assert Validations.compare_maps(validations, parsed_schema) == []
  end
end
