defmodule AuroraUixWeb.Templates.Basic do
  @moduledoc """
  Entry point for basic template functionality, coordinating layout parsing, logic generation, and markup creation.

  Implements the `AuroraUixWeb.Template` behavior by delegating to specialized components:
  - `LayoutParser`: Handles layout structures parsing
  - `LogicModulesGenerator`: Generates business logic modules
  - `MarkupGenerator`: Creates HEEx template fragments

  See delegated modules for detailed function documentation.
  """
  @behaviour AuroraUixWeb.Template

  alias AuroraUixWeb.Templates.Basic.LayoutParser
  alias AuroraUixWeb.Templates.Basic.LogicModulesGenerator
  alias AuroraUixWeb.Templates.Basic.MarkupGenerator

  defdelegate parse_layout(path, mode), to: LayoutParser
  defdelegate generate_module(modules, type, parsed_opts), to: LogicModulesGenerator
  defdelegate generate_view(type, parsed_opts), to: MarkupGenerator
end
