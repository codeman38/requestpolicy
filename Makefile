# NOTE: in this file tab indentation is used.
# Otherwise .RECIPEPREFIX would have to be set.

#
# create variables
#

extension_name := requestpolicy
extension_uuid := requestpolicy@requestpolicy.com

# The zip application to be used.
ZIP := zip

source_dirname := src
build_dirname := build
dist_dirname := dist

source_path := $(source_dirname)/
build_path := $(build_dirname)/
dist_path := $(dist_dirname)/

jar_file := $(build_path)chrome/$(extension_name).jar

# the path of the target XPI file
xpi_file := $(dist_path)$(extension_name).xpi

# collect files that are part of the source code
source_files := $(shell find $(source_dirname) -type f -regex ".*\.jsm?") \
		$(source_dirname)/chrome.manifest \
		$(source_dirname)/install.rdf \
		$(source_dirname)/LICENSE \
		$(source_dirname)/README \
		$(wildcard $(source_dirname)/content/settings/*.css) \
		$(wildcard $(source_dirname)/content/settings/*.html) \
		$(wildcard $(source_dirname)/content/ui/*.xul) \
		$(wildcard $(source_dirname)/locale/*/*.dtd) \
		$(wildcard $(source_dirname)/locale/*/*.properties) \
		$(wildcard $(source_dirname)/skin/*.css) \
		$(wildcard $(source_dirname)/skin/*.png) \
		$(wildcard $(source_dirname)/skin/*.svg)
# take all files from above and create their paths in the "build" directory
all_files := $(patsubst $(source_path)%,$(build_path)%,$(source_files))

javascript_files := $(filter %.js %.jsm,$(all_files))
other_files := $(filter-out $(javascript_files),$(all_files))

# detect deleted files and empty directories
deleted_files :=
empty_dirs :=
ifneq "$(wildcard $(build_path))" ""
# files that have been deleted but still exist in the build directory.
deleted_files := $(shell find $(build_path) -type f | grep -F -v $(addprefix -e ,$(all_files)))
# empty directories. -mindepth 1 to exclude the build directory itself.
empty_dirs := $(shell find $(build_path) -mindepth 1 -type d -empty)
endif




#
# define targets
#

# set "all" to be the default target
.DEFAULT_GOAL := all

# build and create XPI file
.PHONY: all
all: $(xpi_file)
	@echo "Build finished successfully."

# Building means processing all source files and eventually delete
# empty directories and deleted files from the build directory.
.PHONY: build
build: $(build_path)
$(build_path): $(all_files) $(deleted_files) $(empty_dirs)


# create the dist directory
$(dist_path):
	@mkdir -p $(dist_path)

# "dist" means packaging to a XPI file
.PHONY: dist
dist: $(xpi_file)
# Note: We add the build path as a prerequisite, not the phony "build" target.
#       This way we avoid re-packaging in case nothing has changed.
#       Also $(all_files) is needed as prerequisite, so that the xpi gets updated
$(xpi_file): $(build_path) $(all_files) | $(dist_path)
	@rm -f $(xpi_file)
	@echo "Creating XPI file."
	@cd $(build_path) && \
	$(ZIP) $(abspath $(xpi_file)) $(patsubst $(build_path)%,%,$(all_files))
	@echo "Creating XPI file: Done!"

# ___________________
# processing of files
#

# enable Secondary Expansion (so that $@ can be used in prerequisites via $$@)
.SECONDEXPANSION:

$(javascript_files): $$(patsubst $$(build_path)%,$$(source_path)%,$$@)
	@mkdir -p $(dir $@)
	cp $(patsubst $(build_path)%,$(source_path)%,$@) $@
	@# In case javascript files should be processed, it should be done here.

$(other_files): $$(patsubst $$(build_path)%,$$(source_path)%,$$@)
	@mkdir -p $(dir $@)
	cp $(patsubst $(build_path)%,$(source_path)%,$@) $@

# __________________
# "cleaning" targets
#

# This cleans all temporary files and directories created by 'make'.
.PHONY: clean
clean:
	@rm -rf $(xpi_file) $(jar_file) $(build_path)*
	@echo "Cleanup is done."

# remove empty directories
$(empty_dirs): FORCE
	rmdir $@

# delete deleted files that still exist in the build directory.
# this target should be forced
$(deleted_files): FORCE
	@# delete:
	rm $@
	@# delete parent dirs if empty:
	@rmdir --parents --ignore-fail-on-non-empty $(dir $@)

# ____________
# unit testing
#

# Note: currently you have to do some setup before this will work.
# see https://github.com/RequestPolicyContinued/requestpolicy/wiki/Setting-up-a-development-environment#unit-tests-for-requestpolicy

firefox_bin := /moz/firefox/nightly/firefox
mozmill_tests_path := /moz/mozmill-tests/
mozmill_manifest := $(mozmill_tests_path)firefox/tests/addons/$(extension_uuid)/manifest.ini

.PHONY: check test mozmill
check test: mozmill

mozmill: $(xpi_file)
	mozmill -a $(xpi_file) -b $(firefox_bin) -m $(mozmill_manifest)


# ________________
# "helper" targets
#

.PHONY: FORCE
FORCE:
