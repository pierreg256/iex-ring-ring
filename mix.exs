defmodule KeyValue.MixProject do
  use Mix.Project

  def project do
    [
      app: :key_value,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {KeyValue.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependenciers.
  defp deps do
    [
      {:libcluster, "~> 3.3"},
      {:swarm, "~> 3.0"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 3.1"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
