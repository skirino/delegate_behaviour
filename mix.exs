defmodule DelegateBehaviour.Mixfile do
  use Mix.Project

  @github_url "https://github.com/skirino/delegate_behaviour"

  def project do
    [
      app:             :delegate_behaviour,
      version:         "0.1.5",
      elixir:          "~> 1.0",
      build_embedded:  Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      compilers:       compilers,
      deps:            deps,
      description:     description,
      package:         package,
      source_url:      @github_url,
      homepage_url:    @github_url,
      test_coverage:   [tool: Coverex.Task, coveralls: true],
    ]
  end

  def application do
    []
  end

  defp compilers do
    additional = if Mix.env == :prod, do: [], else: [:exref]
    Mix.compilers ++ additional
  end

  defp deps do
    [
      {:coverex, "~> 1.4", only: :test},
      {:dialyze, "~> 0.2", only: :dev},
      {:exref  , "~> 0.1", only: [:dev, :test]},
    ]
  end

  defp description do
    """
    Macros to define modules that delegate to concrete implementations of behaviours
    """
  end

  defp package do
    [
      files:       ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Shunsuke Kirino"],
      licenses:    ["MIT"],
      links:       %{"GitHub repository" => @github_url},
    ]
  end
end
