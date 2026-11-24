defmodule Aurora.Uix.Test.Integration.Ash.QueryParserTest do
  @moduledoc "The Ash query parser."
  use ExUnit.Case, async: true

  alias Aurora.Uix.Integration.Ash.QueryParser
  alias Aurora.Uix.Test.MirrorAsh.Product

  setup do
    %{query: Ash.Query.new(Product)}
  end

  test "the Ash query parser translates order_by", %{query: query} do
    parsed = QueryParser.parse(query, order_by: [desc: :name])
    assert parsed.sort == [name: :desc]
    assert parsed.valid?

    assert QueryParser.parse(query, order_by: [desc_nulls_last: :name, asc: :description]).sort ==
             [name: :desc_nils_last, description: :asc]

    assert QueryParser.parse(query, order_by: [name: :desc]).sort == [name: :desc]
    assert QueryParser.parse(query, order_by: :name).sort == [name: :asc]
    assert QueryParser.parse(query, order_by: {:desc, :name}).sort == [name: :desc]

    refute QueryParser.parse(query, order_by: [name: :sideways]).valid?
  end

  test "the Ash query parser translates where", %{query: query} do
    assert QueryParser.parse(query, where: {:name, :eq, "x"}).filter ==
             QueryParser.parse(query, where: [{:name, :eq, "x"}]).filter

    parsed = QueryParser.parse(query, where: [{:name, :in, ["a", "b"]}])
    assert parsed.valid?
    assert inspect(parsed.filter) == ~s(#Ash.Filter<name in ["a", "b"]>)

    refute QueryParser.parse(query, where: [{:name, :in, "a,b"}]).valid?
  end
end
