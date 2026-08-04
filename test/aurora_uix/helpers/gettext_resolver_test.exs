defmodule Aurora.Uix.Helpers.GettextResolverTest do
  use ExUnit.Case, async: true
  use Aurora.Uix.GettextResolver

  @spec test_translation() :: binary()
  def test_translation, do: dt("Save")

  @spec gettext_domain() :: binary() | nil
  def gettext_domain, do: @gettext_domain

  @spec passthrough(term()) :: term()
  def passthrough(value), do: dt(value)

  describe "Aurora.Uix.GettextResolver" do
    test "dt/1 is available after use Aurora.Uix.GettextResolver" do
      assert test_translation() == "Save"
    end

    test "@gettext_domain module attribute is set" do
      assert gettext_domain() == "default"
    end

    test "dt/1 leaves non-binary dynamic values unchanged" do
      callback = & &1
      assert passthrough(callback) == callback
    end
  end
end
