defmodule NervesTimeZones.Persistence do
  @moduledoc false

  @file_name "localtime"

  @spec(save_time_zone(Path.t(), String.t()) :: :ok, {:error, any()})
  def save_time_zone(data_dir, time_zone) do
    path = Path.join(data_dir, @file_name)

    with :ok <- File.mkdir_p(data_dir) do
      File.write(path, time_zone)
    end
  end

  @spec load_time_zone(Path.t()) :: {:ok, String.t()} | {:error, any()}
  def load_time_zone(data_dir) do
    Path.join(data_dir, @file_name)
    |> File.read()
    |> sanity_check()
  end

  @spec reset(Path.t()) :: :ok | {:error, atom}
  def reset(data_dir) do
    Path.join(data_dir, @file_name)
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
end
