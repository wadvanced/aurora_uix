defmodule AuroraUix.MixProject do
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
        files: ~w(.formatter.exs mix.exs README.md CHANGELOG.md lib)
      ],

      # Docs
      name: "Aurora UIX",
      docs: [
        source_ref: @version,
        extra_section: "GUIDES",
        source_url: @source_url,
        extras: [
          "guides/introduction/getting_started.md",
          "CHANGELOG.md"
        ],
        groups_for_extras: [
          Introduction: ~r(guides/introduction/.?)
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:doctor, "~> 0.22", only: :dev, runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},

      ## Test only dependencies
      {:bandit, "~> 1.5", only: :test, runtime: false},
      {:ecto_sql, "~> 3.10", only: :test, runtime: false},
      {:esbuild, "~> 0.8", only: [:dev, :test], runtime: false},
      {:gettext, "~> 0.20", only: :test, runtime: false},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1,
       only: :test,
       runtime: false},
      {:phoenix, "~> 1.7", only: [:dev, :test], runtime: false},
      {:phoenix_ecto, "~> 4.5", only: :test, runtime: false},
      {:phoenix_html, "~> 4.2", only: :test, runtime: false},
      {:phoenix_live_view, "~> 1.0", override: true, only: :test, runtime: false},
      {:postgrex, ">= 0.0.0", only: :test, runtime: false},
      {:tailwind, "~> 0.2", only: [:dev, :test], runtime: false}
    ]
  end

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
end
