What is mongodb-awesome-backup?
-------------------------------

mongodb-awesome-backup is the collection of scripts which backup MongoDB databases to Amazon S3.


Requirements
------------

* Amazon IAM Access Key ID/Secret Access Key
  * which can access to Amazon S3 buckets

Usage
-----

```bash
docker run --rm \
  -e AWS_ACCESS_KEY_ID=<Your IAM Access Key ID> \
  -e AWS_SECRET_ACCESS_KEY=<Your IAM Secret Access Key> \
  -e S3_TARGTE_BUCKET_URL=<Target S3 Bucket URL (s3://...)> \
  [ -e MONGODB_HOST=<target MongoDB Host (default: "mongo")> \ ]
  [ -e MONGODB_DBNAME=<target DB name> \ ]
  [ -e MONGODB_USERNAME=<DB login username> \ ]
  [ -e MONGODB_PASSWORD=<DB login password> \ ]
  [ -e MONGODB_AUTHDB=<Authentication DB name> \ ] 
  weseek/mongodb-awesome-backup
```
