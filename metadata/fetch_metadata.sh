#!/bin/bash

# fetch a JSON metadata for all sub-CC* in a directory

if [ $# -ne 2 ]; then
  echo "usage: $0 output_dir /path/to/derivatives"
  echo 
  echo "eg. "
  echo "    $0 json ~/vol/dhcp-derived-data/derived_02Jun2018/derivatives"
  exit 1
fi

out_dir=$1
src_dir=$2

redcap_client_dir="/home/john/GIT/redcap-client"
query_script="$redcap_client_dir/ExportAll.py"
venv="$redcap_client_dir/venv"

mkdir -p $out_dir
pushd $out_dir
source $venv/bin/activate

for subject_dir in $src_dir/sub-*; do
  subject=$(basename $subject_dir)
  subject_id=$(echo $subject | cut -d '-' -f 2)

  echo "fetching $subject_id ..."
  python "$query_script" "$subject_id"
done
