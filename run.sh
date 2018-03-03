#! /bin/sh

set -e

if [ -z "${SCHEDULE}" ]; then
  sh backup.sh
else
  echo "exec /usr/local/bin/go-cron "$SCHEDULE" -p 80 -- /backup.sh"
  exec go-cron "$SCHEDULE" -p 80 -- /backup.sh
fi
