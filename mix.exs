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
      {:ecto_sql, "~> 3.10"},
      {:bandit, "~> 1.5"},
      {:gettext, "~> 0.20"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_html, "~> 4.2"},
      {:phoenix_live_view, "~> 1.0", override: true},
      {:postgrex, ">= 0.0.0"},

      ## Dev dependencies
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:doctor, "~> 0.22", only: :dev, runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:esbuild, "~> 0.8", only: [:dev, :test], runtime: false},
      {:floki, ">= 0.30.0", only: :test, runtime: false},
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

  defp before_closing_body_tag(_),
    do:
      ~s(<script type="module" src="https://cdnjs.cloudflare.com/ajax/libs/mermaid/10.4.0/mermaid.esm.min.mjs"></script>)
end
