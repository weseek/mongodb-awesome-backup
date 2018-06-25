#!/bin/bash -e
# End to end test script

# Settings
S3_ENDPOINT_URL="http://localhost:10080"

# assert file exist on s3
#   ARGS
#     $1 ... ENDPOINT_URL: Endpoint URL of S3
#     $2 ... S3_FILE_PATH: File path of S3 to be checked for existence
assert_file_exists_on_s3() {
  if [ $# -ne 2 ]; then return 100; fi

  ENDPOINT_URL=$1
  S3_FILE_PATH=$2
  HTTP_OK=$(curl -I -L --silent "${ENDPOINT_URL}/${S3_FILE_PATH}" 2>&1 | grep -e '^HTTP/.\+200 OK')
  if [ "x${HTTP_OK}" = "x" ]; then echo 'assert_file_exists_on_s3 FAILED'; exit 1; fi
}

# assert restore successful
assert_dummy_record_exists_on_mongodb () {
  docker-compose exec mongo bash -c 'echo -e "use dummy;\n db.dummy.find({name: \"test\"})\n" | mongo | grep -q "ObjectId"'
  if [ $? -ne 0 ]; then echo 'assert_restore_dummy_record FAILED'; exit 1; fi
}

# Wait while container exist
#   ARGS
#     $1 ... CONTAINER_NAME: container name
wait_docker_container() {
  if [ $# -ne 1 ]; then exit 100; fi

  CONTAINER_NAME=$1
  SLEEP_TIMEOUT=30
  while [ $(docker ps -a -q -f status=exited -f name=/${COMPOSE_PROJECT_NAME}_${CONTAINER_NAME}_ | wc -l) -ne 1 ]; do
    sleep 1

    SLEEP_TIMEOUT=$(expr ${SLEEP_TIMEOUT} - 1)
    if [ ${SLEEP_TIMEOUT} -le 0 ]; then
      exit 101;
    fi
  done
}

# Start test script
CWD=$(dirname $0)
cd $CWD

# Read environment variables of Docker
. .env

TODAY=`/bin/date +%Y%m%d` # It is used to generate file name to restore

# Clean up before start s3proxy and mongodb
docker-compose down -v

# Start s3proxy and mongodb
docker-compose up --build init s3proxy mongo &

# Wait while init exist
wait_docker_container "init"

# Execute test
docker-compose up --build app_default app_backup_cronmode app_restore &

# Expect for app_default
wait_docker_container "app_default"
## should upload file `backup-#{TODAY}.tar.bz2` to S3
assert_file_exists_on_s3 ${S3_ENDPOINT_URL} "app_default/backup-${TODAY}.tar.bz2"
echo 'Finished test for app_default: OK'

# Expect for app_restore
wait_docker_container "app_restore"
## should restored mongodb
assert_dummy_record_exists_on_mongodb
echo 'Finished test for app_restore: OK'

# Expect for app_backup_cronmode
## stop container
##   before stop, sleep 65s because test backup is executed every minute in cron mode
docker-compose stop -t 65 "app_backup_cronmode"
## should upload file `backup-#{TODAY}.tar.bz2` to S3
assert_file_exists_on_s3 ${S3_ENDPOINT_URL} "app_backup_cronmode/backup-${TODAY}.tar.bz2"
echo 'Finished test for app_backup_cronmode: OK'

# Clean up all containers
docker-compose down -v

echo "***** ALL TESTS ARE SUCCESSFUL *****"
