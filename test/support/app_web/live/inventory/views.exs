Code.require_file("test/support/aurora_uix_test_web.exs")
Code.require_file("test/support/app_web/router.exs")

defmodule AuroraUixTestWeb.Inventory.Views do
  # Makes the modules attributes persistent.
  use AuroraUixTestWeb, :aurora_uix_for_test

  alias AuroraUixTest.Inventory
  alias AuroraUixTest.Inventory.Product

  auix_schema_config(:product, context: Inventory, schema: Product)

  auix_create_ui()
end
