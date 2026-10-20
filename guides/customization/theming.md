# Creating Custom Registered Themes

Aurora UIX's theme system composes CSS from Elixir modules. A theme declares its rules by name and includes another theme for everything it does not declare, so you create a custom theme by extending the base rules with your own color palette and styling.

## Understanding the Theme Architecture

Aurora UIX themes follow a four-layer include chain:

**Layer 1: Color Palette**
- Defines all color variables for a specific theme variant
- Declares the `:root_colors` rule
- Implements both light and dark mode variants
- Theme-specific and forms the foundation
- Example: `VitreousMarble` theme with Slate/Cyan/Ruby colors
- Includes Layer 2 (`ThemeBase`) for everything else

**Layer 2: Color Aliases**
- Defines `:root_color_aliases` - component-specific color variables (buttons, inputs,
  tables, labels, …) that each default to a generic semantic var from Layer 1
- Sits between the theme palette and the structural variables, so a single alias can be
  overridden to restyle one component without touching its siblings
- Shared across all themes - implemented once in `ThemeBase`
- Includes Layer 3 (`BaseVariables`) for everything else

**Layer 3: Base Variables**
- Defines all structural CSS variables (sizes, spacing, fonts, shadows)
- Color-agnostic - contains only dimension and layout properties
- Includes `Base` for the class rules
- Example: `BaseVariables` defines `--auix-padding-default`, `--auix-border-radius-default`, etc.

**Layer 4: Base Rules**
- Defines all CSS class rules (`.auix-button-default`, `.auix-button`, `.auix-input`, etc.)
- Uses the color and alias variables from Layers 1-2
- Shared across all themes
- Reached by every theme through the `include` chain

## How It Works: Rules & Includes

Each theme module uses `Aurora.Uix.Templates.Theme` and declares its rules with `rule name, css`.
`include` brings in every rule of another theme that the module does not declare itself:

```elixir
defmodule MyApp.Themes.MyTheme do
  use Aurora.Uix.Templates.Theme, theme_name: :my_theme

  rule :root_colors, """
  :root[data-theme-name="#{@theme_name}"] {
    /* CSS for color variables (Layer 1) */
  }
  """

  rule :_auix_button_default, """
  .auix-button-default {
    /* CSS for button styling (Layer 4) */
  }
  """

  # Every other rule comes from the parent theme
  include Aurora.Uix.Templates.Basic.Themes.ThemeBase
end
```

This allows **composition**: each theme layer only declares what it needs and includes the parent
layer for everything else. A rule with the same name as an included rule replaces it.

Rules come in the order they are written, and an `include` places the included theme's rules
where it is written. Write `include` last so your rules come first, as the built-in themes do. A
theme declares each rule name once and has at most one `include`; anything else fails
compilation.

A rule's CSS is built when the theme compiles. It can use `@theme_name`, module attributes and
functions of other modules, but not functions of the theme itself.

Inside a rule, `import_rule(:source_rule, :target_rule)` copies another rule of the theme,
renaming its class selector. For example, `import_rule(:_auix_button_default, :auix_button)` copies
`.auix-button-default { ... }` as `.auix-button { ... }`.

Every theme gets a generated `rules/0`, which lists its rules in stylesheet order as
`Aurora.Uix.Templates.Theme.Rule` structs. Each one has the rule `name`, its `css`, and its
`source`: `:local` for a rule the theme declares, or `{:theme, module}` for a rule that comes from
the theme it includes. `rule_names/0` returns the same names and `rule/1` returns one rule's CSS,
or `""` for a name the theme does not have.

## Layer 1: Color Palette (Custom Theme)

Create your own theme by defining colors as the foundation:

