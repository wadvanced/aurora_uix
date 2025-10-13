defmodule Aurora.Uix.MixProject do
  use Mix.Project

  @source_url "https://github.com/wadvanced/aurora_uix"
  @version "0.1.0-alpha.1"

  def project do
    [
      app: :aurora_uix,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
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
        files: ~w(.formatter.exs mix.exs README.md CHANGELOG.md lib),
        exclude_patterns: [~r"/-local-.*"]
      ],

      # Docs
      name: "Aurora UIX",
      docs: [
        main: "overview",
        logo: "./guides/images/aurora_uix-icon.png",
        assets: %{"./guides/overview/images/" => "images", "./guides/core/images/" => "images"},
        extras: [
          "CHANGELOG.md",
          "guides/overview/overview.md",
          "guides/introduction/getting_started.md",
          "guides/core/fields.md",
          "guides/core/resource_metadata.md",
          "guides/core/layouts.md",
          "guides/core/liveview.md",
          "guides/advanced/advanced_usage.md",
          "guides/advanced/troubleshooting.md"
        ],
        groups_for_extras: [
          Introduction: ~r{guides/introduction/.*},
          Core: ~r{guides/core/.*},
          Advanced: ~r{guides/advanced/.*}
        ],
        before_closing_body_tag: &before_closing_body_tag/1
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Aurora.Uix.Application, []},
      extra_applications: [:logger, :runtime_tools, :inets]
    ]
  end

  # Mix deps.
  defp deps do
    [
      {:aurora_ctx, "~> 0.1"},
      {:accessible, "~> 0.3"},
      {:bandit, "~> 1.5"},
      {:ecto_sql, "~> 3.10"},
      {:gettext, "~> 1.0"},

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
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},

      ## Test dependencies
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:doctor, "~> 0.22", only: :dev, runtime: false},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      {:lazy_html, ">= 0.0.0", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support/", "test/cases_live"]
  defp elixirc_paths(_), do: ["lib", "test/support/app_web"]

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
        "phx.digest.clean --all",
        "esbuild aurora_uix",
        "phx.digest"
      ],
      "assets.deploy": [
        "phx.digest.clean --all",
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
      ]
    ]
  end

  defp before_closing_body_tag(_),
    do:
      ~s(<script type="module" src="https://cdnjs.cloudflare.com/ajax/libs/mermaid/10.4.0/mermaid.esm.min.mjs"></script>)
end
