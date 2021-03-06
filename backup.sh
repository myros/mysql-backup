#!/bin/sh

set -e

post_to_slack() {
  # format message as a code block ```${msg}```
  SLACK_MESSAGE="\`\`\`$1\`\`\`"
  SLACK_URL=$SLACK_HOST

  case "$2" in
    INFO)
      SLACK_ICON=':slack:'
      ;;
    WARNING)
      SLACK_ICON=':warning:'
      ;;
    ERROR)
      SLACK_ICON=':bangbang:'
      ;;
    *)
      SLACK_ICON=':slack:'
      ;;
  esac

  curl -s -d "payload={\"text\": \"${SLACK_ICON} ${SLACK_MESSAGE}\"}" ${SLACK_URL}
}

echo "Begin..."

# INIT VARS
SLACK="MYSQL backup started at `date +%m.%d.` `date +%H:%M` \n"

if [ -z "${MYSQL_HOST}" ]; then
  echo "You need to set the MYSQL_HOST environment variable."
  exit 1
fi

if [ -z "${MYSQL_DB}" ]; then
  MYSQL_DB='--all-databases'
fi

if [ -z "${MYSQL_USER}" ]; then
  echo "You need to set the MYSQL_USER environment variable."
  exit 1
fi

if [ -z "${MYSQL_PASSWORD}" ]; then
  echo "You need to set the MYSQL_PASSWORD environment variable."
  exit 1
fi

if [ -z "${MYSQL_PORT}" ]; then
  echo "You need to set the MYSQL_PORT environment variable."
  exit 1
fi

# # CHECK S3 UPLOAD
# if [ -z "$S3_ACCESS_KEY" -o -z "$S3_SECRET_KEY" -o -z "$S3_BUCKET" ]; then
#   # no AWS data, no S3 upload
#
# fi

#Proces vars
MYSQL_HOST_OPTS="-h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD -P$MYSQL_PORT  -C $MYSQLDUMP_OPTIONS"

#Initialize filename vers and dirs
BACKUP_DIR=${BACKUP_DIR:-/backups}

YEAR=`date +%Y`
MONTH=`date +%m`
DAY=`date +%d`
BACKUP_PATH="$BACKUP_DIR/$YEAR/$MONTH/$DAY"
mkdir -p $BACKUP_PATH

# getting database list
DBS=$(echo $MYSQL_DB | tr ";" "\n")

DB_DONE="Databases: "
MYSQLDUMP="mysqldump -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD -P$MYSQL_PORT $MYSQLDUMP_OPTIONS"

if [ $MYSQL_DB = "--all-databases" ]; then
  if [ $MULTI_FILES = "yes" ]; then
    echo "Creating separate dump of all databases from ${MYSQL_HOST}..."
    databases=`mysql -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD -P$MYSQL_PORT -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)"`
    for db in $databases; do
      FILE_NAME="$db-`date +%H%M%S`.sql.gz"
      echo "Creating dump ${db} ==> $BACKUP_PATH/$FILE_NAME"
      $MYSQLDUMP --databases $db | gzip > "$BACKUP_PATH/$FILE_NAME"
      DB_DONE="$DB_DONE$db; "
    done
  else
    echo "Creating dump of all databases ==> $BACKUP_PATH/$FILE_NAME"
    FILE_NAME="backup-`date +%H%M%S`.sql.gz"
    mysqldump -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD -P$MYSQL_PORT $MYSQLDUMP_OPTIONS --all-databases > $BACKUP_PATH/$FILE_NAME
    DB_DONE="All databases"
  fi
else
  for db in $DBS; do
    #Create dump
    echo "Creating dump ${db} ==> $BACKUP_PATH/$FILE_NAME"
    FILE_NAME=${db}-`date +%H%M%S`.sql.gz
    mysqldump -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD -P$MYSQL_PORT $MYSQLDUMP_OPTIONS  $db > $BACKUP_PATH/$FILE_NAME

    echo "mysqldump $MYSQL_HOST_OPTS $db | gzip > $BACKUP_PATH/$FILE_NAME"
    DB_DONE="$DB_DONE$db; "
  done
fi

# post slack message
if [ ! -z $SLACK_HOST ] && [ ! -z $SLACK_CHANNEL ]; then
  echo "Notifying slack..."
  CURRENT_DATE=`date +%Y.%m.%d`
  CURRENT_TIME=`date +%H:%M`
  SLACK="$SLACK\n${DB_DONE}"
  SLACK="$SLACK\nMYSQL Database backup done at ($CURRENT_TIME)"
  MESSAGE=${SLACK_MESSAGE:-$SLACK}
  echo $MESSAGE
  post_to_slack "$MESSAGE" "INFO"
fi

echo "SQL backup done successfully"
