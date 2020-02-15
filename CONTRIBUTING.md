Contribution
============

First, thank you very much for your contributions! :tada:

Language on GitHub
------------------

You can write issues and PRs in English or Japanese.

Posting Pull Requests
---------------------

* Make sure to post PRs which based on latest master branch.
* Please make sure to pass the test suite before posting your PR.
    * Please make sure to pass the **test for S3** at least, if possible make sure to pass the **test for GCS**.

Executing test locally
----------------------

### test for S3 only

* Execute test script
    ```bash
    $ cd /path/to/mab/repository/
    $ test/s3/e2e.sh
    ```

### test for GCS only

* Prepare GCS bucket for testing only
    * Notice that **ALL OBJECTS UNDER `TARGET_BUCKET_URL` WILL BE REMOVED DURING TESTING**.
* Save auth0 credentials to `conf/.boto_oauth` by executing `gsutil`
    ```bash
    $ cd /path/to/mab/repository/
    $ gsutil config -o test/gcs/conf/.boto_oauth
    ```
    * You can also use environment variable `DOT_BOTO_OAUTH` instead of conf/.boto_oauth
        ```bash
        $ gsutil config
        $ export DOT_BOTO_OAUTH=$(cat ~/.boto)
        ```
* Set environment variables to execute gsutil
    ```bash
    $ export GCP_PROJECT_ID=<Your GCP Project ID>
    $ export GCP_ACCESS_KEY_ID=<Your GCP Access Key>
    $ export GCP_SECRET_ACCESS_KEY=<Your GCP Secret>
    $ export TARGET_BUCKET_URL=<Test GCS Bucket URL ([gs://...])>
    ```
* Execute test script
    ```bash
    $ cd /path/to/mab/repository/
    $ test/gcs/e2e.sh
    ```

### test for all

* Execute test script
    ```bash
    $ cd /path/to/mab/repository/
    $ test/all.sh
    ```
