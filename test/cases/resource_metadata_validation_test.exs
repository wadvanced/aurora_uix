defmodule Aurora.Uix.Test.Cases.ResourceMetadataValidationTest do
  use ExUnit.Case, async: true

  alias Spark.Error.DslError

  defmodule Address do
    use Ecto.Schema

    schema "addresses" do
      field :street, :string
    end
  end

  defmodule Person do
    use Ecto.Schema

    schema "people" do
      field :name, :string
      embeds_one(:address, Aurora.Uix.Test.Cases.ResourceMetadataValidationTest.Address)
    end
  end

  @spec compile(binary()) :: [{module(), binary()}]
  defp compile(body) do
    Code.compile_string("""
    defmodule Aurora.Uix.Test.Cases.ResourceMetadataValidationTest.Sample#{System.unique_integer([:positive])} do
      use Aurora.Uix

    #{body}
    end
    """)
  end

  test "an unknown field option fails compilation" do
    error =
      assert_raise DslError, fn ->
        compile("""
          auix_resource_metadata :product do
            schema Aurora.Uix.Guides.Inventory.Product
            context Aurora.Uix.Guides.Inventory
            field :name, lable: "Name"
          end
        """)
      end

    assert Exception.message(error) =~ "unknown options [:lable]"
  end

  test "a mistyped resource option fails compilation" do
    assert_raise DslError, ~r/renderers/, fn ->
      compile("""
        auix_resource_metadata :product,
          schema: Aurora.Uix.Guides.Inventory.Product,
          context: Aurora.Uix.Guides.Inventory,
          renderers: :toggle_switch
      """)
    end
  end

  test "a mistyped resource preload fails compilation" do
    assert_raise DslError, ~r/preload/, fn ->
      compile("""
        auix_resource_metadata :product,
          schema: Aurora.Uix.Guides.Inventory.Product,
          context: Aurora.Uix.Guides.Inventory,
          preload: :product_location
      """)
    end
  end

  test "a context resource without :context fails compilation" do
    assert_raise DslError,
                 ~r/requires the `:context` option: Aurora\.Uix\.Guides\.Inventory\.Product has a table, so :product is a standalone resource\. Give `context:` with its CRUD functions/,
                 fn ->
                   compile("""
                     auix_resource_metadata :product, schema: Aurora.Uix.Guides.Inventory.Product
                   """)
                 end
  end

  test "a declared resource on a schema with a table is not embedded" do
    body_a = """
      auix_resource_metadata :person,
        schema: Aurora.Uix.Test.Cases.ResourceMetadataValidationTest.Person,
        context: Aurora.Uix.Guides.Inventory
    """

    body_b =
      body_a <>
        """
          auix_resource_metadata :person__address,
            schema: Aurora.Uix.Test.Cases.ResourceMetadataValidationTest.Address,
            context: Aurora.Uix.Guides.Inventory
        """

    [{a, _}] = compile(body_a)
    assert a.auix_resource(:person__address).embedded?

    [{b, _}] = compile(body_b)
    refute b.auix_resource(:person__address).embedded?
  end

  test "backend options are validated by the backend" do
    assert_raise DslError, ~r/unknown options \[:ash_actor_assign\]/, fn ->
      compile("""
        auix_resource_metadata :product,
          schema: Aurora.Uix.Guides.Inventory.Product,
          context: Aurora.Uix.Guides.Inventory,
          backend_opts: [ash_actor_assign: :current_user]
      """)
    end
  end

  test "a declared resource links its associations to imported resources" do
    meta = compile_meta()

    imports =
      "@auix_resource_metadata %{product_transaction: #{inspect(meta)}.auix_resource(:product_transaction), product_location: #{inspect(meta)}.auix_resource(:product_location)}"

    declare =
      "auix_resource_metadata :catalog_product, context: Aurora.Uix.Guides.Inventory, schema: Aurora.Uix.Guides.Inventory.Product"

    for body <- [declare <> "\n" <> imports, imports <> "\n" <> declare] do
      [{mod, _}] = compile(body)
      fields = mod.auix_resource(:catalog_product).fields
      assert fields.product_transactions.data.resource == :product_transaction
      assert fields.product_location_id.data.resource == :product_location
      assert fields.product_location_id.html_type == :select
    end
  end

  test "a declared Ash resource links its associations to imported resources" do
    meta = compile_meta()

    [{mod, _}] =
      compile("""
        auix_resource_metadata :article, ash_resource: Aurora.Uix.Guides.Blog.Post
        @auix_resource_metadata %{author: #{inspect(meta)}.auix_resource(:author)}
      """)

    assert mod.auix_resource(:article).fields.author.data.resource == :author
  end

  test "a declared resource wins, and a module without imports is unchanged" do
    meta = compile_meta()

    imports =
      "@auix_resource_metadata %{product_transaction: #{inspect(meta)}.auix_resource(:product_transaction), product_location: #{inspect(meta)}.auix_resource(:product_location)}"

    declare =
      "auix_resource_metadata :catalog_product, context: Aurora.Uix.Guides.Inventory, schema: Aurora.Uix.Guides.Inventory.Product"

    local =
      "auix_resource_metadata :local_location, context: Aurora.Uix.Guides.Inventory, schema: Aurora.Uix.Guides.Inventory.ProductLocation"

    [{local_mod, _}] = compile(Enum.join([imports, declare, local], "\n"))

    assert local_mod.auix_resource(:catalog_product).fields.product_location_id.data.resource ==
             :local_location

    [{skipped_mod, _}] = compile("@auix_resource_metadata %{nope: nil}\n" <> declare)

    assert skipped_mod.auix_resource(:catalog_product).fields.product_transactions.data.resource ==
             nil

    [{plain_mod, _}] = compile(declare)

    assert plain_mod.auix_resource(:catalog_product).fields.product_transactions.data.resource ==
             nil
  end

  test "resource: links an Ash embedded field and a many-to-one" do
    [{mod, _}] =
      compile("""
        auix_resource_metadata :post do
          ash_resource Aurora.Uix.Guides.Blog.Post
          field :comment, resource: :my_comment
          field :author, resource: :writer
        end

        auix_resource_metadata :my_comment, ash_resource: Aurora.Uix.Guides.Blog.Comment
        auix_resource_metadata :writer, ash_resource: Aurora.Uix.Guides.Blog.Author
        auix_resource_metadata :author, ash_resource: Aurora.Uix.Guides.Blog.Author
      """)

    fields = mod.auix_resource(:post).fields
    assert {fields.comment.resource, fields.comment.data.resource} == {:post, :my_comment}
    assert {fields.author.resource, fields.author.data.resource} == {:post, :writer}
    assert fields.author_id.data.resource == :writer
  end

  test "resource: links an Ecto embedded field" do
    [{mod, _}] =
      compile("""
        auix_resource_metadata :user do
          schema Aurora.Uix.Guides.Accounts.User
          context Aurora.Uix.Guides.Accounts
          field :profile, resource: :profile_card
        end

        auix_resource_metadata :profile_card, schema: Aurora.Uix.Guides.Accounts.User.Profile
      """)

    field = mod.auix_resource(:user).fields.profile
    assert {field.resource, field.data.resource} == {:user, :profile_card}
  end

  test "resource: links to an imported resource" do
    meta = compile_meta()

    [{mod, _}] =
      compile("""
        @auix_resource_metadata %{product_location: #{inspect(meta)}.auix_resource(:product_location)}

        auix_resource_metadata :catalog_product do
          schema Aurora.Uix.Guides.Inventory.Product
          context Aurora.Uix.Guides.Inventory
          field :product_location, resource: :product_location
        end
      """)

    field = mod.auix_resource(:catalog_product).fields.product_location
    assert {field.resource, field.data.resource} == {:catalog_product, :product_location}
  end

  test "resource: with an unknown name fails compilation" do
    assert_raise DslError,
                 ~r/field :product_location of :product links to the unknown resource :nowhere/,
                 fn ->
                   compile("""
                     auix_resource_metadata :product do
                       schema Aurora.Uix.Guides.Inventory.Product
                       context Aurora.Uix.Guides.Inventory
                       field :product_location, resource: :nowhere
                     end
                   """)
                 end
  end

  test "resource: with a resource on another schema fails compilation" do
    assert_raise DslError,
                 ~r/field :product_location of :product links to the resource :movement, whose schema is Aurora\.Uix\.Guides\.Inventory\.ProductTransaction; the field relates to Aurora\.Uix\.Guides\.Inventory\.ProductLocation/,
                 fn ->
                   compile("""
                     auix_resource_metadata :product do
                       schema Aurora.Uix.Guides.Inventory.Product
                       context Aurora.Uix.Guides.Inventory
                       field :product_location, resource: :movement
                     end

                     auix_resource_metadata :movement,
                       context: Aurora.Uix.Guides.Inventory,
                       schema: Aurora.Uix.Guides.Inventory.ProductTransaction
                   """)
                 end
  end

  test "resource: on a plain field fails compilation" do
    body = fn field ->
      """
        auix_resource_metadata :product do
          schema Aurora.Uix.Guides.Inventory.Product
          context Aurora.Uix.Guides.Inventory
          field #{inspect(field)}, resource: :product_location
        end

        auix_resource_metadata :product_location,
          context: Aurora.Uix.Guides.Inventory,
          schema: Aurora.Uix.Guides.Inventory.ProductLocation
      """
    end

    assert_raise DslError,
                 ~r/`resource:` on field :name of :product is not allowed: its type is :string, and only an embedded field or an association links to a resource/,
                 fn -> compile(body.(:name)) end

    assert_raise DslError,
                 ~r/`resource:` on field :product_location_id of :product is not allowed: .* Put `resource:` on the association field :product_location/,
                 fn -> compile(body.(:product_location_id)) end
  end

  @spec compile_meta() :: module()
  defp compile_meta do
    [{meta, _}] =
      compile("""
        auix_resource_metadata :product_transaction,
          context: Aurora.Uix.Guides.Inventory,
          schema: Aurora.Uix.Guides.Inventory.ProductTransaction

        auix_resource_metadata :product_location,
          context: Aurora.Uix.Guides.Inventory,
          schema: Aurora.Uix.Guides.Inventory.ProductLocation

        auix_resource_metadata :author, ash_resource: Aurora.Uix.Guides.Blog.Author
      """)

    meta
  end
end
