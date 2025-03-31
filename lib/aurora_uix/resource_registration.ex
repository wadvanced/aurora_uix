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

    implemented_functions =
      Enum.map(
        [
          %{type: :list_function, name: "list_#{source}", arity: 0},
          %{type: :list_function, name: "list_#{source}", arity: 1},
          %{type: :create_function, name: "create_#{module}", arity: 0},
          %{type: :create_function, name: "create_#{module}", arity: 1},
          %{type: :create_function!, name: "create_#{module}!", arity: 0},
          %{type: :create_function!, name: "create_#{module}!", arity: 1},
          %{type: :get_function, name: "get_#{module}", arity: 1},
          %{type: :get_function, name: "get_#{module}", arity: 2},
          %{type: :get_function!, name: "get_#{module}!", arity: 1},
          %{type: :get_function!, name: "get_#{module}!", arity: 2},
          %{type: :delete_function, name: "delete_#{module}", arity: 1},
          %{type: :delete_function!, name: "delete_#{module}!", arity: 1},
          %{type: :change_function, name: "change_#{module}", arity: 1},
          %{type: :change_function, name: "change_#{module}", arity: 2},
          %{type: :update_function, name: "update_#{module}", arity: 1},
          %{type: :update_function, name: "update_#{module}", arity: 2},
          %{type: :new_function, name: "new_#{module}", arity: 0},
          %{type: :new_function, name: "new_#{module}", arity: 1},
          %{type: :new_function, name: "new_#{module}", arity: 2}
        ],
        &Map.merge(&1, %{
          repo_module: repo_module,
          schema_module: schema_module,
          create_changeset_function: create_changeset_function,
          changeset_function: changeset_function,
          name: String.to_atom(&1.name)
        })
      )

    imports =
      quote do
        import Ecto.Query
        alias AuroraUix.QueryHelper
        alias AuroraUix.RepoHelper
      end

    functions =
      implemented_functions
      |> Enum.reject(&Module.defines?(context_module, {&1.name, &1.arity}, :def))
      |> Enum.map(&generate_function/1)

    quote do
      unquote(imports)
      unquote(functions)
    end
  end

  ## PRIVATE
  # Function templates
  @spec generate_function(map) :: Macro.t()
  defp generate_function(%{type: :list_function, arity: arity} = function) do
    arg = if arity == 1, do: [quote(do: opts)], else: []
    opts = if arity == 1, do: [quote(do: opts)], else: [quote(do: [])]

    quote do
      def unquote(function.name)(unquote_splicing(arg)) do
        unquote(function.schema_module)
        |> from()
        |> QueryHelper.options(unquote_splicing(opts))
        |> unquote(function.repo_module).all()
      end
    end
  end

  defp generate_function(%{type: type, arity: arity} = function)
       when type in [:create_function, :create_function!] do
    repo_function = repo_function(function, "insert")

    arg = if arity == 1, do: [quote(do: attrs)], else: []
    attrs = if arity == 1, do: [quote(do: attrs)], else: [nil]

    quote do
      def unquote(function.name)(unquote_splicing(arg)) do
        %unquote(function.schema_module){}
        |> unquote(function.schema_module).unquote(function.create_changeset_function)(
          unquote_splicing(attrs) || %{}
        )
        |> unquote(function.repo_module).unquote(repo_function)()
      end
    end
  end

  defp generate_function(%{type: type, arity: arity} = function)
       when type in [:get_function, :get_function!] do
    repo_function = repo_function(function, "get")

    arg = if arity == 2, do: [quote(do: id), quote(do: opts)], else: [quote(do: id)]
    opts = if arity == 2, do: [quote(do: opts)], else: [[]]

    quote do
      @doc false
      def unquote(function.name)(unquote_splicing(arg)) do
        unquote(function.schema_module)
        |> from()
        |> QueryHelper.options(unquote_splicing(opts))
        |> unquote(function.repo_module).unquote(repo_function)(id)
      end
    end
  end

  defp generate_function(%{type: type} = function)
       when type in [:delete, :delete!] do
    repo_function = repo_function(function, "delete")

    quote do
      @doc false
      def unquote(function.name)(id) do
        unquote(function.repo_module).unquote(repo_function)(unquote(function.schema_module), id)
      end
    end
  end

  defp generate_function(%{type: :change_function, arity: arity} = function) do
    args = if arity > 1, do: [quote(do: entity), quote(do: attrs)], else: [quote(do: entity)]
    entity = quote(do: entity)
    attrs = if arity > 1, do: quote(do: attrs), else: nil

    quote do
      @doc false
      def unquote(function.name)(unquote_splicing(args)) do
        unquote(function.schema_module).unquote(function.changeset_function)(
          unquote(entity),
          unquote(attrs) || %{}
        )
      end
    end
  end

  defp generate_function(%{type: :update_function, arity: arity} = function) do
    repo_function = repo_function(function, "update")
    args = if arity > 1, do: [quote(do: entity), quote(do: attrs)], else: [quote(do: entity)]
    entity = quote(do: entity)
    attrs = if arity == 2, do: quote(do: attrs), else: nil

    quote do
      @doc false
      def unquote(function.name)(unquote(args)) do
        unquote(entity)
        |> unquote(function.schema_module).unquote(function.changeset_function)(
          unquote(attrs) || %{}
        )
        |> unquote(function.repo_module).unquote(repo_function)()
      end
    end
  end

  defp generate_function(%{type: :new_function, arity: arity} = function) do
    args = if arity > 0, do: [quote(do: opts)], else: []
    opts = if arity > 0, do: quote(do: opts), else: quote(do: [])

    quote do
      @doc false
      def unquote(function.name)(unquote_splicing(args)) do
        RepoHelper.options(
          %unquote(function.schema_module){},
          unquote(function.repo_module),
          unquote(opts)
        )
      end
    end
  end

  defp generate_function(_func), do: quote(do: :ok)

  @spec repo_function(map, binary) :: atom
  defp repo_function(function, repo_function_name) do
    function.name
    |> to_string()
    |> String.ends_with?("!")
    |> maybe_add_bang(repo_function_name)
    |> String.to_atom()
  end

  @spec maybe_add_bang(boolean, binary) :: binary
  defp maybe_add_bang(true, repo_function_name), do: "#{repo_function_name}!"
  defp maybe_add_bang(_, repo_function_name), do: "#{repo_function_name}"

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
