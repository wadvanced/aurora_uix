defmodule Aurora.Uix.Layout.ResourceMetadata do
  @moduledoc """
  Provides a comprehensive, declarative UI configuration system for structured data in
  Phoenix LiveView.

  Enables rich, metadata-driven UI configuration for data structures with flexible
  field-level UI metadata management and seamless integration with Phoenix LiveView.

  ## Configuration Strategies
  - Field-level customization
  - Bulk field configuration
  - Automatic default generation based on field types
  - Inheritance and extension of configurations

  ## Supported Field Attributes
  - Labels and placeholders
  - Input types and lengths
  - Validation rules (e.g. required)
  - Rendering options (readonly, hidden, disabled)
  - Precision and scale for numeric fields
  - Custom rendering via component or function
  - Omission flag to exclude fields entirely (`:omitted`)

  ## Example

  ```elixir
    defmodule MyApp.Product do
      use Ecto.Schema
      import Ecto.Changeset

      schema "products" do
        field :name, :string
        field :price, :float
        field :quantity, :integer
        belongs_to :category, MyApp.Category

        timestamps()
      end
    end

    defmodule MyApp.Category do
      use Ecto.Schema
      import Ecto.Changeset

      schema "categories" do
        field :name, :string
        has_many :products, MyApp.Product

        timestamps()
      end
    end

    defmodule MyAppWeb.Inventory.Views do
      auix_resource_metadata :product, schema: MyApp.Product, context: MyApp.Inventory do
        field :id, hidden: true
        field :name, placeholder: "Product name", max_length: 40, required: true
        field :price, placeholder: "Price", precision: 12, scale: 2
      end

      auix_resource_metadata :category, schema: MyApp.Category do
        field :id, readonly: true
        field :name, max_length: 20, required: true
        field :products, resource: :product
      end
    end
  ```
  """

  alias Aurora.Uix.Counter
  alias Aurora.Uix.Layout.Helpers, as: LayoutHelpers
  alias Aurora.Uix.Layout.Resource, as: DeclaredResource
  alias Aurora.Uix.Layout.Resource.FieldOverride
  alias Aurora.Uix.Layout.ResourceMetadata
  alias Aurora.Uix.Layout.ResourceResolver

  @doc false
  @spec __using__(any()) ::
          {:__block__, [], [{:@ | :import | {any(), any(), any()}, [...], [...]}, ...]}
  defmacro __using__(_opts) do
    quote do
      import Aurora.Uix.Layout.ResourceMetadata

      Module.register_attribute(__MODULE__, :_auix_process_resource_config, accumulate: true)

      @before_compile Aurora.Uix.Layout.ResourceMetadata
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    Counter.start_counter(:auix_fields)

    resources_metadata =
      env.module
      |> Module.get_attribute(:_auix_process_resource_config)
      |> Enum.reverse()
      |> ResourceResolver.resolve()

    resource_functions = Enum.map(resources_metadata, &resource_functions/1)

    quote do
      Module.put_attribute(
        unquote(env.module),
        :auix_resource_metadata,
        unquote(Macro.escape(resources_metadata))
      )

      @doc """
      Gets the configuration for all configured resources.

      Returns all resource metadata configurations.

      Returns a list of resource configurations.
      """
      @spec auix_resources() :: map()
      def auix_resources do
        unquote(Macro.escape(resources_metadata))
      end

      unquote(resource_functions)

      def auix_resource(_), do: nil
    end
  end

  @doc """
  Defines UI configuration for a schema.

  ## Parameters

  - `name` (atom()) - Resource identifier.
  - `opts` (keyword()) - Configuration options.
  - `do_block` (Macro.t() | nil) - Field configurations block.

  ## Options

  ### Common Options

  - `:order_by` (atom() | list() | keyword()) - Order used for displaying the index.
    * atom() - Single field name (e.g., `:name`)
    * list() - List of field names
    * keyword() - Direction-annotated fields (e.g., `[desc: :created_at]`)
    See [Ecto.Query.order_by/3](https://hexdocs.pm/ecto/Ecto.Query.html#order_by/3)
    for details about the supported directions.
  - `:renderers` (map()) - `html_type => renderer` table for every field of this resource
    (e.g. `%{checkbox: :toggle_switch}`). Beats `use Aurora.Uix`; `auix_create_ui`, a layout
    macro's `renderers:` and a field slot beat it. See `Aurora.Uix.Renderers`.

  ### Context-based Integration (`:ctx` type)

  For Ecto schema resources with Context modules:

  - `:schema` (module()) - Required. Ecto schema module.
  - `:context` (module()) - Required. Context module with CRUD functions.

  ### Ash Framework Integration (`:ash` type)

  For Ash Framework resources:

  - `:ash_resource` (module()) - Required. Ash resource module.
  - `:ash_actor_assign` (atom()) - Optional. Name of the `socket.assigns` key that
    holds the actor for policy-protected resources. When set, every generated CRUD
    call forwards `actor: socket.assigns[<assign>]` to Ash (`Ash.read/get/create/
    update/destroy/load` and `AshPhoenix.Form.for_update`). When unset (default),
    no `actor:` is added, preserving the previous behaviour for resources that do
    not use `Ash.Policy.Authorizer`. `:actor_assign` is accepted as a shorthand
    alias. `authorize?:` is never set explicitly — the host domain's own
    `authorize` config decides whether policies run. See the
    [Ash integration guide — Authorization &amp; policies](ash_integration.html#authorization--policies)
    for the worked example, behaviour matrix, and troubleshooting.

  Note: You can also use `:schema` as an alias for `:ash_resource` when working with Ash resources.
  context is irrelevant as ash resources know the domain that they belong to.

  ## Examples

  ### Context-based Resource

      auix_resource_metadata(:product,
        schema: MyApp.Inventory.Product,
        context: MyApp.Inventory,
        order_by: :reference
      )

  ### Context Resource with Sort Direction

      auix_resource_metadata(:product,
        schema: MyApp.Inventory.Product,
        context: MyApp.Inventory,
        order_by: [desc: :created_at]
      )

  ### Ash Resource

      auix_resource_metadata(:author,
        ash_resource: MyApp.Blog.Author,
        order_by: [:name]
      )

  ### Ash Resource with policy-protected actions (actor threading)

      auix_resource_metadata(:template,
        ash_resource: MyApp.Templates.InterfaceDocumentTemplate,
        ash_actor_assign: :current_user
      )

  ## Returns

  Macro.t() - Configured metadata block for the resource.
  """
  @spec auix_resource_metadata(atom(), keyword(), Macro.t() | nil) :: Macro.t()
  defmacro auix_resource_metadata(name, opts \\ [], do_block \\ nil) do
    {block, opts} = LayoutHelpers.extract_block_options(opts, do_block)

    resource_config =
      quote do
        DeclaredResource.new(
          unquote(name),
          unquote(opts),
          List.flatten(unquote(LayoutHelpers.prepare_block(block)))
        )
      end

    quote do
      use ResourceMetadata
      Module.put_attribute(__MODULE__, :_auix_process_resource_config, unquote(resource_config))
    end
  end

  @doc """
  Configures a single field within a resource configuration.

  Provides fine-grained control over field presentation, validation,
  and interaction rules. Supports comprehensive customization of
  individual fields.

  ## Parameters
  - `field` (atom() | tuple()): The name of the field to configure
  - `opts` (keyword()): Field-specific configuration options

  ## Options

  The following options can be provided to configure the field:

  - `:type`(`atom()`) - The html type that best represent the current field elixir type.
  - `:label` (`binary()`) - A custom label for the field. (auto-generated from field name if omitted).
  - `:placeholder` (`binary()`) - Placeholder text for the field.
  - `:length`(`non_neg_integer()`) - Display length of the field.
  - `:precision` (`integer()`) - The numeric precision for decimal or float fields.
  - `:scale` (`integer()`) - The numeric scale for decimal or float fields.
  - `:readonly` (`boolean()`) - Marks the field as read-only.
  - `:hidden` (`boolean()`) - Hides the field.
  - `:filterable?` (`boolean()`) - If true, allows the field to participate in UI filtering.
  - `:sortable?` (`boolean()`) - If false, the index column header offers no sorting. Parsed from the column type when omitted. An upload field (`:data` with an `:upload` map) never offers sorting.
  - `:renderer` (`function()` | `atom()`) - Renderer for the form (edit) and show layouts unless a
    more specific `:edit_renderer`/`:show_renderer` is set. An arity-1 function, or an atom naming
    a predefined renderer (e.g. `:toggle_switch`; see `Aurora.Uix.Renderer`). Does not apply to
    the index layout — use `:index_renderer`.
  - `:index_renderer` (`function()` | `atom()`) - Renderer used only for the index layout.
  - `:edit_renderer` (`function()` | `atom()`) - Renderer used only for the form (edit) layout.
    Falls back to `:renderer` when not set.
  - `:show_renderer` (`function()` | `atom()`) - Renderer used only for the show layout. Falls
    back to `:renderer` when not set.
  - `:required` (`boolean()`) - Marks the field as required.
  - `:disabled` (`boolean()`) - If true, the field should not participate in form interaction.
  - `:omitted` (`boolean()`) - If true, the field will be entirely excluded from the UI and configuration.
  - `:expanded` (`boolean()` | `function()`) - For `embeds_many` fields only. Controls whether the
    embedded collection renders expanded (`true`) or collapsed (`false`, the default) on initial load,
    in both show and edit modes. Accepts a boolean or a captured function of arity 1 (e.g.
    `&MyApp.expanded?/1`, not an inline `fn`) that receives the rendering assigns and returns a
    boolean. The runtime collapse/expand toggle remains available regardless.

  ## Example

  ```elixir
  field :name, label: "Product Name", placeholder: "Enter product name", required: true
  field :price, precision: 12, scale: 2, label: "Price ($)"
  ```
  """
  @spec field(atom() | tuple(), keyword()) :: Macro.t()
  defmacro field(field, opts \\ []) do
    quote do
      FieldOverride.new(unquote(field), unquote(opts))
    end
  end

  @doc """
  Applies configuration to multiple fields simultaneously.

  Enables bulk configuration of fields, reducing repetitive code
  and promoting consistent field settings across multiple attributes.

  ## Parameters
  - `fields` (list() of atoms or tuples): Fields to be configured
  - `opts` (keyword()): Configuration options applied to all specified fields

  ## Example
  ```elixir
  fields [:msrp, :rrp, :list_price], precision: 10, scale: 2
  ```
  """
  @spec fields([atom() | tuple()], keyword()) :: Macro.t()
  defmacro fields(fields, opts \\ []) do
    quotes =
      Enum.map(fields, fn field ->
        quote do
          field(unquote(field), unquote(opts))
        end
      end)

    quote do
      unquote(quotes)
    end
  end

  ## PRIVATE

  # creates the function for each resource.
  @spec resource_functions({atom(), map()}) :: Macro.t()
  defp resource_functions({resource_key, resource}) do
    quote do
      @doc """
      Gets the config for a given resource.
      """
      @spec auix_resource(atom()) :: map()
      def auix_resource(unquote(resource_key)) do
        unquote(Macro.escape(resource))
      end
    end
  end
end
