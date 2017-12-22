#!/bin/bash -e

# settings
BACKUPFILE_PREFIX=${BACKUPFILE_PREFIX:-backup}
#S3_TARGET_BUCKET_URL=s3://...

DELETE_DEVIDE=${DELETE_DEVIDE:-3}
DELETE_TARGET_DAYS_LEFT=${DELETE_TARGET_DAYS_LEFT:-4}

# start script
CWD=`/usr/bin/dirname $0`
cd $CWD

. ./functions.sh
PAST=`create_past_yyyymmdd ${DELETE_TARGET_DAYS_LEFT}`

# check the existence of past file
# if it exists, delete it
TARBALL_PAST="${BACKUPFILE_PREFIX}-${PAST}.tar.bz2"
s3_delete_file_if_delete_backup_day ${S3_TARGET_BUCKET_URL}/${TARBALL_PAST} ${DELETE_TARGET_DAYS_LEFT} ${DELETE_DEVIDE}
