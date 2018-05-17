#!/bin/bash -e

# start script
CRONMODE=${CRONMODE:-false}
if $CRONMODE ; then
  echo "=== started in cron mode `/bin/date "+%Y/%m/%d %H:%M:%S"` ==="
  crontab -l
  exec crond -f -d 8
else
  CWD=`/usr/bin/dirname $0`
  cd $CWD
  
  for arg in $@; do
    ./${arg}.sh
  done
fi
