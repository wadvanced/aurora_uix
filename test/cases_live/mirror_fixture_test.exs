defmodule Aurora.UixWeb.Test.MirrorFixtureTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Repo
  alias Aurora.Uix.Test.Mirror.Seeds
  alias Aurora.Uix.Test.MirrorAsh
  alias Aurora.Uix.Test.MirrorCtx

  require Ash.Query

  auix_resource_metadata(:ctx_product,
    context: Aurora.Uix.Test.MirrorCtx,
    schema: Aurora.Uix.Test.MirrorCtx.Product
  )

  auix_resource_metadata(:ash_product, ash_resource: Aurora.Uix.Test.MirrorAsh.Product)

  @scalars [
    :id,
    :reference,
    :name,
    :description,
    :status,
    :grade,
    :labels,
    :quantity_at_hand,
    :quantity_initial,
    :quantity_entries,
    :quantity_exits,
    :cost,
    :msrp,
    :rrp,
    :list_price,
    :discounted_price,
    :weight,
    :length,
    :width,
    :height,
    :units_per_box,
    :margin,
    :released_on,
    :opens_at,
    :audited_at,
    :discontinued_at,
    :image,
    :thumbnail,
    :deleted,
    :inactive,
    :product_location_id,
    :inserted_at,
    :updated_at
  ]

  @relationships [:product_location, :product_barcode, :product_transactions, :suppliers]

  test "the mirrored fixture gives both backends the same fields and the same rows" do
    :ok = Seeds.delete_all_mirror_data()

    %{"id_1" => location} = Seeds.create_sample_product_locations(1)
    {[_supplied], suppliers} = Seeds.create_sample_products_with_suppliers(1, 2)
    [_barcoded] = Seeds.create_sample_products_with_barcodes(1)
    [_embedded] = Seeds.create_sample_products_with_embeds(1)
    _plain = Seeds.create_sample_products(2, :plain)
    _with_transactions = Seeds.create_sample_products_with_transactions(1, 2, :tx)

    supplier_ids = Enum.map(suppliers, & &1.id)
    attrs = product_attrs(location.id)

    {:ok, ctx_written} =
      attrs
      |> Map.merge(%{
        reference: "mirror_ctx",
        suppliers: supplier_ids,
        product_barcode: barcode_attrs("5000000000001")
      })
      |> MirrorCtx.create_product()

    for index <- 1..2 do
      {:ok, _transaction} =
        ctx_written.id
        |> transaction_attrs(index)
        |> MirrorCtx.create_product_transaction()
    end

    ash_read = ash_product(ctx_written.id)
    assert_written(attrs, ash_read)
    assert sorted_ids(ash_read.suppliers) == Enum.sort(supplier_ids)
    assert ash_read.product_barcode.code == "5000000000001"
    assert length(ash_read.product_transactions) == 2

    {:ok, ash_written} =
      Ash.create(
        MirrorAsh.Product,
        Map.merge(attrs, %{
          reference: "mirror_ash",
          suppliers: supplier_ids,
          product_barcode: barcode_attrs("5000000000002")
        })
      )

    for index <- 1..2 do
      {:ok, _transaction} =
        Ash.create(MirrorAsh.ProductTransaction, transaction_attrs(ash_written.id, index))
    end

    ctx_read = ctx_product(ash_written.id)
    assert_written(attrs, ctx_read)
    assert sorted_ids(ctx_read.suppliers) == Enum.sort(supplier_ids)
    assert ctx_read.product_barcode.code == "5000000000002"
    assert length(ctx_read.product_transactions) == 2

    {:ok, _updated} =
      ash_written.id
      |> ctx_product()
      |> MirrorCtx.update_product(%{
        name: "Renamed through Ecto",
        packaging: %{material: :crate, fragile: false, notes: "ecto note"}
      })

    {:ok, _updated} =
      ctx_written.id
      |> ash_product()
      |> Ash.update(%{
        name: "Renamed through Ash",
        contacts: [%{email: "ash@test.com", name: "Ash"}]
      })

    assert ctx_product(ash_written.id).name == "Renamed through Ecto"
    assert ash_product(ash_written.id).packaging.notes == "ecto note"
    assert ash_product(ctx_written.id).name == "Renamed through Ash"
    assert [%{email: "ash@test.com", name: "Ash"}] = ctx_product(ctx_written.id).contacts

    product_ids = MirrorCtx.Product |> Repo.all() |> Enum.map(& &1.id)
    assert length(product_ids) == 8
    Enum.each(product_ids, &assert_same_product(ctx_product(&1), ash_product(&1)))

    assert sorted_ids(Repo.all(MirrorCtx.ProductLocation)) ==
             sorted_ids(Ash.read!(MirrorAsh.ProductLocation))

    assert sorted_ids(Repo.all(MirrorCtx.Supplier)) == sorted_ids(Ash.read!(MirrorAsh.Supplier))

    ctx = auix_resource(:ctx_product).fields
    ash = auix_resource(:ash_product).fields

    for key <- Map.keys(ctx), Map.has_key?(ash, key) do
      assert {key, ctx[key].type, ctx[key].html_type} ==
               {key, ash[key].type, ash[key].html_type}
    end

    assert Enum.sort(Map.keys(ash) -- Map.keys(ctx)) == [:summary, :suppliers_join_assoc]
    assert Map.keys(ctx) -- Map.keys(ash) == []

    product_count = Repo.aggregate(MirrorCtx.Product, :count)
    assert {:error, %Ash.Error.Invalid{}} = Ash.create(MirrorAsh.Product, %{name: ""})
    refute MirrorCtx.Product.changeset(%MirrorCtx.Product{}, %{name: ""}).valid?
    assert Repo.aggregate(MirrorCtx.Product, :count) == product_count
  end

  @spec product_attrs(Ecto.UUID.t()) :: map()
  defp product_attrs(location_id) do
    %{
      name: "Mirrored item",
      description: "Written by one backend, read by the other.",
      status: "in_stock",
      grade: :premium,
      labels: [:fragile, :hazardous],
      quantity_at_hand: Decimal.new("12.5"),
      quantity_initial: Decimal.new("10"),
      quantity_entries: Decimal.new("3.25"),
      quantity_exits: Decimal.new("0.75"),
      cost: Decimal.new("123.456789"),
      msrp: Decimal.new("199.99"),
      rrp: Decimal.new("189.50"),
      list_price: Decimal.new("179.00"),
      discounted_price: Decimal.new("159.95"),
      weight: Decimal.new("1.5"),
      length: Decimal.new("20"),
      width: Decimal.new("10"),
      height: Decimal.new("5"),
      units_per_box: 12,
      margin: 0.35,
      released_on: ~D[2026-03-01],
      opens_at: ~T[09:30:00],
      audited_at: ~N[2026-03-02 10:15:00],
      discontinued_at: ~U[2026-04-01 12:00:00Z],
      image: <<1, 2, 3>>,
      thumbnail: <<4, 5>>,
      deleted: false,
      inactive: true,
      product_location_id: location_id,
      packaging: %{material: :bag, fragile: true, notes: "handle with care"},
      contacts: [
        %{email: "work@test.com", name: "Work"},
        %{email: "home@test.com", name: "Home"}
      ]
    }
  end

  @spec barcode_attrs(binary()) :: map()
  defp barcode_attrs(code), do: %{code: code, symbology: "EAN-13", registered_at: ~D[2026-01-02]}

  @spec transaction_attrs(Ecto.UUID.t(), integer()) :: map()
  defp transaction_attrs(product_id, index) do
    %{
      type: "entry",
      quantity: Decimal.new(index * 2),
      cost: Decimal.new("4.5"),
      product_id: product_id
    }
  end

  @spec ctx_product(Ecto.UUID.t()) :: MirrorCtx.Product.t()
  defp ctx_product(id) do
    MirrorCtx.Product
    |> Repo.get!(id)
    |> Repo.preload(@relationships)
  end

  @spec ash_product(Ecto.UUID.t()) :: struct()
  defp ash_product(id) do
    [product] =
      MirrorAsh.Product
      |> Ash.Query.filter(id == ^id)
      |> Ash.Query.load(@relationships)
      |> Ash.read!()

    product
  end

  @spec assert_written(map(), struct()) :: true
  defp assert_written(attrs, product) do
    attrs
    |> Map.drop([:packaging, :contacts])
    |> Enum.each(fn {key, value} ->
      assert {key, same?(value, Map.fetch!(product, key))} == {key, true}
    end)

    assert embed(product.packaging, [:material, :fragile, :notes]) == attrs.packaging
    assert Enum.map(product.contacts, &embed(&1, [:email, :name])) == attrs.contacts
  end

  @spec assert_same_product(MirrorCtx.Product.t(), struct()) :: true
  defp assert_same_product(ctx, ash) do
    Enum.each(@scalars, fn key ->
      assert {key, same?(Map.fetch!(ctx, key), Map.fetch!(ash, key))} == {key, true}
    end)

    assert embed(ctx.packaging, [:material, :fragile, :notes]) ==
             embed(ash.packaging, [:material, :fragile, :notes])

    assert Enum.map(ctx.contacts, &embed(&1, [:email, :name])) ==
             Enum.map(ash.contacts || [], &embed(&1, [:email, :name]))

    assert related(ctx.product_location, [:id, :reference, :name, :type]) ==
             related(ash.product_location, [:id, :reference, :name, :type])

    assert related(ctx.product_barcode, [:id, :code, :symbology, :registered_at, :product_id]) ==
             related(ash.product_barcode, [:id, :code, :symbology, :registered_at, :product_id])

    assert related_list(ctx.product_transactions, [:id, :type, :product_id]) ==
             related_list(ash.product_transactions, [:id, :type, :product_id])

    ctx.product_transactions
    |> Enum.sort_by(& &1.id)
    |> Enum.zip(Enum.sort_by(ash.product_transactions, & &1.id))
    |> Enum.each(fn {ctx_transaction, ash_transaction} ->
      assert Decimal.equal?(ctx_transaction.quantity, ash_transaction.quantity)
      assert Decimal.equal?(ctx_transaction.cost, ash_transaction.cost)
    end)

    assert related_list(ctx.suppliers, [:id, :name, :country]) ==
             related_list(ash.suppliers, [:id, :name, :country])
  end

  @spec same?(term(), term()) :: boolean()
  defp same?(%Decimal{} = left, %Decimal{} = right), do: Decimal.equal?(left, right)
  defp same?(left, right), do: left == right

  @spec embed(struct() | nil, [atom()]) :: map() | nil
  defp embed(nil, _keys), do: nil
  defp embed(record, keys), do: Map.take(record, keys)

  @spec related(struct() | nil, [atom()]) :: map() | nil
  defp related(nil, _keys), do: nil
  defp related(record, keys), do: Map.take(record, keys)

  @spec related_list([struct()], [atom()]) :: [map()]
  defp related_list(records, keys), do: records |> Enum.map(&Map.take(&1, keys)) |> Enum.sort()

  @spec sorted_ids([struct()]) :: [Ecto.UUID.t()]
  defp sorted_ids(records), do: records |> Enum.map(& &1.id) |> Enum.sort()
end
