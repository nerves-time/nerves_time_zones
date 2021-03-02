defmodule NervesTimeZones.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/nerves-time/nerves_time_zones"
  @tzdb_version "2020f"
  @tzdb_earliest_date to_string(System.os_time(:second) - 86400)
  @tzdb_latest_date to_string(System.os_time(:second) + 10 * 365 * 86400)

  def project do
    [
      app: :nerves_time_zones,
      version: @version,
      elixir: "~> 1.11",
      description: description(),
      package: package(),
      source_url: @source_url,
      compilers: [:elixir_make | Mix.compilers()],
      make_env: %{
        "TZDB_VERSION" => @tzdb_version,
        "TZDB_EARLIEST_DATE" => @tzdb_earliest_date,
        "TZDB_LATEST_DATE" => @tzdb_latest_date
      },
      make_targets: ["all"],
      make_clean: ["clean"],
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        flags: [:unmatched_returns, :error_handling, :race_conditions, :underspecs]
      ],
      preferred_cli_env: %{
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {NervesTimeZones.Application, []}
    ]
  end

  defp description do
    "Time zones for Nerves"
  end

  defp package do
    %{
      files: [
        "lib",
        "c_src/*.[ch]",
        "mix.exs",
        "README.md",
        "LICENSE",
        "CHANGELOG.md",
        "Makefile"
      ],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    }
  end

  defp deps do
    [
      {:zoneinfo, "~> 0.1.0"},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false},
      {:dialyxir, "~> 1.1.0", only: :dev, runtime: false},
      {:elixir_make, "~> 0.6", runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
