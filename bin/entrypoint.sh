#!/bin/bash -e

# start script
CRONMODE=${CRONMODE:-false}
if $CRONMODE ; then
  echo "=== started in cron mode `/bin/date "+%Y/%m/%d %H:%M:%S"` ==="
  crontab -l
  exec crond -f -d 8
else
  exec command_exec.sh $@
fi

