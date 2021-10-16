# DriftCan

Script for backing up files from a home directory to another directory and also
restoring files back to the home directory.

_This is a work in progress and may change a lot._

## Why?

I usually run into these problems when simply using a backup drive and copying files to it.

* With multiple backups on different drives; it is hard to know which one is the most up to date.
* Files stored on the drive could be compromised if not encrypted.
* Requires manually running the backup on the main computer.
* Requires duplicating the backup to other backup drives manually.
* Hard to know which files need to be backed up and which are not necessary.
* All duplicated backup drives will need to have the minimum space needed.

## Usage

In the backup directory; create empty `example.driftcan` files for paths that should be
backed up.  For Git repositories; create empty `example-repo.driftcan-bundle` files.
Copy the `Makefile` from this project to the backup directory that has the
`.driftcan` files. Execute the `make` command in that backup directory and then
execute the `make clone` command to rsync all the files referred to by the driftcan
files.

```bash
#ls $HOME/
# example example-repo Documents/ other-stuff
#cp Makefile /path/to/backup-directory/
#touch /path/to/backup-directory/example.driftcan
#touch /path/to/backup-directory/Documents.driftcan
#touch /path/to/backup-directory/example-repo.driftcan-bundle

# In your backup directory (usually on an external drive)
#cd /path/to/backup-directory
#make
#make clone
#ls /path/to/backup-directory/
# example example.driftcan 
# Documents/ Documents.driftcan
# example-repo example-repo.driftcan-bundle
```

_TODO_ Add more documentation.  For now, review the [Makefile](Makefile) in
order to understand what it does.

## Testing with Bats

Uses [Bats-core: Bash Automated Testing
System](https://github.com/bats-core/bats-core) to run unit tests.  The
dependencies for using bats-core are installed via git submodules.


```bash
# Run all unit tests (test/*.bats)
./test.sh

# Or watch for changes and run tests
./dev.sh
```
