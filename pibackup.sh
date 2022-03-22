#!/bin/bash

set -eo pipefail

script_name="$(basename "$0")"
script_path="$(readlink -f "${BASH_SOURCE[0]}")"
script_dir="$(cd "$(dirname "$script_path")" &> /dev/null && pwd)"
script_version=$(cd $script_dir ; git describe --tags --abbrev=0 || echo '?? - .git missing')

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
  -d, --destination [HOSTNAME]  Name of the destination host. Default:
                                  self (\$ uname -n)
  -h, --help                    Display this message.
  -n, --image-name [NAME]       Rename the backup file as '<NAME>.img.x'.
                                  Default: self (\$ uname -n)
  -r, --rotation-count [COUNT]  Quantity of files to be kept. Default: 8
  -t, --tmp-dir [DIRECTORY]     Temporary directory to use on the remote node. Default: /tmp
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

function check_remote() {
  if ! ssh $destination which "$1" > /dev/null 2>&1; then
    err "check_remote: $destination: $* failed"
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
destination=$node_name
image_name=$node_name.img
ps_opt=''
rotation_count=8
remote_tmp_dir=/tmp  # /mnt/hdd/tmp
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
    -d | --destination)
      shift
      destination=$1
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -n | --image-name)
      shift
      image_name=$1
      ;;
    -r | --rotation-count)
      shift
      rotation_count=$1
      ;;
    -t | --tmp-dir)
      shift
      remote_tmp_dir=$1
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

# If backup is done locally
if [[ "$node_name" == "$destination" ]]; then
  check pishrink.sh
  check rotate.sh
  check mktemp
  check dd
  check umount

  # Local tmp dir is the same as remote
  local_tmp_dir=$remote_tmp_dir
  chown_cmd='sudo chown pi:pi'
  shrink_cmd='sudo pishrink.sh -a'
  rotate_cmd='rotate.sh'
else  # If remotely
  check sshfs
  check_remote pishrink.sh
  check_remote rotate.sh
  check_remote mktemp
  check_remote dd
  check_remote umount

  local_tmp_dir=$(mktemp -d)
  # also mount remote dd
  p 'Mounting remote disk'
  sshfs -C "$destination:$remote_tmp_dir" "$local_tmp_dir"
  chown_cmd="ssh $destination sudo chown pi:pi"
  shrink_cmd="ssh $destination sudo pishrink.sh -a"
  rotate_cmd="ssh $destination rotate.sh"
fi
local_img=$local_tmp_dir/$image_name
remote_img=$remote_tmp_dir/$image_name

###############################
# Actual backup starting here #
###############################
dd_cmd="sudo dd if=/dev/mmcblk0 bs=4M conv=noerror,sync | dd of="$local_img" bs=4M"

if $compress; then
  shrink_cmd="$shrink_cmd $ps_opt"
fi

if $quiet; then
  dd_cmd="$dd_cmd > /dev/null"
  shrink_cmd="$shrink_cmd > /dev/null"
  rotate_cmd="$rotate_cmd > /dev/null"
fi

# Splitting dd command in half so root doesn't write the image
p 'Dumping sdcard'
eval "$dd_cmd"

p 'Setting permissions'
eval "$chown_cmd $remote_img"

p 'Shrinking image'
eval "$shrink_cmd $remote_img"

# PiShrink will rename image if -z/-Z
if $compress; then
  remote_img="$remote_img.$z_ext"
fi

p 'Rotating previous images'
eval "$rotate_cmd $remote_img $output_dir/$node_name $rotation_count"

# Unmounting remote dir from sshfs
if [[ "$node_name" != "$destination" ]]; then
  p 'Unmounting remote disk'
  sudo umount "$local_tmp_dir"
fi

# We've made it!
p 'Done'

#######
# END #
#######

