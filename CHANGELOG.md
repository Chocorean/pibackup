# pibackup - CHANGELOG

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
