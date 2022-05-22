defmodule Eibisqlite.MixProject do
  use Mix.Project

  def project do
    [
      app: :eibisqlite,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:exqlite, "~> 0.10.1"},
      {:csv, "~> 2.4"},
      {:httpoison, "~> 1.8"},
      {:codepagex, "~> 0.1.6"},
      {:floki, "~> 0.26.0"},
      {:poison, "~> 5.0"}
    ]
  end
end
