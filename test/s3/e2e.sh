#!/bin/bash -xe
# End to end test script

# handle exit and clean up containers
#   ref. https://fumiyas.github.io/2013/12/06/tempfile.sh-advent-calendar.html
handle_exit() {
  docker-compose down -v
  exit 1
}
trap handle_exit EXIT
trap 'rc=$?; trap - EXIT; handle_exit; exit $?' INT PIPE TERM

# assert file exist on s3
#   ARGS
#     $1 ... S3_FILE_PATH: File path of S3 to be checked for existence
assert_file_exists_on_s3() {
  if [ $# -ne 1 ]; then exit 1; fi

  S3_FILE_PATH=$1
  docker-compose exec -T s3proxy sh -c "ls /data/${S3_FILE_PATH} >/dev/null 2>&1"
  if [ $? -ne 0 ]; then
    echo "assert_file_exists_on_s3 FAILED";
    echo "could not find /data/${S3_FILE_PATH} in s3proxy.";
    echo "list of files under /data/"
    docker-compose exec -T s3proxy sh -c "ls -alR /data/"
    exit 1;
  fi
}

# assert restore is successful
assert_dummy_record_exists_on_mongodb () {
  docker-compose exec -T mongo bash -c 'echo -e "use dummy;\n db.dummy.find({name: \"test\"})\n" | mongo | grep -q "ObjectId"'
  if [ $? -ne 0 ]; then echo 'assert_restore_dummy_record FAILED'; exit 1; fi
}

# Start test script
CWD=$(dirname $0)
cd $CWD

TODAY=`/bin/date +%Y%m%d` # It is used to generate file name to restore

echo "=== $0 started at `/bin/date "+%Y/%m/%d %H:%M:%S"` ==="

# Clean up before start s3proxy and mongodb
docker-compose down -v

# Start s3proxy and mongodb
docker-compose up --build s3proxy mongo &
sleep 3 # wait for the network of docker-compose to be ready
docker-compose up --build init

# Test default commands with ServiceAccount/HMAC/OAuth authentications
TEST_SERVICES=("app_default" "app_mongodb_uri")
for ((i = 0; i < ${#TEST_SERVICES[@]}; i++)) {
  # Execute
  docker-compose up --build ${TEST_SERVICES[i]}
  # Expect
  # Use wildcard since the time field of the filename is changed frequently.
  assert_file_exists_on_s3 "${TEST_SERVICES[i]}/backup-${TODAY}*.tar.bz2"
  # Exit test
  echo "Finished test for ${TEST_SERVICES[i]}: OK"
}

TEST_SERVICES=("app_restore" "app_restore_mongodb_uri" "app_restore_mongodb_uri_mongodb_dbname")
for ((i = 0; i < ${#TEST_SERVICES[@]}; i++)) {
  # Execute
  docker-compose up --build ${TEST_SERVICES[i]}
  # Expect
  assert_dummy_record_exists_on_mongodb
  # Exit test
  echo "Finished test for ${TEST_SERVICES[i]}: OK"
  # Clean up mongodb
  docker-compose rm -vfs mongo
  docker-compose up mongo &
}

# Expect for app_backup_cronmode
docker-compose up --build app_backup_cronmode &
sleep 65 # wait for the network of docker-compose to be ready, and wait until test backup is executed at least once.
docker-compose stop app_backup_cronmode
# Expect for app_backup_cronmode
# Use wildcard since the time field of the filename is changed frequently.
assert_file_exists_on_s3 "app_backup_cronmode/backup-${TODAY}*.tar.bz2"
# Exit test for app_restore
echo 'Finished test for app_backup_cronmode: OK'

# Clean up all containers
docker-compose down -v

# Clear trap
trap EXIT

echo "***** S3 TESTS ARE SUCCESSFUL *****"
