defmodule Aurora.UixWeb.Test.AshActorViewsDefinition do
  @moduledoc false

  @doc false
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(_opts) do
    quote do
      use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

      auix_resource_metadata(:policy_item,
        ash_resource: AshActorTest.PolicyItem,
        backend_opts: [ash_actor_assign: :current_user]
      )

      auix_resource_metadata(:policy_item_scope,
        ash_resource: AshActorTest.PolicyItemScope,
        backend_opts: [ash_actor_assign: :scope]
      )

      auix_resource_metadata(:public_item,
        ash_resource: AshActorTest.PublicItem
      )

      auix_create_ui do
        edit_layout :policy_item do
          stacked([:name, :tags])
        end

        edit_layout :policy_item_scope do
          stacked([:name])
        end

        edit_layout :public_item do
          stacked([:name])
        end
      end
    end
  end
end
