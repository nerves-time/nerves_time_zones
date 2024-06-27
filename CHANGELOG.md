# Changelog

## v0.3.5

* Updates
  * Include backwards compatibility time zones. Based on feedback, these are in
    such wide use that it's unexpected when they don't exist. This increases the
    amount of data saved, but if you're using a deduplicating filesystem like
    SquashFS with Nerves, it's very minimal.

## v0.3.4

* Updates
  * Update the IANA database to 2024a
  * Use the `:sync` flag when persisting time zone setting updates to avoid them
    getting lost due to removing the power before the filesystem has been
    written.

## v0.3.3

* Updates
  * Update the IANA database to 2023c
  * Update cached tzcode to 2023c to fix compilation errors with GCC 13.2

## v0.3.2

* Updates
  * Update the IANA database to 2023a

## v0.3.1

* Fixes
  * Some build machines incorrectly detected gettext support when building zic.
    Since gettext isn't needed, force it off to avoid the possibility of a build
    error.

## v0.3.0

This release changes how dates are returned that happen before the earliest date
in the time zone database. This is due to an update to IANA's zic compiler.
Previously the earliest time zone would be extended to dates before the
beginning of the database. This was wrong, though, since there could be any
number of time zone changes. The new way is to return UTC and the unknown time
zone, `-00`.

If you have dates in your regression tests, you probably will need to update
them if they're processed by nerves_time_zones.

* Updates
  * Update the IANA database and zic compiler to 2022g
  * Fix the earliest database date to 2022/1/1 so regression tests can have
    fixed dates without breaking independent of a nerves_time_zones version bump.

## v0.2.2

* Updates
  * Update the IANA database to 2022e

## v0.2.1

* Updates
  * Update the IANA database to 2022b

## v0.2.0

* Added
  * IANA database version, earliest date, and latest date now configurable form
    the application environment (thanks @LostKobrakai)

* Updates
  * Update the IANA database to 2022a

## v0.1.10

* Updates
  * Update the IANA database to 2021e (Palestine DST change date)

## v0.1.9

* Updates
  * Update the IANA database to 2021d (Fiji!)

## v0.1.8

* Updates
  * Update the IANA database to 2021c (reverts the time zone removals in 2021b)

## v0.1.7

* Updates
  * Update the IANA database to 2021b

## v0.1.6

* Improvements
  * Switch from `wget` to `curl` for database download to be friendlier to MacOS
    users
  * Cleanup and reduce Makefile prints

## v0.1.5

* Bug fixes
  * Fix Makefile to support cross-compilation on Mac.

## v0.1.4

* Bug fixes
  * Setting the default time zone didn't work on Nerves. Thanks to @pojiro for
    fixing this.

## v0.1.3

* Updates
  * Update the IANA database to 2021a
  * Add GitHub action to check for IANA database updates and automatically send
    a PR. Thanks to Connor Rigby for huge time saver.

## v0.1.2

* New features
  * Support changing the default time zone to something besides `"Etc/UTC"`

## v0.1.1

* Bug fixes
  * Add files that were missing from the hex package

## v0.1.0

Initial release to hex.
