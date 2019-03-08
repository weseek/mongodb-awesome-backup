#!/bin/bash

CWD=$(dirname $0)

"$CWD/s3/e2e.sh"
"$CWD/gcs/e2e.sh"
