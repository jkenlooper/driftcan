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

@test "Creates a ._driftcan_version file with the version of the Makefile" {
  # Arrange
  version=$(make inspect.DRIFTCAN_VERSION)

  # Act
  run make

  # Assert
  run cat ._driftcan_version
  assert_output "${version}"
}

@test "Checks a ._driftcan_version file to match the version of the Makefile" {
  # Arrange
  version='0.0.1-a'

  # Act
  make DRIFTCAN_VERSION='0.0.1-a'

  # Assert
  # Simulate an updated Makefile with a different version
  run make DRIFTCAN_VERSION='0.0.1-b'
  assert_failure
  run cat ._driftcan_version
  assert_output "${version}"
}


@test "Creates an empty .manifest file if no driftcan files were found" {
  # Arrange
  # ...

  # Act
  run make

  # Assert
  assert_output --partial "No .driftcan files found."

  run test ! -s .manifest
  assert_success
}

@test "Creates an empty .manifest-bundle file if no driftcan bundle files were found" {
  # Arrange
  # ...

  # Act
  run make

  # Assert
  assert_output --partial "No .driftcan-bundle files found."

  run test ! -s .manifest-bundles
  assert_success
}

@test "Nothing created when using make restore with empty manifest files" {
  # Arrange
  fake_home_dir=$(mktemp -d)
  echo "an existing file" > $fake_home_dir/existing_file.txt
  mkdir -p $fake_home_dir/parks/{yellowstone,yosemite}
  echo "a file in a directory" > $fake_home_dir/parks/yellowstone/test1.txt
  echo "a file in a directory" > $fake_home_dir/parks/yosemite/test2.txt

  # Act
  run make HOME_DIR=${fake_home_dir}
  run make HOME_DIR=${fake_home_dir} restore

  # Assert
  assert_output --partial "Restoring driftcan files from ${PWD} to ${fake_home_dir}/"

  run test ! -s .manifest-bundles
  assert_success
}

@test "Nothing created when using make clone with empty manifest files" {
  # Arrange
  fake_home_dir=$(mktemp -d)
  echo "an existing file" > $fake_home_dir/existing_file.txt
  mkdir -p $fake_home_dir/parks/{yellowstone,yosemite}
  echo "a file in a directory" > $fake_home_dir/parks/yellowstone/test1.txt
  echo "a file in a directory" > $fake_home_dir/parks/yosemite/test2.txt
  existing_dir_snapshot=$(tree $fake_home_dir)
  md5sum $(find $fake_home_dir -type f) > checksums

  # Act
  run make HOME_DIR=${fake_home_dir}
  run make HOME_DIR=${fake_home_dir} clone

  # Assert
  assert_output --partial "Cloning driftcan files from ${fake_home_dir}/ to ${PWD}"
  assert_output --partial "Updating git bundles from ${fake_home_dir}/ to ${PWD}"

  run test ! -s .manifest
  assert_success
  run test ! -s .manifest-bundles
  assert_success
  run tree $fake_home_dir
  assert_output "$existing_dir_snapshot"
  run md5sum --check checksums
  assert_success
}

@test "Clones driftcan files" {
  # Arrange
  fake_home_dir=$(mktemp -d)
  echo "an existing file" > $fake_home_dir/existing_file.txt
  touch existing_file.txt.driftcan
  mkdir -p $fake_home_dir/parks/{yellowstone,yosemite}
  echo "a file in a directory" > $fake_home_dir/parks/yellowstone/test1.txt
  mkdir -p $(dirname parks/yellowstone/test1.txt)
  touch parks/yellowstone/test1.txt.driftcan
  echo "a file in a directory" > $fake_home_dir/parks/yosemite/test2.txt
  mkdir -p $(dirname parks/yosemite/test2.txt)
  touch parks/yosemite/test2.txt.driftcan
  mkdir -p $fake_home_dir/parks/arches/
  echo "a file in a directory" > $fake_home_dir/parks/arches/test3.txt
  touch parks/arches.driftcan
  existing_dir_snapshot=$(tree $fake_home_dir)
  md5sum $(find $fake_home_dir -type f) > checksums
  cd $fake_home_dir
  md5sum existing_file.txt parks/yellowstone/test1.txt parks/yosemite/test2.txt parks/arches/test3.txt > $tmp_dir/target_files_checksums
  cd -

  # Act
  run make HOME_DIR=${fake_home_dir}
  run make HOME_DIR=${fake_home_dir} clone

  # Assert
  assert_output --partial "Cloning driftcan files from ${fake_home_dir}/ to ${PWD}"
  assert_output --partial "Updating git bundles from ${fake_home_dir}/ to ${PWD}"

  # creates a .manifest file
  run test -s .manifest
  assert_success
  run test ! -s .manifest-bundles
  assert_success

  # doesn't modify home dir
  run tree $fake_home_dir
  assert_output "$existing_dir_snapshot"
  run md5sum --check checksums
  assert_success

  # clones the files
  run md5sum --check target_files_checksums
  assert_success
}

