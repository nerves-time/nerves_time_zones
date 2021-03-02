defmodule NervesTimeZones.Persistence do
  @moduledoc false

  @file_name "localtime"

  @spec(save_time_zone(String.t()) :: :ok, {:error, any()})
  def save_time_zone(time_zone) do
    data_dir = data_directory()
    path = Path.join(data_dir, @file_name)

    with :ok <- File.mkdir_p(data_dir) do
      File.write(path, time_zone)
    end
  end

  @spec load_time_zone() :: {:ok, String.t()} | {:error, any()}
  def load_time_zone() do
    Path.join(data_directory(), @file_name)
    |> File.read()
    |> sanity_check()
  end

  @spec reset() :: :ok | {:error, atom}
  def reset() do
    Path.join(data_directory(), @file_name)
    |> File.rm()
  end

  defp sanity_check({:ok, time_zone}) do
    if possible_time_zone?(time_zone) do
      {:ok, time_zone}
    else
      {:error, :invalid_file}
    end
  end

  defp sanity_check(error), do: error

  defp possible_time_zone?(time_zone) do
    n = byte_size(time_zone)

    n > 0 and n < 255 and String.valid?(time_zone)
  end

  defp data_directory() do
    Application.get_env(:nerves_time_zones, :data_dir, "/data/nerves_time_zones")
  end
end
