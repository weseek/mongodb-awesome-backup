#!/bin/bash -e

# settings
BACKUPFILE_PREFIX=${BACKUPFILE_PREFIX:-backup}

DELETE_DEVIDE=${DELETE_DEVIDE:-3}
DELETE_TARGET_DAYS_LEFT=${DELETE_TARGET_DAYS_LEFT:-4}

# start script
CWD=`/usr/bin/dirname $0`
cd $CWD

. ./functions.sh
PAST=`create_past_yyyymmdd ${DELETE_TARGET_DAYS_LEFT}`

# check the existence of past file
# if it exists, delete it
TARBALL_PAST="${BACKUPFILE_PREFIX}-${PAST}*.tar.bz2"

if [ `echo $TARGET_BUCKET_URL | cut -f1 -d":"` == "s3" ]; then
  s3_delete_file_if_delete_backup_day ${TARGET_BUCKET_URL}${TARBALL_PAST} ${DELETE_TARGET_DAYS_LEFT} ${DELETE_DEVIDE}
elif [ `echo $TARGET_BUCKET_URL | cut -f1 -d":"` == "gs" ]; then
  gs_delete_file_if_delete_backup_day ${TARGET_BUCKET_URL}${TARBALL_PAST} ${DELETE_TARGET_DAYS_LEFT} ${DELETE_DEVIDE}
fi
