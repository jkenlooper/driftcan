#MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
project_dir := $(dir $(mkfile_path))

# For debugging what is set in variables
inspect.%:
	@echo $($*)

# Always run.  Useful when target is like targetname.% .
# Use $* to get the stem
FORCE:

HOME_DIR = ${HOME}/tmp/driftcan-computer-example

target_driftcan_paths := $(patsubst %.driftcan, %, $(shell find . -name '*.driftcan'))
target_driftcan_bundles := $(patsubst %.driftcan-bundle, %, $(shell find . -name '*.driftcan-bundle'))

.PHONY: all
all: $(target_driftcan_paths) $(target_driftcan_bundles)

#@sed "s/ /\n/g" <<< "$^" | sed "s:^:${HOME_DIR}/:g" > $@
.manifest: $(target_driftcan_paths) $(target_driftcan_bundles)
	@echo "making .manifest"
	@sed "s/ /\n/g" <<< "$^" > $@

%: %.driftcan
	@echo "prereq is $<"
	@echo "target is $@"
	cp -r ${HOME_DIR}/$@ $@

%: %.driftcan-bundle
	@echo "prereq is $<"
	@echo "target is $@"
	cd ${HOME_DIR}/$@ \
	&& git bundle create ${PWD}/$@ --all

%.driftcan-bundle-manifest: $(patsubst %.driftcan-bundle, %, $(target_driftcan_bundles))
	echo "bundle: $<"
	git bundle list-heads $< | cut -f1 -d ' ' | sort --unique > $@

	#cp -r ${HOME_DIR}/$@ $@

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
		--exclude=package-lock.json \
		. ${HOME_DIR}/


.PHONY: clone
clone: .manifest
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
		--exclude=package-lock.json \
		${HOME_DIR}/ .

