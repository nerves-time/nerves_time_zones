defmodule NervesTimeZones.Server do
  use GenServer
  require Logger

  @moduledoc false

  alias NervesTimeZones.{Nif, Persistence}

  @default_data_dir "/data/nerves_time_zones"
  @default_time_zone "Etc/UTC"

  defstruct data_dir: @default_data_dir,
            default_time_zone: @default_time_zone,
            current_time_zone: nil

  @type init_args() :: [data_dir: Path.t()]

  @spec start_link(init_args()) :: GenServer.on_start()
  def start_link(init_args) do
    configure_zoneinfo()
    GenServer.start_link(__MODULE__, check_args(init_args), name: __MODULE__)
  end

  defp check_args(pending_args, good_args \\ [])

  defp check_args([], good_args), do: good_args

  defp check_args([{:data_dir, data_dir} = arg | rest], good_args) when is_binary(data_dir) do
    check_args(rest, [arg | good_args])
  end

  defp check_args([{:default_time_zone, zone} = arg | rest], good_args) when is_binary(zone) do
    if Zoneinfo.valid_time_zone?(zone) do
      check_args(rest, [arg | good_args])
    else
      Logger.warn(
        "Default time zone `#{zone}` isn't valid. Using #{@default_time_zone} instead. Call `NervesTimeZones.time_zones/0` for list."
      )

      check_args(rest, good_args)
    end
  end

  @spec set_time_zone(String.t()) :: :ok | {:error, any()}
  def set_time_zone(time_zone) do
    GenServer.call(__MODULE__, {:set_time_zone, time_zone})
  end

  @spec get_time_zone() :: String.t()
  def get_time_zone() do
    GenServer.call(__MODULE__, :get_time_zone)
  end

  @spec reset_time_zone() :: :ok
  def reset_time_zone() do
    GenServer.call(__MODULE__, :reset_time_zone)
  end

  @spec tz_environment() :: %{String.t() => String.t()}
  def tz_environment() do
    GenServer.call(__MODULE__, :tz_environment)
  end

  @impl GenServer
  def init(init_args) do
    state = struct(__MODULE__, init_args)

    time_zone =
      case Persistence.load_time_zone(state.data_dir) do
        {:ok, zone} -> zone
        _other -> state.default_time_zone
      end

    set_tz_var(time_zone)
    {:ok, %{state | current_time_zone: time_zone}}
  end

  @impl GenServer
  def handle_call({:set_time_zone, new_time_zone}, _from, state) do
    with :ok <- check_time_zone(new_time_zone),
         :ok <- Persistence.save_time_zone(state.data_dir, new_time_zone) do
      set_tz_var(new_time_zone)
      {:reply, :ok, %{state | current_time_zone: new_time_zone}}
    else
      error -> {:reply, error, state}
    end
  end

  def handle_call(:get_time_zone, _from, state) do
    {:reply, state.current_time_zone, state}
  end

  def handle_call(:reset_time_zone, _from, state) do
    _ = Persistence.reset(state.data_dir)

    set_tz_var(state.default_time_zone)
    {:reply, :ok, %{state | current_time_zone: state.default_time_zone}}
  end

  def handle_call(:tz_environment, _from, state) do
    env = %{"TZ" => time_zone_path(state.current_time_zone), "TZDIR" => zoneinfo_path()}
    {:reply, env, state}
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
