# notifications-antivirus

GOV.UK Notify Antivirus service. Read and write scan jobs via a scan queue.  Retrieves the supplied filename from the scan S3 bucket and uses ClamAV to scan the file. Sends the scan status back via a queue to update the notification status.

## First-time setup

This app uses dependencies that are difficult to install locally. In order to make local development easy, we run app commands through a Docker container. Run the following to set this up:

```shell
  make bootstrap
```

Because the container caches things like Python packages, you will need to run this again if you change things like "requirements.txt".

##  Environment Variables

Creating the environment.sh file. Replace [unique-to-environment] with your something unique to the environment. Your AWS credentials should be set up for notify-tools (the development/CI AWS account).

Create a local environment.sh file containing the following:

```
echo "

export NOTIFICATION_QUEUE_PREFIX='YOUR_OWN_PREFIX'

"> environment.sh
```

NOTES:

 * Replace the placeholder key and prefix values as appropriate
 * The unique prefix for the queue names prevents clashing with others' queues in shared amazon environment and enables filtering by queue name in the SQS interface.


```
source environment.sh
```

##  To run the application

```
# install dependencies, etc.
make bootstrap

# run the web app
make run-flask

# run the background tasks
make run-celery
```

##  To test the application

```
# install dependencies, etc.
make bootstrap

make test
```

If you need to run a specific command, such as a single test, you can use the `run_with_docker.sh` script. This is what `test` and other `make` rules use.

```shell
./scripts/run_with_docker.sh pytest tests/some_specific_test.py
```

## To update application dependencies

`requirements.txt` file is generated from the `requirements-app.txt` in order to pin
versions of all nested dependencies. If `requirements-app.txt` has been changed (or
we want to update the unpinned nested dependencies) `requirements.txt` should be
regenerated with

```
make freeze-requirements
```

`requirements.txt` should be committed alongside `requirements-app.txt` changes.
