defmodule NervesTimeZones.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    init_args = Application.get_all_env(:nerves_time_zones)

    children = [
      {NervesTimeZones.Server, init_args}
    ]

    opts = [strategy: :one_for_one, name: NervesTimeZones.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
