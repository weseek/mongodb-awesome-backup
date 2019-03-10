#!/bin/bash
# End to end test script in case of storing to GCS

# Handle exit and clean up containers
#   ref. https://fumiyas.github.io/2013/12/06/tempfile.sh-advent-calendar.html
handle_exit() {
  docker-compose down -v
  exit 1
}
trap handle_exit EXIT
trap 'rc=$?; trap - EXIT; handle_exit; exit $?' INT PIPE TERM

# Assert file exist on GCS
#   ARGS
#     $1 ... GCS_FILE_PATH: File path of S3 to be checked for existence
assert_file_exists_on_gcs() {
  if [ $# -ne 1 ]; then exit 1; fi

  GCS_FILE_PATH=$1
  docker-compose run --rm app_default "list" | grep -q "${GCS_FILE_PATH}"
  if [ $? -ne 0 ]; then
    echo "assert_file_exists_on_gcs FAILED";
    echo "could not be found ${GCS_FILE_PATH} in GCS.";
    echo "list of files under ${GCS_FILE_PATH}"
    docker-compose run --rm app_default "list"
    exit 1;
  fi
}

# Assert restore is successful
assert_dummy_record_exists_on_mongodb () {
  docker-compose exec mongo bash -c 'echo -e "use dummy;\n db.dummy.find({name: \"test\"})\n" | mongo | grep -q "ObjectId"'
  if [ $? -ne 0 ]; then echo 'assert_restore_dummy_record FAILED'; exit 1; fi
}

# Start mongo service and init services
start_mongo_service_and_init_service () {
  if [ $# -eq 1 ]; then
    INIT_BOTO=$1
  fi

  # Initialize .boto config
  docker-compose up --build --no-start init
  DATASTORE_CID=$(docker-compose ps -q init)
  DATASTORE_CNAME=$(docker ps -a -f id=${DATASTORE_CID} --format {{.Names}})
  docker cp conf/.boto_hmac "${DATASTORE_CNAME}:/tmp/.boto"

  if [ -n "$INIT_BOTO" ]; then
    # Config file for GCS test
    if [ ! -f 'conf/.boto_oauth' ]; then
      echo -e "$DOT_BOTO_OAUTH" > 'conf/.boto_oauth'
    fi

    # Copy boto file to container volume
    SERVICES_WITH_BOTO=("app_with_dot_boto" "app_backup_cronmode_with_dot_boto" "app_restore_with_dot_boto")
    for ((j = 0; j < ${#SERVICES_WITH_BOTO[@]}; j++)) {
      SERVICE_NAME=${SERVICES_WITH_BOTO[j]}

      docker-compose up --build --no-start $SERVICE_NAME
      CID=$(docker-compose ps -q $SERVICE_NAME)
      CNAME=$(docker ps -a -f id=${CID} --format {{.Names}})
      docker cp conf/.boto_oauth "${CNAME}:/mab/.boto"
    }
  fi

  # Start mongodb
  docker-compose up --build mongo &
  sleep 3 # wait for the network of docker-compose to be ready
  docker-compose up --build init
}

# Start test script
CWD=$(dirname $0)
cd $CWD

TODAY=`/bin/date +%Y%m%d` # It is used to generate file name to restore

echo "=== $0 started at `/bin/date "+%Y/%m/%d %H:%M:%S"` ==="

# Validate environment variables
REQUIRED_ENVS=("GCP_ACCESS_KEY_ID" "GCP_SECRET_ACCESS_KEY" "GCP_PROJECT_ID" "TARGET_BUCKET_URL" "DOT_BOTO_OAUTH")
SATISFY=1
for ((i = 0; i < ${#REQUIRED_ENVS[@]}; i++)) {
  ENV=$(eval echo "\$${REQUIRED_ENVS[i]}")
  if [ -z "$ENV" ]; then
    echo "ERROR: The environment variable ${REQUIRED_ENVS[i]} must be specified."
    SATISFY=0
  fi
}
if [ $SATISFY -ne 1 ]; then trap EXIT; exit 1; fi

# Clean up bucket before start mongodb
docker-compose down -v

# Test default commands with HMAC/OAuth authentications
TEST_SERVICES=("app_default" "app_with_dot_boto")
WITH_BOTO=("" "true")
for ((i = 0; i < ${#TEST_SERVICES[@]}; i++)) {
  start_mongo_service_and_init_service ${WITH_BOTO[i]}

  SERVICE_NAME=${TEST_SERVICES[i]}

  # Execute app
  docker-compose up --build $SERVICE_NAME
  # Expect for app
  assert_file_exists_on_gcs "backup-${TODAY}.tar.bz2"
  # Exit test for app
  echo "Finished test for $SERVICE_NAME: OK"

  # Clean up all containers
  docker-compose down -v
}

# Test default commands in cron mode with HMAC/OAuth authentications
TEST_SERVICES=("app_backup_cronmode" "app_backup_cronmode_with_dot_boto")
WITH_BOTO=("" "true")
for ((i = 0; i < ${#TEST_SERVICES[@]}; i++)) {
  start_mongo_service_and_init_service ${WITH_BOTO[i]}

  SERVICE_NAME=${TEST_SERVICES[i]}

  # Execute app in cron mode
  docker-compose up --build $SERVICE_NAME &
  sleep 65 # wait for the network of docker-compose to be ready, and wait until test backup is executed at least once.
  docker-compose stop $SERVICE_NAME
  # Expect for app_backup_cronmode
  assert_file_exists_on_gcs "backup-${TODAY}.tar.bz2"
  # Exit test for app_restore
  echo "Finished test for $SERVICE_NAME: OK"

  # Clean up all containers
  docker-compose down -v
}

# Test restore command with HMAC/OAuth authentications
TEST_SERVICES=("app_restore" "app_restore_with_dot_boto")
WITH_BOTO=("" "true")
for ((i = 0; i < ${#TEST_SERVICES[@]}; i++)) {
  start_mongo_service_and_init_service ${WITH_BOTO[i]}

  SERVICE_NAME=${TEST_SERVICES[i]}

  # Expect for app_restore
  docker-compose up --build $SERVICE_NAME
  # Expect for app_restore
  assert_dummy_record_exists_on_mongodb
  # Exit test for app_restore
  echo "Finished test for $SERVICE_NAME: OK"

  # Clean up all containers
  docker-compose down -v
}

# Clear trap
trap EXIT

echo "***** GCS TESTS ARE SUCCESSFUL *****"
