defmodule Aurora.Uix.Test.Cases.DslSchemasTest do
  use ExUnit.Case

  alias Aurora.Uix.Action
  alias Aurora.Uix.Dsl.Schema.ActionOptions
  alias Aurora.Uix.Dsl.Schema.FieldOptions
  alias Aurora.Uix.Dsl.Schema.FormOptions
  alias Aurora.Uix.Dsl.Schema.IndexOptions
  alias Aurora.Uix.Dsl.Schema.ShowOptions

  describe "field options schema" do
    test "exposes the shared field key set with typed entries" do
      schema = FieldOptions.schema()

      assert Keyword.keys(schema) == [
               :key,
               :type,
               :label,
               :placeholder,
               :length,
               :precision,
               :scale,
               :readonly,
               :hidden,
               :required,
               :disabled,
               :omitted,
               :filterable?,
               :sortable?,
               :renderer,
               :index_renderer,
               :edit_renderer,
               :show_renderer,
               :expanded,
               :option_label,
               :order_by,
               :where
             ]

      assert schema[:label] == [type: :string, required: false]
      assert schema[:length] == [type: :non_neg_integer, required: false]
      assert schema[:readonly] == [type: :boolean, required: false]
      assert schema[:renderer] == [type: {:or, [:atom, {:fun, 1}]}, required: false]
      assert schema[:expanded] == [type: {:or, [:boolean, {:fun, 1}]}, required: false]

      assert schema[:option_label] == [
               type: {:or, [:atom, {:fun, 1}, {:fun, 2}]},
               required: false
             ]

      assert schema[:order_by] == [
               type: {:or, [:atom, :keyword_list, {:list, :atom}]},
               required: false
             ]

      assert schema[:where] == [type: :keyword_list, required: false]
    end
  end

  describe "layout options schemas" do
    test "index schema exposes the index key set" do
      schema = IndexOptions.schema()

      assert Keyword.keys(schema) == [
               :pagination_disabled?,
               :sort_disabled?,
               :pagination_items_per_page,
               :pages_bar_range_offset,
               :get_streams,
               :row_id,
               :infinite_scroll_items_load,
               :alternate_streams_suffixes,
               :page_title,
               :page_subtitle,
               :new_action_label,
               :order_by,
               :where,
               :handler_module,
               :renderers
             ]

      assert schema[:pagination_disabled?] == [
               type: {:or, [:boolean, {:fun, 1}]},
               required: false
             ]

      assert schema[:get_streams] == [type: {:fun, 1}, required: false]
      assert schema[:handler_module] == [type: :module, required: false]
    end

    test "form schema exposes the form key set" do
      schema = FormOptions.schema()

      assert Keyword.keys(schema) == [
               :edit_title,
               :edit_subtitle,
               :new_title,
               :new_subtitle,
               :save_action_label,
               :record_navigator,
               :unsaved_changes_guard_disabled?,
               :edit_handler_module,
               :renderers
             ]

      assert schema[:edit_title] == [type: {:or, [:string, {:fun, 1}]}, required: false]

      assert schema[:record_navigator] == [
               type: {:or, [{:in, [:top, :bottom]}, {:list, {:in, [:top, :bottom]}}]},
               required: false
             ]
    end

    test "show schema exposes the show key set" do
      schema = ShowOptions.schema()

      assert Keyword.keys(schema) == [
               :page_title,
               :page_subtitle,
               :edit_action_label,
               :back_action_label,
               :record_navigator,
               :show_handler_module,
               :renderers
             ]

      assert schema[:back_action_label] == [
               type: {:or, [:string, {:fun, 0}]},
               required: false
             ]
    end
  end

  describe "action options schema" do
    test "derives one entry per action option name with prefix-typed values" do
      schema = ActionOptions.schema()
      names = Action.action_option_names()

      schema_keys = schema |> Keyword.keys() |> Enum.sort()

      assert schema_keys == Enum.sort(names)

      for {key, opts} <- schema do
        name = Atom.to_string(key)

        cond do
          String.starts_with?(name, ["add_", "insert_", "replace_"]) ->
            assert opts == [type: {:tuple, [:atom, {:fun, 1}]}, required: false]

          String.starts_with?(name, "remove_") ->
            assert opts == [type: :atom, required: false]
        end
      end
    end
  end
end
