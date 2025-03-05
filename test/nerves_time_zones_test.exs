# SPDX-FileCopyrightText: 2021 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesTimeZonesTest do
  use ExUnit.Case
  doctest NervesTimeZones

  import ExUnit.CaptureLog

  describe "persistence" do
    test "get returns what was set" do
      :ok = NervesTimeZones.set_time_zone("America/Indiana/Indianapolis")
      assert NervesTimeZones.get_time_zone() == "America/Indiana/Indianapolis"
    end

    test "reset restores default" do
      :ok = NervesTimeZones.set_time_zone("Atlantic/Bermuda")
      :ok = NervesTimeZones.reset_time_zone()

      assert NervesTimeZones.get_time_zone() == "Etc/UTC"
    end

    test "save and restore" do
      :ok = NervesTimeZones.set_time_zone("America/New_York")
      restart_app()
      assert NervesTimeZones.get_time_zone() == "America/New_York"
    end

    test "save fails" do
      old_path = Application.get_env(:nerves_time_zones, :data_dir)
      Application.put_env(:nerves_time_zones, :data_dir, "/proc/place/that/fails")
      restart_app()

      log =
        capture_log(fn ->
          {:error, :enoent} = NervesTimeZones.set_time_zone("America/New_York")
        end)

      Application.put_env(:nerves_time_zones, :data_dir, old_path)
      restart_app()

      assert log =~ "Failed to save time zone"
    end

    test "default is UTC" do
      # Clear out the time zone file
      NervesTimeZones.reset_time_zone()

      # This should be a fresh start
      restart_app()

      assert NervesTimeZones.get_time_zone() == "Etc/UTC"
    end

    test "default can be changed" do
      # Clear out the time zone file
      NervesTimeZones.reset_time_zone()

      capture_log(fn ->
        Application.stop(:nerves_time_zones)
        Application.stop(:zoneinfo)
      end)

      # This should simulate a fresh start and not get tricked by
      # zoneinfo finding system time zone files.
      Application.put_env(:zoneinfo, :tzpath, "/some/place/without/zoneinfo")
      Calendar.put_time_zone_database(Calendar.UTCOnlyTimeZoneDatabase)

      # Set the default and check that it is used
      Application.put_env(:nerves_time_zones, :default_time_zone, "America/Chicago")
      Application.ensure_all_started(:nerves_time_zones)
      assert NervesTimeZones.get_time_zone() == "America/Chicago"

      # Restore the default for the next tests
      :application.unset_env(:nerves_time_zones, :default_time_zone)
      restart_app()
    end

    test "setting invalid default time zones logs a warning" do
      # Clear out the time zone file
      NervesTimeZones.reset_time_zone()
      capture_log(fn -> Application.stop(:nerves_time_zones) end)

      # This should be a fresh start
      Application.put_env(:nerves_time_zones, :default_time_zone, "Mars/Olympus_Mons")

      assert capture_log(fn -> Application.start(:nerves_time_zones) end) =~
               "Using Etc/UTC instead"

      assert NervesTimeZones.get_time_zone() == "Etc/UTC"

      # Restore the default
      :application.unset_env(:nerves_time_zones, :default_time_zone)
      restart_app()
    end
  end

  test "tz_environment/0" do
    path = Zoneinfo.tzpath()
    tz = "America/Los_Angeles"

    :ok = NervesTimeZones.set_time_zone(tz)
    assert %{"TZDIR" => path, "TZ" => Path.join(path, tz)} == NervesTimeZones.tz_environment()
  end

  test "valid_time_zone?/1" do
    assert NervesTimeZones.valid_time_zone?("America/Halifax")
    refute NervesTimeZones.valid_time_zone?("Luna/Mare_Tranquilitatis")
    refute NervesTimeZones.valid_time_zone?("")
  end

  describe "time_zones/0" do
    test "main us time zones exist" do
      tz_list = NervesTimeZones.time_zones()
      assert "America/New_York" in tz_list
      assert "America/Chicago" in tz_list
      assert "America/Denver" in tz_list
      assert "America/Phoenix" in tz_list
      assert "America/Los_Angeles" in tz_list
      assert "Pacific/Honolulu" in tz_list
    end

    test "backwards-compatible time zones exist" do
      tz_list = NervesTimeZones.time_zones()
      assert "Europe/Amsterdam" in tz_list
      assert "America/Indiana/Indianapolis" in tz_list
    end

    test "each continent has a time zone that exists" do
      tz_list = NervesTimeZones.time_zones()
      assert "Africa/Nairobi" in tz_list
      assert "America/New_York" in tz_list
      assert "Asia/Tokyo" in tz_list
      assert "Europe/Berlin" in tz_list
      assert "Pacific/Honolulu" in tz_list
      assert "Antarctica/McMurdo" in tz_list
      assert "Arctic/Longyearbyen" in tz_list
      assert "Australia/Melbourne" in tz_list
    end

    test "all non-empty strings" do
      tz_list = NervesTimeZones.time_zones()
      assert Enum.all?(tz_list, &is_binary/1)
      refute "" in tz_list
    end

    test "time zone count is close" do
      tz_list = NervesTimeZones.time_zones()

      # This probably changes with tzdata releases, but if it's not in this
      # range, it would be good to double check the database generation.
      assert_in_delta length(tz_list), 596, 10

      refute "" in tz_list
    end
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

    expected = DateTime.from_naive!(~N[2022-03-08 17:00:00], "America/Phoenix")

    assert {:ok, expected} ==
             DateTime.shift_zone(~U[2022-03-09 00:00:00Z], "America/Phoenix")
  end

  test "requesting timezones when not started" do
    # Stop the app to simulate the case where a request is made before
    # the app is started.
    capture_log(fn -> Application.stop(:nerves_time_zones) end)

    expected = DateTime.from_naive!(~N[2022-03-08 17:00:00], "America/Phoenix")

    assert {:ok, expected} ==
             DateTime.shift_zone(~U[2022-03-09 00:00:00Z], "America/Phoenix")

    Application.start(:nerves_time_zones)
  end

  defp restart_app() do
    capture_log(fn -> Application.stop(:nerves_time_zones) end)
    Application.start(:nerves_time_zones)
  end
end
