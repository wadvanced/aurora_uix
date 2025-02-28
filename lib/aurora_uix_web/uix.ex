defmodule AuroraUixWeb.Uix do
  @moduledoc """
  Provides a low-code, opinionated framework for building dynamic UIs in Phoenix applications.

  This module simplifies UI development by offering declarative tools for schema configuration
  and UI composition. It is designed to reduce boilerplate code while maintaining flexibility
  for customization.

  ## Key Features

  ### 1. Schema Configuration (`auix_resource_config`)
  - Attaches UI-specific metadata to schemas or structured data.
  - Enables consistent rendering of forms, lists, and detail views.
  - Supports customization of field labels, placeholders, validation rules, and more.
  - Works with Ecto schemas, structs, or any structured data format.

  ### 2. UI Composition (`auix_create_ui`)
  - Dynamically generates UI layouts based on schema metadata.
  - Provides pre-built templates for common UI patterns (forms, tables, etc.).
  - Allows customization of layout and interaction logic.
  - Integrates seamlessly with Phoenix LiveView.

  ## Getting Started

  To use `AuroraUixWeb.Uix`, simply `use` it in your module:

  ```elixir
  defmodule MyAppWeb.ProductView do
    use AuroraUixWeb.Uix

    # Define schema configuration
    auix_resource_config :product,
      schema: MyApp.Product,
      context: MyApp.Products do
      field :name, placeholder: "Product name", max_length: 40, required: true
      field :description, max_length: 255
      field :price, precision: 12, scale: 2, readonly: true
    end

    # Create a UI layout
    auix_create_ui :product, actions: [:create, :update] do
      index: [:name, :price]
    end
  end
  ```

  ## Use Cases
  * Rapid prototyping of UIs for CRUD operations.
  * Consistent rendering of forms and tables across an application.
  * Customizable UI components with minimal boilerplate.
  * Integration with Phoenix LiveView for real-time updates.

  ## Example: Full Workflow

  ```elixir
  defmodule MyAppWeb.UserView do
    use AuroraUixWeb.Uix

    # Configure schema metadata
    auix_resource_config :user,
      schema: MyApp.Accounts.User,
      context: MyApp.Accounts do
      field :email, placeholder: "user@example.com", required: true
      field :password, html_type: :password, required: true
    end

    # Generate a UI layout
    auix_create_ui :user,
      actions: [:new, :create],
      renderer: &CustomComponents.registration_form/1
    end
  end
  ```

  ## Opinionated Design
  This module is intentionally opinionated to:

  * Reduce decision fatigue by providing sensible defaults.
  * Encourage consistent UI patterns across applications.
  * Minimize boilerplate code for common use cases.

  While it provides flexibility for customization, it works best when embracing its conventions.
  """
  alias AuroraUixWeb.Uix.CreateUI
  alias AuroraUixWeb.Uix.DataConfigUI

  require Logger

  @doc false
  defmacro __using__(_opts) do
    quote do
      import CreateUI,
        only: [auix_create_ui: 0, auix_create_ui: 1, auix_create_ui: 2]

      import DataConfigUI,
        only: [auix_resource_config: 1, auix_resource_config: 2, auix_resource_config: 3]

      Module.register_attribute(__MODULE__, :_auix_resource_configs, accumulate: true)
    end
  end
end
