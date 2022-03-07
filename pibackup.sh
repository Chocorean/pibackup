#!/bin/bash

script_name=$(basename "$0")

function usage() {
  err "$script_name [destination_node]"
}

function err() {
  echo "$@" >&2
}

function p() {
  echo "[$script_name] $* ..."
}

function check() {
  if ! which "$1" > /dev/null; then
    err "check: $1 not found"
    exit 1
  fi
}

function check_remote() {
  if ! ssh $dest_node which "$1" > /dev/null 2>&1; then
    err "check_remote: $dest_node: $* failed"
    exit 1
  fi 
}

if [ $# -lt 0 ] && [ $# -gt 1 ]; then
  usage
  exit 1
fi

dest_node=$([[ -n "$1" ]] && echo "$1" || echo "raspian")
node_name=$(uname -n)
image_name=$node_name.img
remote_tmp='/mnt/hdd/tmp'

if [[ "$node_name" == "$dest_node" ]]; then
  check pishrink.sh
  check rotate.sh
  tmp_dir=$remote_tmp
  chown_cmd='sudo chown pi:pi'
  shrink_cmd='sudo pishrink.sh > /dev/null 2>&1'
  rotate_cmd='rotate.sh > /dev/null'
else
  check sshfs
  check_remote pishrink.sh
  check_remote rotate.sh
  tmp_dir=$(mktemp -d)
  # also mount remote dd
  p 'mounting remote disk'
  sshfs "$dest_node:/mnt/hdd/tmp" "$tmp_dir"
  chown_cmd="ssh $dest_node sudo chown pi:pi"
  shrink_cmd="ssh $dest_node sudo pishrink.sh > /dev/null 2>&1"
  rotate_cmd="ssh $dest_node rotate.sh > /dev/null"
fi

img_dst=$tmp_dir/$image_name
local_img=$remote_tmp/$image_name

# splitting dd command in half so root doesn't write the image
p 'dumping sdcard'
sudo dd if=/dev/mmcblk0 bs=4m | dd of="$img_dst" bs=4m > /dev/null

p 'setting permissions'
eval "$chown_cmd $local_img"

p 'shrinking image'
eval "$shrink_cmd $local_img"

p 'rotating previous images'
eval "$rotate_cmd $local_img /mnt/hdd/backups/$node_name 7"

# unmounting remote dir from sshfs
if [[ "$node_name" != "$dest_node" ]]; then
  p 'unmounting remote disk'
  sudo umount "$tmp_dir"
fi

