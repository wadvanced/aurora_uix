defmodule Aurora.Uix.Gettext do
  @moduledoc """
  Injects Gettext functionality with configurable backend support.

  Sets up the module to use Gettext with a configurable backend. The backend is resolved by:
  1. Checking the `:backend` option in opts.
  2. Checking the `:gettext_backend` application configuration.
  3. Falling back to `Aurora.Uix.GettextBackend`.

  If a deprecated `:gettext` application configuration exists, it imports that module
  instead of using the standard Gettext setup.

  ## Options
  - `:backend` (module()) - Optional. The Gettext backend module to use. Defaults to
    `Aurora.Uix.GettextBackend`.

  ## Examples
  ```elixir
  defmodule MyApp.Gettext do
    use Aurora.Uix.Gettext
  end

  defmodule MyApp.Gettext do
    use Aurora.Uix.Gettext, backend: MyCustomBackend
  end

  # Usage in modules
  defmodule MyApp.Web do
    use Aurora.Uix.Gettext
  end

  # Then use standard Gettext functions
  MyApp.Gettext.gettext("Hello") # => "Hola" (depending on locale)
  ```

  ## Configuration
  Can be configured via application config:
  ```elixir
  config :aurora_uix, :gettext_backend, MyCustomBackend
  ```
  """

  @doc false
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts) do
    default_backend = opts[:backend] || Aurora.Uix.GettextBackend

    backend_module =
      Application.get_env(:aurora_uix, :gettext_backend, default_backend)

    # For deprecated implementation
    gettext_module = Application.get_env(:aurora_uix, :gettext)

    implementation =
      if is_nil(gettext_module) do
        quote do
          use Gettext, backend: unquote(backend_module)
        end
      else
        quote do
          import unquote(gettext_module)
        end
      end

    quote do
      unquote(implementation)

      @doc false
      def backend do
        unquote(backend_module)
      end
    end
  end
end
