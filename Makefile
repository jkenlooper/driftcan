SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:

DRIFTCAN_VERSION := "0.0.1"

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
project_dir := $(dir $(mkfile_path))

# For debugging what is set in variables
inspect.%:
	@echo $($*)

# Always run.  Useful when target is like targetname.% .
# Use $* to get the stem
FORCE:

HOME_DIR = ${HOME}

target_driftcan_paths := $(patsubst ./%.driftcan, %, $(shell find . -name '*.driftcan'))
target_driftcan_bundles := $(patsubst ./%.driftcan-bundle, %, $(shell find . -name '*.driftcan-bundle'))

objects := ._driftcan_version .manifest .manifest-bundles $(target_driftcan_paths) $(target_driftcan_bundles)

.PHONY: all
all: $(objects)

._driftcan_version:
	@echo ${DRIFTCAN_VERSION} > $@

.manifest: $(target_driftcan_paths)
	@echo "making $@"
	@rm -f $@
	@printf '%s\0' $^ | xargs -0 -I {} echo {} >> $@

.manifest-bundles: $(target_driftcan_bundles)
	@echo "making $@"
	@rm -f $@
	@printf '%s\0' $^ | xargs -0 -I {} echo {} >> $@

# Preserve the modified time of the target and match that with the prereq when
# copying.
%: %.driftcan
	cp --archive --update ${HOME_DIR}/$@ $$(dirname $@)
	touch --time=mtime --date="$$(stat --format='%y' $@)" $<

# TODO: if there are paths within the git repository that also have .driftcan
# files then this doesn't work right since it would create a file that could be
# a directory if the .driftcan happened first.
%: %.driftcan-bundle
	cd ${HOME_DIR}/$@ \
	&& git bundle create ${PWD}/$@ --all


.PHONY: restore
restore: .manifest
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


.PHONY: clone
clone:: .manifest
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
	@echo "Updating git bundles"
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

.PHONY: clean
clean:
	printf '%s\0' $(objects) | xargs -0 rm -rf
