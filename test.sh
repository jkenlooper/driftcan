#!/usr/bin/env bash

for bats_test in ./test/*.bats; do
  $bats_test
done
