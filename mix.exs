defmodule NervesTimeZones.MixProject do
  use Mix.Project

  @app :nerves_time_zones
  @version "0.2.2"
  @source_url "https://github.com/nerves-time/nerves_time_zones"
  @tzdata_version "2022g"
  @tzdata_earliest_date System.os_time(:second) - 86400
  @tzdata_latest_date System.os_time(:second) + 10 * 365 * 86400

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.11",
      description: description(),
      package: package(),
      source_url: @source_url,
      compilers: [:elixir_make | Mix.compilers()],
      make_env: &make_env/0,
      make_error_message: "",
      make_targets: ["all"],
      make_clean: ["clean"],
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        flags: [:unmatched_returns, :error_handling, :missing_return, :extra_return, :underspecs]
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
        "CHANGELOG.md",
        "c_src/*.[ch]",
        "lib",
        "LICENSE",
        "mix.exs",
        "README.md",
        "Makefile",
        "tzcode/private.h",
        "tzcode/README.md",
        "tzcode/tzfile.h",
        "tzcode/version",
        "tzcode/zic.c",
        "tzdata.mk"
      ],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    }
  end

  defp deps do
    [
      {:zoneinfo, "~> 0.1.2"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false},
      {:dialyxir, "~> 1.2.0", only: :dev, runtime: false},
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

  defp make_env() do
    tzdata_version = Application.get_env(@app, :version, @tzdata_version)
    tzdata_earliest_date = Application.get_env(@app, :earliest_date, @tzdata_earliest_date)
    tzdata_latest_date = Application.get_env(@app, :latest_date, @tzdata_latest_date)

    if tzdata_version != @tzdata_version do
      msg = """
      TZ database version #{tzdata_version} differs from the offically supported version #{@tzdata_version}

      This is useful for unit and compatability tests, but should be avoided in production.
      """

      IO.warn(msg, [])
    end

    %{
      "TZDATA_VERSION" => tzdata_version,
      "TZDATA_EARLIEST_DATE" => to_string(tzdata_earliest_date),
      "TZDATA_LATEST_DATE" => to_string(tzdata_latest_date)
    }
  end
end
