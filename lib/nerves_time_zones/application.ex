defmodule NervesTimeZones.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    env = Application.get_all_env(:nerves_time_zones)

    children = [
      {NervesTimeZones.Server, Keyword.take(env, [:data_dir, :default_time_zone])}
    ]

    opts = [strategy: :one_for_one, name: NervesTimeZones.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
