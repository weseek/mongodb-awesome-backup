#!/bin/bash -e

if [ -n "${GOOGLE_PROJECT_ID}" ] && [ -n "${GCP_SERVICE_ACCOUNT_KEY}" ]; then
  # Using GCP service account authorization
  echo ${GCP_SERVICE_ACCOUNT_KEY} | gcloud auth activate-service-account --key-file=-
  gcloud --quiet config set project ${GOOGLE_PROJECT_ID}
elif [ -n "${GCP_ACCESS_KEY_ID}" ] && [ -n "${GCP_SECRET_ACCESS_KEY}" ]; then
  # Using HMAC authorization
  # Expand all variables in "/tmp/.boto"
  envsubst < /tmp/.boto > /root/.boto
else
  echo 'Can not authorizaed. You should set service account authorization or HMAC authorization.'
  exit 1
fi

# REMOVE ALL OBJECTS in GCS bucket
gsutil ls ${TARGET_BUCKET_URL}
gsutil rm -rf ${TARGET_BUCKET_URL}**

# Copy fixture file which is used in test restoring
gsutil cp dummy-backup-20180622000000.tar.bz2 ${TARGET_BUCKET_URL}
