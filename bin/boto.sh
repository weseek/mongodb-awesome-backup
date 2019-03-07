#!/bin/bash -e
if [ ! `echo $TARGET_BUCKET_URL | cut -f1 -d":"` == "gs" ]; then
	exit 0
fi

GCPCLI="/root/gsutil/gsutil"
MOUNT="/mab"

if [ -n "${GCP_ACCESS_KEY_ID} ] || [ -n "${GCP_SECRET_ACCESS_KEY} ]; then
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
  if [ ! -d ${MOUNT} ]; then mkdir -p ${MOUNT}; fi
  ${GCPCLI} config -o ${MOUNT}/.boto
  cp ${MOUNT}/.boto /root/.boto
elif [ -f ${MOUNT}/.boto ]; then
  cp ${MOUNT}/.boto /root/.boto
fi
