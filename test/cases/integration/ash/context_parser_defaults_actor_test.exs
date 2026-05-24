defmodule Aurora.Uix.Integration.Ash.ContextParserDefaultsActorTest do
  @moduledoc """
  Verifies that the Ash `ContextParserDefaults` reads `:ash_actor_assign` (and its
  `:actor_assign` alias) from resource-metadata options and stores it on the resulting
  `CrudSpec` for every CRUD action key.

  This is the contract that lets `auix_resource_metadata :resource, ash_resource: R,
  ash_actor_assign: :current_user` produce CRUD connectors whose specs carry the
  actor-assign atom, so `Ash.Crud.socket_opts/2` can resolve the actor at runtime.
  """
  use ExUnit.Case, async: true

  alias Aurora.Uix.Guides.Blog.Author
  alias Aurora.Uix.Integration.Ash.ContextParserDefaults
  alias Aurora.Uix.Integration.Ash.CrudSpec
  alias Aurora.Uix.Integration.Connector

  @auix_action_keys [
    :list_function,
    :list_function_paginated,
    :get_function,
    :create_function,
    :update_function,
    :delete_function,
    :change_function,
    :new_function
  ]

  describe "option_value/4 with :ash_actor_assign" do
    test "stores actor_assign on the CrudSpec for every CRUD action key" do
      resource_config = %{schema: Author, name: :author}
      opts = [ash_actor_assign: :current_user]

      for key <- @auix_action_keys do
        connector = ContextParserDefaults.option_value(%{}, resource_config, opts, key)

        assert %Connector{type: :ash, crud_spec: %CrudSpec{actor_assign: :current_user}} =
                 connector,
               "expected actor_assign: :current_user on CrudSpec for #{inspect(key)}, " <>
                 "got: #{inspect(connector)}"
      end
    end

    test "accepts :actor_assign as an alias for :ash_actor_assign" do
      resource_config = %{schema: Author, name: :author}
      opts = [actor_assign: :viewer]

      connector = ContextParserDefaults.option_value(%{}, resource_config, opts, :list_function)

      assert %Connector{crud_spec: %CrudSpec{actor_assign: :viewer}} = connector
    end

    test "defaults actor_assign to nil when the option is absent" do
      resource_config = %{schema: Author, name: :author}

      connector = ContextParserDefaults.option_value(%{}, resource_config, [], :list_function)

      assert %Connector{crud_spec: %CrudSpec{actor_assign: nil}} = connector
    end

    test "ignores non-atom values defensively" do
      resource_config = %{schema: Author, name: :author}
      opts = [ash_actor_assign: "current_user"]

      connector = ContextParserDefaults.option_value(%{}, resource_config, opts, :list_function)

      assert %Connector{crud_spec: %CrudSpec{actor_assign: nil}} = connector
    end
  end
end
