[![CircleCI](https://circleci.com/gh/weseek/mongodb-awesome-backup/tree/master.svg?style=shield)](https://circleci.com/gh/weseek/mongodb-awesome-backup/tree/master)

What is mongodb-awesome-backup?
-------------------------------

mongodb-awesome-backup is the collection of scripts which backup MongoDB databases to Amazon S3.


Requirements
------------

* Amazon IAM Access Key ID/Secret Access Key
  * which must have the access lights of the target Amazon S3 bucket.

OR

* Google Cloud Interoperable storage access keys (see https://cloud.google.com/storage/docs/migrating#keys)

Usage
-----
Note that either AWS_ or GCP_ vars are required not both.

```bash
docker run --rm \
  -e AWS_ACCESS_KEY_ID=<Your IAM Access Key ID> \
  -e AWS_SECRET_ACCESS_KEY=<Your IAM Secret Access Key> \
  [ -e GCP_ACCESS_KEY_ID=<Your GCP Access Key> \
  -e GCP_SECRET_ACCESS_KEY=<Your GCP Secret> \
  -e GCP_PROJECT_ID=<Your GCP Project ID> ]\
  -e TARGET_BUCKET_URL=<Target Bucket URL ([s3://...|gs://...])> \
  [ -e BACKUPFILE_PREFIX=<Prefix of Backup Filename (default: "backup") \ ]
  [ -e MONGODB_HOST=<Target MongoDB Host (default: "mongo")> \ ]
  [ -e MONGODB_DBNAME=<Target DB name> \ ]
  [ -e MONGODB_USERNAME=<DB login username> \ ]
  [ -e MONGODB_PASSWORD=<DB login password> \ ]
  [ -e MONGODB_AUTHDB=<Authentication DB name> \ ] 
  weseek/mongodb-awesome-backup
```

and after running this, `backup-YYYYMMdd.tar.bz2` will be placed on Target S3 Bucket.

### How to backup in cron mode

1. modify crontab file
  `$ vim crontab/root`
1. confirm that the permission of "./crontab/root" is "root:root"
1. execute docker container in cron mode

```bash
docker run --rm \
  -e AWS_ACCESS_KEY_ID=<Your IAM Access Key ID> \
  -e AWS_SECRET_ACCESS_KEY=<Your IAM Secret Access Key> \
  [ -e GCP_ACCESS_KEY_ID=<Your GCP Access Key> \
  -e GCP_SECRET_ACCESS_KEY=<Your GCP Secret> \
  -e GCP_PROJECT_ID=<Your GCP Project ID> ]\
  -e TARGET_BUCKET_URL=<Target Bucket URL ([s3://...|gs://...])> \
  -e CRONMODE=true \
  -e CRON_EXPRESSION=<Cron expression (ex. "CRON_EXPRESSION=0 4 * * *" if you want to run at 4:00 every day)> \
  [ -e BACKUPFILE_PREFIX=<Prefix of Backup Filename (default: "backup") \ ]
  [ -e MONGODB_HOST=<Target MongoDB Host (default: "mongo")> \ ]
  [ -e MONGODB_DBNAME=<Target DB name> \ ]
  [ -e MONGODB_USERNAME=<DB login username> \ ]
  [ -e MONGODB_PASSWORD=<DB login password> \ ]
  [ -e MONGODB_AUTHDB=<Authentication DB name> \ ] 
  weseek/mongodb-awesome-backup
```

### How to restore

You can use "**restore**" command to restore database from backup file.

```bash
docker run --rm \
  -e AWS_ACCESS_KEY_ID=<Your IAM Access Key ID> \
  -e AWS_SECRET_ACCESS_KEY=<Your IAM Secret Access Key> \
  [ -e GCP_ACCESS_KEY_ID=<Your GCP Access Key> \
  -e GCP_SECRET_ACCESS_KEY=<Your GCP Secret> \
  -e GCP_PROJECT_ID=<Your GCP Project ID> ]\
  -e TARGET_BUCKET_URL=<Target Bucket URL ([s3://...|gs://...])> \
  -e TARGET_FILE=<Target S3 or GS file name to restore> \
  [ -e MONGODB_HOST=<Target MongoDB Host (default: "mongo")> \ ]
  [ -e MONGODB_DBNAME=<Target DB name> \ ]
  [ -e MONGODB_USERNAME=<DB login username> \ ]
  [ -e MONGODB_PASSWORD=<DB login password> \ ]
  [ -e MONGODB_AUTHDB=<Authentication DB name> \ ] 
  [ -e MONGORESTORE_OPTS=<Options list of mongorestore> \ ]
  weseek/mongodb-awesome-backup restore
```


Environment variables
---------

### For `backup`, `prune`, `list`

#### Required

| Variable              | Description                                                           | Default |
| --------------------- | --------------------------------------------------------------------- | ------- |
| AWS_ACCESS_KEY_ID     | Your IAM Access Key ID                                                |         |
| AWS_SECRET_ACCESS_KEY | Your IAM Secret Access Key                                            |         |
| GCP_ACCESS_KEY_ID     | Your GCP Access Key                                                   |         |
| GCP_SECRET_ACCESS_KEY | Your GCP Secret                                                       |         |
| GCP_PROJECT_ID        | Your GCP Project ID                                                   |         |
| TARGET_BUCKET_URL     | Target Bucket URL ([s3://...\|gs://...]). **URL is needed to be end with '/'**  |         |

#### Optional

| Variable          | Description                                                                                                                                                                   | Default |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| BACKUPFILE_PREFIX | Prefix of Backup Filename                                                                                                                                                     | backup  |
| MONGODB_HOST      | Target MongoDB Host                                                                                                                                                           | mongo   |
| MONGODB_DBNAME    | Target DB name                                                                                                                                                                | -       |
| MONGODB_USERNAME  | DB login username                                                                                                                                                             | -       |
| MONGODB_PASSWORD  | DB login password                                                                                                                                                             | -       |
| MONGODB_AUTHDB    | Authentication DB name                                                                                                                                                        | -       |
| CRONMODE          | If set "true", this container is executed in cron mode.  In cron mode, the script will be executed with the specified arguments and at the time specified by CRON_EXPRESSION. | "false" |
| CRON_EXPRESSION   | Cron expression (ex. "CRON_EXPRESSION=0 4 * * *" if you want to run at 4:00 every day)                                                                                        | -       |

### For `restore`

#### Required

| Variable              | Description                                                                         |     |
| --------------------- | ----------------------------------------------------------------------------------- | --- |
| AWS_ACCESS_KEY_ID     | Your IAM Access Key ID                                                              |     |
| AWS_SECRET_ACCESS_KEY | Your IAM Secret Access Key                                                          |     |
| GCP_ACCESS_KEY_ID     | Your GCP Access Key                                                                 |     |
| GCP_SECRET_ACCESS_KEY | Your GCP Secret                                                                     |     |
| GCP_PROJECT_ID        | Your GCP Project ID                                                                 |     |
| TARGET_BUCKET_URL     | Target Bucket URL ([s3://...\|gs://...]). **URL is needed to be end with '/'**      |     |
| TARGET_FILE           | Target S3 or GS file name to restore                                                |     |

#### Optional

| Variable          | Description                               | Default |
| ----------------- | ----------------------------------------- | ------- |
| MONGODB_HOST      | Target MongoDB Host                       | mongo   |
| MONGODB_DBNAME    | Target DB name                            | -       |
| MONGODB_USERNAME  | DB login username                         | -       |
| MONGODB_PASSWORD  | DB login password                         | -       |
| MONGODB_AUTHDB    | Authentication DB name                    | -       |
| MONGORESTORE_OPTS | Options list of mongorestore. (ex --drop) | -       |
