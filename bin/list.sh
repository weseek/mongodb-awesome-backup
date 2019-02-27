#!/bin/bash -e

# start script
CWD=`/usr/bin/dirname $0`
cd $CWD
. ./functions.sh

# check parameters
if [ "x${TARGET_BUCKET_URL}" == "x" ]; then
  echo "ERROR: The environment variable TARGET_BUCKET_URL must be specified." 1>&2
  exit 1
fi

# output final file list
if [ `echo $TARGET_BUCKET_URL | cut -f1 -d":"` == "s3" ]; then
  echo "There are files below in S3 bucket:"
  s3_list_files ${TARGET_BUCKET_URL}
elif [ `echo $TARGET_BUCKET_URL | cut -f1 -d":"` == "gs" ]; then
  echo "There are files below in GS bucket:"
  gs_list_files ${TARGET_BUCKET_URL}
fi

