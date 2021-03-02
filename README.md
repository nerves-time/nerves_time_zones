# NervesTimeZones

Local time and time zones for Nerves devices

NervesTimeZones provides a way of managing local time on embedded devices. It
provides the following:

1. Set your time zone and have it be used for local time calls like
   `NaiveDateTime.local_now/0`
2. Set up Elixir's [Calendar time zone
   database](https://hexdocs.pm/elixir/Calendar.html) using
   [`zoneinfo`](https://hex.pm/packages/zoneinfo)
3. Provide a small time zone database appropriate for many embedded devices

It does not support the automatic update of the time zone database like
[tzdata](https://hex.pm/packages/tzdata) and [tz](https://hex.pm/packages/tz).
For now, you'll need to build a new version of the `nerves_time_zones` package.

The primary motivation for creating this library was to reduce the size of the
time zone database. `tzdata` and `tz` both work by compiling the IANA database
to an internal format. At the time, `tzdata` compiled to a 3.5 MB ets table
(~600 KB gzip compressed) and `tz` compiled to a 300 KB beam file (~250 KB gzip
compressed). Using TZif files (the `/usr/share/zoneinfo` ones) and 10 years of
time zone records for all time zones resulted in about 450 KB of data (~16 KB
gzip compressed).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `nerves_time_zones` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nerves_time_zones, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/nerves_time_zones](https://hexdocs.pm/nerves_time_zones).

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

