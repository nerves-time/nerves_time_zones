# NervesTimeZones

[![Hex version](https://img.shields.io/hexpm/v/nerves_time_zones.svg "Hex version")](https://hex.pm/packages/nerves_time_zones)
[![CircleCI](https://circleci.com/gh/nerves-time/nerves_time_zones.svg?style=svg)](https://circleci.com/gh/nerves-time/nerves_time_zones)

Local time and time zones for Nerves devices

NervesTimeZones provides a way of managing local time on embedded devices. It
provides the following:

1. Set your time zone and have it be used for local time calls like
   `NaiveDateTime.local_now/0`. The time zone persists across reboots.
2. Set up Elixir's [Calendar time zone
   database](https://hexdocs.pm/elixir/Calendar.html) using
   [`zoneinfo`](https://hex.pm/packages/zoneinfo)
3. Provide a small time zone database appropriate for many embedded devices

It does not support the automatic update of the time zone database like
[tzdata](https://hex.pm/packages/tzdata) and [tz](https://hex.pm/packages/tz).
For now, you'll need to watch for new versions of the `nerves_time_zones`
package. (We're open to changing this, but it's not as easy as regularly polling
IANA.)

The primary motivation for creating this library was to reduce the size of the
time zone database. `tzdata` and `tz` both work by compiling the IANA database
to an internal format. At the time, `tzdata` compiled to a 3.5 MB ets table
(~600 KB gzip compressed) and `tz` compiled to a 300 KB beam file (~250 KB gzip
compressed). Using TZif files (the `/usr/share/zoneinfo` ones) and 10 years of
time zone records for all time zones resulted in about 450 KB of data (~16 KB
gzip compressed).

## Installation

First, add `nerves_time_zones` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nerves_time_zones, "~> 0.1.2"}
  ]
end
```

NervesTimeZones persists the currently selected local time zone to
`"/data/nerves_time_zones"`. This works well on Nerves devices. If you're
developing on your laptop, you may want to change the location by adding the
following in your project's `config.exs`:

```elixir
config :nerves_time_zones, data_dir: "./tmp/nerves_time_zones"
```

The default time zone is "Etc/UTC". If you want it to be something else, set it
in the config like this:

```elixir
config :nerves_time_zones, default_time_zone: "Europe/Paris"
```

## Database example

If you just start up IEx, you may have seen something like this:

```elixir
iex> DateTime.now("America/New_York")
{:error, :utc_only_time_zone_database}
```

`NervesTimeZones` automatically sets up the time zone database so once you've
added the `:nerves_time_zones` dependency, you'll get this instead:

```elixir
iex> DateTime.now("America/New_York")
{:ok, #DateTime<2021-03-11 10:19:59.811175-05:00 EST America/New_York>}
```

`NervesTimeZones` is opinionated on the time zone database provider so it forces
the default and will log messages if there's a conflict with `tzdata` or `tz`.
You can still use those time zone databases if you really want them even though
it defeats the purpose of keeping one database on a device. You'll just need to
manually specify the database in all of your `DateTime` calls.

## Local time example

By default with `NervesTimeZones`, local time will be UTC. You can see this by
running `NaiveDateTime.local_now/1`. Be aware that this behavior is different
from the normal behavior of using your system's local time zone setting if you
trying this out on your laptop. Nerves devices don't have time zone settings by
default.

```elixir
iex> DateTime.utc_now
~U[2021-03-11 15:10:41.573579Z]
iex> NaiveDateTime.local_now
~N[2021-03-11 15:10:44]
```

You can set the time zone like this (note the time shift by 5 hours):

```elixir
iex> NervesTimeZones.set_time_zone("America/New_York")
:ok
iex> NaiveDateTime.local_now
~N[2021-03-11 10:11:02]
```

## Running OS commands

It's possible to use the same time zone database with non-BEAM programs. For
example, on my system the default for C programs is Eastern time:

```elixir
iex> System.cmd("date", [])
{"Thu 11 Mar 2021 10:34:14 AM EST\n", 0}
```

On a Nerves device, this would be UTC, but the concept is the same.

Say I want it to be Hawaii time:

```elixir
iex> NervesTimeZones.set_time_zone("Pacific/Honolulu")
:ok
```

This won't affect the `date` program since it's not running on the BEAM. All is
not lost. `NervesTimeZones` can provide environment settings so that the C
runtime will use the same data base and time zone setting as on the BEAM:

```elixir
iex> System.cmd("date", [], env: NervesTimeZones.tz_environment())
{"Thu 11 Mar 2021 05:40:38 AM HST\n", 0}
iex)> NaiveDateTime.local_now
~N[2021-03-11 05:40:49]
```

## How it works

NervesTimeZones pulls data from the [IANA time zone
database](http://www.iana.org/time-zones) and compiles it to TZif files using
[zic(8)](https://data.iana.org/time-zones/tzdb/zic.8.txt). This is the same
process used to create the files under `/usr/share/zoneinfo`. The difference is
that those contain time period records 50 years or more in the past and over 15
years to the future. NervesTimeZones limits the range substantially to reduce
the database size.

Since the main embedded use cases for time zone information are to show the time
and schedule events in the local time, having past time zone information is not
needed. This saves a ton of space, since time zones changed a lot in the 20th
century.

The second part of the library is a NIF that updates the C runtime's local time
zone setting. This setting also affects Erlang's and Elixir's local time
functions like `NaiveDateTime.local_now/0` as well. The NIF is trivially short
and calls [`tzset(3)`](https://man7.org/linux/man-pages/man3/tzset.3.html) with
the TZif file. Unfortunately, the way to pass the time zone is via the `TZ`
environment variable, so if `TZ` previously pointed to anything before this
library runs, it won't afterwards.

## License

Copyright (C) 2021 Frank Hunleth

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