```elixir
defmodule MyApp.Themes.CustomTheme do
  use Aurora.Uix.Templates.Theme, theme_name: :my_custom_theme
  
  alias Aurora.Uix.Templates.Basic.Themes.ThemeBase

  rule :root_colors, """
  :root[data-theme-name="#{@theme_name}"],
  :host[data-theme-name="#{@theme_name}"] {
    /* Light Mode Colors (Default) */
    --auix-color-bg-default: #FFFFFF;
    --auix-color-bg-secondary: #F3F4F6;
    --auix-color-text-primary: #111827;
    --auix-color-text-secondary: #4B5563;
    --auix-color-error: #EF4444;
    --auix-color-info-ring: #3B82F6;
    
    /* Dark Mode Color Values (Stored as separate variables) */
    --dark--auix-color-bg-default: #0F172A;
    --dark--auix-color-bg-secondary: #1F2937;
    --dark--auix-color-text-primary: #F8FAFC;
    --dark--auix-color-text-secondary: #D1D5DB;
    --dark--auix-color-error: #EF5350;
    --dark--auix-color-info-ring: #64B5F6;
  }
  
  /* Apply Dark Mode via Media Query (respects OS preference) */
  @media (prefers-color-scheme: dark) {
    :root[data-theme-name="#{@theme_name}"],
    :host[data-theme-name="#{@theme_name}"] {
      --auix-color-bg-default: var(--dark--auix-color-bg-default);
      --auix-color-bg-secondary: var(--dark--auix-color-bg-secondary);
      --auix-color-text-primary: var(--dark--auix-color-text-primary);
      --auix-color-text-secondary: var(--dark--auix-color-text-secondary);
      --auix-color-error: var(--dark--auix-color-error);
      --auix-color-info-ring: var(--dark--auix-color-info-ring);
    }
  }
  
  /* Apply Dark Mode via Data Attribute (explicit override, highest priority) */
  :root[data-theme="dark"][data-theme-name="#{@theme_name}"],
  :host[data-theme="dark"][data-theme-name="#{@theme_name}"] {
    --auix-color-bg-default: var(--dark--auix-color-bg-default);
    --auix-color-bg-secondary: var(--dark--auix-color-bg-secondary);
    --auix-color-text-primary: var(--dark--auix-color-text-primary);
    --auix-color-text-secondary: var(--dark--auix-color-text-secondary);
    --auix-color-error: var(--dark--auix-color-error);
    --auix-color-info-ring: var(--dark--auix-color-info-ring);
  }
  """

  include ThemeBase
end
```

**Key features**:
- `@theme_name` attribute automatically injected via `use` macro
- Define `:root_colors` rule with all color variables
- Light mode colors are defined directly in `:root[data-theme-name="..."]`
- Dark mode colors stored as `--dark--` prefixed variables in the same rule
- Use `@media (prefers-color-scheme: dark)` to switch colors based on OS preference
- Use `[data-theme="dark"]` selector for explicit dark mode override (highest priority)
- `include` the parent layer for every non-color rule

## Understanding Light and Dark Modes

Aurora UIX uses a **light-first approach** with dark mode as an optional variant:

**How It Works**:
1. **Single CSS Rule** - One `:root[data-theme-name="..."]` rule defines everything
2. **Light Colors First** - Main color variables (e.g., `--auix-color-bg-default`) are set to light values by default
3. **Dark Color Storage** - Dark colors stored as `--dark--` prefixed variables (e.g., `--dark--auix-color-bg-default`)
4. **Conditional Switching** - Two CSS mechanisms reassign the main variables to dark values when needed

**Switching Mechanisms (Priority Order)**:

1. **Data Attribute** (Highest Priority)
   ```css
   :root[data-theme="dark"][data-theme-name="..."] {
     --auix-color-bg-default: var(--dark--auix-color-bg-default);
   }
   ```
   Explicit user override that always wins

2. **Media Query** (Medium Priority)
   ```css
   @media (prefers-color-scheme: dark) {
     --auix-color-bg-default: var(--dark--auix-color-bg-default);
   }
   ```
   Respects OS/browser dark mode preference

3. **Default Light** (Lowest Priority)
   ```css
   --auix-color-bg-default: #FFFFFF; /* Light default */
   ```
   No selector needed - this is the starting value

