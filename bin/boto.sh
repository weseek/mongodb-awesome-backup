#!/bin/bash -e
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
