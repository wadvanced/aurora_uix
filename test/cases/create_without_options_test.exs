defmodule Aurora.Uix.Test.Cases.CreateWithoutOptions do
  use Aurora.Uix.Test.Web.UICase

  defmodule DefaultWithoutOptions do
    # Makes the modules attributes persistent.
    use Aurora.Uix.Test.Web, :aurora_uix_for_test

    auix_resource_metadata(:product)
    auix_create_ui()
  end

  test "Test UI default without options - no schema, no context" do
    index_module = Module.concat(TestModule, Index)
    assert false == Code.ensure_loaded?(index_module)
  end
end
