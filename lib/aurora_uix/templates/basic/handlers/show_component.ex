defmodule Aurora.Uix.Templates.Basic.Handlers.ShowComponent do
  @moduledoc """
  Provides a LiveComponent handler for rendering entity details and event management in Aurora
  UIX templates.

  This module implements the `Phoenix.LiveComponent` behaviour to manage show view state,
  section switching, and navigation events for entities within the Aurora UIX framework. It
  handles component updates, section switching, and navigation events, integrating with
  context modules and routing stacks.

  ## Key Features

    - Renders and updates show views using context module functions.
    - Manages section switching and interactive elements on show pages.
    - Handles navigation and modal interactions within show views.
    - Integrates with routing stack for complex navigation flows.
    - Provides error handling for unhandled events.

  ## Key Constraints

    - Expects assigns to include an `:auix` map with required keys (`:entity`, `:modules`, etc.).
    - Relies on context modules to provide get functions.
    - Designed for use within Aurora UIX LiveView templates.
  """

  use Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl
end
