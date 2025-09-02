defmodule Aurora.Uix.MixProject do
  use Mix.Project

  @source_url "https://github.com/wadvanced/aurora_uix"
  @version "0.1.0"

  def project do
    [
      app: :aurora_uix,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [
        plt_add_apps: [:eex, :mix]
      ],
      aliases: aliases(),

      # Hex
      description: "Low code UI for the elixir's Phoenix Framework",
      package: [
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
      extra_applications: [:logger]
    ]
  end

  # Mix deps.
  defp deps do
    [
      {:aurora_ctx, "~> 0.1"},
      {:ecto_sql, "~> 3.10"},
      {:bandit, "~> 1.5"},
      {:gettext, "~> 0.20"},
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_html, "~> 4.2"},
      {:phoenix_live_view, "~> 1.0"},
      {:postgrex, ">= 0.0.0"},

      ## Dev dependencies
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:doctor, "~> 0.22", only: :dev, runtime: false},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      {:esbuild, "~> 0.8", only: [:dev, :test], runtime: false},
      {:floki, ">= 0.30.0", only: :test, runtime: false},
      {:tailwind, "~> 0.2", only: [:dev, :test], runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
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
