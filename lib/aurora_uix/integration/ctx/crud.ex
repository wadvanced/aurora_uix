defmodule Aurora.Uix.Integration.Ctx.Crud do
  @moduledoc """
  CRUD operations for Context-based (Ecto) resources.

  Provides wrapper functions that delegate to Context-based function references stored
  in CrudSpec structures. Enables consistent CRUD interface across different backend
  implementations by invoking the appropriate function with the provided arguments.

  ## Key Features

  - Delegates CRUD operations to Context function references
  - Supports standard operations: list, get, create, update, delete
  - Pagination integration via `Aurora.Ctx.Core`
  - Consistent interface matching Ash CRUD operations

  ## Key Constraints

  - Requires valid CrudSpec with function_spec field populated
  - Function arities must match the operation requirements
  - Pagination relies on `Aurora.Ctx.Core.to_page/2`
  """
  alias Aurora.Ctx.Core, as: CtxCore
  alias Aurora.Ctx.Pagination
  alias Aurora.Uix.Integration.Ctx.CrudSpec

  @doc """
  Lists resources using the provided CrudSpec function.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The spec containing the list function reference.
  - `opts` (keyword()) - Query options passed to the function.

  ## Returns

  term() - The result from the function invocation (typically a pagination structure).

  ## Examples

      iex> crud_spec = %CrudSpec{function_spec: &MyContext.list_users/1}
      iex> list(crud_spec, where: [{:active, true}])
      %Pagination{entries: [...]}
  """
  @spec list(CrudSpec.t(), keyword()) :: term()
  def list(%CrudSpec{function_spec: function_spec}, opts), do: function_spec.(opts)

  @doc """
  Navigates to a specific page in paginated results.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The spec (currently unused).
  - `pagination` (Pagination.t()) - The current pagination structure.
  - `page` (integer()) - The target page number.

  ## Returns

  Pagination.t() - Updated pagination structure with the requested page data.

  ## Examples

      iex> to_page(crud_spec, %Pagination{page: 1, pages_count: 5}, 3)
      %Pagination{page: 3, entries: [...]}
  """
  @spec to_page(CrudSpec.t(), Pagination.t(), integer()) :: Pagination.t()
  def to_page(_crud_spec, pagination, page), do: CtxCore.to_page(pagination, page)

  @doc """
  Retrieves a single resource by ID.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The spec containing the get function reference.
  - `id` (term()) - The resource identifier.
  - `opts` (keyword()) - Additional options passed to the function.

  ## Returns

  struct() | nil - The retrieved resource or `nil` if not found.

  ## Examples

      iex> crud_spec = %CrudSpec{function_spec: &MyContext.get_user/2}
      iex> get(crud_spec, 123, [])
      %User{id: 123}
  """
  @spec get(CrudSpec.t(), term(), keyword()) :: struct() | nil
  def get(%CrudSpec{function_spec: function_spec}, id, opts),
    do: function_spec.(id, opts)

  @doc """
  Creates a changeset for updating a resource.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The spec containing the change function reference.
  - `entity` (struct()) - The resource to create a changeset for.
  - `attrs` (map()) - Attributes to apply to the changeset.

  ## Returns

  Ecto.Changeset.t() - A changeset structure.

  ## Examples

      iex> crud_spec = %CrudSpec{function_spec: &MyContext.change_user/2}
      iex> change(crud_spec, %User{}, %{name: "John"})
      %Ecto.Changeset{...}
  """
  @spec change(CrudSpec.t(), struct(), map()) :: Ecto.Changeset.t()
  def change(%CrudSpec{function_spec: function_spec}, entity, attrs),
    do: function_spec.(entity, attrs)

  @doc """
  Creates a new resource struct with optional preloading.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The spec containing the new function reference.
  - `attrs` (map()) - Initial attributes for the new resource.
  - `opts` (keyword()) - Options passed to the function.

  ## Returns

  struct() - A new resource struct.

  ## Examples

      iex> crud_spec = %CrudSpec{function_spec: &MyContext.new_user/2}
      iex> new(crud_spec, %{name: "Jane"}, [])
      %User{name: "Jane"}
  """
  @spec new(CrudSpec.t(), map(), keyword()) :: struct()
  def new(%CrudSpec{function_spec: function_spec}, attrs, opts), do: function_spec.(attrs, opts)

  @doc """
  Creates a new resource in the database.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The spec containing the create function reference.
  - `params` (map()) - Parameters for the new resource.

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.

  ## Examples

      iex> crud_spec = %CrudSpec{function_spec: &MyContext.create_user/1}
      iex> create(crud_spec, %{name: "Alice", email: "alice@example.com"})
      {:ok, %User{name: "Alice"}}
  """
  @spec create(CrudSpec.t(), map()) :: tuple()
  def create(%CrudSpec{function_spec: function_spec}, params),
    do: function_spec.(params)

  @doc """
  Updates an existing resource in the database.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The spec containing the update function reference.
  - `entity` (struct()) - The resource to update.
  - `params` (map()) - Parameters to update.

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.

  ## Examples

      iex> crud_spec = %CrudSpec{function_spec: &MyContext.update_user/2}
      iex> update(crud_spec, %User{id: 1}, %{name: "Bob"})
      {:ok, %User{id: 1, name: "Bob"}}
  """
  @spec update(CrudSpec.t(), struct(), map()) :: tuple()
  def update(%CrudSpec{function_spec: function_spec}, entity, params),
    do: function_spec.(entity, params)

  @doc """
  Deletes a resource from the database.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The spec containing the delete function reference.
  - `entity` (struct()) - The resource to delete.

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.

  ## Examples

      iex> crud_spec = %CrudSpec{function_spec: &MyContext.delete_user/1}
      iex> delete(crud_spec, %User{id: 1})
      {:ok, %User{id: 1}}
  """
  @spec delete(CrudSpec.t(), struct()) :: tuple()
  def delete(%CrudSpec{function_spec: function_spec}, entity),
    do: function_spec.(entity)
end
