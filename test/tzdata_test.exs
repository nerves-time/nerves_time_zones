# SPDX-FileCopyrightText: 2021 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule TzdataTest do
  use ExUnit.Case, async: true

  @year 365 * 24 * 60 * 60
  @day 24 * 60 * 60

  # Check that records are available from now until 10 years from now
  # The "- 31 * @day" part is to avoid failing on old database builds.
  @earliest_record_after NaiveDateTime.utc_now()
  @latest_record_after NaiveDateTime.add(NaiveDateTime.utc_now(), 10 * @year - 31 * @day)

  for time_zone <- NervesTimeZones.time_zones() do
    test "metadata for #{time_zone}" do
      {:ok, meta} = Zoneinfo.get_metadata(unquote(time_zone))

      # These tests check that records were generated for the requested range
      assert NaiveDateTime.compare(@earliest_record_after, meta.earliest_record_utc) == :gt
      assert NaiveDateTime.compare(@latest_record_after, meta.latest_record_utc) == :lt
    end
  end
end
