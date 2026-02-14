# Troubleshooting

Common issues and solutions for Aurora UIX.

## Styling Not Applied

**Symptoms:** Aurora UIX components render but styling appears broken or missing.

**Solutions:**

1. **Basic setup checks:**
   - Ensure you've run `mix auix.gen.stylesheet` to generate the stylesheet
   - Verify `@import "auix-stylesheet.css";` exists in your `assets/css/app.css`
   - Check that assets are rebuilt after adding the import: `mix phx.digest.clean --all && mix assets.build`
   - In development, restart your server to ensure hot reload picks up CSS changes

2. **Theme configuration issues:**
   - Check your theme is correctly configured in `config/{environment}.exs`:
     ```elixir
     config :aurora_uix, theme_name: :white_charcoal  # or :vitreous_marble
     ```
   - Verify the theme name spelling matches exactly (themes available: `:white_charcoal`, `:vitreous_marble`)
   - Run `mix auix.gen.stylesheet` again after changing the theme configuration

3. **Custom theme CSS issues:**
   - If using a custom theme module, verify it implements the `Aurora.Uix.Templates.Theme` behaviour
   - Ensure all CSS rules in your custom theme are valid CSS (check for syntax errors)
   - Verify the theme module uses the correct macro: `use Aurora.Uix.Templates.Theme, theme_name: :your_theme_name`
   - Test CSS rules individually by inspecting with browser DevTools
   - Check theme module is properly compiled: `mix compile --force`

## Icons Not Displaying

**Symptoms:** Icons appear as blank spaces or missing symbols.

**Solutions:**
- If you're not already using Heroicons in your project, run `mix auix.gen.icons`
- Verify `@import "auix-icons.css";` exists in your `assets/css/app.css`
- If you're using Heroicons from your own dependency, ensure those CSS classes are available
- Check the browser DevTools (Inspect Element) to see if the icon element has the correct CSS class applied

## UI Components Not Rendering

**Symptoms:** Pages show blank or malformed UI elements.

**Solutions:**
- Verify you've defined resource metadata with `auix_resource_metadata/3` macro
- Ensure the layout DSL in `auix_create_ui` includes the fields you want to display
- Check for errors in the browser console (F12 / DevTools)
- Verify LiveView is properly connected (check for `PhxLiveSocket` connection in console)

## Compilation Errors

**Symptoms:** `mix compile` fails with module or macro errors.

**Solutions:**
- Ensure all dependencies are installed: `mix deps.get`
- Check that your resource and layout macros follow the correct syntax
- Verify all schema modules are correctly imported in your metadata module
- Clear build artifacts and recompile: `mix clean && mix compile`

## LiveView Connection Issues

**Symptoms:** UI updates don't work, no response to form submissions.

**Solutions:**
- Verify your router includes the necessary LiveView routes
- Check that Phoenix LiveView is properly installed and configured
- Open browser DevTools to see if there are WebSocket connection errors
- Ensure the `/live` endpoint is accessible (check router configuration)

## Incorrect LiveView Routes

**Symptoms:** Routes work but link to wrong pages, "module not found" errors, or components won't mount.

**Cause:** The `auix_create_ui/0` macro creates submodules (`.Index` and `.Show`) for your generated UI modules. If you manually write router links without accounting for these submodules, routes won't match.

**Solutions:**

1. **Understand the module structure:**
   When you use `auix_create_ui`, it creates:
   ```elixir
   Overview.Product         # Parent module (generated)
   Overview.Product.Index   # List and CRUD operations
   Overview.Product.Show    # Detail view
   ```

2. **Use the correct module paths in your router:**
   ```elixir
   # CORRECT - uses the .Index and .Show submodules
   scope "/products" do
     pipe_through(:browser)
     live "/", Overview.Product.Index
     live "/:id", Overview.Product.Show
     live "/new", Overview.Product.Index, :new
     live "/:id/edit", Overview.Product.Index, :edit
   end
   ```

   ```elixir
   # WRONG - these paths won't work
   live "/", Overview.Product           # ❌ Module Overview.Product is not a LiveView
   live "/:id", Overview.Product        # ❌ Same issue
   ```

3. **Use the `auix_live_resources` helper (recommended):**
   This automatically generates all routes with correct module paths:
   ```elixir
   import Aurora.Uix.RouteHelper

   scope "/products" do
     pipe_through(:browser)
     auix_live_resources("/", Overview.Product)  # ✅ Generates all routes correctly
   end
   ```

