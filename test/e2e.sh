#!/bin/bash -e

# Read environment variables of Docker
. .env

# Settings
S3_ENDPOINT_URL="http://localhost:10080"
AWSCLIOPT="--endpoint-url=http://s3proxy:80/"
TODAY=`/bin/date +%Y%m%d` # It is used to generate file name to restore
LAST_TEST_CONTAINER=""

# Exit test
handle_exit() {
  if [ -n "${TESTING_CONTAINER}" ]; then dump_all_log; fi
  TODAY=${TODAY} \
    docker-compose -f test/docker-compose.yml down
}
trap handle_exit EXIT
trap 'rc=$?; trap - EXIT; handle_exit; exit $?' INT PIPE TERM

# Dump all logs of containers
dump_all_log() {
  CONTAINER_ID_LIST=$(docker-compose ps -q)
  echo "${CONTAINER_ID_LIST}" | while read CONTAINER_ID
  do
    echo "===== container logs ====="
    echo "$(docker ps -a -f id=${CONTAINER_ID})"
    echo "--------------------------"
    docker logs ${CONTAINER_ID}
  done
}

# check a S3 file is exist
check_s3_file_exist() {
  if [ $# -ne 2 ]; then return 100; fi

  ENDPOINT_URL=$1
  S3_FILE_PATH=$2
  curl -I -L --silent "${ENDPOINT_URL}/${S3_FILE_PATH}" 2>&1 | grep -e '^HTTP/' | grep -q '200 OK'
}

# start test script
CWD=$(dirname $0)
cd $CWD
cd ..

TODAY=${TODAY} \
  docker-compose -f test/docker-compose.yml up -d --build

# sleep because test backup is executed every minutes in cron mode
sleep 65

# app_default
TESTING_CONTAINER="app_default"
## should upload file `backup-#{TODAY}.tar.bz2` to S3
check_s3_file_exist ${S3_ENDPOINT_URL} "app_default/backup-${TODAY}.tar.bz2"
## exit code should be 0
##   see. https://blog.m4i.jp/2016/02/16/docker-ps-filter
test $(docker ps -a -q -f exited=0 -f name=/${COMPOSE_PROJECT_NAME}_app_default | wc -l) -eq 1

# Test for app_restore
TESTING_CONTAINER="app_restore"
## should upload file `backup-#{TODAY}.tar.bz2` to S3
check_s3_file_exist ${S3_ENDPOINT_URL} "app_restore/backup-${TODAY}.tar.bz2"
## exit code should be 0
##   see. https://blog.m4i.jp/2016/02/16/docker-ps-filter
test $(docker ps -a -q -f exited=0 -f name=/${COMPOSE_PROJECT_NAME}_app_restore | wc -l) -eq 1

# test for backup in cron mode
TESTING_CONTAINER="app_backup_cronmode"
## should upload file `backup-#{TODAY}.tar.bz2` to S3
check_s3_file_exist ${S3_ENDPOINT_URL} "app_backup_cronmode/backup-${TODAY}.tar.bz2"

TESTING_CONTAINER=""
echo "***** ALL TESTS ARE SUCCESSFUL *****"
