# SPDX-FileCopyrightText: 2021 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesTimeZones.Nif do
  @on_load {:load_nif, 0}
  @compile {:autoload, false}

  @moduledoc false

  def load_nif() do
    nif_binary = Application.app_dir(:nerves_time_zones, "priv/nif")
    :erlang.load_nif(to_charlist(nif_binary), 0)
  end

  def set(_value) do
    :erlang.nif_error(:nif_not_loaded)
  end
end
