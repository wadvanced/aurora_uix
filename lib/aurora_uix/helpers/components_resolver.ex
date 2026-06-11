defmodule Aurora.Uix.ComponentsResolver do
  @moduledoc """
  Macro module that enables runtime component overriding for Aurora UIX component modules.

  When a component module calls `use Aurora.Uix.ComponentsResolver, :some_key`, it:

  1. Imports `Aurora.Uix.ComponentsResolverHelper`, making the `resolve_component_for/1`
     macro available.
  2. Stores the given atom as `@components_override`, which is the Application env key
     used to look up a host override module at runtime.
  3. Injects a `components_override/0` function (via `@before_compile`) that returns the
     configured key.

  ## Usage

  ```elixir
  defmodule MyComponents do
    use Aurora.Uix.ComponentsResolver, :my_components

    def my_component(%{host_components: nil} = assigns) do
      # default implementation
    end

    resolve_component_for(:my_component)
  end
  ```

  Each component module uses a distinct key:

  | Module             | Key                          |
  |--------------------|------------------------------|
  | `CoreComponents`   | `:core_components`           |
  | `Components`       | `:basic_components`          |
  | `FilteringComponents` | `:basic_filtering_components` |
  | `RoutingComponents` | `:basic_routing_components` |

  See `Aurora.Uix.ComponentsResolverHelper` for how the public dispatch function is
  generated and how runtime lookup works.
  """

  defmacro __using__(components_override) do
    quote do
      import Aurora.Uix.ComponentsResolverHelper
      Module.put_attribute(__MODULE__, :components_override, unquote(components_override))
      @before_compile Aurora.Uix.ComponentsResolver
    end
  end

  defmacro __before_compile__(env) do
    module = env.module
    attribute = Module.get_attribute(module, :components_override)

    quote do
      def components_override do
        unquote(attribute)
      end
    end
  end
end
