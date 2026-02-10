# Ash Framework Integration

Aurora UIX is a powerful low-code framework for building dynamic CRUD UIs in Phoenix LiveView applications. 
While Aurora UIX works perfectly with traditional Phoenix Contexts and Ecto schemas, it also provides **integration** with the [Ash Framework](https://ash-hq.org/).

This guide explains how to leverage Aurora UIX's Ash integration as an alternative backend to the standard Context-based approach.

## Overview

Aurora UIX is designed with a flexible backend architecture that supports multiple data access patterns. 
Aurora UIX seamlessly adapts to use Ash as the backend, transforming your existing Ash resources into complete UI implementations **without requiring any changes to your Ash resources**.

### Why Aurora UIX with Ash?

If your application already uses Ash Framework, Aurora UIX provides:

- **Zero Duplication** - Reuse your existing Ash resource definitions and actions, mildly aligned to Ash concept 'Model your domain, derive the rest'
- **Automatic Action Discovery** - Aurora UIX detects and uses your defined Ash actions
- **Declarative Configuration** - No need to write Context functions or custom queries
- **Type Safety** - Leverages Ash's type system for automatic field inference
- **Constraint Awareness** - Respects Ash constraints like `:one_of` for enum fields
- **Flexible Backend Use** - Use Ash and Context-based resources in the same Aurora UIX application

## Prerequisites

Before enabling Aurora UIX's Ash integration, ensure you have:

1. **Aurora UIX** installed and working (see [Getting Started](getting_started.md))
2. **Ash Framework** installed and configured in your Phoenix project
3. **Ash Resources** with defined actions and attributes
4. **An Ash Domain** (optional but recommended) organizing your resources

### Required Dependencies

Besides Aurora UIX, you'll need to add Ash dependencies for using it as a backend for UI rendering. In your `mix.exs`:

```elixir
def deps do
  [
    {:aurora_uix, "~> 0.1.2"},  # Main framework
    {:ash, "~> 3.0"},           # If use Ash as backend
    {:ash_postgres, "~> 2.0"}   # Needed if using postgres as your data layer. Add any other data layer required by your backend
  ]
end
```

## Basic Configuration

### Step 1: Define Your Ash Resource (or Use Existing)

If you already have Ash resources, skip to Step 3. Otherwise, create an Ash resource with standard or customized CRUD actions:

```elixir
defmodule Aurora.Uix.Guides.Blog.Post do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Aurora.Uix.Guides.Blog

  postgres do
    table("posts")
    repo(Aurora.Uix.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:title, :string)
    attribute(:content, :string)
    attribute(:published_at, :utc_datetime)

    attribute :status, :atom do
      constraints one_of: [:draft, :published, :archived]
      default :draft
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to(:author, Aurora.Uix.Guides.Blog.Author)
    belongs_to(:category, Aurora.Uix.Guides.Blog.Category)
  end

  actions do
    default_accept [:title, :content, :status, :author_id, :category_id]
    defaults [:create, :read, :destroy, :update]
  end
end
```

### Step 2: Define Your Ash Domain

Organize resources in an Ash domain:

```elixir
defmodule Aurora.Uix.Guides.Blog do
  use Ash.Domain

  resources do
    resource Aurora.Uix.Guides.Blog.Post
    resource Aurora.Uix.Guides.Blog.Author
    
    resource Aurora.Uix.Guides.Blog.Category do
      define :list_categories, action: :read
    end
  end
end
```

### Step 3: Configure Aurora UIX Resource Metadata

Create a module to configure your UI:

```elixir
defmodule Aurora.UixWeb.Guides.AshOverview do
  use Aurora.Uix

  alias Aurora.Uix.Guides.Blog.Author
  alias Aurora.Uix.Guides.Blog.Category
  alias Aurora.Uix.Guides.Blog.Post
  alias Aurora.Uix.Guides.Blog.Tag

  auix_resource_metadata(:author, ash_resource: Author)
  auix_resource_metadata(:post, ash_resource: Post)
  auix_resource_metadata(:category, ash_resource: Category)
  auix_resource_metadata(:tag, ash_resource: Tag)

  auix_create_ui do
    index_columns(:post, [:title, :author, :status])

    show_layout :post do
      stacked do
        inline([:status])
        inline([:title, :author])
        inline([:comment])
      end
    end

    edit_layout :post do
      stacked do
        inline([:title])
        inline([:author])
        inline([:comment])

        group "details" do
          inline([:status, :published_at])
        end

        inline([:tags])
      end
    end
  end
end
```

### Step 4: Add to Router

```elixir
defmodule Aurora.UixWeb.Router do
  use Aurora.UixWeb, :router
  import Aurora.Uix.Router

  scope "/guides-overview", Aurora.UixWeb.Guides do
    pipe_through :browser

    auix_live_resources("/posts", AshOverview.Post)
    auix_live_resources("/authors", AshOverview.Author)
    auix_live_resources("/categories", AshOverview.Category)
    auix_live_resources("/tags", AshOverview.Tag)
  end
end
```

That's it! Aurora UIX will generate complete CRUD interfaces using your existing Ash actions, without requiring any changes to your Ash resources or domain definitions.

## Configuration Options

### Resource Metadata Options

When configuring an Ash resource, you can use these options:

#### Required Options

- `:ash_resource` (module()) - Your Ash resource module

#### Optional Options

- `:ash_domain` (module()) - Ash domain containing the resource. If omitted, actions are resolved directly from the resource
- `:order_by` (atom() | list() | keyword()) - Default ordering for index views

#### Alternative Syntax

You can also use `:schema` as an alias for `:ash_resource` and `:context` as an alias for `:ash_domain`:

```elixir
# These are equivalent
auix_resource_metadata :user, ash_resource: User, ash_domain: Accounts
auix_resource_metadata :user, schema: User, context: Accounts
```

### Examples

#### Without Domain

```elixir
auix_resource_metadata :author, ash_resource: Author do
  field :name, required: true
  field :bio, html_type: :textarea
end
```

#### With Domain and Ordering

```elixir
auix_resource_metadata :post,
  ash_resource: Post,
  ash_domain: Blog,
  order_by: [desc: :published_at] do
  field :title, required: true, max_length: 100
  field :content, html_type: :textarea
  field :published_at, readonly: true
end
```

#### Multiple Resources

```elixir
defmodule MyAppWeb.BlogViews do
  use Aurora.Uix

  alias MyApp.Blog
  alias MyApp.Blog.{Author, Post, Category}

  auix_resource_metadata :author, ash_resource: Author, ash_domain: Blog
  auix_resource_metadata :post, ash_resource: Post, ash_domain: Blog
  auix_resource_metadata :category, ash_resource: Category, ash_domain: Blog

  auix_create_ui()
end
```

## How Aurora UIX Discovers Ash Actions

One of Aurora UIX's strengths is its ability to work with your existing code. When configured to use an Ash resource, 
Aurora UIX automatically discovers and maps Ash actions to UI operations without requiring any modifications to your Ash resources. The resolution process follows these rules:

### Action Discovery Process

1. **Primary Actions First** - If an action is marked as `primary?: true`, it's selected
2. **Fallback to First Available** - If no primary action exists, the first action of the matching type is used
3. **Domain vs Resource Resolution**:
   - **With `:ash_domain`** - Actions are looked up through the domain's resource references
   - **Without `:ash_domain`** - Actions are resolved directly from the resource module

### Aurora UIX Operation Mapping

Aurora UIX provides these UI operations and automatically maps them to corresponding Ash action types:

| Aurora UIX Operation | Ash Alias | Ash Action Type | Used For | Notes |
|---------------------|-----------|-----------------|----------|-------|
| `:list_function` | `:ash_read_action` | `:read` | Index view (non-paginated) | Uses first read action without pagination |
| `:list_function_paginated` | `:ash_read_action_paginated` | `:read` | Index view (paginated) | Requires `pagination` configuration on action |
| `:get_function` | `:ash_get_action` | `:read` | Show view | Uses read action for fetching single record |
| `:new_function` | `:ash_new_function` | N/A (function) | New form initialization | Requires a 2-arity function returning a struct representing the entity |
| `:create_function` | `:ash_create_action` | `:create` | New/Create form | Uses create action |
| `:update_function` | `:ash_update_action` | `:update` | Edit form | Uses update action |
| `:delete_function` | `:ash_destroy_action` | `:destroy` | Delete operation | Uses destroy action |
| `:change_function` | `:ash_update_action` | `:update` | Changeset creation | Uses update action for building changesets |

### Pagination Support

For paginated index views, your read action must have pagination configured:

```elixir
actions do
  read :list do
    primary? true
    
    pagination do
      offset? true
      countable true
      default_limit 20
    end
  end
end
```

Aurora UIX will automatically use this action for paginated index views.

### Custom Actions

You can specify custom actions using options:

```elixir
auix_resource_metadata :post,
  ash_resource: Post,
  ash_read_action: :published_posts,      # Custom read action
  ash_create_action: :publish,            # Custom create action
  ash_update_action: :edit_published do   # Custom update action
  # field configuration...
end
```

Available custom action options:
- `:ash_read_action` - Custom read action name
- `:ash_read_action_paginated` - Custom paginated read action
- `:ash_get_action` - Custom get action for show view
- `:ash_new_function` - Custom 2-arity function for new form initialization (must return a struct)
- `:ash_create_action` - Custom create action
- `:ash_update_action` - Custom update action
- `:ash_destroy_action` - Custom destroy action

#### Custom New Function

Unlike other options that reference Ash actions, `:ash_new_function` accepts a custom function for initializing new records:

```elixir
auix_resource_metadata :post,
  ash_resource: Post,
  ash_new_function: &MyApp.Blog.new_post/2 do
  # field configuration...
end

# The function must have arity 2 and return a struct
defmodule MyApp.Blog do
  def new_post(attrs, _opts) do
    struct(
      %Post{
        status: :draft,
        published_at: nil,
        author_id: get_current_user_id()
      }, attrs
    )
  end
end
```

## How Aurora UIX Renders Ash Relationships

Aurora UIX intelligently handles Ash relationships defined in your resources, automatically rendering them with appropriate UI components based on their type. 
This works with your existing relationship definitions—no changes needed.

### Belongs To Relationships

`belongs_to` relationships are rendered as select dropdowns:

```elixir
# In your Ash resource
relationships do
  belongs_to :author, MyApp.Blog.Author
  belongs_to :category, MyApp.Blog.Category
end

# In your Aurora UIX configuration
auix_resource_metadata :post, ash_resource: Post, ash_domain: Blog do
  field :author_id, html_type: :select, option_label: :name
  field :category_id, html_type: :select, option_label: :name
end
```

### Has Many Relationships

`has_many` relationships are rendered as nested lists with add/edit/delete actions:

```elixir
# In your Ash resource
relationships do
  has_many :posts, MyApp.Blog.Post
end

# In your Aurora UIX configuration
auix_resource_metadata :author, ash_resource: Author do
  field :posts, order_by: [desc: :published_at]
end
```

### Many to Many Relationships

For many-to-many relationships through join resources:

```elixir
# Define the join resource
defmodule MyApp.Blog.PostTag do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: MyApp.Blog

  relationships do
    belongs_to :post, MyApp.Blog.Post, primary_key?: true, allow_nil?: false
    belongs_to :tag, MyApp.Blog.Tag, primary_key?: true, allow_nil?: false
  end
end

# In your Post resource
relationships do
  many_to_many :tags, MyApp.Blog.Tag do
    through MyApp.Blog.PostTag
    source_attribute_on_join_resource :post_id
    destination_attribute_on_join_resource :tag_id
  end
end

# Aurora UIX will automatically handle this relationship
```

## Embedded Resources

Ash supports embedded resources (similar to Ecto embeds). Aurora UIX renders these inline:

```elixir
# Define embedded resource
defmodule MyApp.Blog.Comment do
  use Ash.Resource, data_layer: :embedded

  attributes do
    attribute :body, :string
    attribute :author_name, :string
  end
end

# Use in main resource
defmodule MyApp.Blog.Post do
  attributes do
    # Single embed
    attribute :primary_comment, MyApp.Blog.Comment
    
    # Array of embeds
    attribute :comments, {:array, MyApp.Blog.Comment}
  end
end
```

Aurora UIX will render:
- `embeds_one` - Single nested form
- `embeds_many` - List of nested forms with add/remove actions

## Advanced Examples

### Custom Layouts with Ash Resources

```elixir
defmodule MyAppWeb.BlogViews do
  use Aurora.Uix

  alias MyApp.Blog
  alias MyApp.Blog.Post

  auix_resource_metadata :post,
    ash_resource: Post,
    ash_domain: Blog,
    order_by: [desc: :published_at]

  auix_create_ui do
    # Custom index columns
    index_columns(:post, [:title, :author, :status, :published_at])

    # Custom show layout
    show_layout :post do
      stacked do
        inline([:title])
        inline([:author, :category])
        inline([:status, :published_at])
        inline([:content])
        
        group "Metadata" do
          inline([:inserted_at, :updated_at])
        end
      end
    end

    # Custom edit layout
    edit_layout :post do
      stacked do
        inline([:title])
        inline([:author_id])
        inline([:category_id])
        inline([:content])
        
        group "Publishing" do
          inline([:status])
          inline([:published_at])
        end
        
        inline([:tags])
      end
    end
  end
end
```

### Conditional Field Display

Use field options to control visibility:

```elixir
auix_resource_metadata :user, ash_resource: User do
  field :id, hidden: true
  field :email, required: true
  field :password_hash, omitted: true  # Completely excluded
  field :role, html_type: :select
  field :created_at, readonly: true
  field :updated_at, readonly: true, hidden: true
end
```

### Filtering and Sorting

Configure default filtering and sorting:

```elixir
auix_resource_metadata :post,
  ash_resource: Post,
  order_by: [desc: :published_at] do
  
  field :title, filterable?: true
  field :status, filterable?: true, html_type: :select
  field :author_id, filterable?: true, html_type: :select, option_label: :name
end
```

## Ash vs Aurora UIX Filtering and Sorting

When using Aurora UIX with Ash, you have two options for implementing filtering and sorting: using Ash's declarative approach or Aurora UIX's built-in features. Both are valid choices, and **it's perfectly fine to use Ash's declarative options**, especially if Ash will remain your application's backend.

### Using Ash's Declarative Approach

You can define filtering and sorting directly in your Ash resource using preparations and argument definitions:

```elixir
defmodule MyApp.Blog.Post do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: MyApp.Blog

  actions do
    read :list do
      primary? true
      
      # Define sortable fields
      prepare build(sort: [published_at: :desc])
      
      # Define filterable arguments
      argument :status, :atom do
        constraints one_of: [:draft, :published, :archived]
      end
      
      argument :author_id, :uuid
      
      # Apply filters
      prepare fn query, _ ->
        query
        |> Ash.Query.filter_input(status: arg(:status))
        |> Ash.Query.filter_input(author_id: arg(:author_id))
      end
    end
  end
end
```

### Advantages of Ash's Approach

✅ **Declarative and Centralized** - All logic lives in the resource definition  
✅ **Backend Consistency** - Same filtering/sorting logic across all interfaces (UI, API, GraphQL)  
✅ **Type Safety** - Leverages Ash's type system and constraints  
✅ **Authorization Integration** - Works seamlessly with Ash policies  
✅ **Domain Logic Cohesion** - Keeps business rules with the resource  
✅ **Long-term Stability** - If Ash is your committed backend, no future migration needed  

### Advantages of Aurora UIX's Approach

✅ **UI-Specific Control** - Fine-tune filtering/sorting per UI without affecting other interfaces  
✅ **Simpler Resource Definitions** - Keeps Ash resources focused on core domain logic  
✅ **Flexibility** - Easier to change UI behavior without modifying backend  
✅ **Backend Independence** - Same Aurora UIX code works if you switch from Ash to Contexts (consider using [Aurora Ctx](https://github.com/wadvanced/aurora_ctx) for declarative Context functions)  
✅ **Rapid Prototyping** - Quick UI iterations without touching resource definitions  

### When to Use Each Approach

**Use Ash's declarative approach when:**
- Ash is your long-term backend strategy
- You want consistent filtering/sorting across all application interfaces
- Your filtering logic involves complex business rules or authorization
- You prefer keeping all domain logic in one place
- You're building multiple clients (web UI, mobile API, GraphQL) that need the same filtering

**Use Aurora UIX's built-in features when:**
- You need UI-specific filtering that shouldn't affect other interfaces
- You're prototyping or experimenting with different UI approaches
- You want to keep Ash resources minimal and focused
- You might migrate away from Ash in the future (Aurora Ctx provides a similar declarative approach for Contexts)
- You have simple, UI-only filtering requirements

### Combining Both Approaches

You can also use both together for maximum flexibility:

```elixir
# In Ash resource - core business filtering
actions do
  read :published_posts do
    prepare build(sort: [published_at: :desc])
    filter expr(status == :published)
  end
end

# In Aurora UIX - additional UI-specific filtering
auix_resource_metadata :post,
  ash_resource: Post,
  ash_read_action: :published_posts do
  
  field :author_id, filterable?: true, html_type: :select
  field :category_id, filterable?: true, html_type: :select
end
```

### Recommendation

**If Ash is staying as your backend, using Ash's declarative options is encouraged.** It provides better cohesion, type safety, and ensures consistency across your application. 
Aurora UIX is designed to work seamlessly with Ash's native features—you don't need to duplicate logic in the UI layer.

## Choosing Between Ash and Context Integration

Aurora UIX supports both integration approaches equally well. The choice depends on your application architecture, not Aurora UIX limitations.

### Use Aurora UIX with Ash Integration When:

✅ Your application **already uses** Ash Framework
✅ You want to reuse existing Ash resource definitions and actions
✅ Your team prefers declarative, action-based resource definitions
✅ You need Ash's built-in features (authorization, multi-tenancy, etc.)
✅ You want to leverage Ash's ecosystem (GraphQL, JSON:API, etc.)

### Use Aurora UIX with Context Integration When:

✅ You're starting a **new project** with Aurora UIX
✅ Your team is more familiar with traditional Phoenix/Ecto patterns
✅ You have an existing Phoenix app with Context modules
✅ You prefer explicit function definitions and direct query control
✅ Your domain logic is straightforward

**Note**: When using Contexts, consider pairing Aurora UIX with [Aurora Ctx](https://github.com/wadvanced/aurora_ctx)—a declarative DSL for Context functions that provides a declarative approach.

**Important**: Both approaches provide the same Aurora UIX features (layouts, field customization, relationships, etc.). The backend choice doesn't limit Aurora UIX functionality.

### Backend Comparison

| Aspect | Aurora UIX with Ash | Aurora UIX with Contexts |
|--------|---------------------|--------------------------|
| **Aurora UIX Features** | ✅ Full support | ✅ Full support |
| **Resource Definition** | Ash resources | Ecto schemas |
| **CRUD Operations** | Ash actions | Context functions |
| **Discovery Method** | Automatic from actions | By naming convention |
| **Authorization** | Via Ash policies | Manual in contexts |
| **Configuration** | `:ash_resource`, `:ash_domain` | `:schema`, `:context` |

## Migrating Between Backends

Aurora UIX's flexible architecture allows you to migrate between backends if your application needs change. Both directions are supported.

### From Context to Ash (Adding Ash to Existing Aurora UIX App)

If you want to add Ash to an existing Aurora UIX application using Contexts:

1. **Create Ash Resource** from your Ecto schema:
   ```elixir
   # Before: Ecto Schema
   defmodule MyApp.Accounts.User do
     use Ecto.Schema
     schema "users" do
       field :email, :string
       field :name, :string
     end
   end
   
   # After: Ash Resource
   defmodule MyApp.Accounts.User do
     use Ash.Resource,
       data_layer: AshPostgres.DataLayer,
       domain: MyApp.Accounts
     
     attributes do
       uuid_primary_key :id
       attribute :email, :string
       attribute :name, :string
     end
     
     actions do
       defaults [:read, :create, :update, :destroy]
     end
   end
   ```

2. **Create Ash Domain** to replace your Context:
   ```elixir
   defmodule MyApp.Accounts do
     use Ash.Domain
     
     resources do
       resource MyApp.Accounts.User
     end
   end
   ```

3. **Update Aurora UIX Configuration**:
   
   ```elixir
   # Before
   auix_resource_metadata :user, schema: User, context: Accounts
   
   # After
   # This is a semantic change, ash_resource is an alias of schema, and ash_domain is an alias of context
   auix_resource_metadata :user, ash_resource: User, ash_domain: Accounts
   ```

### From Ash to Context (Removing Ash Dependency)

If you decide to remove Ash and use standard Phoenix Contexts:

1. Convert Ash resource to standard Ecto schema
2. Create Context module with CRUD functions (`list_users/1`, `get_user/2`, etc.)
3. Update Aurora UIX configuration to use `:schema` and `:context` options
4. Remove Ash dependencies from `mix.exs`

The Aurora UIX UI code and layouts remain unchanged—only the backend configuration changes.

## Troubleshooting

### Common Issues

#### Action Not Found

**Error**: `Error processing action ':read' of resource ':user' with expected type ':read' : Does not exists or it is of the wrong type`

**Solution**: Ensure your resource has the required action defined:
```elixir
actions do
  defaults [:read, :create, :update, :destroy]
  # or explicitly
  read :read do
    primary? true
  end
end
```

#### Pagination Not Supported

**Error**: `Does not exists or it is of the wrong type, or pagination is not supported`

**Solution**: Add pagination to your read action:
```elixir
read :list do
  primary? true
  
  pagination do
    offset? true
    countable true
  end
end
```

#### Domain Resolution Issues

If actions aren't being discovered, try:

1. **Explicitly specify the domain**:
   ```elixir
   auix_resource_metadata :user, ash_resource: User, ash_domain: Accounts
   ```

2. **Or define domain actions**:
   ```elixir
   # In your domain
   resources do
     resource User do
       define :list_users, action: :read
     end
   end
   ```

#### Relationship Not Rendering

Ensure the related resource is also configured:

```elixir
auix_resource_metadata :post, ash_resource: Post
auix_resource_metadata :author, ash_resource: Author  # Must also be configured

# In post configuration
field :author_id, html_type: :select, option_label: :name
```

## Best Practices for Aurora UIX with Ash

These practices help Aurora UIX work optimally with your Ash resources.

### 1. Mark Primary Actions

Help Aurora UIX select the right actions by marking your main actions as primary:

```elixir
actions do
  read :list do
    primary? true
  end
  
  create :create do
    primary? true
  end
end
```

### 2. Configure Pagination for Index Views

Enable pagination on custom read actions that Aurora UIX will use for index views:

```elixir
read :list do
  primary? true
  
  pagination do
    offset? true
    countable true
    default_limit 25
    max_page_size 100
  end
end
```

### 3. Use Domains for Organization

Group related resources in domains:

```elixir
defmodule MyApp.Blog do
  use Ash.Domain
  
  resources do
    resource Post
    resource Author
    resource Category
    resource Tag
  end
end
```

### 4. Leverage Constraints for Auto-Configuration

Aurora UIX reads Ash constraints to configure UI components automatically:

```elixir
attribute :status, :atom do
  constraints one_of: [:draft, :published, :archived]
  # Aurora UIX will render this as a select dropdown
end
```

### 5. Document Custom Actions

If using custom actions, document them:

```elixir
auix_resource_metadata :post,
  ash_resource: Post,
  # Use custom action for listing only published posts
  ash_read_action: :published,
  ash_read_action_paginated: :published_paginated
```

## Next Steps

Now that you understand Aurora UIX's Ash integration, explore these Aurora UIX features:

- [Resource Metadata](resource_metadata.md) - Configure fields, validations, and display options
- [Layouts](layouts.md) - Build custom UI structures with Aurora UIX's layout DSL
- [LiveView Integration](liveview.md) - Advanced customization and event handling
- [Getting Started](getting_started.md) - Learn about Context-based integration

## Additional Resources

- [Aurora UIX GitHub](https://github.com/wadvanced/aurora_uix) - Main documentation and examples
- [Aurora Ctx GitHub](https://github.com/wadvanced/aurora_ctx) - Declarative DSL for Phoenix Context functions, perfect companion for Aurora UIX with Context backends
- [Ash Framework](https://ash-hq.org/) - Learn about Ash (if you're new to it)
- [Ash Postgres](https://hexdocs.pm/ash_postgres/) - Ash data layer documentation

---

