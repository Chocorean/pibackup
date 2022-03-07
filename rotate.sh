#!/bin/bash

# rotate.sh
# version 1.0
#
# Move a file to another folder and rotate previous versions.

usage() {
  cat 2>&1 <<- END
usage: $(basename $0) <target> <dst_dir> <count>
END
}

if [[ $# -ne 3 ]]; then
  usage
  exit 1
fi

src=$1    # Path to the file to rotate
dst=$2    # Directory in which $1 is copied
count=$3  # How many files do we want to keep

error () {
  echo "error: $1" >&2
  exit 1
}

[[ -f $src ]] || error "\$1: '$src' is not a file"
[[ -d $dst ]] || error "\$2: '$dst' is not a directory"
[[ $count =~ ^-?[0-9]+$ ]] || error "\$3: '$count' is not a positive integer"
[[ $count -gt 0 ]] || error "\$3: '$count' is not positive"

filename="$(basename $src)"

for i in $(seq 0 $((count-2)) | tac)
do
  target="$dst/$filename.$i"
  test -e "$target" && mv "$target" "$dst/$filename.$((i+1))"
  # empty command to avoid exit if test fails
  :;
done
mv "$src" "$dst/$filename.0"

