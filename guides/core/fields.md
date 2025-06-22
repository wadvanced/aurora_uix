# Customizing Fields

You can customize field behavior and appearance in Aurora UIX.

## Field Options

- `field_html_type` — The HTML type of the field. Handled types: `:text`, `:number`, `:checkbox`, `:select`, `:datetime-local`, `:time`, `:one_to_many_association`, `:many_to_one_association`.
- `html_id` — A unique HTML id for the field.
- `renderer` — A custom rendering function for the field.
- `label` — Display label for the field.
- `placeholder` — Placeholder text for input fields.
- `length` — Maximum allowed length of input (integer).
- `precision` — Number of digits for numeric fields.
- `scale` — Number of digits to the right of the decimal separator for numeric fields.
- `hidden: true` — Hide the field from the UI (included but not visible).
- `readonly: true` — Make the field read-only.
- `required: true` — Field must not be empty.
- `disabled: true` — Field does not participate in form interaction.
- `omitted: true` — Field is not displayed or used at all (as if it doesn't exist).

Example:

```elixir
auix_resource_metadata :product, schema: MyApp.Product do
  field :id, hidden: true
  field :reference, readonly: true, length: 30
  field :description, length: 255, required: true, placeholder: "Enter description"
  field :price, field_html_type: :number, precision: 8, scale: 2
  field :category_id, field_html_type: :select, option_label: :name
  field :avatar, renderer: &MyAppWeb.Helpers.avatar/1
end
```

## Associations

Aurora UIX supports associations (`has_many`, `belongs_to`).

### Many-to-One

For **many-to-one associations** (such as `belongs_to`), you can use the `option_label` field option to control how related records are displayed in select dropdowns. This allows you to customize the label shown for each option in the dropdown.

See [Resource Metadata: Associations](../resource_metadata.md#associations) for detailed usage and examples.

### One-to-Many

For **one-to-many associations** (`has_many`), the `option_label` option is not applicable.
