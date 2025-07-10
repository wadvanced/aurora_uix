# Advanced Usage

This guide covers advanced topics for customizing and extending Aurora UIX.

## Custom Templates

You can provide your own template modules by implementing the `Aurora.Uix.Template` behaviour. Your module must implement the following required callbacks:

- `generate_module/1`: Generates the handling code (LiveView modules, components, etc.) for a given layout type and configuration.
- `default_core_components_module/0`: Returns the module containing your core UI components (such as forms, tables, modals).
- `css_classes/0`: Returns a map of CSS class mappings for different template components.

These callbacks allow you to control how UI modules and markup are generated for your application.

Aurora UIX provides a built-in basic template implementation at `Aurora.Uix.Web.Templates.Basic`, which you can use as a reference or starting point for your own templates.

## Overriding Core Components

You can override the default core components by passing a custom module when using the `Aurora.Uix.Web.CoreComponentsImporter`:

```elixir
use Aurora.Uix.Web.CoreComponentsImporter, core_components_module: MyAppWeb.MyCoreComponents
```

Alternatively, you can set the default core components module globally using your `config.exs` or environment-specific config file:

```elixir
config :aurora_uix, :core_components_module, MyAppWeb.MyCoreComponents
```

When this config is set, Aurora UIX will use your custom core components module throughout the application, unless a different module is explicitly passed to `CoreComponentsImporter`.

## Notes

- Only the callbacks listed above are required by the core behavior and present in the default template implementation. If you need custom markup or layout parsing, you can add additional functions to your own template modules.
- The built-in templates and helpers are designed for extensibility. You can create your own helpers or override any part of the rendering pipeline by providing your own modules.
