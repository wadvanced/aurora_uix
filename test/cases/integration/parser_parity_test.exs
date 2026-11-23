defmodule Aurora.Uix.Test.Cases.ParserParityTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Integration.Ash
  alias Aurora.Uix.Integration.Ctx
  alias Aurora.Uix.Test.MirrorAsh
  alias Aurora.Uix.Test.MirrorCtx

  defmodule Settings do
    use Ecto.Schema

    embedded_schema do
      field :settings, :map
    end
  end

  @parsers [
    %{
      name: :ash,
      parser: Ash.FieldsParser,
      product: MirrorAsh.Product,
      embedded: MirrorAsh.Packaging,
      undefined_key: {:selected_check__, :boolean}
    },
    %{
      name: :ctx,
      parser: Ctx.FieldsParser,
      product: MirrorCtx.Product,
      embedded: MirrorCtx.Product.Packaging,
      undefined_key: :selected_check__
    }
  ]

  test "sortable? answers the same on both backends" do
    for backend <- @parsers do
      %{parser: parser, product: product} = backend

      fields =
        product
        |> parser.parse_fields(:product)
        |> then(&parser.parse_associations(product, :product, %{}, &1))
        |> Map.new(&{&1.key, &1})

      for key <- [:name, :quantity_initial, :released_on, :product_location_id],
          do: assert(fields[key].sortable?, "#{backend.name}: #{key} is sortable")

      for key <- [:labels, :packaging, :contacts, :product_location],
          do: refute(fields[key].sortable?, "#{backend.name}: #{key} is not sortable")

      refute parser.parse_field(product, :product, backend.undefined_key).sortable?,
             "#{backend.name}: a key the resource does not define is not sortable"
    end

    settings =
      Settings
      |> Ctx.FieldsParser.parse_fields(:settings)
      |> Enum.find(&(&1.key == :settings))

    refute settings.sortable?
  end

  test "embedded_schema? answers the same on both backends" do
    for backend <- @parsers do
      %{parser: parser, product: product, embedded: embedded} = backend

      assert parser.embedded_schema?(embedded),
             "#{backend.name}: #{inspect(embedded)} is embedded"

      for module <- [product, String],
          do: refute(parser.embedded_schema?(module), "#{backend.name}: #{inspect(module)}")
    end
  end
end
