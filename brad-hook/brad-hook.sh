#!/bin/sh
### BEGIN INIT INFO
# Provides:          brad-hook
# Required-Start:    $local_fs $network $named $time $syslog
# Required-Stop:     $local_fs $network $named $time $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       This script provides a simple wrapper for the brad hook service
### END INIT INFO

NAME=brad-hook

SCRIPT="cd /home/tchap/brad/brad-hook && node index.js -- bradhook"
PIDGET="pgrep -f bradhook"
RUNAS=tchap

PIDFILE=/var/run/$NAME.pid
LOGFILE=/home/tchap/brad/brad-hook/logs/$NAME.log

start() {
  if [ -f $PIDFILE ] && kill -0 $(cat $PIDFILE); then
    echo 'Service already running' >&2
    return 1
  fi
  echo 'Starting service…' >&2
  local CMD="$SCRIPT &> \"$LOGFILE\" & echo \$!"
  sudo su -m -c "$CMD" $RUNAS
  sleep 1 # some time to get only the good pid
  sudo sh -c "$PIDGET > $PIDFILE"
}

stop() {
  if [ ! -f "$PIDFILE" ]; then
    echo 'Service not running' >&2
    return 1
  fi
  echo 'Stopping service…' >&2
  sudo ps -ef | grep bradhook | grep -v grep | awk '{print $2}' | xargs kill && sudo rm -f "$PIDFILE"
  echo 'Service stopped' >&2
}

uninstall() {
  echo -n "Are you really sure you want to uninstall this service? That cannot be undone. [yes|No] "
  local SURE
  read SURE
  if [ "$SURE" = "yes" ]; then
    stop
    rm -f "$PIDFILE"
    echo "Notice: log file was not removed: '$LOGFILE'" >&2
    update-rc.d -f $NAME remove
    rm -fv "$0"
  fi
}

status() {
    printf "%-50s" "Checking $NAME..."
    if [ -f $PIDFILE ]; then
        PID=$(cat $PIDFILE)
        if [ -z '$(ps axf | grep "${PID}" | grep -v grep)' ]; then
            printf "%s\n" "The process appears to be dead but pidfile still exists"
        else
            echo "Running, the PID is $PID"
        fi
    else
        printf "%s\n" "Service not running"
    fi
}


case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  status)
    status
    ;;
  uninstall)
    uninstall
    ;;
  restart)
    stop
    start
    ;;
  *)
    echo "Usage: $0 {start|stop|status|restart|uninstall}"
esac