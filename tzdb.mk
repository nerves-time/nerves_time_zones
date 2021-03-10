# Makefile for building the test database
#
# Makefile targets:
#
# all           build and install the database
# clean         clean build products and intermediates
#
# Variables to override:
#
# MIX_APP_PATH  path to the build directory
# CC_FOR_BUILD  C compiler

TOP := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

# Since this is for test purposes, be sure this matches what the tz (or tzdata)
# libraries use or you'll get discrepancies that are ok.
TZDB_NAME=tzdb-$(TZDB_VERSION)
TZDB_ARCHIVE_NAME=$(TZDB_NAME).tar.lz
TZDB_ARCHIVE_PATH=$(TOP)/$(TZDB_ARCHIVE_NAME)
TZDB_URL=https://data.iana.org/time-zones/releases/$(TZDB_ARCHIVE_NAME)
ZIC_OPTIONS=-r @$(TZDB_EARLIEST_DATE)/@$(TZDB_LATEST_DATE)

PREFIX = $(MIX_APP_PATH)/priv
BUILD  = $(MIX_APP_PATH)/tzdb
CC_FOR_BUILD=cc

calling_from_make:
	mix compile

all: $(PREFIX)/zoneinfo

### Copied from tzcode Makefile

# Package name for the code distribution.
PACKAGE=        tzcode

# Version number for the distribution, overridden in the 'tarballs' rule below.
VERSION=        unknown

# Email address for bug reports.
BUGEMAIL=       tz@iana.org

# Backwards compatibility
BACKWARD=       backward

# Everything that's normally installed
PRIMARY_YDATA=  africa antarctica asia australasia \
                europe northamerica southamerica
YDATA=          $(PRIMARY_YDATA) etcetera
NDATA=          factory
TDATA=          $(YDATA)

$(BUILD)/tzdb/version.h: $(BUILD)/tzdb/version
	VERSION=`cat $(BUILD)/tzdb/version` && printf '%s\n' \
		'static char const PKGVERSION[]="($(PACKAGE)) ";' \
		"static char const TZVERSION[]=\"$$VERSION\";" \
		'static char const REPORT_BUGS_TO[]="$(BUGEMAIL)";' \
		>$@.out
	mv $@.out $@

### End copied definitions

$(BUILD)/tzdb/zic: $(BUILD)/tzdb $(BUILD)/tzdb/zic.c $(BUILD)/tzdb/version.h
	$(CC_FOR_BUILD) -o $@ $(BUILD)/tzdb/zic.c

$(PREFIX)/zoneinfo: $(BUILD)/tzdb/zic $(PREFIX) Makefile
	cd $(BUILD)/tzdb && ./zic -d $@ $(ZIC_OPTIONS) $(TDATA)

$(TZDB_ARCHIVE_PATH):
	wget -O $(TZDB_ARCHIVE_PATH) $(TZDB_URL)

$(BUILD)/tzdb: $(TZDB_ARCHIVE_PATH) $(BUILD)
	cd $(BUILD) && lzip -d -c $(TZDB_ARCHIVE_PATH) | tar x
	mv $(BUILD)/$(TZDB_NAME) $@

$(PREFIX) $(BUILD):
	mkdir -p $@

clean:
	$(RM) -r $(BUILD) $(PREFIX)

.PHONY: all clean calling_from_make
