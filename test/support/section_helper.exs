defmodule AuroraUixTestWeb.SectionHelper do
  use AuroraUixTestWeb.ConnCase
  import Phoenix.LiveViewTest

  @spec auix_index(binary | atom) :: integer
  def auix_index(index) do
    index
    |> to_string()
    |> String.split("_")
    |> List.last()
    |> String.to_integer()
  end

  @spec auix_button_selector(atom, integer) :: binary
  def auix_button_selector(section_index, tab_index) do
    ~s|button[data-button-sections-index="#{auix_index(section_index)}"][data-button-tab-index="#{auix_index(tab_index)}"]|
  end

  @spec auix_section_selector(atom, integer) :: binary
  def auix_section_selector(section_index, tab_index) do
    ~s|div[data-tab-sections-index="#{auix_index(section_index)}"][data-tab-index="#{auix_index(tab_index)}"]|
  end

  @spec auix_phx_value(binary, atom) :: any
  def auix_phx_value(element_html, value_name) do
    parsed_value_name = value_name |> to_string() |> String.replace("_", "-")

    element_html
    |> then(&Regex.run(~r/phx-value-#{parsed_value_name}="([^"]+)"/, &1))
    |> List.last()
    |> String.replace("&quot;", "\"")
    |> Jason.decode!()
  end

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

  @spec parent_section_id(Phoenix.LiveViewTest.View, atom | integer | nil, atom | integer) ::
          binary
  def parent_section_id(view, section_index \\ :section_1, tab_index) do
    view
    |> render()
    |> Floki.parse_document!()
    |> Floki.attribute(auix_section_selector(section_index, tab_index), "data-tab-parent-id")
    |> to_string()
  end

  @spec section_tab_id(Phoenix.LiveViewTest.View, atom | integer | nil, atom | integer) :: binary
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

  @spec assert_section_is_active(Phoenix.LiveViewTest.View, atom | integer | nil, atom | integer) ::
          Macro.t()
  def assert_section_is_active(view, section_index \\ :section_1, tab_index) do
    {floki, tab_id} = section_tab_id(view, section_index, tab_index)

    assert(
      section_active?(floki, tab_id),
      "Tab at section: `#{section_index}`, index: `#{tab_index}` is not active, or one of its parent is not active"
    )
  end

  @spec refute_section_is_active(Phoenix.LiveViewTest.View, atom | integer | nil, atom | integer) ::
          Macro.t()
  def refute_section_is_active(view, section_index \\ :section_1, tab_index) do
    {floki, tab_id} = section_tab_id(view, section_index, tab_index)

    refute(
      section_active?(floki, tab_id),
      "Tab at section: `#{section_index}`, index: `#{tab_index}` is active along with its parents"
    )
  end

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

  @spec refute_field_is_visible_in_section(
          Phoenix.LiveViewTest.View,
          atom | binary | list,
          atom | integer | nil,
          atom | integer
        ) :: Macro.t()
  def refute_field_is_visible_in_section(view, field_name, section_index \\ :section_1, tab_index)

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
