defmodule Aurora.Uix.Templates.Basic.Handlers.Form do
  @moduledoc """
  Provides a LiveComponent handler for form rendering and event management in Aurora UIX templates.

  This module implements the `Phoenix.LiveComponent` behaviour to manage form state, validation,
  and persistence for entities within the Aurora UIX framework. It handles form updates, validation,
  saving, section switching, and navigation events, integrating with context modules and routing stacks.

  ## Key Features

    - Renders and updates forms using context module functions.
    - Handles validation and save events, updating the UI and persisting changes.
    - Manages navigation and section switching within forms.
    - Integrates with routing stack for complex navigation flows.
    - Provides error handling for unhandled events.

  ## Key Constraints

    - Expects assigns to include an `:auix` map with required keys (`:entity`, `:modules`, etc.).
    - Relies on context modules to provide change, create, update, and get functions.
    - Designed for use within Aurora UIX LiveView templates.
  """

  use Aurora.Uix.Templates.Basic.Handlers.FormImpl
end
