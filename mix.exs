


defmodule Ecstatic.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ecstatic,
      version: "0.1.1",
      elixir: "~> 1.8",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      name: "Ecstatic",
      deps: deps(),
      package: package(),
      docs: docs(),
      elixirc_paths:
       if Mix.env() == :test do
        ["lib", "test/lib"]
       else
        ["lib"]
       end
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp package do
    [
      description: "An ECS (Entity-Component-System) framework in Elixir",
      licenses: ["MIT"],
      maintainers: ["Aldric Giacomoni"],
      links: %{github: "https://github.com/trevoke/ecstatic"},
      source_url: "https://github.com/trevoke/ecstatic"
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:uuid, "~> 1.1"},
      {:gen_stage, "~> 0.12.2"},
      {:dialyxir, "~> 1.0-pre4", only: [:dev], runtime: false}
    ]
  end

end
