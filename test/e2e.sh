#!/bin/bash -e
# This shell script is end to end test program.
# 

# Settings
S3_ENDPOINT_URL="http://localhost:10080"
TODAY=`/bin/date +%Y%m%d` # It is used to generate file name to restore
LAST_TEST_CONTAINER=""
TEST_IMAGE_NAME=${TEST_IMAGE_NAME:-weseek/mongodb-awesome-backup}

# Handle exit and execute docker-compose down to remove containers
#   This function is executed when shell script is exited.
handle_exit() {
  if [ -n "${TESTING_CONTAINER}" ]; then
    echo "***** TEST FAILED *****"
    echo "failed test: ${TESTING_CONTAINER}"
  fi
  docker-compose -f docker-compose.yml down
  if [ -n "${CONTAINER_ID}"]; then
    docker stop ${CONTAINER_ID}
    docker rm ${CONTAINER_ID}
  fi
}
trap handle_exit EXIT
trap 'rc=$?; trap - EXIT; handle_exit; exit $?' INT PIPE TERM

# Check a S3 file exist
#   ARGS
#     $1 ... ENDPOINT_URL: Endpoint URL of S3
#     $2 ... S3_FILE_PATH: File path of S3 to be checked for existence
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
docker-compose -f docker-compose.yml up --build &

# Sleep while s3 bucket is created
SLEEP_TIMEOUT=30
while [ $(docker ps -a -q -f status=exited -f name=/${COMPOSE_PROJECT_NAME}_init_s3proxy_1 | wc -l) -ne 1 ]; do
  sleep 1

  SLEEP_TIMEOUT=$(expr ${SLEEP_TIMEOUT} - 1)
  if [ ${SLEEP_TIMEOUT} -le 0 ]; then
    exit 255;
  fi
done

# Test for app_default
TESTING_CONTAINER="app_default"
## execute app_default (exit code should be 0)
docker run --rm --env-file=.env \
  -e S3_TARGET_BUCKET_URL=s3://app_default/ \
  --link ${COMPOSE_PROJECT_NAME}_mongo_1:mongo \
  --link ${COMPOSE_PROJECT_NAME}_s3proxy_1:s3proxy \
  --network ${COMPOSE_PROJECT_NAME}_default \
  ${TEST_IMAGE_NAME}
## should upload file `backup-#{TODAY}.tar.bz2` to S3
check_s3_file_exist ${S3_ENDPOINT_URL} "app_default/backup-${TODAY}.tar.bz2"

# Test for app_restore
TESTING_CONTAINER="app_restore"
## execute app_restore (exit code should be 0)
docker run --rm --env-file=.env \
  -e S3_TARGET_BUCKET_URL=s3://app_restore/ \
  -e S3_TARGET_FILE=backup-${TODAY}.tar.bz2 \
  --link ${COMPOSE_PROJECT_NAME}_mongo_1:mongo \
  --link ${COMPOSE_PROJECT_NAME}_s3proxy_1:s3proxy \
  --network ${COMPOSE_PROJECT_NAME}_default \
  ${TEST_IMAGE_NAME} backup restore
## should upload file `backup-#{TODAY}.tar.bz2` to S3
check_s3_file_exist ${S3_ENDPOINT_URL} "app_restore/backup-${TODAY}.tar.bz2"
## [TODO] should restored mongodb

# Test for backup in cron mode
TESTING_CONTAINER="app_backup_cronmode"
## execute app_default
CONTAINER_ID=$(docker run -d --rm --env-file=.env \
  -e S3_TARGET_BUCKET_URL=s3://app_backup_cronmode/ \
  -e CRONMODE=true \
  -e "CRON_EXPRESSION=* * * * *" \
  --link ${COMPOSE_PROJECT_NAME}_mongo_1:mongo \
  --link ${COMPOSE_PROJECT_NAME}_s3proxy_1:s3proxy \
  --network ${COMPOSE_PROJECT_NAME}_default \
  ${TEST_IMAGE_NAME})
## stop container
##   before stop, sleep 65s because test backup is executed every minute in cron mode
docker stop -t 65 ${CONTAINER_ID} && CONTAINER_ID=""
## should upload file `backup-#{TODAY}.tar.bz2` to S3
check_s3_file_exist ${S3_ENDPOINT_URL} "app_backup_cronmode/backup-${TODAY}.tar.bz2"

TESTING_CONTAINER=""
echo "***** ALL TESTS ARE SUCCESSFUL *****"
