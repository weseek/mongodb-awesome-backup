Contribution
============

First, thank you very much for your contributions! :tada:

Language on GitHub
------------------

You can write issues and PRs in English or Japanese.

Posting Pull Requests
---------------------

* Make sure to post PRs which based on latest master branch.
* Please make sure to execute the test suite locally before posting your PR.
    * Executing **test for S3 is required**, and executing **test for GCS is not required**, but is expected.

Executing test locally
----------------------

### test for S3 only

* Executing test script
```
$ cd /path/to/mab/repository/
$ test/s3/e2e.sh
```

### test for GCS only

* Prepare GCS bucket for testing only
    * Notice that it **REMOVE ALL OBJECTS UNDER TARGET_BUCKET_URL**.
* Save auth0 credentials to `conf/.boto_oauth` by executing `gsutil`
```
$ gsutil config -o conf/.boto_oauth
```
* Set environment variables to execute mongo
```
$ export GCP_PROJECT_ID=<Your GCP Project ID>
$ export GCP_ACCESS_KEY_ID=<Your GCP Access Key>
$ export GCP_SECRET_ACCESS_KEY=<Your GCP Secret>
$ export TARGET_BUCKET_URL=<Test GCS Bucket URL ([gs://...])>
```
* Executing test script
```
$ cd /path/to/mab/repository/
$ test/gcs/e2e.sh
```

### test for all

* Executing test script
```
$ cd /path/to/mab/repository/
$ test/all.sh
```
