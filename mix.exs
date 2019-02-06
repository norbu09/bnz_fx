defmodule BnzFx.MixProject do
  use Mix.Project

  def project do
    [
      app: :bnz_fx,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:con_cache],
      extra_applications: [:logger, :inets, :ssl, :exoml],
      mod: {BnzFx.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:exoml, ">= 0.0.2"},
      {:con_cache, github: "sasa1977/con_cache"}
    ]
  end
end