4. **Verify routes with `mix phx.routes`:**
   Run this command to see all registered routes and verify they point to the correct modules:
   ```shell
   mix phx.routes | grep products
   ```
   Look for routes like: `GET  /products   Overview.Product.Index :index`

## Database Issues

**Symptoms:** Errors loading or saving data, missing table errors.

**Solutions:**
- Verify PostgreSQL (or your database) is running
- Check that the correct database is configured in your `config/`
- Run pending migrations: `mix ecto.migrate`
- Verify your schema module matches the actual database table structure

## Embedded and Associated Resources Metadata

**Symptoms:** Configuration changes to embedded or associated resources don't work, fields 
don't appear in forms, or metadata options seem to be ignored.

**Cause:** When a resource has embedded or associated resources, the metadata name must 
reflect the relationship hierarchy using double underscore notation (`__`) to be recognized 
by Aurora UIX.

**Understanding the Naming Convention:**

When you have a parent resource (e.g., `Post`) with embedded or associated child resources 
(e.g., `Comment`), and the parent resource has metadata named `:post`, you must prefix the 
embedded resource metadata with the parent's name:

- Parent metadata: `:post`
- Embedded resource metadata: `:post__comment` (not `:comment`)

**Example:**

```elixir
# Parent resource metadata
auix_resource_metadata(:post, ash_resource: Post, order_by: :title)

# CORRECT - Embedded resource uses parent prefix
auix_resource_metadata(:post__comment, ash_resource: Comment) do
  field :description, html_type: :textarea
end

# WRONG - This won't be recognized as belonging to Post
auix_resource_metadata(:comment, ash_resource: Comment) do
  field :description, html_type: :textarea
end
```

**When to Use This Pattern:**

1. **Embedded resources** defined with `embeds_one` or `embeds_many` in Ecto schemas
2. **Associated resources** defined with `has_one`, `has_many`, `belongs_to` in Ecto schemas
3. **Ash embedded resources** defined with `attribute` type embeds in Ash resources
4. **Ash relationships** defined with `has_one`, `has_many`, `belongs_to` in Ash resources

**Solutions:**

1. **Rename your metadata definition:**
   ```elixir
   # If Post has embedded Comments, use:
   auix_resource_metadata(:post__comment, ash_resource: Comment)
   
   # For multiple levels, continue the pattern:
   auix_resource_metadata(:post__comment__reply, ash_resource: Reply)
   ```

2. **Update field configurations:**
   ```elixir
   # All field customizations must use the prefixed name
   auix_resource_metadata(:post__comment, ash_resource: Comment) do
     field :content, html_type: :textarea
     field :author, label: "Comment Author"
   end
   ```

3. **Reference in layouts:**
   ```elixir
   # In your UI layouts, reference the embedded resource normally
   show_layout :post do
     stacked([:title, :author, :comment])  # 'comment' works here
   end
   
   edit_layout :post do
     stacked([:title, :comment])  # Same here
   end
   ```

4. **Verify the relationship structure:**
   - Check your schema or Ash resource definition to confirm the embedding structure
   - Ensure the parent resource metadata name matches what you're using as the prefix
   - Use `mix phx.routes` or inspect compiled metadata to verify configuration

**Complete Working Example:**

```elixir
use Aurora.Uix

alias MyApp.Blog.Post
alias MyApp.Blog.Comment

# Parent resource
auix_resource_metadata(:post, ash_resource: Post, order_by: :title)

# Embedded resource - note the :post__comment naming
auix_resource_metadata(:post__comment, ash_resource: Comment) do
  field :description, html_type: :textarea
end

auix_create_ui do
  show_layout :post do
    stacked([:status, :title, :author, :comment])
  end
  
  edit_layout :post do
    stacked([:title, :comment])
  end
end
```

## Performance Issues

**Symptoms:** Slow page loads or unresponsive UI.

**Solutions:**
- Check for N+1 query problems in your context functions
- Use Phoenix DevTools or `:observer` to identify bottlenecks
- Verify preloads are configured for associations in your queries
- Consider pagination for large data lists


## Still Stuck?

- Review the [Advanced Usage Guide](./advanced_usage.md) for complex setups
- Check the [Getting Started Guide](../introduction/getting_started.md) to verify setup steps
- Open an issue on [GitHub](https://github.com/wadvanced/aurora_uix/issues) with details about your setup and error messages