## Layer 2: Color Aliases

The `ThemeBase` module sits between a theme's own palette and the structural variables.
It defines component-specific color aliases (buttons, inputs, tables, labels, …), each
defaulting to a generic semantic var from Layer 1:

```elixir
defmodule Aurora.Uix.Templates.Basic.Themes.ThemeBase do
  use Aurora.Uix.Templates.Theme

  alias Aurora.Uix.Templates.Basic.Themes.BaseVariables

  rule :root_color_aliases, """
  :root, :host {
    --auix-color-label-text: var(--auix-color-text-label);
    --auix-color-input-text: var(--auix-color-text-primary);
    --auix-color-button-bg: var(--auix-color-bg-default--reverted);
    /* ... more component aliases ... */
  }
  """

  include BaseVariables
end
```

**Key concept**: overriding a single alias in your theme's `:root_colors` block (e.g.
`--auix-color-button-bg`) restyles that one component without touching any of its
siblings, since every other component keeps pulling from the shared alias defaults.

## Layer 3: Base Variables

The `BaseVariables` module defines all non-color CSS variables:

```elixir
defmodule Aurora.Uix.Templates.Basic.Themes.BaseVariables do
  use Aurora.Uix.Templates.Theme
  alias Aurora.Uix.Templates.Basic.Themes.Base

  rule :root, """
  :root, :host {
    /* Sizes & Dimensions */
    --auix-box-size-unit: 1rem;
    --auix-border-radius-default: 0.5rem;
    --auix-padding-default: 0.625rem;
    
    /* Fonts */
    --auix-font-size-title: 1.125rem;
    --auix-font-family-default: var(--auix-font-sans);
    
    /* Shadows */
    --auix-shadow-default: 0 1px 3px 0 var(--auix-color-shadow-black-alpha);
  }
  """

  include Base
end
```

**Key concept**: The `:root` rule defines all structural properties using CSS variables. These work together with the color variables from Layer 1 to create the complete theme.

## Creating a Simple Color Palette Theme

For a simple theme that only changes colors, you only need to define the color palette in Layer 1:

```elixir
defmodule MyApp.Themes.Ocean do
  use Aurora.Uix.Templates.Theme, theme_name: :ocean
  
  alias Aurora.Uix.Templates.Basic.Themes.ThemeBase

  rule :root_colors, """
  :root[data-theme-name="#{@theme_name}"],
  :host[data-theme-name="#{@theme_name}"] {
    /* Light Mode (Default) */
    --auix-color-bg-default: #E0F2FE;      /* Sky-100 */
    --auix-color-bg-secondary: #BAE6FD;    /* Sky-200 */
    --auix-color-text-primary: #0C4A6E;    /* Sky-900 */
    --auix-color-text-secondary: #0369A1;  /* Sky-700 */
    --auix-color-error: #0EA5E9;           /* Sky-400 */
    --auix-color-focus-ring: #06B6D4;      /* Cyan-500 */
    
    /* Dark Mode Color Values */
    --dark--auix-color-bg-default: #082F49;
    --dark--auix-color-bg-secondary: #0C4A6E;
    --dark--auix-color-text-primary: #E0F2FE;
    --dark--auix-color-text-secondary: #38BDF8;
    --dark--auix-color-error: #38BDF8;
    --dark--auix-color-focus-ring: #06B6D4;
  }
  
  /* Apply Dark Mode via Media Query */
  @media (prefers-color-scheme: dark) {
    :root[data-theme-name="#{@theme_name}"],
    :host[data-theme-name="#{@theme_name}"] {
      --auix-color-bg-default: var(--dark--auix-color-bg-default);
      --auix-color-bg-secondary: var(--dark--auix-color-bg-secondary);
      --auix-color-text-primary: var(--dark--auix-color-text-primary);
      --auix-color-text-secondary: var(--dark--auix-color-text-secondary);
      --auix-color-error: var(--dark--auix-color-error);
      --auix-color-focus-ring: var(--dark--auix-color-focus-ring);
    }
  }
  
  /* Apply Dark Mode via Data Attribute (explicit override) */
  :root[data-theme="dark"][data-theme-name="#{@theme_name}"],
  :host[data-theme="dark"][data-theme-name="#{@theme_name}"] {
    --auix-color-bg-default: var(--dark--auix-color-bg-default);
    --auix-color-bg-secondary: var(--dark--auix-color-bg-secondary);
    --auix-color-text-primary: var(--dark--auix-color-text-primary);
    --auix-color-text-secondary: var(--dark--auix-color-text-secondary);
    --auix-color-error: var(--dark--auix-color-error);
    --auix-color-focus-ring: var(--dark--auix-color-focus-ring);
  }
  """

  include ThemeBase
end
```

