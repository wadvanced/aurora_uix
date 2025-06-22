# Layout System

Aurora UIX provides a flexible layout DSL for forms, lists, and detail views.

## Basic Layouts

Define layouts using macros:

```elixir
auix_create_ui do
  index_columns :product, [:reference, :name]
  edit_layout :product do
    inline [:reference, :name, :description]
  end
end
```

## Sub-Layouts

- `inline`: Horizontal grouping.
- `stacked`: Vertical grouping.
- `group`: Visual grouping with a title.
- `sections`: Tabbed sections.

Example:

```elixir
edit_layout :product do
  sections do
    section "Details" do
      group "Identification", [:reference, :name]
      stacked [:description]
    end
    section "Prices", [:price, :discount]
  end
end
```

## Default Layouts

If you omit a layout, Aurora UIX generates a sensible default.

## Next Steps
- [LiveView Integration](liveview.md)
- [Advanced Usage](../advanced/advanced_usage.md)