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

# Since this is for test purposes, be sure this matches what the tz (or tzdata)
# libraries use or you'll get discrepancies that are ok.
DL = dl
TZDATA_NAME=tzdata$(TZDATA_VERSION)
TZDATA_ARCHIVE_NAME=$(TZDATA_NAME).tar.gz
TZDATA_ARCHIVE_PATH=$(abspath $(DL)/$(TZDATA_ARCHIVE_NAME))

TZCODE_NAME=tzcode$(TZDATA_VERSION)
TZCODE_ARCHIVE_NAME=$(TZCODE_NAME).tar.gz
TZCODE_ARCHIVE_PATH=$(abspath $(DL)/$(TZCODE_ARCHIVE_NAME))

ZIC_OPTIONS=-r @$(TZDATA_EARLIEST_DATE)/@$(TZDATA_LATEST_DATE)

PREFIX = $(MIX_APP_PATH)/priv
BUILD  = $(MIX_APP_PATH)/build
CC_FOR_BUILD=cc
TZVERSION = $(BUILD)/TZVERSION
ZIC = $(BUILD)/$(TZCODE_NAME)/zic

CFLAGS=

ifeq ($(shell uname -s),Darwin)
# Apparently using sys/random.h on MacOS requires more than zic.c
# provides, so just disable it since its new to 2022f
CFLAGS=-DHAVE_GETRANDOM=false
endif

calling_from_make:
	mix compile

all: $(PREFIX) $(BUILD) $(PREFIX)/zoneinfo

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

$(BUILD)/$(TZCODE_NAME)/version.h: $(TZVERSION)
	VERSION=`cat $(TZVERSION)` && printf '%s\n' \
		'static char const PKGVERSION[]="($(PACKAGE)) ";' \
		"static char const TZVERSION[]=\"$$VERSION\";" \
		'static char const REPORT_BUGS_TO[]="$(BUGEMAIL)";' \
		>$@.out
	mv $@.out $@
	$(RM) -r $(PREFIX)/zoneinfo $(ZIC)

### End copied definitions

$(ZIC): $(BUILD)/$(TZCODE_NAME)/.extracted $(BUILD)/$(TZCODE_NAME)/zic.c $(BUILD)/$(TZCODE_NAME)/version.h
	@echo " HOSTCC $(notdir $@)"
	$(CC_FOR_BUILD) $(CFLAGS) -o $@ $(BUILD)/$(TZCODE_NAME)/zic.c

$(PREFIX)/zoneinfo: $(BUILD)/$(TZDATA_NAME)/.extracted $(ZIC) Makefile
	@echo "    ZIC $(notdir $@)"
	cd $(BUILD)/$(TZDATA_NAME) && $(ZIC) -d $@ $(ZIC_OPTIONS) $(TDATA)

$(TZDATA_ARCHIVE_PATH) $(TZCODE_ARCHIVE_PATH): $(DL)
	@echo "   CURL $(notdir $@)"
	curl -L https://data.iana.org/time-zones/releases/$(notdir $@) > $@

$(BUILD)/$(TZDATA_NAME)/.extracted: $(TZDATA_ARCHIVE_PATH)
	mkdir -p $(dir $@)
	cd $(dir $@) && tar xf $(TZDATA_ARCHIVE_PATH)
	touch $@

$(BUILD)/$(TZCODE_NAME)/.extracted: $(TZCODE_ARCHIVE_PATH)
	mkdir -p $(dir $@)
	cd $(dir $@) && tar xf $<
	touch $@

$(PREFIX) $(BUILD) $(DL):
	mkdir -p $@

$(TZVERSION): $(BUILD)
	echo $(TZDATA_VERSION) > $@

clean:
	$(RM) -r $(BUILD) $(PREFIX)

.PHONY: all clean calling_from_make

# Don't echo commands unless the caller exports "V=1"
${V}.SILENT:
