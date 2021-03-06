#!/bin/sh
### BEGIN INIT INFO
# Provides:          odauto
# Required-Start:    
# Required-Stop:
# Should-Start:      
# Default-Start:     1 2 3 4 5
# Default-Stop:      0 6
# Short-Description: System information
# Description:       System information
#
### END INIT INFO
### Copyright(c) 2014 OpenDomo Services SL. Licensed under GPL v3 or later


CFGPATH="/etc/opendomo/control/system"
CTRLPATH="/var/opendomo/control/system"
PIDFILE="/var/opendomo/run/systemstatus.pid"

test -d $CFGPATH || mkdir -p $CFGPATH
test -d $CTRLPATH || mkdir -p $CTRLPATH


do_background() {
	# 1. Saving PID file
	echo -n >$PIDFILE
	while test -f $PIDFILE
	do
		grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}' > $CTRLPATH/cpuusage.value
		df / | awk '{ print "bootdisk:AIM_:" $5 }' | tail -n 1 | sed -e 's/%//' > $CTRLPATH/bootdisk.value
		cd /media
		for d in *; do
			df  /media/$d | tail -n 1 | awk '{ print $5 }' | sed -e 's/%//'  > $CTRLPATH/$d.value
		done
		df --total | grep total | awk '{ print $5 }' | sed -e 's/%//' > $CTRLPATH/totaldisk.value
		sleep 60
	done
}
	
do_start () {
	log_action_begin_msg "Starting ODAUTO service"
	if test -f $PIDFILE; then
		echo -n "(already started!)"
	else
		mkdir -p $CTRLDIR > /dev/null
		cd /usr/local/opendomo/daemons/
		$0 background > /dev/null &
	fi
	log_action_end_msg $?
}

do_stop () {
	log_action_begin_msg "Stoping ODAUTO service"
	rm $PIDFILE 2>/dev/null	
	log_action_end_msg $?
}

do_status () {
	if test -f $PIDFILE; then
		echo "$basename $0 is running"
		exit 0
	else
		echo "$basename $0 is not running"
		exit 1
	fi
}


case "$1" in
	background)
		do_background
		;;
	start)
		do_start
		;;
	restart|reload|force-reload)
		do_stop
		do_start
		exit 3
		;;
	stop)
		do_stop
		exit 3
	;;
	status)
		do_status
		exit $?
		;;
	*)
		echo "Usage: $0 [start|stop|restart|status]" >&2
		exit 3
		;;
esac