defmodule NervesTimeZones.Server do
  use GenServer
  require Logger

  @moduledoc false

  alias NervesTimeZones.{Nif, Persistence}

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @spec set_time_zone(String.t()) :: :ok | {:error, any()}
  def set_time_zone(time_zone) do
    GenServer.call(__MODULE__, {:set_time_zone, time_zone})
  end

  @spec get_time_zone() :: String.t()
  def get_time_zone() do
    GenServer.call(__MODULE__, :get_time_zone)
  end

  @spec tz_environment() :: %{String.t() => String.t()}
  def tz_environment() do
    GenServer.call(__MODULE__, :tz_environment)
  end

  @impl GenServer
  def init(_init_args) do
    configure_zoneinfo()

    time_zone =
      case Persistence.load_time_zone() do
        {:ok, zone} -> zone
        _other -> "Etc/UTC"
      end

    set_tz_var(time_zone)
    {:ok, time_zone}
  end

  @impl GenServer
  def handle_call({:set_time_zone, new_time_zone}, _from, current_time_zone) do
    with :ok <- check_time_zone(new_time_zone),
         :ok <- Persistence.save_time_zone(new_time_zone) do
      set_tz_var(new_time_zone)
      {:reply, :ok, new_time_zone}
    else
      error -> {:reply, error, current_time_zone}
    end
  end

  def handle_call(:get_time_zone, _from, current_time_zone) do
    {:reply, current_time_zone, current_time_zone}
  end

  def handle_call(:tz_environment, _from, current_time_zone) do
    env = %{"TZ" => time_zone_path(current_time_zone), "TZDIR" => zoneinfo_path()}
    {:reply, env, current_time_zone}
  end

  defp check_time_zone(time_zone) do
    if Zoneinfo.valid_time_zone?(time_zone) do
      :ok
    else
      {:error, :unknown_time_zone}
    end
  end

  defp set_tz_var(time_zone) do
    # This sets the TZ environment variable so that Erlang local time works
    # and so does any new process started by Erlang.
    time_zone
    |> time_zone_path()
    |> to_charlist()
    |> Nif.set()
  end

  defp configure_zoneinfo() do
    # This pretty forcefully configures time zone lookups. The justification
    # is that if a user adds :nerves_time_zones to their dependencies, they expect it
    # to work and shouldn't have to do anything more. If users want to also use
    # Tz or Tzdata, then they can still do that on a per-call basis to Elixir date functions.
    Application.put_env(:zoneinfo, :tzpath, zoneinfo_path())

    case Calendar.get_time_zone_database() do
      Zoneinfo.TimeZoneDatabase ->
        :ok

      Calendar.UTCOnlyTimeZoneDatabase ->
        :ok

      other ->
        Logger.warn("""
        nerves_time_zones requires that the Calendar TimeZoneDatabase be unset or set to Zoneinfo.TimeZoneDatabase.
        Something else set it to #{inspect(other)}. Check your config.exs and remove another setting if there.
        """)
    end

    Calendar.put_time_zone_database(Zoneinfo.TimeZoneDatabase)
  end

  defp time_zone_path(time_zone) do
    Path.join(zoneinfo_path(), time_zone)
  end

  defp zoneinfo_path() do
    Application.app_dir(:nerves_time_zones, "priv/zoneinfo")
  end
end
