# Creating Custom Registered Themes

Aurora UIX's theme system leverages Elixir's pattern matching and module composition to create flexible, composable CSS generation. Rather than hard-coding CSS, themes are Elixir modules that define rules dynamically, allowing you to create custom themes by extending base rules with your own color palettes and styling.

## Understanding the Theme Architecture

Aurora UIX themes follow a three-layer pattern:

**Layer 1: Color Palette**
- Defines all color variables for a specific theme variant
- Uses pattern matching to define `:root_colors` rule
- Implements both light and dark mode variants
- Theme-specific and forms the foundation
- Example: `VitreousMarble` theme with Slate/Cyan/Ruby colors

**Layer 2: Base Variables**
- Defines all structural CSS variables (sizes, spacing, fonts, shadows)
- Color-agnostic - contains only dimension and layout properties
- Delegates to Base for additional rules
- Example: `BaseVariables` defines `--auix-padding-default`, `--auix-border-radius-default`, etc.

**Layer 3: Base Rules**
- Defines all CSS class rules (`.auix-button-default`, `.auix-button`, `.auix-input`, etc.)
- Uses the color variables from Layer 1
- Shared across all themes
- Delegated through pattern matching for composition

## How It Works: Pattern Matching & Composition

Each theme module implements the `Aurora.Uix.Templates.Theme` behaviour with a `rule/1` function. This function uses pattern matching to return CSS for specific rule names:

```elixir
def rule(:root_colors) do
  # Returns CSS for color variables (Layer 1)
end

def rule(:root) do
  # Returns CSS for structural variables (Layer 2)
end

def rule(:_auix_button_default) do
  # Returns CSS for button styling (Layer 3)
end

def rule(other_rule) do
  # Delegate to parent theme
  SomeOtherTheme.rule(other_rule)
end
```

This pattern allows **composition**: each theme layer only defines what it needs, delegating everything else to the parent layer.

## Layer 1: Color Palette (Custom Theme)

Create your own theme by defining colors as the foundation:

```elixir
defmodule MyApp.Themes.CustomTheme do
  use Aurora.Uix.Templates.Theme, theme_name: :my_custom_theme
  
  alias Aurora.Uix.Templates.Basic.Themes.BaseVariables

  @impl true
  def rule(:root_colors) do
    """
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
  end

  # Delegate everything else to BaseVariables
  @impl true
  def rule(rule), do: BaseVariables.rule(rule)
end
```

**Key features**:
- `@theme_name` attribute automatically injected via `use` macro
- Define `:root_colors` rule with all color variables
- Light mode colors are defined directly in `:root[data-theme-name="..."]`
- Dark mode colors stored as `--dark--` prefixed variables in the same rule
- Use `@media (prefers-color-scheme: dark)` to switch colors based on OS preference
- Use `[data-theme="dark"]` selector for explicit dark mode override (highest priority)
- Delegate non-color rules to parent layer via pattern matching

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

## Layer 2: Base Variables

The `BaseVariables` module defines all non-color CSS variables:

```elixir
defmodule Aurora.Uix.Templates.Basic.Themes.BaseVariables do
  use Aurora.Uix.Templates.Theme
  alias Aurora.Uix.Templates.Basic.Themes.Base

  @impl true
  def rule(:root) do
    """
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
  end

  # Delegate everything else to Base
  @impl true
  def rule(rule), do: Base.rule(rule)
end
```

**Key concept**: The `:root` rule defines all structural properties using CSS variables. These work together with the color variables from Layer 1 to create the complete theme.

## Creating a Simple Color Palette Theme

For a simple theme that only changes colors, you only need to define the color palette in Layer 1:

