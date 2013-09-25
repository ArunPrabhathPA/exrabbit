defmodule Rabbit.Mixfile do
  use Mix.Project

  def project do
    [ app: :rabbit,
      version: "0.0.1",
      name:  "Elixir RabbitMq",
      elixir: "~> 0.10.3-dev",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [ applications: [:gproc],
    mod: { Rabbit, [] }]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "~> 0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [
      {:gen_bunny, "0.1", github: "atulpundhir/gen_bunny"},
      {:gproc, github: "esl/gproc"},
      {:ex_doc, github: "elixir-lang/ex_doc"},
      {:jiffy, github: "davisp/jiffy"}
    ]
  end
end
