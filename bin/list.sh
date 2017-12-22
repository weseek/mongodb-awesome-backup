#!/bin/bash -e

# start script
CWD=`/usr/bin/dirname $0`
cd $CWD
. ./functions.sh

# check parameters
if [ "x${S3_TARGET_BUCKET_URL}" == "x" ]; then
  echo "ERROR: The environment variable S3_TARGET_BUCKET_URL must be specified." 1>&2
  exit 1
fi

# output final file list
echo "There are files below in S3 bucket:"
s3_list_files ${S3_TARGET_BUCKET_URL}
