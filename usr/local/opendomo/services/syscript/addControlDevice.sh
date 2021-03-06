#!/bin/sh
#desc:Add Control device
#package:odauto
#type:local

# Copyright(c) 2015 OpenDomo Services SL. Licensed under GPL v3 or later

CFGPATH="/etc/opendomo/control"

cd /usr/local/opendomo/bindings/
for binding in *.sh
do
	BID=`echo $binding | cut -f1 -d.`
	BDESC=`grep '#desc' $binding | head -n1 |  cut -f2 -d:`
	DEVICETYPELIST="$DEVICETYPELIST,$BID:$BDESC"
done

# If we are passing all 5 parameters, 
if ! test -z "$5"; then
	TYPE="$1"
	USERNAME="$2"
	PASS="$3"
	URL="$4"
	
	REFRESH="$5"
	TMPFILE="/var/opendomo/tmp/controlconfig.tmp"
	
	# Saving configuration
	DEVICENAME=`basename $URL| sed 's/[^a-z0-9A-Z]//g'`
	mkdir -p /etc/opendomo/control/$DEVICENAME
	CFGFILE="/etc/opendomo/control/$DEVICENAME.conf"
	echo "URL=$URL" > $CFGFILE
	echo "USERNAME=$USERNAME" >> $CFGFILE
	echo "PASS=$PASS" >> $CFGFILE
	echo "TYPE=$TYPE" >> $CFGFILE
	echo "REFRESH=$REFRESH" >> $CFGFILE
	echo "DEVNAME=$DEVICENAME" >> $CFGFILE
	
	if /usr/local/opendomo/bindings/$TYPE.sh validate $CFGFILE
	then
		echo "#INFO The device was created and it will be available soon"			
		/usr/local/opendomo/daemons/odauto.sh restart > /dev/null
		/usr/local/opendomo/manageControlDevices.sh
	else
		echo "#ERR: Cannot connect to the specified device"	
		source $CFGFILE
		# Delete the file and directory
		rm $CFGFILE
		rm -fr /etc/opendomo/control/$DEVICENAME
	fi

	echo
else
	if test -z "$1"
	then
		# No parameters at all
		TYPE="odcontrol2"
		REFRESH=5
	else
		# ONE parameter (the device name)
		if test -f /etc/opendomo/control/$1.conf
		then
			source /etc/opendomo/control/$1.conf
		else
			echo "#ERR: The device cannot be edited"
			exit 1
		fi
	fi

fi


# Always display the form: empty to create a new one or full to modify
echo "#> Add Control device"
echo "form:`basename $0`"
echo "	type	Type	list[$DEVICETYPELIST]	$TYPE"
echo "	username	Username	text	$USER"
echo "	password	Password	text	$PASS"
echo "	ipaddress	URL 	text	$URL"
echo "	refresh 	Refresh 	text	$REFRESH"
echo
