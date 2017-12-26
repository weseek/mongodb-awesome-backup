#!/bin/bash -ex

# settings
BACKUPFILE_PREFIX=${BACKUPFILE_PREFIX:-backup}
MONGODB_HOST=${MONGODB_HOST:-mongo}
TODAY=`/bin/date +%Y%m%d`
BACKUPEDDAY=${BACKUPEDDAY:-$TODAY}

# start script
CWD=`/usr/bin/dirname $0`
cd $CWD
. ./functions.sh

MONGORESTORE_OPTS=""

echo "=== $0 started at `/bin/date "+%Y/%m/%d %H:%M:%S"` ==="


TMPDIR="/tmp"
TARGET_DIRNAME="mongodump"
TARGET="${TMPDIR}/${TARGET_DIRNAME}"
TAR_CMD="/bin/tar"
TAR_OPTS="jxvf"

DIRNAME=`/usr/bin/dirname ${TARGET}`
BASENAME=`/usr/bin/basename ${TARGET}`
TARBALL="${BACKUPFILE_PREFIX}-${BACKUPEDDAY}.tar.bz2"
TARBALL_FULLPATH="${TMPDIR}/${TARBALL}"

S3_TARBALL_FULLURL=${S3_TARGET_BUCKET_URL}${TARBALL}


# check parameters
if [ "x${S3_TARGET_BUCKET_URL}" == "x" ]; then
  echo "ERROR: The environment variable S3_TARGET_BUCKET_URL must be specified." 1>&2
  exit 1
fi

# download tarball from Amazon S3
s3_pull_file ${S3_TARBALL_FULLURL} ${TARBALL_FULLPATH}

# run tar command
echo "expands ${TARGET}..."
time ${TAR_CMD} ${TAR_OPTS} ${TARBALL_FULLPATH} -C ${DIRNAME} ${BASENAME}


# restore database
if [ "x${MONGODB_DBNAME}" != "x" ]; then
  MONGORESTORE_OPTS="${MONGORESTORE_OPTS} -d ${MONGODB_DBNAME}"
  TARGET=${TARGET}/${MONGODB_DBNAME}
fi
if [ "x${MONGODB_USERNAME}" != "x" ]; then
  MONGORESTORE_OPTS="${MONGORESTORE_OPTS} -u ${MONGODB_USERNAME} -p ${MONGODB_PASSWORD}"
fi
if [ "x${MONGODB_AUTHDB}" != "x" ]; then
  MONGORESTORE_OPTS="${MONGORESTORE_OPTS} --authenticationDatabase ${MONGODB_AUTHDB}"
fi
echo "restore MongoDB..."
mongorestore -h ${MONGODB_HOST} --drop -v ${TARGET} ${MONGORESTORE_OPTS}

# delete tarball if restore was successfully over
if [ -d ${TMPDIR}/${TARGET_DIRNAME} ]; then
  rm -rf ${TMPDIR}/${TARGET_DIRNAME}
fi
