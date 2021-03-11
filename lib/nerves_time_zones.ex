defmodule NervesTimeZones do
  @moduledoc """
  Local time support for Nerves devices

  The `nerves_time_zones` application provides support for local time on Nerves
  devices. It does this by bundling a time zone database that's compatible with
  the `zoneinfo` library and providing logic to set the local time zone with
  the C runtime (and hence Erlang and Elixir).

  To use, call `NervesTimeZones.set_time_zone/1` with the any IANA time zone
  name (e.g., `"America/New_York"`). The time zone will be persisted so you
  won't need to set it again. It is safe to always set it on boot if your
  project will always be located in one time zone.

  After this, calls to `NaiveDateTime.local_now/1` will return the local time.
  If you would prefer `DateTime` struct, call
  `DateTime.now(NervesTimeZones.get_time_zone())`.

  If running a non-BEAM program that is time zone aware, you may need to set
  environment variables for it to work right. See
  `NervesTimeZones.tz_environment/0` for the proper settings.
  """

  @doc """
  Set the local time zone

  Only known time zone names can be set. Others will return an error.
  `"Etc/UTC"` should always be available.

  This time zone will be persisted and restored after a reboot.
  """
  @spec set_time_zone(String.t()) :: :ok | {:error, any}
  defdelegate set_time_zone(time_zone), to: NervesTimeZones.Server

  @doc """
  Return the current local time zone
  """
  @spec get_time_zone() :: String.t()
  defdelegate get_time_zone(), to: NervesTimeZones.Server

  @doc """
  Reset the time zone to the default

  This cleans up any saved time zone information and reapplies the defaults.
  """
  @spec reset_time_zone() :: :ok
  defdelegate reset_time_zone(), to: NervesTimeZones.Server

  @doc """
  Return environment variables for running OS processes

  If you're using `System.cmd/3` to start an OS process that is time zone
  aware, call this to set the environment appropriately. For example,
  `System.cmd("my_program", [], env: NervesTimeZones.tz_environment())`
  """
  @spec tz_environment() :: %{String.t() => String.t()}
  defdelegate tz_environment, to: NervesTimeZones.Server

  @doc """
  Return all known time zones

  This function scans the time zone database each time it's called. It's
  not slow, but if you just need to verify whether a time zone exists,
  call `valid_time_zone?/1` instead.
  """
  @spec time_zones() :: [String.t()]
  defdelegate time_zones(), to: Zoneinfo

  @doc """
  Return whether a time zone is valid
  """
  @spec valid_time_zone?(String.t()) :: boolean
  defdelegate valid_time_zone?(time_zone), to: Zoneinfo
end
