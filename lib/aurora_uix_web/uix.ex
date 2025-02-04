defmodule AuroraUixWeb.Uix do
  @moduledoc """
  Provides tools for low-code, highly opinionated view rendering and handling in Phoenix applications.

  This module introduces two key features:

  1. `auix_schema_config`: Adds UI-specific metadata to schemas to enhance their rendering capabilities in forms, lists, and other views.
  2. `auix_create_ui`: Allows for the composition of UI layouts and interaction logic by leveraging schema metadata.

  ## `auix_schema_config`

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
      auix_schema_config :product, schema: MyApp.Product, context: MyApp.Inventory do
        field :id, hidden: true
        field :name, placeholder: "Product name", max_length: 40, required: true
        field :price, placeholder: "Price", precision: 12, scale: 2
      end

      auix_schema_config :category, schema: MyApp.Category do
        field :id, readonly: true
        field :name, max_length: 20, required: true
      end
    end
  ```

  ## `auix_create_ui`
  This macro defines the layout and behavior of the views and components to be rendered.
  It relies on the metadata defined through auix_schema_config to determine field characteristics.

  ### Example
    ```elixir
    defmodule MyAppWeb.ProductLive.Index do
      ## These two lines should create a complete CRUD for the schema MyApp.Product
      auix_schema_config :product, schema: MyApp.Product, context: MyApp.Inventory
      auix_create_ui for: :product
    end
  ```

  ```elixir
    defmodule MyAppWeb.ProductLive.Index do
      auix_create_ui do
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
  alias AuroraUixWeb.Uix.CreateUI
  alias AuroraUixWeb.Uix.SchemaConfigUI

  require Logger

  defmacro __using__(_opts) do
    quote do
      import Uix
      Module.register_attribute(__MODULE__, :_auix_schema_configs, accumulate: true)
      Module.register_attribute(__MODULE__, :_auix_layouts, accumulate: true)
    end
  end

  defmacro auix_schema_config(name, opts \\ []) do
    schema_config = AuroraUixWeb.Uix.__register_schema_config__(name, opts)

    quote do
      unquote(schema_config)
    end
  end

  defmacro auix_schema_config(name, opts, do: block) do
    schema_config = AuroraUixWeb.Uix.__register_schema_config__(name, opts)

    quote do
      unquote(schema_config)
      unquote(block)
    end
  end

  defmacro auix_create_ui(opts \\ []) do
    quote do
      use CreateUI
      Module.put_attribute(__MODULE__, :_auix_layouts_opts, unquote(opts))
    end
  end

  defmacro auix_create_ui(opts, do: block) do
    quote do
      use CreateUI
      Module.put_attribute(__MODULE__, :_auix_layouts_opts, unquote(opts))
      unquote(block)
    end
  end

  @doc """
  Registers schema metadata and configuration for a given schema within the module.

  See `AuroraUix.SchemaConfigUI.__auix_schema_config__/2` for more details.

  """
  @spec __register_schema_config__(atom, Keyword.t()) :: Macro.t()
  def __register_schema_config__(name, opts) do
    quote do
      use SchemaConfigUI, schema_name: unquote(name)

      schema_config =
        SchemaConfigUI.__auix_schema_config__(
          unquote(name),
          unquote(opts)
        )

      Module.put_attribute(__MODULE__, :_auix_schema_configs, {unquote(name), schema_config})
    end
  end
end