@test "Clones driftcan bundle files" {
  skip "Handling of driftcan bundle files will change."
  # Arrange
  fake_home_dir=$(mktemp -d)
  echo "an existing file" > $fake_home_dir/existing_file.txt
  touch existing_file.txt.driftcan
  mkdir -p $fake_home_dir/parks/{yellowstone,yosemite}
  echo "a file in a directory" > $fake_home_dir/parks/yellowstone/test1.txt
  mkdir -p $(dirname parks/yellowstone/test1.txt)
  touch parks/yellowstone/test1.txt.driftcan
  echo "a file in a directory" > $fake_home_dir/parks/yosemite/test2.txt
  mkdir -p $(dirname parks/yosemite/test2.txt)
  touch parks/yosemite/test2.txt.driftcan

  mkdir -p $fake_home_dir/parks/arches/
  cd $fake_home_dir/parks/arches/
  git init
  echo "a file in a git repository" > $fake_home_dir/parks/arches/test3.txt
  git add .
  git commit -m 'testing'
  cd -

  existing_dir_snapshot=$(tree $fake_home_dir)
  md5sum $(find $fake_home_dir -type f) > checksums
  cd $fake_home_dir
  md5sum existing_file.txt parks/yellowstone/test1.txt parks/yosemite/test2.txt parks/arches/test3.txt > $tmp_dir/target_files_checksums
  cd -

  # Act
  run make HOME_DIR=${fake_home_dir}
  run make HOME_DIR=${fake_home_dir} clone

  # Assert
  assert_output --partial "Cloning driftcan files from ${fake_home_dir}/ to ${PWD}"
  assert_output --partial "Updating git bundles from ${fake_home_dir}/ to ${PWD}"

  # creates a .manifest file
  run test -s .manifest
  assert_success
  run test ! -s .manifest-bundles
  assert_success

  # doesn't modify home dir
  run tree $fake_home_dir
  assert_output "$existing_dir_snapshot"
  run md5sum --check checksums
  assert_success

  # clones the files
  run md5sum --check target_files_checksums
  assert_success
}

@test "Creates links for driftcan-link files" {
  # Arrange
  fake_home_dir=$(mktemp -d)
  echo "an existing file" > $fake_home_dir/existing_file.txt
  touch existing_file.txt.driftcan-link
  mkdir -p $fake_home_dir/parks/{yellowstone,yosemite}
  echo "a file in a directory" > $fake_home_dir/parks/yellowstone/test1.txt
  mkdir -p $(dirname parks/yellowstone/test1.txt)
  touch parks/yellowstone/test1.txt.driftcan-link
  echo "a file in a directory" > $fake_home_dir/parks/yosemite/test2.txt
  mkdir -p $(dirname parks/yosemite/test2.txt)
  touch parks/yosemite/test2.txt.driftcan-link
  mkdir -p $fake_home_dir/parks/arches/
  echo "a file in a directory" > $fake_home_dir/parks/arches/test3.txt
  touch parks/arches.driftcan-link
  existing_dir_snapshot=$(tree $fake_home_dir)
  md5sum $(find $fake_home_dir -type f) > checksums
  cd $fake_home_dir
  md5sum existing_file.txt parks/yellowstone/test1.txt parks/yosemite/test2.txt parks/arches/test3.txt > $tmp_dir/target_files_checksums
  cd -

  # Act
  run make HOME_DIR=${fake_home_dir}
  run make HOME_DIR=${fake_home_dir} clone

  # Assert
  assert_output --partial "Linking driftcan-link files from ${fake_home_dir}/ to ${PWD}"

  # creates a .manifest-link file
  run test -s .manifest-links
  assert_success
  run test ! -s .manifest
  assert_success
  run test ! -s .manifest-bundles
  assert_success

  # doesn't modify home dir
  run tree $fake_home_dir
  assert_output "$existing_dir_snapshot"
  run md5sum --check checksums
  assert_success

  # links the files
  run md5sum --check target_files_checksums
  assert_success
}

@test "Can remove all tracked files by using 'make clean'" {
  # Arrange
  fake_home_dir=$(mktemp -d)
  echo "an existing file" > $fake_home_dir/existing_file.txt
  touch existing_file.txt.driftcan
  mkdir -p $fake_home_dir/parks/{yellowstone,yosemite}
  echo "a file in a directory" > $fake_home_dir/parks/yellowstone/test1.txt
  mkdir -p $(dirname parks/yellowstone/test1.txt)
  touch parks/yellowstone/test1.txt.driftcan
  echo "a file in a directory" > $fake_home_dir/parks/yosemite/test2.txt
  mkdir -p $(dirname parks/yosemite/test2.txt)
  touch parks/yosemite/test2.txt.driftcan
  existing_dir_snapshot=$(tree $fake_home_dir)
  md5sum $(find $fake_home_dir -type f) > checksums
  cd $fake_home_dir
  md5sum existing_file.txt parks/yellowstone/test1.txt parks/yosemite/test2.txt > $tmp_dir/target_files_checksums
  cd -

  # Act
  make HOME_DIR=${fake_home_dir}
  make HOME_DIR=${fake_home_dir} clone
  run make HOME_DIR=${fake_home_dir} clean

  # Assert
  assert_output --partial "Removing driftcan files from ${PWD}"

  # deletes .manifest file
  run test ! -e .manifest
  assert_success
  run test ! -e .manifest-bundles
  assert_success

  # doesn't modify home dir
  run tree $fake_home_dir
  assert_output "$existing_dir_snapshot"
  run md5sum --check checksums
  assert_success

  # deletes only the files created by the .driftcan
  for f in existing_file.txt parks/yellowstone/test1.txt parks/yosemite/test2.txt; do
    run test ! -e $f
    assert_success
    run test -e $f.driftcan
    assert_success
  done
}