This creates a complete ocean-blue theme with light and dark modes. All dimensions, fonts, shadows come from the parent layers.

**Using the Ocean theme**:

```html
<!-- Light mode (default) - no data-theme attribute needed -->
<html data-theme-name="ocean">

<!-- Dark mode via OS preference -->
<!-- Automatically uses dark colors if user's OS prefers dark mode -->
<html data-theme-name="ocean">

<!-- Dark mode via explicit attribute (overrides OS preference) -->
<html data-theme-name="ocean" data-theme="dark">

<!-- Light mode via explicit attribute (overrides OS preference) -->
<html data-theme-name="ocean" data-theme="light">
```

## Overriding Specific Rules

You can override individual CSS rules in Layer 4 while keeping everything else:

```elixir
defmodule MyApp.Themes.CompactTheme do
  use Aurora.Uix.Templates.Theme, theme_name: :compact
  
  alias Aurora.Uix.Templates.Basic.Themes.ThemeBase

  # Because `<.button>` applies `.auix-button-default` as its structural base,
  # customising it here propagates to every button variant (primary, alt, index-bar)
  # without touching color rules.
  rule :_auix_button_default, """
  .auix-button-default {
    display: flex;
    flex-direction: row;
    align-items: center;
    padding: 0.25rem 0.5rem;  /* More compact padding */
    font-size: 0.75rem;        /* Smaller font */
    border-radius: 0.25rem;    /* Tighter corners */
  }
  """

  # Define colors
  rule :root_colors, """
  :root[data-theme-name="#{@theme_name}"],
  :host[data-theme-name="#{@theme_name}"] {
    --auix-color-bg-default: #FFFFFF;
    --auix-color-text-primary: #000000;
    /* ... other colors ... */
  }
  """

  include ThemeBase
end
```

**Rules and includes allow you to**:
- Define custom rules for specific selectors
- Include the parent theme for everything else
- Incrementally customize without duplicating code

## Using Custom Themes

**Step 1: Create Your Theme Module**

Simply create a theme module that uses the `Aurora.Uix.Templates.Theme` macro:

```elixir
defmodule MyApp.Themes.Ocean do
  use Aurora.Uix.Templates.Theme, theme_name: :ocean
  
  # ... declare your rule :root_colors, etc.
end
```

**Step 2: Generate Stylesheet**

The build task `mix auix.gen.stylesheet` automatically:
- Discovers all theme modules in your application
- Collects all rules from each theme
- Generates a unified stylesheet with all themes

No manual registration needed!

```bash
mix auix.gen.stylesheet
```

**Step 3: Configure Default Theme**

Set the default theme in your application config:

```elixir
# config/config.exs
config :aurora_uix, theme_name: :ocean
```

**Step 4: Apply Theme to HTML**

The `AuixThemeName` hook automatically sets the `data-theme-name` attribute on the HTML element:

- **For Generated UI**: The hook is already included in all generated layouts
- **For Custom/Non-Generated UI**: Add the hook manually:

```elixir
# In your custom root layout template
<html phx-hook="AuixThemeName">
  <!-- content -->
</html>
```

The hook:
- Listens for `set_html_theme_name` events from the server
- Sets `data-theme-name` attribute to the configured theme
- Triggers CSS theme switching automatically

