defmodule Aurora.Uix.Templates.Basic.Handlers.Index do
  @moduledoc """
  LiveView handler for index pages in Aurora UIX.

  Manages the lifecycle and event handling for index views, including streaming, navigation,
  deletion, and entity assignment. Integrates with Aurora UIX helpers and rendering pipeline.

  ## Key Features

    - Streams entities for efficient index rendering.
    - Handles navigation, patching, and routing stack for index and form components.
    - Supports deletion of entities with context-aware logic.
    - Integrates with Aurora UIX helpers and rendering pipeline.

  ## Key Constraints

    - Expects `:auix` key in assigns with required subkeys for context, functions, and configuration.
    - Designed for use within Phoenix LiveView index templates.
  """

  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl
end
