defmodule AuroraUix.ResourceRegistration do
  @moduledoc """
  A module for dynamically registering and generating CRUD (Create, Read, Update, Delete)
  resource functions for Ecto schemas.

  ## Overview

  This module provides a macro-based approach to automatically generate common database
  operation functions for an Ecto schema. It creates functions based on the schema's
  database table name, simplifying the process of creating repetitive CRUD methods.

  ## Relationship with Ecto.Schema

  The module works directly with Ecto schemas, using the `__schema__(:source)` method
  to derive the base name for generated functions. This ensures tight integration
  with Ecto's schema definition and database mapping.

  ## Usage

  1. Use the module in your context module:
  ```elixir
  defmodule MyApp.Accounts do
    use AuroraUix.ResourceRegistration

    auix_register_resource(User)
  end
  ```

  2. Optionally, you can specify a custom repo or additional options:
  ```elixir
  auix_register_resource(User, CustomRepo,
    changeset_function: :update_changeset,
    create_changeset_function: :create_changeset
  )
  ```

  ## Generated Functions

  For each registered Ecto schema, functions are generated using the schema's
  database table name. For example, for a schema with table name `users`:
  - `list_users/0`: Retrieves all records
  - `create_user/1`: Creates a new record
  - `create_user!/1`: Creates a new record (raises on error)
  - `get_user/1`: Retrieves a record by ID
  - `get_user!/1`: Retrieves a record by ID (raises on error)
  - `delete_user/1`: Deletes a record by ID
  - `delete_user!/1`: Deletes a record by ID (raises on error)
  - `change_user/2`: Applies a changeset to a record

  ## Macros

  ### `auix_register_resource/3`
  Registers a resource for automatic CRUD function generation.

  #### Parameters
  - `schema_module`: The Ecto schema module to generate functions for
  - `repo`: (Optional) The repository module to use. Defaults to auto-detection
  - `opts`: (Optional) Additional configuration options

  #### Options
  - `:changeset_function` - Custom changeset function name (default: `:changeset`)
  - `:create_changeset_function` - Specific changeset for creation (falls back to `:changeset`)

  """

  alias AuroraUix.ResourceRegistration

  defmacro __using__(_opts) do
    quote do
      import AuroraUix.ResourceRegistration
      Module.register_attribute(__MODULE__, :_auix_crud_resource, accumulate: true)
      @before_compile ResourceRegistration
    end
  end

  defmacro __before_compile__(env) do
    functions =
      env.module
      |> Module.get_attribute(:_auix_crud_resource, [])
      |> Enum.map(&ResourceRegistration.__auix_register_resource__(env.module, &1))

    quote do
      unquote(functions)
    end
  end

  @doc """
  Registers a resource for automatic CRUD function generation.

  ## Parameters
    - `schema_module`: The Ecto schema module to generate functions for
    - `repo`: (Optional) The repository module to use. Defaults to auto-detection
    - `opts`: (Optional) Additional configuration options

  ## Options
    - `:changeset_function` - Custom changeset function name (default: `:changeset`)
    - `:create_changeset_function` - Specific changeset for creation (falls back to `:changeset`)

  ## Examples
  ```elixir
    # Basic usage
    auix_register_resource(User)

    # With custom repo
      auix_register_resource(User, CustomRepo)

      # With custom changeset functions
      auix_register_resource(User, nil,
          changeset_function: :update_changeset,
          create_changeset_function: :create_changeset
        )
    ```
  """
  defmacro auix_register_resource(schema_module, repo \\ nil, opts \\ []) do
    quote do
      Module.put_attribute(__MODULE__, :_auix_crud_resource, %{
        schema_module: unquote(schema_module),
        repo: unquote(repo),
        opts: unquote(opts)
      })
    end
  end

  @doc false
  @spec __auix_register_resource__(module, map) :: Macro.t()
  def __auix_register_resource__(
        context_module,
        %{schema_module: schema_module, repo: repo, opts: opts}
      ) do
    repo_module =
      get_repo_module(context_module, repo)

    source = schema_module.__schema__(:source)

    module =
      schema_module
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    create_changeset_function = get_option(opts, :create_changeset_function)
    changeset_function = get_option(opts, :changeset_function)

    list_function = String.to_atom("list_#{source}")
    create_function = String.to_atom("create_#{module}")
    create_function! = String.to_atom("create_#{module}!")
    get_function = String.to_atom("get_#{module}")
    get_function! = String.to_atom("get_#{module}!")
    delete_function = String.to_atom("delete_#{module}")
    delete_function! = String.to_atom("delete_#{module}!")
    change_function = String.to_atom("change_#{module}")

    quote do
      @doc false
      def unquote(list_function)() do
        unquote(repo_module).all(unquote(schema_module))
      end

      @doc false
      def unquote(create_function)(attrs \\ %{}) do
        %unquote(schema_module){}
        |> unquote(schema_module).unquote(create_changeset_function)(attrs)
        |> unquote(repo_module).insert()
      end

      @doc false
      def unquote(create_function!)(attrs \\ %{}) do
        %unquote(schema_module){}
        |> unquote(schema_module).unquote(create_changeset_function)(attrs)
        |> unquote(repo_module).insert!()
      end

      @doc false
      def unquote(get_function)(id) do
        unquote(repo_module).get(unquote(schema_module), id)
      end

      @doc false
      def unquote(get_function!)(id) do
        unquote(repo_module).get!(unquote(schema_module), id)
      end

      @doc false
      def unquote(delete_function)(id) do
        unquote(repo_module).delete(unquote(schema_module), id)
      end

      @doc false
      def unquote(delete_function!)(id) do
        unquote(repo_module).delete!(unquote(schema_module), id)
      end

      @doc false
      def unquote(change_function)(entity, attrs \\ %{}) do
        unquote(schema_module).unquote(changeset_function)(entity, attrs)
      end
    end
  end

  @spec get_repo_module(module, module | nil) :: module
  defp get_repo_module(context_module, nil) do
    context_module
    |> Module.split()
    |> List.first()
    |> then(&Module.concat(&1, Repo))
  end

  defp get_repo_module(_context_module, repo), do: repo

  @spec get_option(keyword, atom) :: any
  defp get_option(opts, :create_changeset_function) do
    if opts[:create_changeset_function],
      do: opts[:create_changeset],
      else: get_option(opts, :changeset_function)
  end

  defp get_option(opts, :changeset_function) do
    if opts[:changeset_function], do: opts[:changeset_function], else: :changeset
  end
end
