#!/bin/bash -e

# settings
MONGODB_HOST=${MONGODB_HOST:-mongo}
TARGET_FILE=${TARGET_FILE}
MONGORESTORE_OPTS=${MONGORESTORE_OPTS:-}

# start script
CWD=`/usr/bin/dirname $0`
cd $CWD
. ./functions.sh

echo "=== $0 started at `/bin/date "+%Y/%m/%d %H:%M:%S"` ==="

TMPDIR="/tmp"
TARGET_DIRNAME="mongodump"
TARGET="${TMPDIR}/${TARGET_DIRNAME}"
TAR_CMD="/bin/tar"
TAR_OPTS="jxvf"

DIRNAME=`/usr/bin/dirname ${TARGET}`
BASENAME=`/usr/bin/basename ${TARGET}`
TARBALL_FULLPATH="${TMPDIR}/${TARGET_FILE}"
TARBALL_FULLURL=${TARGET_BUCKET_URL}${TARGET_FILE}

# check parameters
if [ "x${TARGET_BUCKET_URL}" == "x" ]; then
  echo "ERROR: The environment variable TARGET_BUCKET_URL must be specified." 1>&2
  exit 1
fi
if [ "x${TARGET_FILE}" == "x" ]; then
  echo "ERROR: The environment variable TARGET_FILE must be specified." 1>&2
  exit 1
fi

if [ `echo $TARGET_BUCKET_URL | cut -f1 -d":"` == "s3" ]; then
  # download tarball from Amazon S3
  s3_copy_file ${TARBALL_FULLURL} ${TARBALL_FULLPATH}
elif [ `echo $TARGET_BUCKET_URL | cut -f1 -d":"` == "gs" ]; then
  gs_copy_file ${TARBALL_FULLURL} ${TARBALL_FULLPATH}
fi

# run tar command
echo "expands ${TARGET}..."
time ${TAR_CMD} ${TAR_OPTS} ${TARBALL_FULLPATH} -C ${DIRNAME} ${BASENAME}

# restore database
if [ "x${MONGODB_DBNAME}" != "x" ]; then
  MONGORESTORE_OPTS="--nsInclude=${MONGODB_DBNAME}.* ${MONGORESTORE_OPTS}"
fi

if [ "x${MONGODB_URI}" != "x" ]; then
  MONGORESTORE_OPTS="--uri=${MONGODB_URI} ${MONGORESTORE_OPTS}"
else
  if [ "x${MONGODB_USERNAME}" != "x" ]; then
    MONGORESTORE_OPTS="${MONGORESTORE_OPTS} -u ${MONGODB_USERNAME} -p ${MONGODB_PASSWORD}"
  fi
  if [ "x${MONGODB_AUTHDB}" != "x" ]; then
    MONGORESTORE_OPTS="${MONGORESTORE_OPTS} --authenticationDatabase ${MONGODB_AUTHDB}"
  fi
  MONGORESTORE_OPTS="-h ${MONGODB_HOST} ${MONGORESTORE_OPTS}"
fi
echo "restore MongoDB..."
mongorestore -v ${TARGET} ${MONGORESTORE_OPTS}
