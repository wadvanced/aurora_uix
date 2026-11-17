defmodule Aurora.Uix.Templates.Basic.OneToManyRowsTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Templates.Basic.Renderers.OneToMany

  test "a one-to-many list needs the index component of its resource" do
    assigns = %{
      field: %{type: :one_to_many_association, key: :products, data: %{resource: :product}},
      auix: %{configurations: %{product: %{artifacts: %{index_component: nil}}}}
    }

    assert_raise ArgumentError,
                 ~r/the one-to-many field :products needs an index component for :product/,
                 fn -> OneToMany.render(assigns) end
  end

  test "load_rows/1 takes the preloaded rows" do
    one_to_many = %{
      field: %{key: :products},
      auix: %{entity: %{products: [%{id: 1}]}, layout_tree: %{order_by: nil, where: nil}}
    }

    assert OneToMany.load_rows(one_to_many) == [%{id: 1}]

    assert one_to_many
           |> put_in([:auix, :entity], %{products: %Ecto.Association.NotLoaded{}})
           |> OneToMany.load_rows() == []

    assert one_to_many |> put_in([:auix, :entity], nil) |> OneToMany.load_rows() == []
  end
end
