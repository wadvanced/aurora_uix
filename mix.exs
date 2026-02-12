defmodule Aurora.Uix.MixProject do
  use Mix.Project

  @source_url "https://github.com/wadvanced/aurora_uix"
  @version "0.1.3"

  def project do
    [
      app: :aurora_uix,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      xref: xref(Mix.env()),
      dialyzer: [
        plt_add_apps: [:eex, :mix],
        ignore_warnings: ".dialyzer.ignore-warnings"
      ],
      aliases: aliases(),
      listeners: [Phoenix.CodeReloader],
      # Hex
      description: "Low code UI for the elixir's Phoenix Framework",
      package: [
        name: "aurora_uix",
        maintainers: ["Federico Alcántara"],
        licenses: ["MIT"],
        links: %{"GitHub" => @source_url},
        files: ~w(.formatter.exs mix.exs README.md CHANGELOG.md assets/js lib),
        exclude_patterns: [~r"/-local-.*", ~r"/aurora_uix_web*", ~r"/aurora_uix/guides/*"]
      ],

      # Docs
      name: "Aurora UIX",
      docs: [
        main: "overview",
        logo: "./guides/images/aurora_uix-icon.png",
        assets: %{"./guides/overview/images/" => "images", "./guides/core/images/" => "images"},
        extras: [
          "CHANGELOG.md",
          "CONTRIBUTING.md",
          "guides/overview/overview.md",
          "guides/introduction/getting_started.md",
          "guides/core/resource_metadata.md",
          "guides/core/ash_integration.md",
          "guides/core/layouts.md",
          "guides/core/liveview.md",
          "guides/advanced/advanced_usage.md",
          "guides/advanced/troubleshooting.md"
        ],
        groups_for_extras: [
          Introduction: ~r{guides/introduction/.*},
          Core: ~r{guides/core/.*},
          Advanced: ~r{guides/advanced/.*},
          Developers: ~r{CONTRIBUTING*}
        ],
        groups_for_modules: [
          "Core Data Structures": [
            Aurora.Uix.Action,
            Aurora.Uix.Counter,
            Aurora.Uix.Field,
            Aurora.Uix.Filter,
            Aurora.Uix.Resource,
            Aurora.Uix.Selection,
            Aurora.Uix.Stack,
            Aurora.Uix.Stack.EmptyStackError,
            Aurora.Uix.TreePath
          ],
          Layouts: [
            Aurora.Uix.Layout.Blueprint,
            Aurora.Uix.Layout.CreateLayout,
            Aurora.Uix.Layout.CreateUI,
            Aurora.Uix.Layout.Helpers,
            Aurora.Uix.Layout.Options,
            Aurora.Uix.Layout.Options.Form,
            Aurora.Uix.Layout.Options.Index,
            Aurora.Uix.Layout.Options.Show,
            Aurora.Uix.Layout.ResourceMetadata
          ],
          "Parsers & Integration": [
            Aurora.Uix.Parser,
            Aurora.Uix.Parsers.Common,
            Aurora.Uix.Integration.Connector,
            Aurora.Uix.Integration.ContextParserDefaults,
            Aurora.Uix.Integration.Crud,
            Aurora.Uix.Integration.FieldsParser
          ],
          "Context Integration": [
            Aurora.Uix.Integration.Ctx.ContextParserDefaults,
            Aurora.Uix.Integration.Ctx.Crud,
            Aurora.Uix.Integration.Ctx.CrudSpec,
            Aurora.Uix.Integration.Ctx.FieldsParser
          ],
          "Ash Integration": [
            Aurora.Uix.Integration.Ash.ContextParserDefaults,
            Aurora.Uix.Integration.Ash.Crud,
            Aurora.Uix.Integration.Ash.CrudSpec,
            Aurora.Uix.Integration.Ash.FieldsParser,
            Aurora.Uix.Integration.Ash.QueryParser
          ],
          "Default Integration": [
            Aurora.Uix.Integration.Default.FieldsParser
          ],
          "Template System": [
            Aurora.Uix.Template,
            Aurora.Uix.Templates.Basic,
            Aurora.Uix.Templates.CssSanitizer,
            Aurora.Uix.Templates.Theme,
            Aurora.Uix.Templates.ThemeHelper
          ],
          "Basic Template - Actions": [
            Aurora.Uix.Templates.Basic.Actions,
            Aurora.Uix.Templates.Basic.Actions.EmbedsMany,
            Aurora.Uix.Templates.Basic.Actions.Form,
            Aurora.Uix.Templates.Basic.Actions.Index,
            Aurora.Uix.Templates.Basic.Actions.OneToMany,
            Aurora.Uix.Templates.Basic.Actions.ShowComponent
          ],
          "Basic Template - Components": [
            Aurora.Uix.Templates.Basic.Components,
            Aurora.Uix.Templates.Basic.Components.FilteringComponents,
            Aurora.Uix.Templates.Basic.ConfirmButton,
            Aurora.Uix.Templates.Basic.CoreComponents,
            Aurora.Uix.Templates.Basic.EmbedsManyComponent,
            Aurora.Uix.Templates.Basic.RoutingComponents
          ],
          "Basic Template - Generators": [
            Aurora.Uix.Templates.Basic.Generators.FormGenerator,
            Aurora.Uix.Templates.Basic.Generators.IndexGenerator,
            Aurora.Uix.Templates.Basic.Generators.ShowComponentGenerator,
            Aurora.Uix.Templates.Basic.ModulesGenerator
          ],
          "Basic Template - Handlers": [
            Aurora.Uix.Templates.Basic.Handlers.Form,
            Aurora.Uix.Templates.Basic.Handlers.FormImpl,
            Aurora.Uix.Templates.Basic.Handlers.Index,
            Aurora.Uix.Templates.Basic.Handlers.IndexImpl,
            Aurora.Uix.Templates.Basic.Handlers.ShowComponent,
            Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl
          ],
          "Basic Template - Renderers": [
            Aurora.Uix.Templates.Basic.Helpers,
            Aurora.Uix.Templates.Basic.Renderer,
            Aurora.Uix.Templates.Basic.Renderers.EmbedsManyRenderer,
            Aurora.Uix.Templates.Basic.Renderers.EmbedsOneRenderer,
            Aurora.Uix.Templates.Basic.Renderers.FieldRenderer,
            Aurora.Uix.Templates.Basic.Renderers.FormRenderer,
            Aurora.Uix.Templates.Basic.Renderers.IndexRenderer,
            Aurora.Uix.Templates.Basic.Renderers.ManyToOne,
            Aurora.Uix.Templates.Basic.Renderers.OneToMany,
            Aurora.Uix.Templates.Basic.Renderers.SectionsRenderer,
            Aurora.Uix.Templates.Basic.Renderers.ShowComponentRenderer
          ],
          "Basic Template - Themes": [
            Aurora.Uix.Templates.Basic.Themes.Base,
            Aurora.Uix.Templates.Basic.Themes.BaseVariables,
            Aurora.Uix.Templates.Basic.Themes.VitreousMarble,
            Aurora.Uix.Templates.Basic.Themes.WhiteCharcoal
          ],
          "General Helpers": [
            Aurora.Uix.BehaviourHelper,
            Aurora.Uix.CoreComponentsImporter,
            Aurora.Uix.Gettext,
            Aurora.Uix.GettextBackend,
            Aurora.Uix.Helpers.Common,
            Aurora.Uix.RouteHelper
          ],
          "Mix Tasks": [
            Mix.Tasks.Uix.Gen.Icons,
            Mix.Tasks.Uix.Gen.Stylesheet
          ]
        ],
        exclude: ["lib/aurora_uix_web/**/*", "lib/aurora_uix/guides/**/*"],
        before_closing_body_tag: &before_closing_body_tag/1,
        filter_modules: &filter_modules/2
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Aurora.Uix.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]

    # end
  end

  # Mix deps.
  defp deps do
    [
      {:aurora_ctx, "~> 0.1"},
      {:accessible, "~> 0.3"},
      {:bandit, "~> 1.5"},
      {:css_parser, "~> 0.1"},
      {:ecto_sql, "~> 3.10"},
      {:gettext, "~> 1.0"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1,
       only: :dev,
       runtime: false},
      {:phoenix, "~> 1.8"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:postgrex, ">= 0.0.0"},
      {:struct_inspect, "~> 0.1"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},

      ## Dev dependencies
      {:ash, "~> 3.0", only: [:dev, :test]},
      {:ash_phoenix, "~> 2.3", only: [:dev, :test]},
      {:ash_postgres, "~> 2.0", only: [:dev, :test]},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},

      ## Test dependencies
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:doctor, "~> 0.22", only: :dev, runtime: false},
      {:ex_doc, "~> 0.40", only: [:dev, :test], runtime: false},
      {:image, "~> 0.37", only: :test},
      {:lazy_html, ">= 0.0.0", only: :test},
      {:wallaby, "~> 0.30", only: :test, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support/"]
  defp elixirc_paths(_), do: ["lib"]

  defp xref(:test) do
    "test/cases_live"
    |> xref_excluded_test_modules()
    |> then(&[exclude: &1])
  end

  defp xref(_), do: []

  defp xref_excluded_test_modules(prefix) do
    prefix
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".exs"))
    |> Enum.reduce([], &test_module_name("#{prefix}/#{&1}", &2))
  end

  defp test_module_name(file_name, acc) do
    file_name
    |> File.read!()
    |> String.split("\n")
    |> Enum.filter(&(String.starts_with?(&1, "defmodule ") and String.ends_with?(&1, "Test do")))
    |> List.first()
    |> String.split()
    |> Enum.at(1)
    |> expanded_test_module_names(acc)
  end

  defp expanded_test_module_names(name, acc) do
    Enum.reduce(
      [
        "Product.Index",
        "ProductTransaction.Index",
        "ProductLocation.Index",
        "Product.Show",
        "ProductTransaction.Show",
        "ProductLocation.Show"
      ],
      acc,
      &[Module.concat(name, &1) | &2]
    )
  end

  defp aliases do
    [
      "assets.build": [
        "compile",
        "phx.digest.clean --all",
        "auix.gen.icons",
        "auix.gen.stylesheet",
        "esbuild aurora_uix",
        "phx.digest"
      ],
      "assets.deploy": [
        "compile",
        "phx.digest.clean --all",
        "auix.gen.icons",
        "auix.gen.stylesheet",
        "esbuild aurora_uix",
        "phx.digest"
      ],
      "assets.setup": ["esbuild.install --if-missing"],
      consistency: [
        "format",
        "compile --warnings-as-errors",
        "credo --strict",
        "dialyzer",
        "doctor"
      ],
      documentation: [
        "test test/guides/capture_overview_images.exs test/guides/capture_layout_images.exs",
        "docs"
      ]
    ]
  end

  defp before_closing_body_tag(_),
    do:
      ~s(<script type="module" src="https://cdnjs.cloudflare.com/ajax/libs/mermaid/10.4.0/mermaid.esm.min.mjs"></script>)

  defp filter_modules(module, _map) do
    module
    |> to_string()
    |> process_starts_with()
  end

  defp process_starts_with(module) do
    ["Elixir.Aurora.Uix.Guides", "Elixir.Aurora.UixWeb"]
    |> Enum.map(fn string -> module |> String.starts_with?(string) |> Kernel.!() end)
    |> Enum.all?()
  end
end
