defmodule Aurora.Uix.Templates.Basic.GettextCoverageTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Templates.Basic.Generators.FormGenerator

  @target_files [
    "lib/aurora_uix/templates/basic/components/embeds_many_component.ex",
    "lib/aurora_uix/templates/basic/components/core_components.ex",
    "lib/aurora_uix/templates/basic/components/components.ex",
    "lib/aurora_uix/templates/basic/components/confirm_button.ex",
    "lib/aurora_uix/templates/basic/actions/index.ex",
    "lib/aurora_uix/templates/basic/actions/embeds_many.ex",
    "lib/aurora_uix/templates/basic/handlers/index_impl.ex"
  ]

  @spec sample_parsed_opts() :: map()
  defp sample_parsed_opts do
    %{
      layout_tree: %{
        tag: :form,
        inner_elements: [
          %{tag: :field, name: :reference, inner_elements: []},
          %{tag: :field, name: :name, inner_elements: []}
        ]
      },
      fields: [
        %{label: "Reference", omitted: false},
        %{label: "Name", omitted: false},
        %{label: "Name", omitted: false},
        %{label: nil, omitted: false}
      ],
      preload: [],
      configurations: %{},
      resource_name: :product,
      modules: %{caller: Aurora.UixWeb.Test, web: Aurora.UixWeb.Test},
      module_name: "GeneratedProduct"
    }
  end

  describe "template gettext coverage" do
    test "targeted files route direct gettext strings through dt" do
      Enum.each(
        @target_files -- ["lib/aurora_uix/templates/basic/components/core_components.ex"],
        fn path ->
          content = File.read!(path)

          refute content =~ "gettext(\""
          assert content =~ "dt("
        end
      )

      core_components = File.read!("lib/aurora_uix/templates/basic/components/core_components.ex")
      refute core_components =~ "gettext(\"close\")"
      refute core_components =~ "gettext(\"Success!\")"
      assert core_components =~ "dt(\"close\")"
      assert core_components =~ "Gettext.dngettext(backend(), \"errors\""
      assert core_components =~ "Gettext.dgettext(backend(), \"errors\""
    end
  end

  describe "form generator gettext extraction" do
    test "generated modules always use Aurora.Uix.Gettext" do
      generated =
        sample_parsed_opts()
        |> FormGenerator.generate_module()
        |> Macro.to_string()

      assert generated =~ "use Aurora.Uix.Gettext"
      refute generated =~ "_aurora_uix_extract"
    end

    test "configured gettext domain emits unique extraction calls" do
      source_path = File.cwd!() <> "/lib/aurora_uix/templates/basic/generators/form_generator.ex"
      source = File.read!(source_path)

      old_domain = Application.get_env(:aurora_uix, :gettext_domain)
      temp_module = Aurora.Uix.Test.FormGeneratorWithDomain

      try do
        Application.put_env(:aurora_uix, :gettext_domain, "forms")
        :code.purge(temp_module)
        :code.delete(temp_module)

        [{compiled_module, _bytecode}] =
          source
          |> String.replace(
            "defmodule Aurora.Uix.Templates.Basic.Generators.FormGenerator do",
            "defmodule Aurora.Uix.Test.FormGeneratorWithDomain do"
          )
          |> Code.compile_string(source_path)

        generated =
          sample_parsed_opts()
          |> compiled_module.generate_module()
          |> Macro.to_string()

        assert generated =~ "use Aurora.Uix.Gettext"
        assert generated =~ "defp _aurora_uix_extract do"
        assert generated =~ "dgettext(\"forms\", \"Reference\")"
        assert length(Regex.scan(~r/dgettext\("forms", "Name"\)/, generated)) == 1
        refute generated =~ "dgettext(\"forms\", nil)"
      after
        if old_domain do
          Application.put_env(:aurora_uix, :gettext_domain, old_domain)
        else
          Application.delete_env(:aurora_uix, :gettext_domain)
        end

        :code.purge(temp_module)
        :code.delete(temp_module)
      end
    end
  end
end