**Using Multiple Themes**

If you want to support theme switching at runtime:

```elixir
# In your view/controller
def handle_event("switch_theme", %{"theme" => theme_name}, socket) do
  {:noreply, push_event(socket, "set_html_theme_name", %{theme_name: theme_name})}
end
```

The CSS will automatically apply the correct theme based on the `data-theme-name` attribute.

## Building Rules from Shared CSS

Rule CSS is built when the theme compiles, so keep shared pieces in module attributes or in
functions of another module:

```elixir
defmodule MyApp.Themes.Advanced do
  use Aurora.Uix.Templates.Theme, theme_name: :advanced

  alias Aurora.Uix.Templates.Basic.Themes.ThemeBase
  alias MyApp.Themes.Palette

  @radius "0.25rem"

  # Custom rule for buttons
  rule :_auix_button_default, ".auix-button-default { border-radius: #{@radius}; }"

  # Custom rule for inputs
  rule :_auix_input, ".auix-input { border-radius: #{@radius}; }"

  # Custom colors, built by another module
  rule :root_colors, Palette.root_colors(@theme_name)

  include ThemeBase
end
```

This approach provides:
- **Composition**: Each layer adds its own rules
- **Overridability**: Replace any rule you want
- **Inclusion**: Undeclared rules come from the parent
- **Reusability**: Share base variables across themes
- **Maintainability**: Clear separation of concerns

## Real-World Example: Brand-Specific Theme

```elixir
defmodule MyApp.Themes.BrandTheme do
  use Aurora.Uix.Templates.Theme, theme_name: :brand
  
  alias Aurora.Uix.Templates.Basic.Themes.ThemeBase
  
  # Only override what's specific to your brand
  rule :root_colors, """
  :root[data-theme-name="#{@theme_name}"],
  :host[data-theme-name="#{@theme_name}"] {
    /* Brand Colors */
    --auix-color-bg-default: #F9F5F0;        /* Brand cream */
    --auix-color-text-primary: #2C1810;      /* Brand dark brown */
    --auix-color-focus-ring: #C85A3A;        /* Brand orange */
    --auix-color-error: #D32F2F;
    --auix-color-info-ring: #1976D2;
    
    /* Shadows using brand colors */
    --auix-color-shadow-alpha: rgba(44, 24, 16, 0.08);
    
    /* Dark mode */
    --dark--auix-color-bg-default: #1A1208;
    --dark--auix-color-text-primary: #F9F5F0;
    --dark--auix-color-focus-ring: #FF9966;
  }
  """

  include ThemeBase
end
```

You define only the unique parts of your brand theme, and inherit all structural CSS from the base layers. This keeps your theme **small, focused, and maintainable**.

## Built-in Themes

Aurora UIX ships with two registered themes:

- `:white_charcoal` — the library default (light-first, neutral grays)
- `:vitreous_marble` — Slate/Cyan/Ruby palette

Select one via `config :aurora_uix, theme_name: :white_charcoal` and re-run
`mix auix.gen.stylesheet` after changing the configuration.

## References

For complete examples, see:
- `lib/aurora_uix/templates/basic/themes/vitreous_marble.ex` - Full theme implementation
- `lib/aurora_uix/templates/basic/themes/theme_base.ex` - Color alias definitions (Layer 2)
- `lib/aurora_uix/templates/basic/themes/base_variables.ex` - Base variables definition
- `lib/aurora_uix/templates/basic/themes/base.ex` - Base CSS rules (over 2.7k lines of composition)

## Related guides

- [Customizing & Extending Aurora UIX](customization.md) — the central customization hub
- [Styling Aurora UIX in a Host Application](styling.md) — token-level `--auix-*` overrides without authoring a theme
- [Writing a Style Bridge](writing_a_style_bridge.md) — map host design-system tokens onto `--auix-*` variables
- [Troubleshooting](../advanced/troubleshooting.md) — theme configuration issues
