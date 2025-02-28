defmodule AuroraUixWeb.Uix.LayoutConfigUI.Inline do
  @moduledoc ~S"""
  Provides macros for defining inline field arrangements in a form layout.

  This module is used within `layout` to specify which fields should be displayed in a single row.
  Inline layouts allow for a more compact presentation of related fields, improving readability and usability.

  ## Usage

  The `inline/1` macro defines a row of fields that should be rendered together, space permitting.

  ### Example

  ```elixir
  defmodule ProductViews do
    alias MyApp.Inventory
    alias MyApp.Inventory.Product

    auix_resource_config(:product, context: Inventory, schema: Product)

    auix_create_ui do
      layout :product do
        inline [:name, :description, :price]
      end
    end
  end
  ```

  In this example, `name`, `description`, and `price` will be displayed on the same row when screen size allows.

  ### Defining Field Characteristics

  Fields inside an `inline` block can be customized individually using keyword options:

  ```elixir
  inline [name: [required: true], description: [length: 50], price: [scale: 2]]
  ```

  Each field can have specific UI properties while still being part of the same inline layout.

  ### Responsive Behavior

  If there isn’t enough space, fields will be wrapped to the next line based on the available screen width.
  On mobile devices, each field may be displayed in its own row.
  """

  alias AuroraUixWeb.Uix.LayoutConfigUI

  @doc """
  Defines an inline row of fields for a form layout.

  ## Parameters
    - `fields` (list): A list of field atoms to be displayed inline.

  ## Example

  ```elixir
    inline [:name, :email, :phone]
  ```

  This will render name, email, and phone in a single row (if space allows).
  """
  @spec inline(list | Keyword.t()) :: Macro.t()
  defmacro inline(fields) do
    inline =
      quote do
        current_container = Module.get_attribute(__MODULE__, :_auix_current_container, [])

        __MODULE__
        |> LayoutConfigUI.__expand_fields__(unquote(fields))
        |> then(
          &Module.put_attribute(__MODULE__, :_auix_current_container, [
            {:inline, &1} | current_container
          ])
        )
      end

    quote do
      unquote(inline)
    end
  end
end
