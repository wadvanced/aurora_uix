Code.require_file("test/cases/integration/fields_parser_validations_test.exs")

defmodule ModuleEnum do
  use Ash.Type.Enum, values: [:draft, published: [label: "Live"], archived: nil]
end

defmodule NewTypeEnum do
  use Ash.Type.NewType, subtype_of: :atom, constraints: [one_of: [:draft, :published, :archived]]
end

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

defmodule HasOneRelationship do
  use Ash.Resource,
    domain: nil

  attributes do
    uuid_primary_key :id
    attribute :first_field, :integer
    attribute :second_field, :string
    attribute :all_types_id, :integer
  end
end

defmodule ManyToManyRelationship do
  use Ash.Resource,
    domain: nil

  attributes do
    uuid_primary_key :id
    attribute :first_field, :integer
    attribute :second_field, :string
  end
end

defmodule ManyToManyJoinRelationship do
  use Ash.Resource,
    domain: nil

  attributes do
    uuid_primary_key :id
    # AllTypes uses an integer primary key, ManyToManyRelationship a uuid one; the join attribute
    # types must match their respective sides or Ash warns about incompatible foreign keys.
    attribute :all_types_id, :integer
    attribute :many_to_many_relationship_id, :uuid
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

    attribute :field_multi_status, {:array, :atom} do
      constraints items: [one_of: [:draft, :published, :archived]]
    end

    attribute :field_string_array, {:array, :string}
    attribute :field_module_enum, ModuleEnum
    attribute :field_multi_module_enum, {:array, ModuleEnum}
    attribute :field_new_type_enum, NewTypeEnum
    attribute :field_multi_new_type_enum, {:array, NewTypeEnum}

    attribute :embeds_many, {:array, EmbedsMany}
    attribute :embeds_one, EmbedsOne
  end

  relationships do
    belongs_to :belongs_to_field, BelongsToRelationship
    has_many :has_many_field, HasManyRelationship
    has_one :has_one_field, HasOneRelationship

    many_to_many :many_to_many_field, ManyToManyRelationship do
      through ManyToManyJoinRelationship
      source_attribute_on_join_resource :all_types_id
      destination_attribute_on_join_resource :many_to_many_relationship_id
    end
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
      # Ecto names the join by table, Ash by join resource -- the one genuinely divergent key.
      |> put_in([:many_to_many_field, :data, :join_through], ManyToManyJoinRelationship)

    parsed_schema =
      AllTypes
      |> Ash.FieldsParser.parse_fields(:all_types)
      |> then(&Ash.FieldsParser.parse_associations(AllTypes, :all_types, %{}, &1))
      |> Map.new(&{&1.key, &1})

    assert Validations.compare_maps(validations, parsed_schema) == []
  end

  # Ash-only: neither shape has an Ecto counterpart, so they stay out of the shared golden map.
  describe "enum flavours without a `one_of` constraint" do
    test "a module enum takes its options -- and their labels -- from the module" do
      field = parsed_field(:field_module_enum)

      assert field.type == :string
      assert field.html_type == :select
      assert field.filterable?
      assert field.length == 9

      # `:published` declares a label, the other two fall back to Ash's humanized default.
      assert field.data == %{
               select: %{
                 opts: [{"Draft", :draft}, {"Live", :published}, {"Archived", :archived}],
                 multiple: false
               }
             }
    end

    test "a NewType is unwrapped to the constraints its subtype carries" do
      field = parsed_field(:field_new_type_enum)

      assert field.html_type == :select

      assert field.data == %{
               select: %{
                 opts: [{"Draft", :draft}, {"Published", :published}, {"Archived", :archived}],
                 multiple: false
               }
             }
    end

    test "the array form of either is a multiple select, and is not filterable" do
      for key <- [:field_multi_module_enum, :field_multi_new_type_enum] do
        field = parsed_field(key)

        assert field.html_type == :select
        assert field.data.select.multiple
        refute field.filterable?
      end
    end
  end

  @spec parsed_field(atom()) :: Aurora.Uix.Field.t()
  defp parsed_field(key) do
    AllTypes
    |> Ash.FieldsParser.parse_fields(:all_types)
    |> Enum.find(&(&1.key == key))
  end
end
