defmodule Aurora.Uix.Test.Cases.DslEntitiesTest do
  use ExUnit.Case

  alias Aurora.Uix.Dsl.Entity.Field
  alias Aurora.Uix.Dsl.Entity.Fields
  alias Aurora.Uix.Dsl.Entity.ResourceMetadata

  describe "entity structs" do
    test "carry the prescribed fields with spark metadata" do
      assert %ResourceMetadata{__spark_metadata__: nil}.name == nil
      assert Map.has_key?(%ResourceMetadata{}, :renderers)
      assert Map.has_key?(%Field{}, :option_label)
      assert Map.has_key?(%Field{}, :__spark_metadata__)
      assert %Fields{keys: [:a]}.opts == []
    end

    test "declarations name the entity with its args and target" do
      assert %Spark.Dsl.Entity{name: :resource_metadata, args: [:name]} =
               ResourceMetadata.__entity__()

      assert ResourceMetadata.__entity__().target == ResourceMetadata

      assert %Spark.Dsl.Entity{name: :field, args: [:key]} = Field.__entity__()
      assert Field.__entity__().target == Field
      assert %Spark.Dsl.Entity{name: :fields, args: [:keys]} = Fields.__entity__()
    end

    test "bulk declaration validates its key list" do
      assert {:ok, %Fields{}} = Fields.validate_keys(%Fields{keys: [:a, :b]})
      assert {:error, _} = Fields.validate_keys(%Fields{keys: []})
    end
  end
end
