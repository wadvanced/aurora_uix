defmodule Aurora.Uix.Test.Integration.Ash.QueryParserTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Guides.Blog.Post
  alias Aurora.Uix.Integration.Ash.QueryParser

  setup do
    %{query: Ash.Query.new(Post)}
  end

  test "a direction-first order_by is translated to Ash's field-first form", %{query: query} do
    parsed = QueryParser.parse(query, order_by: [desc: :title])
    assert parsed.sort == [title: :desc]
    assert parsed.valid?
  end

  test "nulls directions map to Ash's nils directions", %{query: query} do
    assert QueryParser.parse(query, order_by: [desc_nulls_last: :title, asc: :content]).sort ==
             [title: :desc_nils_last, content: :asc]
  end

  test "Ash sorts, atoms and a single tuple keep working", %{query: query} do
    assert QueryParser.parse(query, order_by: [title: :desc]).sort == [title: :desc]
    assert QueryParser.parse(query, order_by: :title).sort == [title: :asc]
    assert QueryParser.parse(query, order_by: {:desc, :title}).sort == [title: :desc]
  end

  test "a single-tuple where equals its one-element list", %{query: query} do
    assert QueryParser.parse(query, where: {:title, :eq, "x"}).filter ==
             QueryParser.parse(query, where: [{:title, :eq, "x"}]).filter
  end

  test "an unsupported sort direction surfaces as an invalid query", %{query: query} do
    refute QueryParser.parse(query, order_by: [title: :sideways]).valid?
  end

  test "an in condition takes a list", %{query: query} do
    parsed = QueryParser.parse(query, where: [{:title, :in, ["a", "b"]}])
    assert parsed.valid?
    assert inspect(parsed.filter) == ~s(#Ash.Filter<title in ["a", "b"]>)
  end

  test "a comma-separated in value is not split", %{query: query} do
    refute QueryParser.parse(query, where: [{:title, :in, "a,b"}]).valid?
  end
end
