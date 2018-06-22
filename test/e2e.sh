#!/bin/bash -e
# End to end test script
# 
# Environment Variables
#   TEST_TARGET_IMAGE_TAG: Tag name of testing the target image is set by TEST_TARGET_IMAGE_TAG.
#                          (Default value is 'weseek/mongodb-awesome-backup')

# Settings
S3_ENDPOINT_URL="http://localhost:10080"
TEST_TARGET_IMAGE_TAG=${TEST_TARGET_IMAGE_TAG:-weseek/mongodb-awesome-backup}

# Handle exit and execute docker-compose down to remove containers
#   This function is executed when shell script is exited.
handle_exit() {
  if [ $(docker ps -a -q -f status=exited -f name=/${COMPOSE_PROJECT_NAME} | wc -l) -ne 0 ]; then
    echo "***** TEST FAILED *****"
  fi
  docker-compose -f docker-compose.s3mock_and_mongodb.yml down
  docker-compose -f docker-compose.e2e_test.yml down
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

TODAY=`/bin/date +%Y%m%d` # It is used to generate file name to restore

# Start s3proxy and mongodb
docker-compose -f docker-compose.s3mock_and_mongodb.yml up --build &

# Sleep while s3 bucket is created
SLEEP_TIMEOUT=30
while [ $(docker ps -a -q -f status=exited -f name=/${COMPOSE_PROJECT_NAME}_init_s3proxy_1 | wc -l) -ne 1 ]; do
  sleep 1

  SLEEP_TIMEOUT=$(expr ${SLEEP_TIMEOUT} - 1)
  if [ ${SLEEP_TIMEOUT} -le 0 ]; then
    exit 255;
  fi
done

# Execute test
TODAY=${TODAY} \
  docker-compose -f docker-compose.e2e_test.yml up --build &

# Expect for app_default
## should upload file `backup-#{TODAY}.tar.bz2` to S3
check_s3_file_exist ${S3_ENDPOINT_URL} "app_default/backup-${TODAY}.tar.bz2"

# Expect for app_restore
## should upload file `backup-#{TODAY}.tar.bz2` to S3
check_s3_file_exist ${S3_ENDPOINT_URL} "app_restore/backup-${TODAY}.tar.bz2"
## [TODO] should restored mongodb

# Expect for app_backup_cronmode
## stop container
##   before stop, sleep 65s because test backup is executed every minute in cron mode
CONTAINER_ID=$(docker run -a -q -f name=/${COMPOSE_PROJECT_NAME}_app_backup_cronmode_1)
docker stop -t 65 ${CONTAINER_ID}
## should upload file `backup-#{TODAY}.tar.bz2` to S3
check_s3_file_exist ${S3_ENDPOINT_URL} "app_backup_cronmode/backup-${TODAY}.tar.bz2"

echo "***** ALL TESTS ARE SUCCESSFUL *****"
