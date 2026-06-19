defmodule Aurora.Uix.Templates.Basic.CoreComponentsInputTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Phoenix.LiveViewTest

  alias Aurora.Uix.Templates.Basic.CoreComponents

  @spec render_input(map()) :: String.t()
  defp render_input(assigns) do
    render_component(&CoreComponents.input/1, assigns)
  end

  @spec with_warning_level(function()) :: any()
  defp with_warning_level(fun) do
    Logger.configure(level: :warning)
    result = fun.()
    Logger.configure(level: :error)
    result
  end

  describe "input/1 with copyable: true" do
    test "renders copy button with data-auix-copy-target when id is present" do
      html =
        render_input(%{
          type: "text",
          id: "my-field",
          name: "my-field",
          value: "",
          copyable: true,
          host_components: nil,
          errors: [],
          label: nil,
          fieldset_class: "",
          label_class: "",
          input_class: "",
          omit_label?: false
        })

      assert html =~ ~s(data-auix-copy-target="my-field")
      assert html =~ ~s(phx-hook="AuixCopyToClipboard")
    end

    test "emits no warning when id is present" do
      log =
        capture_log(fn ->
          render_input(%{
            type: "text",
            id: "my-field",
            name: "my-field",
            value: "",
            copyable: true,
            host_components: nil,
            errors: [],
            label: nil,
            fieldset_class: "",
            label_class: "",
            input_class: "",
            omit_label?: false
          })
        end)

      refute log =~ "copyable input was rendered without a valid"
    end

    test "emits warning when id is nil" do
      log =
        with_warning_level(fn ->
          capture_log(fn ->
            render_input(%{
              type: "text",
              id: nil,
              name: "my-field",
              value: "",
              copyable: true,
              host_components: nil,
              errors: [],
              label: nil,
              fieldset_class: "",
              label_class: "",
              input_class: "",
              omit_label?: false
            })
          end)
        end)

      assert log =~ "copyable input was rendered without a valid"
    end

    test "emits warning for textarea when id is nil" do
      log =
        with_warning_level(fn ->
          capture_log(fn ->
            render_input(%{
              type: "textarea",
              id: nil,
              name: "my-field",
              value: "",
              copyable: true,
              host_components: nil,
              errors: [],
              label: nil,
              fieldset_class: "",
              label_class: "",
              input_class: "",
              omit_label?: false
            })
          end)
        end)

      assert log =~ "copyable input was rendered without a valid"
    end
  end

  describe "input/1 without copyable" do
    test "does not emit warning for checkbox" do
      log =
        capture_log(fn ->
          render_input(%{
            type: "checkbox",
            id: nil,
            name: "my-check",
            value: false,
            checked: false,
            copyable: false,
            host_components: nil,
            errors: [],
            label: nil,
            fieldset_class: "",
            label_class: "",
            input_class: "",
            omit_label?: false
          })
        end)

      refute log =~ "copyable input was rendered without a valid"
    end
  end
end
