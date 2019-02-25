#!/bin/bash -x
if [ ! `echo $TARGET_BUCKET_URL | cut -f1 -d":"` == "gs" ]; then
	exit 0
fi

GCPCLI="/root/gsutil/gsutil"
MOUNT="/mab"

if [ -z "${GCP_ACCESS_KEY_ID} ] || [ -z "${GCP_SECRET_ACCESS_KEY} ]; then
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
  ${GCPCLI} config -o /mab/.boto
  cp ${MOUNT}/.boto /root/.boto
elif [ -f ${MOUNT}/.boto ]; then
  cp ${MOUNT}/.boto /root/.boto
fi
