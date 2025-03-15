Code.require_file("test/support/conn_case.exs")

defmodule AuroraUixTest.UICase do
  @moduledoc """
  Support for testing schema metadata behaviour.
  """

  alias AuroraUix.Field
  alias AuroraUixTest.UICase

  @spec validate_schema(map, atom, map) :: boolean
  def validate_schema(resource_configs, schema, fields_checks) do
    metadata = get_in(resource_configs, [schema, Access.key!(:fields)])

    Enum.each(fields_checks, fn {field_id, checks} ->
      field = locate_field(metadata, field_id)
      validate_field(field, checks, field_id)
    end)
  end

  @spec validate_field(Field.t(), map, atom) :: :ok
  def validate_field(nil, _checks, field_id), do: raise("Field `#{field_id}` was not found")

  def validate_field(field, checks, field_id) do
    Enum.each(checks, fn {key, value} ->
      current_value = Map.get(field, key)

      if current_value != value do
        raise(
          "Field `#{field_id}`, key: `#{key}`. Expected: `#{value}`, current: `#{current_value}`"
        )
      end
    end)
  end

  @spec locate_field(map, atom) :: map | nil
  def locate_field(schema_config, field) do
    Enum.find(schema_config, fn
      %{field: ^field} -> true
      _ -> false
    end)
  end

  @spec resource_configs(module) :: map
  def resource_configs(module) do
    attributes(module, :_auix_resource_configs)
  end

  @spec attributes(module, atom) :: map
  def attributes(module, attribute) do
    Code.ensure_compiled(module)

    :attributes
    |> module.__info__()
    |> Keyword.get(attribute, [])
    |> List.first()
  end

  @spec phx_value(binary, atom) :: any
  def phx_value(element_html, value_name) do
    parsed_value_name = value_name |> to_string() |> String.replace("_", "-")

    element_html
    |> then(&Regex.run(~r/phx-value-#{parsed_value_name}="([^"]+)"/, &1))
    |> List.last()
    |> String.replace("&quot;", "\"")
    |> Jason.decode!()
  end

  @spec phx_button_selector(atom) :: binary
  def phx_button_selector(level_name) do
    level_name
    |> to_string()
    |> String.replace("level_", "")
    |> String.to_integer()
    |> Kernel.-(1)
    |> then(&String.duplicate(~s(button[phx-click="switch_section"] + div ), &1))
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro __using__(_) do
    apply(__MODULE__, :test_case, [])
  end

  @doc false
  @spec test_case() :: Macro.t()
  def test_case do
    quote do
      use AuroraUixTestWeb.ConnCase
      import AuroraUixTest.UICase
    end
  end

  @doc false
  @spec phoenix_case() :: Macro.t()
  def phoenix_case do
    quote do
      use AuroraUixTestWeb.ConnCase
      import Phoenix.LiveViewTest
      import UICase, only: [phx_value: 2, phx_button_selector: 1]

      @spec click_section_button(Phoenix.LiveViewTest.View, binary, integer, atom | nil) :: binary
      def click_section_button(view, section_id, level_name \\ :level_1, position) do
        phx_button_selector = phx_button_selector(level_name)

        view
        |> element(
          ~s|#{phx_button_selector} button[phx-click="switch_section"]:nth-of-type(#{position})|
        )
        |> render_click()
      end

      @spec assert_section_button(Phoenix.LiveViewTest.View, binary, atom | nil) :: any
      def assert_section_button(view, section_id, level_name \\ :level_1, position) do
        phx_button_selector = phx_button_selector(level_name)

        element_html =
          view
          |> element(
            ~s|#{phx_button_selector} button[phx-click="switch_section"]:nth-of-type(#{position})|
          )
          |> render()

        phx_value = phx_value(element_html, :tab_id)

        assert(
          phx_value["tab_id"] =~ "auix-section-#{section_id}",
          "Tab button: `#{section_id}` not found at #{position}\n#{element_html}"
        )
      end

      @spec refute_section_button(Phoenix.LiveViewTest.View, binary, integer, atom | nil) :: any
      def refute_section_button(view, section_id, level_name \\ :level_1, position) do
        phx_button_selector = phx_button_selector(level_name)

        refute view
               |> element(
                 ~s|#{phx_button_selector} button[phx-click="switch_section"]:nth-of-type(#{position})|
               )
               |> has_element?()
      end

      @spec assert_field(Phoenix.LiveViewTest.View, binary) :: any
      def assert_field(view, field_name) do
        field = field_name |> to_string() |> Macro.underscore()

        assert view
               |> element("#auix-field-#{field}-form")
               |> has_element?()
      end

      @spec refute_field(Phoenix.LiveViewTest.View, binary) :: any
      def refute_field(view, field_name) do
        field = field_name |> to_string() |> Macro.underscore()

        refute view
               |> element("#auix-field-#{field}-form")
               |> has_element?()
      end
    end
  end
end
