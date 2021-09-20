#!./test/bats/bin/bats

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'

  PROJECT_DIR=$PWD
  tmp_dir=$(mktemp -d)
  cd $tmp_dir
  ln -s $PROJECT_DIR/Makefile
}

teardown () {
  echo "Teardown $tmp_dir"
  tree -a $tmp_dir
  rm -r $tmp_dir
}

@test "Creates a version file" {
  # Arrange
  # ...

  # Act
  run make
  version=$(make inspect.DRIFTCAN_VERSION)

  # Assert
  run cat ._driftcan_version
  assert_output "${version}"
}
