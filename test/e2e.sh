#!/bin/bash -e
# End to end test script
# 
# Environment Variables
#   TEST_TARGET_IMAGE_TAG: Tag name of testing the target image is set by TEST_TARGET_IMAGE_TAG.
#                          (Default value is 'weseek/mongodb-awesome-backup')

# Settings
S3_ENDPOINT_URL="http://localhost:10080"
TEST_TARGET_IMAGE_TAG=${TEST_TARGET_IMAGE_TAG:-weseek/mongodb-awesome-backup}

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

# Wait while container exist
#   ARGS
#     $1 ... CONTAINER_NAME: container name
wait_docker_container() {
  if [ $# -ne 1 ]; then return 100; fi

  CONTAINER_NAME=$1
  CONTAINER_ID=$(docker ps -a -q -f name=/${COMPOSE_PROJECT_NAME}_${CONTAINER_NAME})
  SLEEP_TIMEOUT=30
  while [ $(docker ps -a -q -f status=exited -f name=/${COMPOSE_PROJECT_NAME}_${CONTAINER_NAME} | wc -l) -ne 1 ]; do
    sleep 1

    SLEEP_TIMEOUT=$(expr ${SLEEP_TIMEOUT} - 1)
    if [ ${SLEEP_TIMEOUT} -le 0 ]; then
      exit 101;
    fi
  done
}

# Wait while container exist
#   ARGS
#     $1 ... CONTAINER_NAME: container name
#     $2 ... DOCKER_STOP_OPT: options of docker stop
stop_docker_container() {
  if [ $# -le 1 ]; then return 100; fi

  CONTAINER_NAME=$1
  DOCKER_STOP_OPT=$2
  CONTAINER_ID=$(docker ps -a -q -f name=/${COMPOSE_PROJECT_NAME}_${CONTAINER_NAME})
  docker stop ${DOCKER_STOP_OPT} ${CONTAINER_ID}
}

# Start test script
CWD=$(dirname $0)
cd $CWD

# Read environment variables of Docker
. .env

TODAY=`/bin/date +%Y%m%d` # It is used to generate file name to restore

# Clean up before start s3proxy and mongodb
TODAY=${TODAY} \
  docker-compose down

# Start s3proxy and mongodb
TODAY=${TODAY} \
  docker-compose up --build init_s3proxy_and_mongo s3proxy mongo &

# Sleep while s3 bucket is created
wait_docker_container "init_s3proxy_and_mongo"

# Execute test
TODAY=${TODAY} \
  docker-compose up --build app_default app_backup_cronmode app_restore &

# Expect for app_default
wait_docker_container "app_default"
## should upload file `backup-#{TODAY}.tar.bz2` to S3
check_s3_file_exist ${S3_ENDPOINT_URL} "app_default/backup-${TODAY}.tar.bz2"
echo 'Finished test for app_default: OK'

# Expect for app_restore
wait_docker_container "app_restore"
## should upload file `backup-#{TODAY}.tar.bz2` to S3
check_s3_file_exist ${S3_ENDPOINT_URL} "app_restore/backup-${TODAY}.tar.bz2"
## [TODO] should restored mongodb
echo 'Finished test for app_restore: OK'

# Expect for app_backup_cronmode
## stop container
##   before stop, sleep 65s because test backup is executed every minute in cron mode
stop_docker_container "app_backup_cronmode" "-t 65"
## should upload file `backup-#{TODAY}.tar.bz2` to S3
check_s3_file_exist ${S3_ENDPOINT_URL} "app_backup_cronmode/backup-${TODAY}.tar.bz2"
echo 'Finished test for app_backup_cronmode: OK'

# Clean up all containers
TODAY=${TODAY} \
  docker-compose down

echo "***** ALL TESTS ARE SUCCESSFUL *****"
