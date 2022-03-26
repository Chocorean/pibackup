#!/bin/bash

set -eo pipefail

script_name="$(basename "$0")"
script_path="$(readlink -f "${BASH_SOURCE[0]}")"
script_dir="$(cd "$(dirname "$script_path")" &> /dev/null && pwd)"
script_version=$(cd $script_dir ; git describe --tags --abbrev=0 || cat VERSION)

#######################
# print related stuff #
#######################

function err() {
  echo "$1 $2 $3" >&2
}

function p() {
  $quiet || echo "[$script_name] $* ..."
}


#####################
# CLI related stuff #
#####################

function usage() {
  cat << END
---
$script_name $script_version
---

usage: $script_name -o <output> [options]

Required parameters:
  -o, --output-dir [DIRECTORY]  Where backup will be saved and rotated.

Optional parameters:
  -h, --help                    Display this message.
  -n, --image-name [NAME]       Rename the backup file as '<NAME>.img.x'.
                                  Default: self (\$ uname -n)
  -r, --rotation-count [COUNT]  Quantity of files to be kept. Default: 8
  -t, --tmp-dir [DIRECTORY]     Temporary directory to use on the remote node. Default: /tmp
  -T, --target [HOSTNAME]       Name of the host to backup. Default: self
  -q, --quiet                   Silent mode.
  -z, --gzip                    Compress image using gzip.
  -Z, --xz                      Compress image using xz.
END
}

read_var() {
  if [ -n "$1" ]; then
    echo $1
  else
    err "$(usage)"
    exit 1
  fi
}

##########################
# pibackup related stuff #
##########################

function check() {
  if ! which "$1" > /dev/null; then
    err "check: $1 not found"
    exit 1
  fi
}

#########
# BEGIN #
#########

node_name=$(uname -n)

######################
# Reading parameters #
######################

# Preparing optional parameters with default values
compress=false
image_name=$target.img
ps_opt=''
rotation_count=8
tmp_dir=/tmp  # /mnt/hdd/tmp
target=$node_name
quiet=false
z_ext=''

# This one is requried and has to be defined later
#output_dir=/mnt/hdd/backups/$node_name

# Reading parameters
while [ -n "$1" ]; do
  case "$1" in
    # Required
    -o | --output-dir)
      shift
      output_dir=$1
      ;;
    # Optional
    -h | --help)
      usage
      exit 0
      ;;
    -n | --image-name)
      shift
      image_name=$1
      force_name=true
      ;;
    -r | --rotation-count)
      shift
      rotation_count=$1
      ;;
    -t | --tmp-dir)
      shift
      tmp_dir=$1
      ;;
    -T | --target)
      shift
      target=$1
      if [ -z "$force_name" ]; then
        image_name="$target.img"
      fi
      ;;
    -q | --quiet)
      quiet=true
      ;;
    -z | --gzip)
      compress=true
      ps_opt='-z'
      z_ext='gz'
      ;;
    -Z | --xz)
      compress=true
      ps_opt='-Z'
      z_ext='xz'
      ;;
    # Default
    *)
      err "$(usage)"
      exit 1
      ;;
  esac
  shift
done

# Checking required parameters
if [ -z "$output_dir" ]; then
  err 'Missing required parameter: -o, --output-dir'
  err "$(usage)"
  exit 1
fi

########
# Init #
########

image_path=$tmp_dir/$image_name

# Making sure requirements are satisfied
check pishrink.sh
check rotate.sh

# Defining commands
chown_cmd='sudo chown pi:pi'
shrink_cmd='sudo pishrink.sh -a'
rotate_cmd="rotate.sh"

# dd command is made of two parts
if [[ "$node_name" == "$target" ]]; then  # local
  dd_cmd='sudo dd if=/dev/mmcblk0 bs=4M conv=noerror,sync'
else  # remote
  dd_cmd="ssh $target sudo dd if=/dev/mmcblk0 bs=4M conv=noerror,sync"
fi
if $quiet; then
  dd_cmd="$dd_cmd 2> /dev/null | dd of=$image_path bs=4M 2> /dev/null"
else
  dd_cmd="$dd_cmd | dd of=$image_path bs=4M"
fi

# Compression options
if $compress; then
  shrink_cmd="$shrink_cmd $ps_opt"
fi

# More quiet commands
if $quiet; then
  shrink_cmd="$shrink_cmd > /dev/null"
  rotate_cmd="$rotate_cmd > /dev/null"
fi

###############################
# Actual backup starting here #
###############################

# Splitting dd command in half so root doesn't write the image
p 'Dumping sdcard'
eval "$dd_cmd"

p 'Setting permissions'
eval "$chown_cmd $image_path"

p 'Shrinking image'
eval "$shrink_cmd $image_path"

# PiShrink will rename image if -z/-Z
if $compress; then
  image_path="$image_path.$z_ext"
fi

p 'Rotating previous images'
mkdir -p $output_dir/$target
eval "$rotate_cmd $image_path $output_dir/$target $rotation_count"

# We've made it!
p 'Done'

#######
# END #
#######

