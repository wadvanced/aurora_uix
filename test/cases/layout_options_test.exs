defmodule Aurora.Uix.Test.Cases.LayoutOptionsTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Layout.Options
  alias Aurora.Uix.Layout.Options.Form
  alias Aurora.Uix.Layout.Options.Option

  describe "options/0" do
    test "lists each option of the set with its layout type" do
      assert %Option{layout_type: :form, name: :edit_title} in Form.options()
      assert Enum.all?(Form.options(), &(&1.layout_type == :form))
    end

    test "available_options/1 reads the options of every set" do
      assert :record_navigator in Options.available_options(:form)
      assert :record_navigator in Options.available_options(:show)
      refute :edit_title in Options.available_options(:show)
    end
  end

  describe "use" do
    test "a listed option is read from the layout, then from get_default/2" do
      [{options_set, _binary}] =
        Code.compile_string("""
        defmodule Aurora.Uix.Test.LayoutOptionsSample#{System.unique_integer([:positive])} do
          use Aurora.Uix.Layout.Options, layout_type: :sample, options: [:greeting, :farewell]

          defp get_default(_assigns, :greeting), do: {:ok, "hello"}
          defp get_default(_assigns, option), do: {:not_found, option}
        end
        """)

      assigns = %{auix: %{layout_type: :sample, layout_tree: %{options: [farewell: "bye"]}}}

      assert options_set.get(assigns, :greeting) == {:ok, "hello"}
      assert options_set.get(assigns, :farewell) == {:ok, "bye"}
      assert options_set.get(assigns, :unlisted) == {:not_found, :unlisted}
    end

    test "the 0.1.x form without an option list fails compilation" do
      assert_raise ArgumentError, ~r/no longer lists the options/, fn ->
        Code.compile_string("""
        defmodule Aurora.Uix.Test.LayoutOptionsOldSample do
          use Aurora.Uix.Layout.Options, :sample
        end
        """)
      end
    end
  end
end
