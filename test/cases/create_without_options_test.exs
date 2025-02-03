defmodule AuroraUixTest.CreateWithoutOptions do
  use AuroraUixTest.UICase

  defmodule DefaultWithoutOptions do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    auix_schema_configs(:product)
    auix_create_ui()
  end

  test "Test UI default without options - no schema, no context" do
    layouts = layouts(DefaultWithoutOptions)
    assert layouts == %{}
  end
end
