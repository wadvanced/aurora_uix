defmodule Aurora.Uix.Guides.Blog.Post do
  @moduledoc """
  Ash resource representing blog posts for guides and examples.

  ## Key Features

  - Belongs to author and category
  - Status tracking (draft, published, archived)
  - Multi-value labels (featured, sponsored, opinion, full_review)
  - Publication timestamp support
  - Embedded tags array for categorization

  ## Key Constraints

  - Only for guides and test scenarios
  - Status must be one of: `:draft`, `:published`, `:archived`
  - Default status is `:draft`
  - Stored in PostgreSQL posts table
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Aurora.Uix.Guides.Blog,
    primary_read_warning?: false

  postgres do
    table("posts")
    repo(Aurora.Uix.Repo)
  end

  alias Aurora.Uix.Guides.Blog.Comment
  alias Aurora.Uix.Guides.Blog.Tag

  attributes do
    uuid_primary_key(:id)

    attribute(:title, :string)
    attribute(:content, :string)
    attribute(:published_at, :utc_datetime)

    attribute :status, :atom do
      constraints one_of: [:draft, :published, :archived]
      default :draft
    end

    # `nil_items?: true` is the multi-value select's empty-list sentinel showing through: the
    # renderer always submits one blank, Ash casts it to `nil`, and without this the whole list is
    # rejected with "no nil values" before any change can strip it. `reject_blank_labels/2` does.
    attribute :labels, {:array, :atom} do
      constraints nil_items?: true,
                  items: [one_of: [:featured, :sponsored, :opinion, :full_review]]

      public? true
    end

    attribute :tags, {:array, Tag}, public?: true

    attribute :comment, Comment do
      public? true
      default %Comment{}
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to(:author, Aurora.Uix.Guides.Blog.Author)
    belongs_to(:category, Aurora.Uix.Guides.Blog.Category)

    many_to_many :topics, Aurora.Uix.Guides.Blog.Topic do
      through Aurora.Uix.Guides.Blog.PostTopic
      source_attribute_on_join_resource :post_id
      destination_attribute_on_join_resource :topic_id
    end
  end

  actions do
    default_accept [
      :title,
      :content,
      :status,
      :labels,
      :tags,
      :comment,
      :published_at,
      :category_id,
      :author_id
    ]

    defaults [:destroy]

    create :create do
      primary? true
      argument :topics, {:array, :uuid}, allow_nil?: true, constraints: [nil_items?: true]
      change &__MODULE__.reject_blank_topics/2
      change &__MODULE__.reject_blank_labels/2
      change manage_relationship(:topics, :topics, type: :append_and_remove)
    end

    update :update do
      primary? true
      # manage_relationship cannot run on Ash's atomic update path.
      require_atomic? false
      argument :topics, {:array, :uuid}, allow_nil?: true, constraints: [nil_items?: true]
      change &__MODULE__.reject_blank_topics/2
      change &__MODULE__.reject_blank_labels/2
      change manage_relationship(:topics, :topics, type: :append_and_remove)
    end

    read :read do
      primary? true
      pagination required?: false, offset?: true
    end
  end

  calculations do
    calculate :summary, :string, expr(title <> " is " <> status)
  end

  @doc """
  Drops the blank entry the many-to-many renderer always submits.

  The renderer emits a hidden empty-value sentinel so that de-selecting every topic still submits
  the key; without it membership could never be cleared. Ash casts that blank to `nil` (hence the
  `nil_items?: true` constraint on the argument, which would otherwise reject the list outright), so
  this strips the nils before `manage_relationship` tries to resolve them.

  ## Parameters
  - `changeset` (Ash.Changeset.t()) - The changeset being built.
  - `context` (term()) - Change context, unused.

  ## Returns
  Ash.Changeset.t() - The changeset with a cleaned `:topics` argument.
  """
  @spec reject_blank_topics(Ash.Changeset.t(), term()) :: Ash.Changeset.t()
  def reject_blank_topics(changeset, _context) do
    case Ash.Changeset.fetch_argument(changeset, :topics) do
      {:ok, topics} when is_list(topics) ->
        Ash.Changeset.set_argument(
          changeset,
          :topics,
          Enum.reject(topics, &(is_nil(&1) or &1 == ""))
        )

      _other ->
        changeset
    end
  end

  @doc """
  Drops the blank entry the multi-value select renderer always submits.

  Same sentinel as `reject_blank_topics/2`, one layer down: `:labels` is a plain attribute rather
  than a relationship argument, so the blank arrives already cast to `nil` (hence `nil_items?: true`
  on the attribute) and is stripped here before the row is written.

  ## Parameters
  - `changeset` (Ash.Changeset.t()) - The changeset being built.
  - `context` (term()) - Change context, unused.

  ## Returns
  Ash.Changeset.t() - The changeset with a cleaned `:labels` attribute.
  """
  @spec reject_blank_labels(Ash.Changeset.t(), term()) :: Ash.Changeset.t()
  def reject_blank_labels(changeset, _context) do
    case Ash.Changeset.fetch_change(changeset, :labels) do
      {:ok, labels} when is_list(labels) ->
        Ash.Changeset.force_change_attribute(
          changeset,
          :labels,
          Enum.reject(labels, &(is_nil(&1) or &1 == ""))
        )

      _other ->
        changeset
    end
  end
end
