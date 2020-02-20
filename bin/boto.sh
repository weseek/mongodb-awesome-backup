#!/bin/bash -e
if [ "`echo $TARGET_BUCKET_URL | cut -f1 -d':'`" != "gs" ]; then
	exit 0
fi

GCPCLI="/root/google-cloud-sdk/bin/gsutil"
GCLOUDCLI="/root/google-cloud-sdk/bin/gcloud"
MOUNT="/mab"

if [ -n "${GOOGLE_PROJECT_ID}" ] && [ -n "${GCP_SERVICE_ACCOUNT_KEY}" ]; then
  # Using GCP service account authorization
  echo ${GCP_SERVICE_ACCOUNT_KEY} | ${GCLOUDCLI} auth activate-service-account --key-file=-
  ${GCLOUDCLI} --quiet config set project ${GOOGLE_PROJECT_ID}
elif [ -n "${GCP_ACCESS_KEY_ID}" ] && [ -n "${GCP_SECRET_ACCESS_KEY}" ]; then
  # Using HMAC authorization
  cat <<- HERE > /root/.boto
[Credentials]

gs_access_key_id = $GCP_ACCESS_KEY_ID
gs_secret_access_key = $GCP_SECRET_ACCESS_KEY

[Boto]

https_validate_certificates = True

[GoogleCompute]

[GSUtil]

content_language = en

default_api_version = 1

default_project_id = $GCP_PROJECT_ID

[OAuth2]
HERE
elif [ ! -f ${MOUNT}/.boto ]; then
  # Using interactive authorization
  if [ ! -d ${MOUNT} ]; then mkdir -p ${MOUNT}; fi
  ${GCPCLI} config -o ${MOUNT}/.boto
  cp ${MOUNT}/.boto /root/.boto
elif [ -f ${MOUNT}/.boto ]; then
  # Using mounted `.boto` file authorization
  cp ${MOUNT}/.boto /root/.boto
fi
