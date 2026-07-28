defmodule Aurora.Uix.Guides.Blog.PostTopic do
  @moduledoc """
  Ash join resource linking posts and topics for guides and examples.

  Carries no attributes of its own beyond the two foreign keys — it exists solely to express the
  many-to-many linkage that `Post.topics` reads through.

  ## Key Features

  - Belongs to post and topic
  - Unique identity on the pair, so a topic cannot be added to a post twice

  ## Key Constraints

  - Only for guides and test scenarios
  - Rows are managed through `Post`'s create and update actions, not directly
  - Stored in PostgreSQL post_topics table
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Aurora.Uix.Guides.Blog

  postgres do
    table("post_topics")
    repo(Aurora.Uix.Repo)
  end

  attributes do
    uuid_primary_key(:id)
  end

  relationships do
    belongs_to(:post, Aurora.Uix.Guides.Blog.Post)
    belongs_to(:topic, Aurora.Uix.Guides.Blog.Topic)
  end

  identities do
    identity(:unique_post_topic, [:post_id, :topic_id])
  end

  actions do
    default_accept [:post_id, :topic_id]

    defaults [:read, :destroy, :create, :update]
  end
end
