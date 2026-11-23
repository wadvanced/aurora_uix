defmodule Aurora.UixWeb.Test.Mirror.Variants.IncludedLayouts do
  @moduledoc false

  @doc false
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(_opts) do
    quote do
      use Aurora.Uix

      auix_create_layout do
        edit_layout :product do
          inline([:reference, :name])
        end

        show_layout :product do
          inline([:reference, :description])
        end
      end
    end
  end
end
