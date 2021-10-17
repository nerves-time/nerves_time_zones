# Changelog

## v0.1.8

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
  * Setting the default timezone didn't work on Nerves. Thanks to @pojiro for
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
