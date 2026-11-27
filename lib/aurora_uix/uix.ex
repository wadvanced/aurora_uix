defmodule Aurora.Uix do
  @moduledoc """
  Generates the index, form and show views of Ecto schemas and Ash resources in a Phoenix
  application.

  ## Key Features

  - `auix_resource_metadata` describes a resource: its schema, its backend and the options of
    its fields. See `Aurora.Uix.Layout.ResourceMetadata`.
  - `auix_create_ui` generates the LiveView and the components of the declared resources from
    their layouts. See `Aurora.Uix.Layout.CreateUI`.
  - `use Aurora.Uix, renderers: %{checkbox: :toggle_switch}` sets the renderer of every field of
    an HTML type for every resource of the module. `auix_resource_metadata`, `auix_create_ui`,
    `index_columns`, `edit_layout` and `show_layout` accept the same option; see
    `Aurora.Uix.Renderers` for the precedence.

  ## Key Constraints

  - Used through `use Aurora.Uix`.
  - A resource is an Ecto schema with an `aurora_ctx` style context, or an Ash resource. A custom
    backend can be registered.

  ## Example

  ```elixir
  defmodule MyAppWeb.ProductViews do
    use Aurora.Uix

    alias MyApp.Inventory
    alias MyApp.Inventory.Product

    auix_resource_metadata :product do
      context Inventory
      schema Product
      field :name, placeholder: "Product name", length: 40, required: true
      field :list_price, precision: 12, scale: 2, readonly: true
    end

    auix_create_ui do
      index_columns :product, [:name, :list_price]

      edit_layout :product do
        stacked [:name, :description, :list_price]
      end
    end
  end
  ```

  Route the generated views with `Aurora.Uix.RouteHelper.auix_live_resources/3`, inside your web
  scope:

  ```elixir
  auix_live_resources("/products", ProductViews.Product)
  ```
  """
  use StructInspect.Overrides

  alias Aurora.Uix.Template

  require Logger

  @doc false
  defmacro __using__(opts) do
    quote do
      use Aurora.Uix.Dsl

      @auix_html_type_renderers unquote(Keyword.get(opts, :renderers, Macro.escape(%{})))
      Module.register_attribute(__MODULE__, :auix_resource_metadata, accumulate: true)
      Module.register_attribute(__MODULE__, :auix_modules, accumulate: true)

      @auix_template Template.uix_template()
      @auix_layout_tags Template.uix_template().layout_tags()
    end
  end
end
