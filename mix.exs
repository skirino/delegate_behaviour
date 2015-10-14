defmodule DelegateBehaviour.Mixfile do
  use Mix.Project

  def project do
    [
      app:             :delegate_behaviour,
      version:         "0.1.3",
      elixir:          "~> 1.0",
      build_embedded:  Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps:            deps,
      description:     description,
      package:         package,
      source_url:      "https://github.com/skirino/delegate_behaviour",
      homepage_url:    "https://github.com/skirino/delegate_behaviour",
      test_coverage:   [tool: Coverex.Task, coveralls: true],
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:coverex, "~> 1.4", only: :test},
      {:dialyze, "~> 0.2", only: :dev},
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
      links:       %{"GitHub repository" => "https://github.com/skirino/delegate_behaviour"},
    ]
  end
end
