# SPDX-FileCopyrightText: 2021 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule TzdataTest do
  use ExUnit.Case, async: true

  @year 365 * 24 * 60 * 60
  @day 24 * 60 * 60

  # Check that records are available from now until 10 years from now
  # The "- 31 * @day" part is to avoid failing on old database builds.
  @earliest_record_after NaiveDateTime.utc_now()
  @latest_record_after NaiveDateTime.add(NaiveDateTime.utc_now(), 10 * @year - 31 * @day)

  for time_zone <- NervesTimeZones.time_zones() do
    test "metadata for #{time_zone}" do
      {:ok, meta} = Zoneinfo.get_metadata(unquote(time_zone))

      # These tests check that records were generated for the requested range
      assert NaiveDateTime.compare(@earliest_record_after, meta.earliest_record_utc) == :gt
      assert NaiveDateTime.compare(@latest_record_after, meta.latest_record_utc) == :lt
    end
  end

  @tag :tmp_dir
  test "rebuilds the database only when the configured range changes", %{tmp_dir: tmp_dir} do
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    {meta, _output} = build_database(tmp_dir, ~U[2022-01-01 00:00:00Z], ~U[2030-01-01 00:00:00Z])
    assert meta.earliest_record_utc == ~N[2022-01-01 00:00:00]
    assert meta.latest_record_utc == ~N[2030-01-01 00:00:00]

    {meta, _output} = build_database(tmp_dir, ~U[2023-01-01 00:00:00Z], ~U[2030-01-01 00:00:00Z])
    assert meta.earliest_record_utc == ~N[2023-01-01 00:00:00]
    assert meta.latest_record_utc == ~N[2030-01-01 00:00:00]

    {meta, _output} = build_database(tmp_dir, ~U[2023-01-01 00:00:00Z], ~U[2031-01-01 00:00:00Z])
    assert meta.earliest_record_utc == ~N[2023-01-01 00:00:00]
    assert meta.latest_record_utc == ~N[2031-01-01 00:00:00]

    {_meta, output} = build_database(tmp_dir, ~U[2023-01-01 00:00:00Z], ~U[2031-01-01 00:00:00Z])
    refute output =~ "ZIC"
  end

  defp build_database(path, earliest, latest) do
    env =
      Mix.Project.config()[:make_env].()
      |> Map.merge(%{
        "MIX_APP_PATH" => path,
        "TZDATA_EARLIEST_DATE" => to_string(DateTime.to_unix(earliest)),
        "TZDATA_LATEST_DATE" => to_string(DateTime.to_unix(latest))
      })
      |> Map.to_list()

    {output, status} =
      System.cmd("make", ["-f", "tzdata.mk", "all"], env: env, stderr_to_stdout: true)

    assert status == 0, output

    {:ok, tzif} =
      path
      |> Path.join("priv/zoneinfo/America/New_York")
      |> File.read!()
      |> Zoneinfo.TZif.parse()

    {Zoneinfo.Meta.to_meta("America/New_York", tzif), output}
  end
end
