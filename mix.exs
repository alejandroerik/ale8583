defmodule Ale8583.MixProject do
  use Mix.Project

  def project do
    [
      app: :ale8583,
      version: "0.1.1",
      elixir: "~> 1.5",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Ale8583",
      source_url: "https://github.com/alejandroerik/ale8583"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description() do
    "ISO8583(MasterC and PROSA) parser for ELIXIR language."
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.14", only: :dev},
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end

  defp package do
    [
      name: "ale8583",
      # These are the default files included in the package
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Erik Linares", "PROFAM"],
      licenses: ["GNU GPLv3"],
      links: %{"GitHub" => "https://github.com/alejandroerik/ale8583"}
    ]
  end
end
