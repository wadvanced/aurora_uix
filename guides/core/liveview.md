# LiveView Integration

Aurora UIX is designed to work seamlessly with Phoenix LiveView.

## Usage

Use the generated modules in your router and templates as you would with any LiveView.

Example route:

```elixir
live "/products", MyAppWeb.ProductViews.Product.Index
```

## Events

Aurora UIX handles standard CRUD events and navigation. You can add custom event handlers as needed.

