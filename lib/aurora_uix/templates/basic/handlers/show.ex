defmodule Aurora.Uix.Templates.Basic.Handlers.Show do
  @moduledoc """
  Handles LiveView events and rendering for the "show" page of an entity in the Aurora UIX basic template.

  Provides LiveView callbacks and event handlers for:
    - Rendering entity details.
    - Switching between sections/tabs.
    - Deleting entities with feedback and navigation.
    - Forward and backward navigation within the UI.

  ## Key Features

    - Loads and displays a single entity using context and function references from assigns.
    - Handles tab/section switching via `"switch_section"` events.
    - Supports entity deletion with feedback and navigation.
    - Manages forward and backward routing events for navigation.

  ## Key Constraints

    - Expects `:auix` assign to be present in the socket, containing context, function, and preload info.
    - Assumes the presence of supporting modules: `ModulesGenerator`, `Renderer`, and helpers.
  """
  use Aurora.Uix.Templates.Basic.Handlers.ShowImpl
end
