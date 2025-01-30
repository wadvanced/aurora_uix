defmodule AuroraUixWeb.Uix do
  @moduledoc """
  Provides tools for low-code, highly opinionated view rendering and handling in Phoenix applications.

  This module introduces two key features:

  1. `auix_schema_metadata`: Adds UI-specific metadata to schemas to enhance their rendering capabilities in forms, lists, and other views.
  2. `auix_define`: Allows for the composition of UI layouts and interaction logic by leveraging schema metadata.

  ## `auix_schema_metadata`

  Ecto schemas typically lack the metadata required for rendering user interfaces effectively.
  This macro enriches schemas with metadata for UI purposes, such as field visibility, placeholders, validation rules, and layout grouping.

  ### Example:

  ```elixir
    defmodule MyApp.Product do
      use Ecto.Schema
      import Ecto.Changeset

      schema "products" do
        field :name, :string
        field :price, :float
        field :quantity, :integer
        belongs_to :category, MyApp.Category

        timestamps()
      end
    end

    defmodule MyApp.Category do
      use Ecto.Schema
      import Ecto.Changeset

      schema "categories" do
        field :name, :string
        has_many :products, MyApp.Product

        timestamps()
      end
    end

    defmodule MyAppWeb.ProductLive.Index do
      auix_schema_metadata :product, schema: MyApp.Product, context: MyApp.Inventory do
        field :id, hidden: true
        field :name, placeholder: "Product name", max_length: 40, required: true
        field :price, placeholder: "Price", precision: 12, scale: 2
      end

      auix_schema_metadata :category, schema: MyApp.Category do
        field :id, readonly: true
        field :name, max_length: 20, required: true
      end
    end
  ```

  ## `auix_define`
  This macro defines the layout and behavior of the views and components to be rendered.
  It relies on the metadata defined through auix_schema_metadata to determine field characteristics.

  ### Example
    ```elixir
    defmodule MyAppWeb.ProductLive.Index do
      ## These two lines should create a complete CRUD for the schema MyApp.Product
      auix_schema_metadata :product, schema: MyApp.Product, context: MyApp.Inventory
      auix_define for: :product
    end
  ```

  ```elixir
    defmodule MyAppWeb.ProductLive.Index do
      auix_define do
        layout :form, :component do
          group "Product" do
            row product: name, product: price
          end
          group "Category Details" do
            row category: (field :name, readonly: true)
          end
          tab "Sales" do
            row _assigns: :last_quarter
          end
          tab "Forecast" do
            group "Next Semester" do
              row forecast: :quantities
              row forecast: :revenues
            end
            group "Next Year" do
              row forecast_next: :quantities
              row forecast_next: :revenues
            end
          end
        end

        layout :list, :index do
          row :category_name, :product_name, :product_quantity
        end
      end
    end
  ```

  """
  alias AuroraUixWeb.Uix
  alias AuroraUixWeb.Uix.DefineUI
  alias AuroraUixWeb.Uix.SchemaMetadataUI

  require Logger

  defmacro __using__(_opts) do
    quote do
      import Uix
      Module.register_attribute(__MODULE__, :_auix_schemas, accumulate: true)
      @before_compile AuroraUixWeb.Uix
    end
  end

  defmacro __before_compile__(env) do
    ## Schema metadata definitions are returned in reversed order.
    schema_metadata = env.module |> Module.get_attribute(:_auix_schemas) |> Enum.reverse()
    ## Field modifications are returned in reversed order.
    fields = env.module |> Module.get_attribute(:_auix_fields) |> Enum.reverse()

    Module.delete_attribute(env.module, :_auix_schemas)
    Module.delete_attribute(env.module, :_auix_fields)

    schema_metadata
    |> SchemaMetadataUI.__merge_schemas_and_fields__(fields)
    |> then(&Module.put_attribute(env.module, :_auix_schemas, &1))

    quote do
      :ok
    end
  end

  defmacro auix_schema_metadata(name, opts \\ []) do
    schema_metadata = AuroraUixWeb.Uix.__schema_metadata__(name, opts)

    quote do
      unquote(schema_metadata)
    end
  end

  defmacro auix_schema_metadata(name, opts, do: block) do
    schema_metadata = AuroraUixWeb.Uix.__schema_metadata__(name, opts)

    quote do
      unquote(schema_metadata)
      unquote(block)
    end
  end

  defmacro auix_define(opts \\ []) do
    quote do
      import DefineUI, only: [layout: 2, layout: 3, layout: 4]

      DefineUI.__auix_define__(__MODULE__, unquote(opts))
    end
  end

  defmacro auix_define(opts, do: block) do
    quote do
      import DefineUI, only: [layout: 2, layout: 3, layout: 4]

      DefineUI.__auix_define__(__MODULE__, unquote(opts))
      unquote(block)
    end
  end

  @spec __schema_metadata__(atom, Keyword.t()) :: Macro.t()
  def __schema_metadata__(name, opts) do
    quote do
      use SchemaMetadataUI, schema_name: unquote(name)

      schema_metadata =
        SchemaMetadataUI.__auix_metadata__(
          unquote(name),
          unquote(opts)
        )

      Module.put_attribute(__MODULE__, :_auix_schemas, {unquote(name), schema_metadata})
    end
  end
end
