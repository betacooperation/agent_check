defmodule AgentCheck.Mixfile do
  use Mix.Project

  def project do
    [
      app: :agent_check,
      version: "0.2.0",
      elixir: "~> 1.5",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AgentCheck.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.18", only: :dev}
    ]
  end

  defp description do
    """
    HAProxy Agent Check protocol implementation for Elixir/Phoenix apps. Allows for easy rolling restarts and dynamic backpressure to your HAProxy loadbalancer.
    """
  end
  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Bart ten Brinke", "Beta Corp"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/betacooperation/agent_check"}
    ]
  end
end
