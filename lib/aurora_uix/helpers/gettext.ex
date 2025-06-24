defmodule Aurora.Uix.Web.Gettext do
  @moduledoc """
  Provides dynamic Gettext functionality for Aurora UIX, allowing the backend to be determined by
  an environment variable or application configuration.

  ## Purpose
  Enables internationalization (I18n) in Aurora UIX-based applications by injecting Gettext support
  with a configurable backend. This allows for flexible language translation strategies and easy
  integration with custom or default Gettext backends.

  ## Key Constraints
  - The backend can be set via the `:backend` option or the `:gettext_backend` application config.
  - If no backend is specified, defaults to `Aurora.Uix.Web.GettextBackend`.
  """

  @doc """
  Injects Gettext functionality with configurable backend support.

  ## Parameters
  - `opts` (keyword()) - Options for configuring the backend. Options:
    * `:backend` (module()) - Optional. The Gettext backend module to use. Defaults to
      `Aurora.Uix.Web.GettextBackend`.

  ## Returns
  - `Macro.t()` - A quoted expression that injects Gettext or imports the configured backend.

  ## Examples
  ```elixir
  defmodule MyApp.Gettext do
    use Aurora.Uix.Web.Gettext
  end

  defmodule MyApp.Gettext do
    use Aurora.Uix.Web.Gettext, backend: MyCustomBackend
  end

  # Usage in runtime
  MyApp.Gettext.gettext("Hello") # => "Hola" (depending on locale)

  # The backend can also be configured via application config:
  #
  #   config :aurora_uix, :gettext_backend, MyCustomBackend
  ```
  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts) do
    default_backend = opts[:backend] || Aurora.Uix.Web.GettextBackend

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

      @doc """
      Provides the configured backend
      """
      def backend do
        unquote(backend_module)
      end
    end
  end
end
