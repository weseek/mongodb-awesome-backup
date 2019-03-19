#!/bin/bash -e

# Expand all variables in "/tmp/.boto"
envsubst < /tmp/.boto > /root/.boto

# REMOVE ALL OBJECTS in GCS bucket
gsutil ls ${TARGET_BUCKET_URL}
gsutil rm -rf ${TARGET_BUCKET_URL}

# Copy fixture file which is used in test restoring
gsutil cp dummy-backup-20180622.tar.bz2 ${TARGET_BUCKET_URL}
