defmodule Aurora.Uix.Test.Cases.ResourceMetadataTest do
  use ExUnit.Case, async: true

  import Aurora.UixWeb.Test.UICase,
    only: [assert_values_order: 2, resource_configs: 1, validate_schema: 3]

  alias Aurora.Uix.Test.MirrorAsh
  alias Aurora.Uix.Test.MirrorCtx
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
      embeds_one(:address, Aurora.Uix.Test.Cases.ResourceMetadataTest.Address)
    end
  end

  defmodule CtxDefaults do
    use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

    auix_resource_metadata(:product, context: MirrorCtx, schema: MirrorCtx.Product)

    auix_resource_metadata(:product_transaction,
      context: MirrorCtx,
      schema: MirrorCtx.ProductTransaction
    )
  end

  defmodule AshDefaults do
    use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

    auix_resource_metadata(:product, ash_resource: MirrorAsh.Product)
    auix_resource_metadata(:product_transaction, ash_resource: MirrorAsh.ProductTransaction)
  end

  defmodule WithoutOptions do
    use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

    auix_resource_metadata(:product)
    auix_create_ui()
  end

  defmodule CtxFieldChanges do
    use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

    auix_resource_metadata :product do
      context MirrorCtx
      schema(MirrorCtx.Product)
      field(:inactive, length: 10)
      field(:name, sortable?: false)
      field(:inserted_at, hidden: true)
      fields([:weight, :length, :width, :height], precision: 16, scale: 3)
      # :height field properties are changed again, the last one should be the one prevailing
      field(:height, scale: 1)
      field(:data_virtual, html_type: :checkbox)
      field(:status, renderer_opts: [max: 5])
      field(:contacts, expanded: true)
    end
  end

  defmodule AshFieldChanges do
    use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

    auix_resource_metadata :product do
      ash_resource(MirrorAsh.Product)
      field(:inactive, length: 10)
      field(:name, sortable?: false)
      field(:inserted_at, hidden: true)
      fields([:weight, :length, :width, :height], precision: 16, scale: 3)
      # :height field properties are changed again, the last one should be the one prevailing
      field(:height, scale: 1)
      field(:data_virtual, html_type: :checkbox)
      field(:status, renderer_opts: [max: 5])
      field(:contacts, expanded: true)
    end
  end

  @backends [
    %{
      name: :ash,
      source: "ash_resource Aurora.Uix.Test.MirrorAsh.Product",
      defaults: AshDefaults,
      field_changes: AshFieldChanges,
      product: MirrorAsh.Product,
      product_transaction: MirrorAsh.ProductTransaction,
      context: nil
    },
    %{
      name: :ctx,
      source: "context Aurora.Uix.Test.MirrorCtx\n    schema Aurora.Uix.Test.MirrorCtx.Product",
      defaults: CtxDefaults,
      field_changes: CtxFieldChanges,
      product: MirrorCtx.Product,
      product_transaction: MirrorCtx.ProductTransaction,
      context: MirrorCtx
    }
  ]

  test "a resource takes its defaults from its schema" do
    for backend <- @backends do
      labelled("[backend: #{backend.name}]", fn ->
        defaults = resource_configs(backend.defaults)

        validate_schema(defaults, :product,
          cost: %{html_type: :number, name: "cost", label: "Cost", precision: 10, scale: 2}
        )

        validate_schema(defaults, :product_transaction,
          product_id: %{html_type: :select, name: "product_id", length: 36}
        )

        for {name, schema} <- [
              product: backend.product,
              product_transaction: backend.product_transaction
            ] do
          resource = backend.defaults.auix_resource(name)

          assert resource.schema == schema
          assert resource.context == backend.context
          assert resource.fields != nil
          assert resource.fields != []
        end
      end)
    end

    resource_configs = resource_configs(WithoutOptions)
    assert is_nil(Map.get(resource_configs, :product_transaction))
    product = Map.get(resource_configs, :product)

    assert is_nil(Map.get(product, :schema))
    assert is_nil(Map.get(product, :context))
    assert product |> Map.get(:fields, %{}) |> Enum.empty?()

    refute WithoutOptions |> Module.concat(Index) |> Code.ensure_loaded?()
  end

  test "field declarations change the parsed fields, the last one winning" do
    for backend <- @backends do
      labelled("[backend: #{backend.name}]", fn ->
        field_changes = resource_configs(backend.field_changes)

        validate_schema(field_changes, :product,
          inactive: %{html_type: :checkbox, name: "inactive", label: "Inactive", length: 10},
          reference: %{sortable?: true},
          name: %{sortable?: false},
          inserted_at: %{hidden: true},
          weight: %{precision: 16, scale: 3},
          length: %{precision: 16, scale: 3},
          width: %{precision: 16, scale: 3},
          # Order is important, scale is changed, once again on the :height field
          height: %{precision: 16, scale: 1},
          data_virtual: %{html_type: :checkbox, sortable?: false},
          status: %{renderer_opts: [max: 5]}
        )

        contacts = get_in(field_changes, [:product, Access.key!(:fields), :contacts])

        assert contacts.expanded == true
        # The embeds_many source-of-truth keys must survive the override.
        assert Map.has_key?(contacts.data, :related)
        assert Map.has_key?(contacts.data, :owner)
        assert Map.has_key?(contacts.data, :resource)
      end)
    end
  end

  test "fields_order follows the declaration order" do
    ash_order =
      ~w(id reference name description status grade labels quantity_initial quantity_at_hand cost
         msrp rrp list_price discounted_price weight length width height quantity_entries
         quantity_exits units_per_box margin released_on opens_at audited_at discontinued_at image
         thumbnail deleted inactive packaging contacts product_location_id summary
         suppliers_join_assoc product_location product_transactions product_barcode suppliers)a

    ctx_order =
      ~w(id reference name description quantity_at_hand quantity_initial quantity_entries
         quantity_exits cost msrp rrp list_price discounted_price weight length width height image
         thumbnail status grade labels units_per_box margin released_on opens_at audited_at
         discontinued_at deleted inactive packaging contacts product_location_id
         product_transactions product_barcode product_location suppliers data_virtual)a

    for {backend, expected} <- Enum.zip(@backends, [ash_order, ctx_order]) do
      labelled("[backend: #{backend.name}]", fn ->
        fields_order =
          backend.field_changes
          |> resource_configs()
          |> get_in([Access.key!(:product), Access.key!(:fields_order)])

        assert_values_order(fields_order, expected)
      end)
    end
  end

  test "auix_create_ui with no layout generates the index and the form modules" do
    for backend <- @backends do
      labelled("[backend: #{backend.name}]", fn ->
        ui =
          compile_ui(
            "auix_resource_metadata :product do\n    #{backend.source}\n  end\n\n  auix_create_ui()"
          )

        index_functions = Module.concat(ui, Product.Index).__info__(:functions)
        assert {:__live__, 0} in index_functions
        assert {:handle_params, 3} in index_functions
        assert {:handle_event, 3} in index_functions
        assert {:handle_info, 2} in index_functions

        form_functions = Module.concat(ui, Product.FormComponent).__info__(:functions)
        assert {:__live__, 0} in form_functions
        assert {:__components__, 0} in form_functions
        assert {:update, 2} in form_functions
        assert {:handle_event, 3} in form_functions

        product = ui.auix_resource(:product)
        assert product.schema == backend.product
        assert product.context == backend.context
        assert product.fields != nil
        assert product.fields != []
      end)
    end
  end

  test "a field declared generated? is loaded with the entity" do
    for backend <- @backends do
      labelled("[backend: #{backend.name}]", fn ->
        assert :name in compile_generated(backend, "generated?: true").auix_preloads().product
        refute :name in compile_generated(backend, "label: \"Name\"").auix_preloads().product
      end)
    end
  end

  test "a declared resource decides whether an embedded schema is embedded" do
    body_a = """
      auix_resource_metadata :person,
        schema: Aurora.Uix.Test.Cases.ResourceMetadataTest.Person,
        context: Aurora.Uix.Test.MirrorCtx
    """

    body_b =
      body_a <>
        """
          auix_resource_metadata :person__address,
            schema: Aurora.Uix.Test.Cases.ResourceMetadataTest.Address,
            context: Aurora.Uix.Test.MirrorCtx
        """

    [{a, _}] = compile(body_a)
    assert a.auix_resource(:person__address).embedded?

    [{b, _}] = compile(body_b)
    refute b.auix_resource(:person__address).embedded?
  end

  test "declared and imported resources link the associations of a resource" do
    meta = compile_meta()

    imports =
      "@auix_resource_metadata %{product_transaction: #{inspect(meta)}.auix_resource(:product_transaction), product_location: #{inspect(meta)}.auix_resource(:product_location)}"

    declare =
      "auix_resource_metadata :catalog_product, context: Aurora.Uix.Test.MirrorCtx, schema: Aurora.Uix.Test.MirrorCtx.Product"

    for body <- [declare <> "\n" <> imports, imports <> "\n" <> declare] do
      [{mod, _}] = compile(body)
      fields = mod.auix_resource(:catalog_product).fields
      assert fields.product_transactions.data.resource == :product_transaction
      assert fields.product_location_id.data.resource == :product_location
      assert fields.product_location_id.html_type == :select
    end

    [{article_mod, _}] =
      compile("""
        auix_resource_metadata :article, ash_resource: Aurora.Uix.Test.MirrorAsh.Product
        @auix_resource_metadata %{author: #{inspect(meta)}.auix_resource(:author)}
      """)

    assert article_mod.auix_resource(:article).fields.product_location.data.resource == :author

    local =
      "auix_resource_metadata :local_location, context: Aurora.Uix.Test.MirrorCtx, schema: Aurora.Uix.Test.MirrorCtx.ProductLocation"

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

  test "resource: links an embedded field and an association to a named resource" do
    meta = compile_meta()

    [{post_mod, _}] =
      compile("""
        auix_resource_metadata :post do
          ash_resource Aurora.Uix.Test.MirrorAsh.Product
          field :packaging, resource: :my_comment
          field :product_location, resource: :writer
        end

        auix_resource_metadata :my_comment, ash_resource: Aurora.Uix.Test.MirrorAsh.Packaging
        auix_resource_metadata :writer, ash_resource: Aurora.Uix.Test.MirrorAsh.ProductLocation
        auix_resource_metadata :author, ash_resource: Aurora.Uix.Test.MirrorAsh.ProductLocation
      """)

    post_fields = post_mod.auix_resource(:post).fields

    assert {post_fields.packaging.resource, post_fields.packaging.data.resource} ==
             {:post, :my_comment}

    assert {post_fields.product_location.resource, post_fields.product_location.data.resource} ==
             {:post, :writer}

    assert post_fields.product_location_id.data.resource == :writer

    [{user_mod, _}] =
      compile("""
        auix_resource_metadata :user do
          schema Aurora.Uix.Test.MirrorCtx.Product
          context Aurora.Uix.Test.MirrorCtx
          field :packaging, resource: :profile_card
        end

        auix_resource_metadata :profile_card, schema: Aurora.Uix.Test.MirrorCtx.Product.Packaging
      """)

    packaging = user_mod.auix_resource(:user).fields.packaging
    assert {packaging.resource, packaging.data.resource} == {:user, :profile_card}

    [{catalog_mod, _}] =
      compile("""
        @auix_resource_metadata %{product_location: #{inspect(meta)}.auix_resource(:product_location)}

        auix_resource_metadata :catalog_product do
          schema Aurora.Uix.Test.MirrorCtx.Product
          context Aurora.Uix.Test.MirrorCtx
          field :product_location, resource: :product_location
        end
      """)

    product_location = catalog_mod.auix_resource(:catalog_product).fields.product_location

    assert {product_location.resource, product_location.data.resource} ==
             {:catalog_product, :product_location}
  end

  test "field options that fail compilation" do
    generated_field = fn field_options ->
      """
        auix_resource_metadata :product do
          context Aurora.Uix.Test.MirrorCtx
          schema Aurora.Uix.Test.MirrorCtx.Product
          field :name, #{field_options}
        end

        auix_create_ui do
          index_columns :product, [:reference, :name]
        end
      """
    end

    cases = [
      {"an unknown field option",
       """
         auix_resource_metadata :product do
           schema Aurora.Uix.Test.MirrorCtx.Product
           context Aurora.Uix.Test.MirrorCtx
           field :name, lable: "Name"
         end
       """, ~r/unknown options \[:lable\]/},
      {"generated? must be a boolean", generated_field.("generated?: \"yes\""), ~r/generated\?/},
      {"data no longer accepts generated", generated_field.("data: %{generated: true}"),
       ~r/unknown options \[:generated\]/}
    ]

    assert_compile_errors(cases)
  end

  test "a failed compilation leaves nothing behind for the next one in the process" do
    for backend <- @backends do
      valid = """
        auix_resource_metadata :product do
          #{backend.source}
        end
      """

      cases = [
        {"#{backend.name}: a nested field with an unknown option",
         """
           auix_resource_metadata :product do
             #{backend.source}
             field :name, lable: "Name"
           end
         """, ~r/unknown options \[:lable\]/},
        {"#{backend.name}: a layout with an unknown option",
         """
         #{valid}
           auix_create_ui do
             index_columns :product, [:reference], page_tittle: "x"
           end
         """, ~r/unknown index layout options \[:page_tittle\]/}
      ]

      for {label, failing, regex} <- cases do
        labelled(label, fn ->
          assert_raise(DslError, regex, fn -> compile_ui(failing) end)
          assert is_atom(compile_ui(valid))
        end)
      end
    end
  end

  test "resource options that fail compilation" do
    cases = [
      {"a mistyped resource option",
       """
         auix_resource_metadata :product,
           schema: Aurora.Uix.Test.MirrorCtx.Product,
           context: Aurora.Uix.Test.MirrorCtx,
           renderers: :toggle_switch
       """, ~r/renderers/},
      {"a mistyped resource preload",
       """
         auix_resource_metadata :product,
           schema: Aurora.Uix.Test.MirrorCtx.Product,
           context: Aurora.Uix.Test.MirrorCtx,
           preload: :product_location
       """, ~r/preload/},
      {"a context resource without :context",
       """
         auix_resource_metadata :product, schema: Aurora.Uix.Test.MirrorCtx.Product
       """,
       ~r/requires the `:context` option: Aurora\.Uix\.Test\.MirrorCtx\.Product has a table, so :product is a standalone resource\. Give `context:` with its CRUD functions/},
      {"backend options validated by the backend",
       """
         auix_resource_metadata :product,
           schema: Aurora.Uix.Test.MirrorCtx.Product,
           context: Aurora.Uix.Test.MirrorCtx,
           backend_opts: [ash_actor_assign: :current_user]
       """, ~r/unknown options \[:ash_actor_assign\]/}
    ]

    assert_compile_errors(cases)
  end

  test "resource: links that fail compilation" do
    plain_field = fn field ->
      """
        auix_resource_metadata :product do
          schema Aurora.Uix.Test.MirrorCtx.Product
          context Aurora.Uix.Test.MirrorCtx
          field #{inspect(field)}, resource: :product_location
        end

        auix_resource_metadata :product_location,
          context: Aurora.Uix.Test.MirrorCtx,
          schema: Aurora.Uix.Test.MirrorCtx.ProductLocation
      """
    end

    cases = [
      {"resource: with an unknown name",
       """
         auix_resource_metadata :product do
           schema Aurora.Uix.Test.MirrorCtx.Product
           context Aurora.Uix.Test.MirrorCtx
           field :product_location, resource: :nowhere
         end
       """, ~r/field :product_location of :product links to the unknown resource :nowhere/},
      {"resource: with a resource on another schema",
       """
         auix_resource_metadata :product do
           schema Aurora.Uix.Test.MirrorCtx.Product
           context Aurora.Uix.Test.MirrorCtx
           field :product_location, resource: :movement
         end

         auix_resource_metadata :movement,
           context: Aurora.Uix.Test.MirrorCtx,
           schema: Aurora.Uix.Test.MirrorCtx.ProductTransaction
       """,
       ~r/field :product_location of :product links to the resource :movement, whose schema is Aurora\.Uix\.Test\.MirrorCtx\.ProductTransaction; the field relates to Aurora\.Uix\.Test\.MirrorCtx\.ProductLocation/},
      {"resource: on a plain field", plain_field.(:name),
       ~r/`resource:` on field :name of :product is not allowed: its type is :string, and only an embedded field or an association links to a resource/},
      {"resource: on a foreign key", plain_field.(:product_location_id),
       ~r/`resource:` on field :product_location_id of :product is not allowed: .* Put `resource:` on the association field :product_location/}
    ]

    assert_compile_errors(cases)
  end

  @spec assert_compile_errors([{binary(), binary(), Regex.t()}]) :: term()
  defp assert_compile_errors(cases) do
    for compile_case <- cases, do: assert_compile_error(compile_case)
  end

  @spec assert_compile_error({binary(), binary(), Regex.t()}) :: term()
  defp assert_compile_error({label, body, regex}) do
    labelled(label, fn ->
      assert_raise(DslError, regex, fn -> compile(body) end)
    end)
  end

  @spec compile_generated(map(), binary()) :: module()
  defp compile_generated(backend, field_options) do
    compile_ui("""
    auix_resource_metadata :product do
      #{backend.source}
      field :name, #{field_options}
    end

    auix_create_ui do
      index_columns :product, [:reference, :name]
    end
    """)
  end

  # `auix_create_ui` resolves the web module from the caller's namespace, so a module that
  # generates views is named under `Aurora.UixWeb`.
  @spec compile_ui(binary()) :: module()
  defp compile_ui(body) do
    name =
      Module.concat(
        Aurora.UixWeb.Test,
        "ResourceMetadataSample#{System.unique_integer([:positive])}"
      )

    Code.compile_string("""
    defmodule #{inspect(name)} do
      use Aurora.Uix

    #{body}
    end
    """)

    name
  end

  @spec compile(binary()) :: [{module(), binary()}]
  defp compile(body) do
    Code.compile_string("""
    defmodule Aurora.Uix.Test.Cases.ResourceMetadataTest.Sample#{System.unique_integer([:positive])} do
      use Aurora.Uix

    #{body}
    end
    """)
  end

  @spec compile_meta() :: module()
  defp compile_meta do
    [{meta, _}] =
      compile("""
        auix_resource_metadata :product_transaction,
          context: Aurora.Uix.Test.MirrorCtx,
          schema: Aurora.Uix.Test.MirrorCtx.ProductTransaction

        auix_resource_metadata :product_location,
          context: Aurora.Uix.Test.MirrorCtx,
          schema: Aurora.Uix.Test.MirrorCtx.ProductLocation

        auix_resource_metadata :author, ash_resource: Aurora.Uix.Test.MirrorAsh.ProductLocation
      """)

    meta
  end

  @spec labelled(binary(), (-> any())) :: any()
  defp labelled(label, fun) do
    fun.()
  rescue
    error in ExUnit.AssertionError ->
      reraise %{error | message: "#{label}: #{error.message}"}, __STACKTRACE__
  end
end
