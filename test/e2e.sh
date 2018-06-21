#!/bin/bash -e

# Settings
S3_ENDPOINT_URL="http://localhost:10080"
TODAY=`/bin/date +%Y%m%d` # It is used to generate file name to restore
LAST_TEST_CONTAINER=""
TEST_IMAGE_NAME=${TEST_IMAGE_NAME:-weseek/mongodb-awesome-backup}

# Exit test
handle_exit() {
  if [ -n "${TESTING_CONTAINER}" ]; then
    echo "***** TEST FAILED *****"
    echo "failed test: ${TESTING_CONTAINER}"
  fi
  TODAY=${TODAY} \
    docker-compose -f docker-compose.yml down
}
trap handle_exit EXIT
trap 'rc=$?; trap - EXIT; handle_exit; exit $?' INT PIPE TERM

# Check a S3 file exist
check_s3_file_exist() {
  if [ $# -ne 2 ]; then return 100; fi

  ENDPOINT_URL=$1
  S3_FILE_PATH=$2
  curl -I -L --silent "${ENDPOINT_URL}/${S3_FILE_PATH}" 2>&1 | grep -e '^HTTP/' | grep -q '200 OK'
}

# Start test script
CWD=$(dirname $0)
cd $CWD

# Read environment variables of Docker
. .env

# Start s3proxy and mongodb
TODAY=${TODAY} \
  docker-compose -f docker-compose.yml up --build &

# Sleep while s3 bucket is created
sleep 30

# Test for app_default
TESTING_CONTAINER="app_default"
## execute app_default (exit code should be 0)
docker run --rm --env-file=.env \
  -e S3_TARGET_BUCKET_URL=s3://app_default/ \
  --link mongodb_awesome_backup_test_mongodb:mongo \
  --network mongodb_awesome_backup_test_default \
  ${TEST_IMAGE_NAME}
## should upload file `backup-#{TODAY}.tar.bz2` to S3
check_s3_file_exist ${S3_ENDPOINT_URL} "app_default/backup-${TODAY}.tar.bz2"

# Test for app_restore
TESTING_CONTAINER="app_restore"
## execute app_restore (exit code should be 0)
docker run --rm --env-file=.env \
  -e S3_TARGET_BUCKET_URL=s3://app_restore/ \
  -e S3_TARGET_FILE=backup-${TODAY}.tar.bz2 \
  --link mongodb_awesome_backup_test_mongodb:mongo \
  --network mongodb_awesome_backup_test_default \
  ${TEST_IMAGE_NAME} backup restore
## should upload file `backup-#{TODAY}.tar.bz2` to S3
check_s3_file_exist ${S3_ENDPOINT_URL} "app_restore/backup-${TODAY}.tar.bz2"
## [TODO] should restored mongodb

# Test for backup in cron mode
TESTING_CONTAINER="app_backup_cronmode"
## execute app_default
docker run -d --name ${TESTING_CONTAINER} --rm --env-file=.env \
  -e S3_TARGET_BUCKET_URL=s3://app_backup_cronmode/ \
  -e CRONMODE=true \
  -e "CRON_EXPRESSION=* * * * *" \
  --link mongodb_awesome_backup_test_mongodb:mongo \
  --network mongodb_awesome_backup_test_default \
  ${TEST_IMAGE_NAME}
CONTAINER_ID=$?
## sleep because test backup is executed every minute in cron mode
sleep 65
## stop container
docker stop ${CONTAINER_ID}
## should upload file `backup-#{TODAY}.tar.bz2` to S3
check_s3_file_exist ${S3_ENDPOINT_URL} "app_backup_cronmode/backup-${TODAY}.tar.bz2"

TESTING_CONTAINER=""
echo "***** ALL TESTS ARE SUCCESSFUL *****"
