#!/bin/bash -e

# Create buckets
/usr/bin/aws --endpoint-url=http://s3proxy:80/ s3 mb s3://app_default 
/usr/bin/aws --endpoint-url=http://s3proxy:80/ s3 mb s3://app_backup_cronmode
/usr/bin/aws --endpoint-url=http://s3proxy:80/ s3 mb s3://app_restore

# Copy fixture files which are used in test restoring
/usr/bin/aws --endpoint-url=http://s3proxy:80/ s3 cp /dummy-backup-20180622.tar.bz2 s3://app_restore/
