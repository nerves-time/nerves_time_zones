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
TZDATA_URL=https://data.iana.org/time-zones/releases/$(TZDATA_ARCHIVE_NAME)
ZIC_OPTIONS=-r @$(TZDATA_EARLIEST_DATE)/@$(TZDATA_LATEST_DATE)

PREFIX = $(MIX_APP_PATH)/priv
BUILD  = $(MIX_APP_PATH)/build
CC_FOR_BUILD=cc
TZVERSION = $(BUILD)/TZVERSION

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

tzcode/version.h: $(TZVERSION)
	VERSION=`cat $(TZVERSION)` && printf '%s\n' \
		'static char const PKGVERSION[]="($(PACKAGE)) ";' \
		"static char const TZVERSION[]=\"$$VERSION\";" \
		'static char const REPORT_BUGS_TO[]="$(BUGEMAIL)";' \
		>$@.out
	mv $@.out $@
	$(RM) -r $(PREFIX)/zoneinfo

### End copied definitions

$(BUILD)/zic: tzcode/zic.c tzcode/version.h
	@echo " HOSTCC $(notdir $@)"
	$(CC_FOR_BUILD) -o $@ tzcode/zic.c

$(PREFIX)/zoneinfo: $(BUILD)/zic $(BUILD)/$(TZDATA_NAME)/.extracted Makefile
	@echo "    ZIC $(notdir $@)"
	cd $(BUILD)/$(TZDATA_NAME) && $(BUILD)/zic -d $@ $(ZIC_OPTIONS) $(TDATA)

$(TZDATA_ARCHIVE_PATH): $(DL)
	@echo "   CURL $(notdir $@)"
	curl -L $(TZDATA_URL) > $@

$(BUILD)/$(TZDATA_NAME)/.extracted: $(TZDATA_ARCHIVE_PATH)
	mkdir -p $(BUILD)/$(TZDATA_NAME)
	cd $(BUILD)/$(TZDATA_NAME) && tar xf $(TZDATA_ARCHIVE_PATH)
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
