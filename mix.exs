defmodule AuroraUix.MixProject do
  use Mix.Project

  def project do
    [
      app: :aurora_uix,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
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
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.4", only: [:dev]},
      {:doctor, "~> 0.22.0", only: :dev}
    ]
  end

  defp aliases do
    [
      consistency: ["format", "credo --strict", "dialyzer", "doctor"]
    ]
  end
end
