#!/bin/bash
set -x

work_dir="./tmp"

function help(){
  echo "Usage: $0 /path/to/bosh_logs_path(file or folder for *.tgz)"
  echo "  provide *.tgz logs or folder"
  exit 1
}

if [ -z $1 ]; then
  help
fi

echo "==== Analyzing inputs"
if [ -f $1 ]; then
    if [[ "$1" != *".tgz" ]]; then
      help
    fi
    SOURCE_DIR=$(basename $1 ".tgz" )
    file_list=$1
elif [ -d $1 ]; then
  SOURCE_DIR=$1
  file_list=$(find $SOURCE_DIR -type f -name "*.tgz" )
fi

function untar_tgz(){
    file=$1
    echo "    file:"$file
    folder_name=$(basename $file ".tgz" )
    mkdir -p $work_dir/$folder_name
    tar xf $file -C $work_dir/$folder_name
}


echo "==== Exploding logs from the given source $1 into $work_dir ..."
for file in $file_list; do
    untar_tgz $file
done;

echo ""
echo "==== Exploding any sub *.tgz under $work_dir"
file_list=$(find $work_dir -type f -name "*.tgz" )
for file in $file_list; do
    untar_tgz $file
done;

echo ""
echo "==== Exploding any process archived logs under $work_dir"
find $work_dir -name "*.gz" | xargs gunzip -d -r

echo "COMPLETED: exploded files under $work_dir"