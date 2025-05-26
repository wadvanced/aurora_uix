defmodule Aurora.Uix.Web.Test.SectionHelper do
  @moduledoc """
  Helper module for testing sections in Aurora UIX components.
  Provides utilities for interacting with and asserting section states, buttons, and fields.
  """

  use Aurora.Uix.Web.Test.ConnCase
  import Phoenix.LiveViewTest

  @doc """
  Converts a section or tab index to integer.

  - index: string() | atom() - The index to convert

  Returns: integer()
  """
  @spec auix_index(binary | atom) :: integer
  def auix_index(index) do
    index
    |> to_string()
    |> String.split("_")
    |> List.last()
    |> String.to_integer()
  end

  @doc """
  Generates a CSS selector for a section button.

  - section_index: integer() - The section index
  - tab_index: integer() - The tab index

  Returns: string() - CSS selector
  """
  @spec auix_button_selector(atom, integer) :: binary
  def auix_button_selector(section_index, tab_index) do
    ~s|button[data-button-sections-index="#{auix_index(section_index)}"][data-button-tab-index="#{auix_index(tab_index)}"]|
  end

  @doc """
  Generates a CSS selector for a section.

  - section_index: integer() - The section index
  - tab_index: integer() - The tab index

  Returns: string() - CSS selector
  """
  @spec auix_section_selector(atom, integer) :: binary
  def auix_section_selector(section_index, tab_index) do
    ~s|div[data-tab-sections-index="#{auix_index(section_index)}"][data-tab-index="#{auix_index(tab_index)}"]|
  end

  @doc """
  Extracts a phx-value from an element's HTML.

  - element_html: string() - The HTML content
  - value_name: atom() - The value name to extract

  Returns: decoded JSON value
  """
  @spec auix_phx_value(binary, atom) :: any
  def auix_phx_value(element_html, value_name) do
    parsed_value_name = value_name |> to_string() |> String.replace("_", "-")

    element_html
    |> then(&Regex.run(~r/phx-value-#{parsed_value_name}="([^"]+)"/, &1))
    |> List.last()
    |> String.replace("&quot;", "\"")
    |> Jason.decode!()
  end

  @doc """
  Clicks a section button and verifies it is active.

  - view: LiveView - The LiveView instance
  - section_title: string() - The section title
  - section_index: atom() | integer() - The section index, defaults to :section_1
  - tab_index: atom() | integer() - The tab index

  Returns: string() - The rendered HTML
  """
  @spec click_section_button(
          Phoenix.LiveViewTest.View,
          binary,
          atom | integer | nil,
          atom | integer
        ) :: binary
  def click_section_button(view, section_title, section_index \\ :section_1, tab_index) do
    assert_section_button_is_active(view, section_title, section_index, tab_index)

    button_selector = auix_button_selector(section_index, tab_index)

    view
    |> element(button_selector)
    |> render_click()
  end

  @doc """
  Gets the parent section ID for a given section.

  - view: LiveView - The LiveView instance
  - section_index: atom() | integer() - The section index, defaults to :section_1
  - tab_index: atom() | integer() - The tab index

  Returns: string() - Parent section ID
  """
  @spec parent_section_id(Phoenix.LiveViewTest.View, atom | integer | nil, atom | integer) ::
          binary
  def parent_section_id(view, section_index \\ :section_1, tab_index) do
    view
    |> render()
    |> Floki.parse_document!()
    |> Floki.attribute(auix_section_selector(section_index, tab_index), "data-tab-parent-id")
    |> to_string()
  end

  @doc """
  Gets the section tab ID and parsed HTML for a given section.

  - view: LiveView - The LiveView instance
  - section_index: atom() | integer() - The section index, defaults to :section_1
  - tab_index: atom() | integer() - The tab index

  Returns: {Floki.html_tree(), string()} - Tuple with parsed HTML and tab ID
  """
  @spec section_tab_id(Phoenix.LiveViewTest.View, atom | integer | nil, atom | integer) ::
          {Floki.html_tree(), binary}
  def section_tab_id(view, section_index \\ :section_1, tab_index) do
    section_index = auix_index(section_index)

    floki =
      view
      |> render()
      |> Floki.parse_document!()

    tab_id =
      floki
      |> Floki.attribute(auix_section_selector(section_index, tab_index), "id")
      |> to_string()

    {floki, tab_id}
  end

  @doc """
  Checks if a section is active based on its HTML attributes.

  - floki: Floki.html_tree() - Parsed HTML tree
  - section_id: string() - The section ID to check

  Returns: boolean() - Whether the section is active
  """
  @spec section_active?(Floki.html_tree(), binary) :: boolean
  def section_active?(_floki, ""), do: true

  def section_active?(floki, section_id) do
    section = Floki.find(floki, "##{section_id}")

    with true <- section |> Floki.attribute("data-tab-active") |> List.first("") =~ "active",
         false <- section |> Floki.attribute("class") |> List.first("") =~ "hidden",
         true <-
           section
           |> Floki.attribute("data-tab-parent-id")
           |> List.first()
           |> to_string()
           |> then(&section_active?(floki, &1)) do
      true
    else
      _ -> false
    end
  end

  @doc """
  Asserts that a section is active. Fails the test if the section is not active.

  - view: LiveView - The LiveView instance
  - section_index: atom() | integer() - The section index, defaults to :section_1
  - tab_index: atom() | integer() - The tab index

  Returns: Macro.t()
  """
  @spec assert_section_is_active(Phoenix.LiveViewTest.View, atom | integer | nil, atom | integer) ::
          Macro.t()
  def assert_section_is_active(view, section_index \\ :section_1, tab_index) do
    {floki, tab_id} = section_tab_id(view, section_index, tab_index)

    assert(
      section_active?(floki, tab_id),
      "Tab at section: `#{section_index}`, index: `#{tab_index}` is not active, or one of its parent is not active"
    )
  end

  @doc """
  Refutes that a section is active. Fails the test if the section is active.

  - view: LiveView - The LiveView instance
  - section_index: atom() | integer() - The section index, defaults to :section_1
  - tab_index: atom() | integer() - The tab index

  Returns: Macro.t()
  """
  @spec refute_section_is_active(Phoenix.LiveViewTest.View, atom | integer | nil, atom | integer) ::
          Macro.t()
  def refute_section_is_active(view, section_index \\ :section_1, tab_index) do
    {floki, tab_id} = section_tab_id(view, section_index, tab_index)

    refute(
      section_active?(floki, tab_id),
      "Tab at section: `#{section_index}`, index: `#{tab_index}` is active along with its parents"
    )
  end

  @doc """
  Asserts that any parent section of the given section is active.
  Fails the test if none of the parent sections are active.

  - view: LiveView - The LiveView instance
  - section_index: atom() | integer() - The section index, defaults to :section_1
  - tab_index: atom() | integer() - The tab index

  Returns: :ok | no_return() - Assertion result
  """
  @spec assert_parent_section_is_active(
          Phoenix.LiveViewTest.View,
          atom | integer | nil,
          atom | integer
        ) :: Macro.t()
  def assert_parent_section_is_active(view, section_index \\ :section_1, tab_index) do
    floki = view |> render() |> Floki.parse_document!()

    tab_id = parent_section_id(view, section_index, tab_index)

    assert(
      section_active?(floki, tab_id),
      "Any of the parents of section: `#{section_index}`, index: `#{tab_index}` is inactive"
    )
  end

  @doc """
  Refutes that any parent section of the given section is active.
  Fails the test if any of the parent sections are active.

  - view: LiveView - The LiveView instance
  - section_index: atom() | integer() - The section index, defaults to :section_1
  - tab_index: atom() | integer() - The tab index

  Returns: :ok | no_return() - Assertion result
  """
  @spec refute_parent_section_is_active(
          Phoenix.LiveViewTest.View,
          atom | integer | nil,
          atom | integer
        ) :: Macro.t()
  def refute_parent_section_is_active(view, section_index \\ :section_1, tab_index) do
    floki = view |> render() |> Floki.parse_document!()

    tab_id = parent_section_id(view, section_index, tab_index)

    refute(
      section_active?(floki, tab_id),
      "Any of the parents of section: `#{section_index}`, index: `#{tab_index}` is active"
    )
  end

  @doc """
  Asserts that one or more section buttons are active.

  - view: LiveView - The LiveView instance
  - section_title: string() | [string()] - The section title(s)
  - section_index: atom() | integer() - The section index, defaults to :section_1
  - tab_index: atom() | integer() - The tab index

  Returns: Macro.t()
  """
  @spec assert_section_button_is_active(
          Phoenix.LiveViewTest.View,
          atom | binary | list,
          atom | integer | nil,
          atom | integer
        ) :: Macro.t()
  def assert_section_button_is_active(view, section_title, section_index \\ :section_1, tab_index)

  def assert_section_button_is_active(view, section_titles, section_index, tab_index)
      when is_list(section_titles) do
    Enum.each(
      section_titles,
      &assert_section_button_is_active(view, &1, section_index, tab_index)
    )
  end

  def assert_section_button_is_active(view, section_title, section_index, tab_index) do
    button_selector = auix_button_selector(section_index, tab_index)

    element_html =
      view
      |> element(button_selector)
      |> render()

    auix_phx_value = auix_phx_value(element_html, :tab_id)

    assert(
      auix_phx_value["tab_id"] =~ "auix-section-#{section_title}",
      "Tab button: `#{section_title}` not found at #{tab_index}\n#{element_html}"
    )

    assert_parent_section_is_active(view, section_index, tab_index)
  end

  @doc """
  Refutes that one or more section buttons are active.

  - view: LiveView - The LiveView instance
  - section_title: string() | [string()] - The section title(s)
  - section_index: atom() | integer() - The section index, defaults to :section_1
  - tab_index: atom() | integer() - The tab index

  Returns: Macro.t()
  """
  @spec refute_section_button_is_active(
          Phoenix.LiveViewTest.View,
          atom | binary | list,
          atom | integer | nil,
          atom | integer
        ) :: Macro.t()
  def refute_section_button_is_active(view, section_title, section_index \\ :section_1, tab_index)

  def refute_section_button_is_active(view, section_titles, section_index, tab_index)
      when is_list(section_titles) do
    Enum.each(
      section_titles,
      &refute_section_button_is_active(view, &1, section_index, tab_index)
    )
  end

  def refute_section_button_is_active(view, section_title, section_index, tab_index) do
    button_selector = auix_button_selector(section_index, tab_index)

    active? =
      view
      |> element(button_selector)
      |> render()
      |> Floki.parse_fragment!()
      |> Floki.attribute("class")
      |> List.first() =~
        "active"

    floki = view |> render() |> Floki.parse_document!()

    tab_id = parent_section_id(view, section_index, tab_index)

    parent_section_active? = section_active?(floki, tab_id)

    refute(
      active? and parent_section_active?,
      "Tab button: `#{section_title}` was found ACTIVE at #{tab_index}\n"
    )
  end

  @doc """
  Asserts that one or more fields are visible in a section.

  - view: LiveView - The LiveView instance
  - field_names: string() | [string()] - The field name(s)
  - section_index: atom() | integer() - The section index, defaults to :section_1
  - tab_index: atom() | integer() - The tab index

  Returns: Macro.t()
  """
  @spec assert_field_is_visible_in_section(
          Phoenix.LiveViewTest.View,
          atom | binary | list,
          atom | integer | nil,
          atom | integer
        ) :: Macro.t()
  def assert_field_is_visible_in_section(
        view,
        field_names,
        section_index \\ :section_1,
        tab_index
      )

  def assert_field_is_visible_in_section(view, field_names, section_index, tab_index)
      when is_list(field_names) do
    Enum.each(
      field_names,
      &assert_field_is_visible_in_section(view, &1, section_index, tab_index)
    )
  end

  def assert_field_is_visible_in_section(view, field_name, section_index, tab_index) do
    field = field_name |> to_string() |> Macro.underscore()

    field_selector =
      ~s|#{auix_section_selector(section_index, tab_index)} [id^="auix-field-#{field}-"]|

    assert view
           |> element(field_selector)
           |> has_element?()

    assert_section_is_active(view, section_index, tab_index)
  end

  @doc """
  Refutes that one or more fields are visible in a section.

  - view: LiveView - The LiveView instance
  - field_names: string() | [string()] - The field name(s)
  - section_index: atom() | integer() - The section index, defaults to :section_1
  - tab_index: atom() | integer() - The tab index

  Returns: Macro.t()
  """
  @spec refute_field_is_visible_in_section(
          Phoenix.LiveViewTest.View,
          atom | binary | list,
          atom | integer | nil,
          atom | integer
        ) :: Macro.t()
  def refute_field_is_visible_in_section(
        view,
        field_names,
        section_index \\ :section_1,
        tab_index
      )

  def refute_field_is_visible_in_section(view, field_names, section_index, tab_index)
      when is_list(field_names) do
    Enum.each(
      field_names,
      &refute_field_is_visible_in_section(view, &1, section_index, tab_index)
    )
  end

  def refute_field_is_visible_in_section(view, field_name, section_index, tab_index) do
    field = field_name |> to_string() |> Macro.underscore()

    field_selector =
      ~s|#{auix_section_selector(section_index, tab_index)} [id^="auix-field-#{field}-"]|

    assert view
           |> element(field_selector)
           |> has_element?()

    refute_section_is_active(view, section_index, tab_index)
  end
end
