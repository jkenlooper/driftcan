SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:

DRIFTCAN_VERSION := "0.1.0-alpha.1"

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
project_dir := $(dir $(mkfile_path))

# For debugging what is set in variables
inspect.%:
	@echo $($*)

# Always run.  Useful when target is like targetname.% .
# Use $* to get the stem
FORCE:

HOME_DIR = ${HOME}

# TODO: rename .driftcan target files to .driftcan-path
target_driftcan_paths := $(patsubst ./%.driftcan, %, $(shell find . -name '*.driftcan'))
target_driftcan_bundles := $(patsubst ./%.driftcan-bundle, %, $(shell find . -name '*.driftcan-bundle'))
target_driftcan_links := $(patsubst ./%.driftcan-link, %, $(shell find . -name '*.driftcan-link'))

objects := ._driftcan_version .manifest .manifest-bundles .manifest-links $(target_driftcan_paths) $(target_driftcan_bundles) $(target_driftcan_links)

.PHONY: all
all: check_version $(objects)

._driftcan_version:
	@echo ${DRIFTCAN_VERSION} > $@

.PHONY: check_version
check_version: ._driftcan_version
	test "$$(cat $<)" = "$(DRIFTCAN_VERSION)"

# TODO: rename .manifest to ._driftcan_manifest_paths
.manifest: $(target_driftcan_paths)
	@if [ -z "$(target_driftcan_paths)" ]; then \
		echo "No .driftcan files found."; \
		touch $@; \
	else \
		echo "making $@"; \
		rm -f $@; \
		printf '%s\0' $^ | xargs -0 -I {} echo {} >> $@; \
	fi

# TODO: rename .manifest-bundles to ._driftcan_manifest_bundles
.manifest-bundles: $(target_driftcan_bundles)
	@if [ -z "$(target_driftcan_bundles)" ]; then \
		echo "No .driftcan-bundle files found."; \
		touch $@; \
	else \
		echo "making $@"; \
		rm -f $@; \
		printf '%s\0' $^ | xargs -0 -I {} echo {} >> $@; \
	fi

# TODO: rename .manifest-links to ._driftcan_manifest_links
.manifest-links: $(target_driftcan_links)
	@if [ -z "$(target_driftcan_links)" ]; then \
		echo "No .driftcan-link files found."; \
		touch $@; \
	else \
		echo "making $@"; \
		rm -f $@; \
		printf '%s\0' $^ | xargs -0 -I {} echo {} >> $@; \
	fi

# Preserve the modified time of the target and match that with the prereq when
# copying.
# TODO: if it's a directory; set mtime to the newest file in the directory.
%: %.driftcan
	cp --archive --update ${HOME_DIR}/$@ $$(dirname $@)
	touch --time=mtime --date="$$(stat --format='%y' $@)" $<

# TODO: if there are paths within the git repository that also have .driftcan
# files then this doesn't work right since it would create a file that could be
# a directory if the .driftcan happened first.
%: %.driftcan-bundle
	cd ${HOME_DIR}/$@ \
	&& git bundle create ${PWD}/$@ --all

%: %.driftcan-link
	@if [ -L $@ ]; then \
		echo "removing symbolic link $@"; \
		rm -f $@; \
	fi
	ln --symbolic --force ${HOME_DIR}/$@ $@
	touch --time=mtime --date="$$(stat --format='%y' $@)" $<

.PHONY: restore
restore: .manifest
	@echo "Restoring driftcan files from ${PWD} to ${HOME_DIR}/"
	rsync --archive \
		--delay-updates \
		--itemize-changes \
		--relative \
		--recursive \
		--files-from=.manifest \
		--copy-links \
		--exclude=.git \
		--exclude=.vagrant \
		--exclude=node_modules \
		--exclude=lost+found \
		. ${HOME_DIR}/

# Handle restore of .manifest-bundles

.PHONY: clone
clone:: .manifest
	@echo "Cloning driftcan files from ${HOME_DIR}/ to ${PWD}"
	rsync --archive \
		--delay-updates \
		--itemize-changes \
		--relative \
		--recursive \
		--files-from=.manifest \
		--copy-links \
		--exclude=.git \
		--exclude=.vagrant \
		--exclude=node_modules \
		--exclude=lost+found \
		${HOME_DIR}/ .

clone:: .manifest-bundles
	@echo "Updating git bundles from ${HOME_DIR}/ to ${PWD}"
	@while read bundle_path; do \
		if [[ -n "$${bundle_path}" ]]; then \
		echo "Checking git repo: $${bundle_path}"; \
		tmpfile_a=$$(mktemp); \
		tmpfile_b=$$(mktemp); \
		cd ${HOME_DIR}/$${bundle_path} && \
			git ls-remote ${PWD}/$${bundle_path} | sort --unique > $$tmpfile_a && \
			git ls-remote . | sort --unique > $$tmpfile_b && \
			diff -b $$tmpfile_a $$tmpfile_b > /dev/null || \
			git bundle create ${PWD}/$${bundle_path} --all; \
		fi \
	done < $<

clone:: .manifest-links
	@echo "Linking driftcan-link files from ${HOME_DIR}/ to ${PWD}"

.PHONY: clean
clean:
	@echo "Removing driftcan files from ${PWD}"
	printf '%s\0' $(objects) | xargs -0 rm -rf
