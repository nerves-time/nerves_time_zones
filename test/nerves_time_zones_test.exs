defmodule NervesTimeZonesTest do
  use ExUnit.Case
  doctest NervesTimeZones

  import ExUnit.CaptureLog

  describe "persistence" do
    test "default is UTC" do
      capture_log(fn -> Application.stop(:nerves_time_zones) end)
      NervesTimeZones.Persistence.reset()

      Application.start(:nerves_time_zones)
      assert NervesTimeZones.get_time_zone() == "Etc/UTC"
    end

    test "save and restore" do
      :ok = NervesTimeZones.set_time_zone("America/New_York")
      capture_log(fn -> Application.stop(:nerves_time_zones) end)

      Application.start(:nerves_time_zones)
      assert NervesTimeZones.get_time_zone() == "America/New_York"
    end
  end

  test "tz_environment/0" do
    path = Zoneinfo.tzpath()
    tz = "America/Los_Angeles"

    :ok = NervesTimeZones.set_time_zone(tz)
    assert %{"TZDIR" => path, "TZ" => Path.join(path, tz)} == NervesTimeZones.tz_environment()
  end

  test "sets Calendar TimeZoneDatabase" do
    # The database isn't set in our config.exs. NervesTimeZones sets it
    assert Calendar.get_time_zone_database() == Zoneinfo.TimeZoneDatabase
  end

  test "sets local time" do
    NervesTimeZones.set_time_zone("Etc/UTC")
    assert NaiveDateTime.diff(NaiveDateTime.local_now(), NaiveDateTime.utc_now()) < 2

    NervesTimeZones.set_time_zone("Etc/GMT+1")
    expected = NaiveDateTime.utc_now() |> NaiveDateTime.add(60 * 60)
    assert NaiveDateTime.diff(NaiveDateTime.local_now(), expected) < 2
  end

  test "warns if someone else sets Calendar's TimeZoneDatabase" do
    assert capture_log(fn ->
             Application.stop(:nerves_time_zones)
             Calendar.put_time_zone_database(Tzdata.TimeZoneDatabase)
             Application.start(:nerves_time_zones)
           end) =~ " Check your config.exs"
  end

  test "timezone lookups work" do
    # The goal of this test is to sanity check that the time zone
    # data base is being used and less that the conversion is
    # correct.

    expected = DateTime.new!(~D[2021-03-08], ~T[17:00:00], "America/Phoenix")

    assert {:ok, expected} ==
             DateTime.shift_zone(~U[2021-03-09 00:00:00Z], "America/Phoenix")
  end
end
