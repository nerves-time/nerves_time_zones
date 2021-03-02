defmodule NervesTimeZones.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {NervesTimeZones.Server, []}
    ]

    opts = [strategy: :one_for_one, name: NervesTimeZones.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