```elixir
defmodule MyApp.Themes.Ocean do
  use Aurora.Uix.Templates.Theme, theme_name: :ocean
  
  alias Aurora.Uix.Templates.Basic.Themes.BaseVariables

  @impl true
  def rule(:root_colors) do
    """
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
  end

  @impl true
  def rule(rule), do: BaseVariables.rule(rule)
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

You can override individual CSS rules in Layer 3 while keeping everything else:

```elixir
defmodule MyApp.Themes.CompactTheme do
  use Aurora.Uix.Templates.Theme, theme_name: :compact
  
  alias Aurora.Uix.Templates.Basic.Themes.BaseVariables

  # Because `<.button>` applies `.auix-button-default` as its structural base,
  # customising it here propagates to every button variant (primary, alt, index-bar)
  # without touching color rules.
  @impl true
  def rule(:_auix_button_default) do
    """
    .auix-button-default {
      display: flex;
      flex-direction: row;
      align-items: center;
      padding: 0.25rem 0.5rem;  /* More compact padding */
      font-size: 0.75rem;        /* Smaller font */
      border-radius: 0.25rem;    /* Tighter corners */
    }
    """
  end

  # Define colors
  @impl true
  def rule(:root_colors) do
    """
    :root[data-theme-name="#{@theme_name}"],
    :host[data-theme-name="#{@theme_name}"] {
      --auix-color-bg-default: #FFFFFF;
      --auix-color-text-primary: #000000;
      /* ... other colors ... */
    }
    """
  end

  # Delegate everything else
  @impl true
  def rule(rule), do: BaseVariables.rule(rule)
end
```

**Pattern matching allows you to**:
- Define custom rules for specific selectors
- Delegate to parent theme for everything else
- Incrementally customize without duplicating code

## Using Custom Themes

**Step 1: Create Your Theme Module**

Simply create a theme module that uses the `Aurora.Uix.Templates.Theme` macro:

```elixir
defmodule MyApp.Themes.Ocean do
  use Aurora.Uix.Templates.Theme, theme_name: :ocean
  
  # ... define your rule(:root_colors), etc.
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

## The Power of Pattern Matching

The real power comes from Elixir's pattern matching and module composition:

```elixir
defmodule MyApp.Themes.Advanced do
  use Aurora.Uix.Templates.Theme, theme_name: :advanced
  
  alias Aurora.Uix.Templates.Basic.Themes.BaseVariables

  # Custom rule for buttons
  def rule(:_auix_button_default), do: custom_button_styles()
  
  # Custom rule for inputs
  def rule(:_auix_input_default), do: custom_input_styles()
  
  # Custom colors
  def rule(:root_colors), do: custom_colors()
  
  # Everything else delegates
  def rule(rule), do: BaseVariables.rule(rule)

  defp custom_button_styles do
    # Your button CSS
  end

  defp custom_input_styles do
    # Your input CSS
  end

  defp custom_colors do
    # Your color variables
  end
end
```

This approach provides:
- **Composition**: Each layer adds its own rules
- **Overridability**: Replace any rule you want
- **Delegation**: Unused rules inherit from parent
- **Reusability**: Share base variables across themes
- **Maintainability**: Clear separation of concerns

## Real-World Example: Brand-Specific Theme

```elixir
defmodule MyApp.Themes.BrandTheme do
  use Aurora.Uix.Templates.Theme, theme_name: :brand
  
  alias Aurora.Uix.Templates.Basic.Themes.BaseVariables
  
  # Only override what's specific to your brand
  @impl true
  def rule(:root_colors) do
    """
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
  end

  @impl true
  def rule(rule), do: BaseVariables.rule(rule)
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
- `lib/aurora_uix/templates/basic/themes/base_variables.ex` - Base variables definition
- `lib/aurora_uix/templates/basic/themes/base.ex` - Base CSS rules (2,296 lines of composition)

## Related guides

- [Customizing & Extending Aurora UIX](customization.md) — the central customization hub
- [Styling Aurora UIX in a Host Application](styling.md) — token-level `--auix-*` overrides without authoring a theme
- [Writing a Style Bridge](writing_a_style_bridge.md) — map host design-system tokens onto `--auix-*` variables
- [Troubleshooting](../advanced/troubleshooting.md) — theme configuration issues
