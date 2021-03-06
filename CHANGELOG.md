# pibackup - CHANGELOG

- 0.5 - My favorite update so far
  - Fix #9 (no need to run from remote node)
  - Fix #4 (merge rotate into main script)
  - Add a cheap-ass logo from "free" stuff
  - Update doc accordingly to new features
  - Add restore part in README
- 0.4.1 - Fix remote logic
  - Variables were not correctly set:used. Still subject to modification, but so far the correct logic is now implemented.
- 0.4 - Compression bugfix
  - Fix bug introduced in 0.3 (script was not working anymore)
  - Add 'noerror,sync' conv dd flags
  - Add -z and -Z (compression) options
  - Improve quiet mode
  - Do not suppress anymore stderr when quiet mode is on
  - Tested behavior with cron
  - Update doc
- 0.3.1 - Minor bugfix (crash when unable to get script version)
- 0.3 - Speed improvements
- 0.2 - CLI update - 03/08/22
  - Minor changes
    - Update doc
    - Add CLI behavior
      1. Required parameters:
          - `-o, --output-dir [DIRECTORY]`  Where backup will be saved and rotated.
      2. Optional parameters:
          - `-d, --destination [HOSTNAME]`  Name of the destination host. Default: self ($ uname -n)
          - `-h, --help`                    Display this message.
          - `-n, --image-name [NAME]`       Rename the backup file as '<NAME>.img.x'. Default: self ($ uname -n)
          - `-r, --rotation-count [COUNT]`  Quantity of files to be kept. Default: 8
          - `-t, --tmp-dir [DIRECTORY]`     Temporary directory to use on the remote node. Default: /tmp
          - `-q, --quiet`                   Silent mode.
    - Add `dd`, `umount` and `mktemp` to the list of paranoid checks
    - Add CHANGELOG.md
- 0.1 - Initial version - 02/08/22
