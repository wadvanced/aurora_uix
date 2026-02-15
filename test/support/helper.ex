defmodule Aurora.Uix.Test.Helper do
  @moduledoc """
  Helper functions for test data generation.

  ## Key Features
  - Utilities to create sample records for testing purposes.
  - Generates products, product locations, and transactions for test scenarios.
  """

  alias Aurora.Uix.Guides.Accounts.User
  alias Aurora.Uix.Guides.Blog.Author
  alias Aurora.Uix.Guides.Blog.Category
  alias Aurora.Uix.Guides.Blog.Post
  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductLocation
  alias Aurora.Uix.Guides.Inventory.ProductTransaction

  alias Aurora.Uix.Repo

  require Logger

  @transaction_types ~w(entry exit returns move_in move_out)
  @transaction_types_count Enum.count(@transaction_types)

  @doc """
  Creates a sequence of sample products with incremental IDs.

  ## Parameters
  - `count` (integer()) - Number of products to create.
  - `prefix` (atom() | nil) - Prefix to use in the reference of the product.
  - `attrs` (map()) - Attributes to override defaults.

  ## Returns
  map() - Map of product IDs with atom keys in the format `id_n`.
  """
  @spec create_sample_products(integer(), atom() | nil, map()) :: map()
  def create_sample_products(count, prefix \\ nil, attrs \\ %{}) do
    length = count |> to_string() |> String.length()

    1..count
    |> Enum.map(fn index ->
      reference_id = reference_id(prefix, index, length)
      reference = "item_#{reference_id}"
      name = "Item #{reference_id}"
      description = "This is the item #{reference_id} as described."
      cost = index / 100 + 123
      quantity_at_hand = :rand.uniform(10_000)

      %Product{
        reference: reference,
        name: name,
        description: description,
        cost: cost,
        quantity_at_hand: quantity_at_hand
      }
      |> struct(attrs)
      |> Repo.insert()
      |> elem(1)
      |> then(&{"id_#{reference_id}", &1})
    end)
    |> Map.new()
  end

  @doc """
  Creates sample products with associated transactions.

  ## Parameters
  - `product_count` (integer()) - Number of products to create.
  - `transactions_count` (integer()) - Number of transactions per product.
  - `prefix` (atom() | nil) - Prefix for product references.
  - `attrs` (map()) - Attributes to override defaults.

  ## Returns
  map() - Map of product IDs with associated transactions.
  """
  @spec create_sample_products_with_transactions(integer(), integer(), atom() | nil, map() | nil) ::
          map()
  def create_sample_products_with_transactions(
        product_count,
        transactions_count,
        prefix \\ nil,
        attrs \\ %{}
      ) do
    product_count
    |> create_sample_products(prefix, attrs)
    |> Enum.map(&create_sample_product_transactions(&1, transactions_count))
  end

  @doc """
  Creates sample product locations.

  ## Parameters
  - `locations_count` (integer()) - Number of locations to create.

  ## Returns
  list(ProductLocation.t()) - List of created product locations.
  """
  @spec create_sample_product_locations(integer(), atom() | nil) :: list(ProductLocation.t())
  def create_sample_product_locations(locations_count, prefix \\ nil) do
    length = locations_count |> to_string() |> String.length()

    1..locations_count
    |> Enum.map(fn index ->
      reference_id = reference_id(prefix, index, length)

      %ProductLocation{
        reference: "test-reference-#{reference_id}",
        name: "test-name-#{reference_id}",
        type: "test-type-#{reference_id}"
      }
      |> Repo.insert()
      |> elem(1)
      |> then(&{"id_#{index}", &1})
    end)
    |> Map.new()
  end

  @doc """
  Creates sample users.
  """
  @spec create_sample_users(non_neg_integer(), map()) :: :ok
  def create_sample_users(count, attrs \\ %{}) do
    Enum.map(
      1..count,
      &(%User{
          given_name: "John #{&1}",
          family_name: "john#{&1}@doe.com",
          avatar_url: "https://noexist-avatar-#{&1}.svg",
          profile: %{online: false, dark_mode: false, visibility: :public}
        }
        |> struct(attrs)
        |> Repo.insert()
        |> elem(1))
    )
  end

  @doc """
  Creates sample authors.
  """
  @spec create_sample_authors(non_neg_integer(), map()) :: :ok
  def create_sample_authors(count, attrs \\ %{}) do
    length = count |> to_string() |> String.length()

    Enum.map(1..count, fn index ->
      reference_id = reference_id("test", index, length)

      change =
        %Author{
          name: "Author#{reference_id}",
          email: "author#{reference_id}@test.com",
          bio: "Born in January #{1990 - index}"
        }
        |> struct(attrs)
        |> Map.from_struct()
        |> Enum.filter(&(elem(&1, 0) in [:name, :email, :bio]))

      Author
      |> Ash.Changeset.for_create(:create, change)
      |> Ash.create!()
    end)
  end

  @doc """
  Creates sample categories.
  """
  @spec create_sample_categories(non_neg_integer(), map()) :: :ok
  def create_sample_categories(count, attrs \\ %{}) do
    Enum.map(1..count, fn index ->
      change =
        %Category{
          name: "Category-#{index}",
          description: "Category for #{index} selected"
        }
        |> struct(attrs)
        |> Map.from_struct()
        |> Enum.filter(&(elem(&1, 0) in [:name, :description]))

      Category
      |> Ash.Changeset.for_create(:create, change)
      |> Ash.create!()
    end)
  end

  @doc """
  Creates sample posts.
  """
  @spec create_sample_posts(non_neg_integer(), map()) :: :ok
  def create_sample_posts(count, attrs \\ %{}) do
    length = count |> to_string() |> String.length()

    Enum.map(1..count, fn index ->
      reference_id = reference_id("test", index, length)

      change =
        %Post{
          title: "Post#{reference_id}",
          content: "lorem ipsum lorem ipsum #{reference_id} lorem ipsum",
          status: "published"
        }
        |> struct(attrs)
        |> Map.from_struct()
        |> Enum.filter(&(elem(&1, 0) in [:title, :content, :status, :author_id, :tags, :comment]))

      Post
      |> Ash.Changeset.for_create(:create, change)
      |> Ash.create!()
    end)
  end

  @doc """
  Create overview sample data.
  """
  @spec create_guides_sample_data() :: :ok
  def create_guides_sample_data do
    delete_all_sample_data()

    product_locations =
      Enum.map(["North", "South", "East", "West"], fn location ->
        id = String.downcase(location)

        Inventory.create_product_location(%{
          reference: "overview-#{id}",
          name: "#{location} Side",
          type: "type-#{:rand.uniform(5)}"
        })
      end)

    create_sample_products_with_transactions(100, 3, :overview, %{
      quantity_initial: :rand.uniform(999),
      list_price: :rand.uniform(250) + 200,
      rpp: :rand.uniform(250),
      product_location_id:
        product_locations |> Enum.at(:rand.uniform(4) - 1) |> elem(1) |> Map.get(:id)
    })

    blog_count = 5
    categories = create_sample_categories(blog_count)

    authors =
      create_sample_authors(blog_count)

    Enum.each(1..blog_count, fn index ->
      reference_id = reference_id("overview", index, 1)

      create_sample_posts(1, %{
        title: "Overview Post #{index}",
        content: "lorem ipsum lorem ipsum #{reference_id} lorem ipsum",
        author_id: Enum.at(authors, index - 1).id,
        category_id: Enum.at(categories, index - 1).id
      })
    end)
  end

  @doc """
  Deletes all inventory data. 
  """
  @spec delete_all_inventory_data() :: :ok
  def delete_all_inventory_data do
    Repo.delete_all(ProductTransaction)
    Repo.delete_all(Product)
    Repo.delete_all(ProductLocation)
  end

  @doc """
  Deletes all account data.
  """
  @spec delete_all_accounts_data() :: :ok
  def delete_all_accounts_data do
    Repo.delete_all(User)
  end

  @doc """
  Deletes all blog data.
  """
  @spec delete_all_blog_data() :: :ok
  def delete_all_blog_data do
    Repo.delete_all(Post)
    Repo.delete_all(Author)
    Repo.delete_all(Category)
  end

  @doc """
  Deletes all sample data
  """
  @spec delete_all_sample_data() :: :ok
  def delete_all_sample_data do
    delete_all_inventory_data()
    delete_all_accounts_data()
    delete_all_blog_data()
  end

  @doc """
  Converts to boolean
  """
  @spec to_boolean(term()) :: boolean()
  def to_boolean(nil), do: false

  def to_boolean(value) when is_binary(value) do
    value
    |> String.downcase()
    |> String.trim()
    |> Kernel.==("true")
  end

  def to_boolean(value) when is_number(value), do: value != 0

  def to_boolean(_value), do: false

  ## PRIVATE ##

  @spec create_sample_product_transactions({binary(), Ecto.Schema.t()}, integer()) ::
          {binary(), Ecto.Schema.t()}
  defp create_sample_product_transactions(product, transactions_count) do
    1..transactions_count
    |> Enum.map(fn index ->
      Repo.insert(%ProductTransaction{
        product: elem(product, 1),
        type: transaction_type(),
        quantity: index * 2,
        cost: index / 100 + 456
      })
    end)
    |> then(fn _ -> product end)
  end

  @spec reference_id(atom() | binary() | nil, integer(), integer()) :: binary()
  defp reference_id(nil, index, length), do: reference_id("", index, length)

  defp reference_id(prefix, index, length) when is_atom(prefix),
    do: prefix |> to_string() |> reference_id(index, length)

  defp reference_id(prefix, index, length) when is_binary(prefix) do
    prefix_with_hyphen = if prefix == "", do: "", else: "#{prefix}-"

    index
    |> to_string()
    |> String.length()
    |> then(&(length - &1))
    |> then(&String.duplicate("0", &1))
    |> then(&"#{prefix_with_hyphen}#{&1}#{index}")
  end

  @spec transaction_type() :: binary()
  defp transaction_type do
    @transaction_types_count
    |> :rand.uniform()
    |> then(&Enum.at(@transaction_types, &1 - 1))
  end
end
