defmodule Chatbot.MixProject do
  use Mix.Project

  def project do
    [
      app: :chatbot,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [plt_add_apps: [:nostrum]],
      preferred_cli_env: [credo: :test, dialyzer: :test, gradient: :test]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Chatbot.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: :test, runtime: false},
      {:dialyxir, "~> 1.3", only: :test, runtime: false},
      {:gradient, github: "esl/gradient", only: :test, runtime: false},
      {:jason, "~> 1.4"},
      {:nostrum, "~> 0.6", runtime: Mix.env() != :test},
      {:openai, "~> 0.5"}
    ]
  end
end
