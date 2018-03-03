
# Automated Docker MySql Backup

This Docker image runs mysqldump to backup one or multiple databases using cron job to folder `/backups` and notifies Slack.

If SLACK vars are set, SLACK channel will be notified.

## Features

* Backup multiple MySql databases
* Slack notification
* Automatic, scheduled backups
* Nice documentation and samples
* Docker-compose file included

## Usage:

    docker run -d \
        --env MYSQL_HOST=mysql \
        --env MYSQL_PORT=5432 \
        --env MYSQL_USER=docker \
        --env MYSQL_PASSWORD=docker \
        --volume /host_folder:/backups
        myros/myql-backup

## Periodic backups

You can change the SCHEDULE environment variable like -e SCHEDULE="@daily" or SCHEDULE="@every 6h" to change its default frequency, by default is daily.

More information about the scheduling can be found [here](https://godoc.org/github.com/robfig/cron#hdr-Predefined_schedules).

## Required variables

Variable | Description
--- | ---
MYSQL_HOST | the host/ip of your mysql database
MYSQL_PORT | the port number of your mysql database
MYSQL_USER | the username of your mysql database
MYSQL_PASSWORD | the password of your mysql database
MYSQL_DB | the database name(s) to dump. If you want to use multiple databases, delimit with ";". Default: --all-databases

### Optional variables

Variable | Description
--- | ---
SEPARATE_FILES | separate backup files for --all-databases value
MYSQL_EXTRA_OPTS | the extra options to pass to pg_dump command
SCHEDULE | the interval of cron job to run pg_dump. `@daily` by default, which is every day at 00:00.

### Slack variables (optional)

Variable | Description
--- | ---
SLACK_CHANNEL | Slack channel
SLACK_HOST | Slack webhook
SLACK_MESSAGE | Message that will be posted. Default message: `MYSQL Database backup done (2018.03.03) (database1; database2...)`

## Docker compose

```
version: "2"

services:
  backups:
    image: myros/mysql-backup
    volumes:
      - ~/backups/mysql:/backups

    environment:
      MYSQL_USER: docker
      MYSQL_PASSWORD: docker
      MYSQL_PORT: 3306
      MYSQL_HOST: mysql
      # MYSQL_DB: wp_test_1; wp_test_2
      MYSQL_EXTRA_OPTS: --opt -v
      SCHEDULE: "@every 1h"
      SLACK_CHANNEL: "backups"
      SLACK_HOST: "https://hooks.slack.com/services/YOUR_DATA"

networks:
  default:
    external:
      name: YOUR_MYSQL_NETWORK
```

## One time backups

#### Just backup

```
  docker run -e MYSQL_HOST=mysql \
    -e MYSQL_DB=database_name \
    -e MYSQL_USER=docker \
    -e MYSQL_PASSWORD=docker \
    -e MYSQL_PORT=5432 \
    myros/mysql-backup /backup.sh
```

#### With network

```
  docker run -e MYSQL_HOST=mysql \
    -e MYSQL_DB=database_name \
    -e MYSQL_USER=docker \
    -e MYSQL_PASSWORD=docker \
    -e MYSQL_PORT=5432 \
    --network YOUR MYSQL_NETWORK \
    myros/mysql-backup /backup.sh
```

#### With network and Slack

```
  docker run -e MYSQL_HOST=mysql \
    -e MYSQL_DB=database_name \
    -e MYSQL_USER=docker \
    -e MYSQL_PASSWORD=docker \
    -e MYSQL_PORT=5432 \
    -e SLACK_HOST=SLACK_WEBHOOK_URL \
    -e SLACK_CHANNEL=backups --network YOUR MYSQL_NETWORK \
    myros/mysql-backup /backup.sh
```

## Restore from a backup

To see the list of backups, you can run:

    docker exec myros/mysql-backup ls /backups

To restore database from a certain backup, simply run:


```
    docker run docker run -e MYSQL_HOST=mysql -e MYSQL_DB=dbname -e MYSQL_USER=user -e MYSQL_PASSWORD=password  myros/mysql-backup /restore.sh /backups/PATH_TO_YOUR_FILE
```

## TODO

* S3 upload/download
* sending emails
* proper restore & import
