#!/bin/sh
#desc:ODEnergy
#package:odauto

### Copyright(c) 2014 OpenDomo Services SL. Licensed under GPL v3 or later

# validate device
if test "$1" == "validate"; then
	source "$2"

	# Validation command
	if wget $URL/data.xml --http-user=$USER --http-password=$PASS -O - 
	then
		exit 0
	else
		exit 1
	fi
fi

if test -f $1
then
	source $1
else
	if test -f /etc/opendomo/control/$1.conf
	then
		source /etc/opendomo/control/$1.conf
	else
		echo "#ERROR: Invalid configuration file"
		exit 1
	fi
fi


PIDFILE="/var/opendomo/run/odauto.pid"
TMPFILE=/var/opendomo/tmp/$DEVNAME.tmp
LISTFILE=/var/opendomo/tmp/$DEVNAME.lst
CFGDIR=/etc/opendomo/control
CTRLDIR=/var/opendomo/control

# Preparations:
test -d $CTRLDIR/$DEVNAME/ || mkdir -p $CTRLDIR/$DEVNAME/
test -d $CFGDIR/$DEVNAME/ || mkdir -p $CFGDIR/$DEVNAME/
test -d /var/www/data || mkdir -p /var/www/data


while test -f $PIDFILE
do
	echo >  /var/www/data/$DEVNAME.odauto.tmp

	# Making the actual call
	if wget -q $URL/data.xml --http-user=$USER --http-password=$PASS -O $TMPFILE
	then
		
			
		# LSTFILE contiene el listado correcto
		for param in voltage_L1 voltage_L2 voltage_L3 current_L1 current_L2 current_L3
		do
			INFOFILE=$CFGDIR/$DEVNAME/$PNAME.info
			if ! test -f $INFOFILE; then
				echo "way='in'" > $INFOFILE
				echo "tag='power'" >> $INFOFILE
				echo "desc='$param'" >> $INFOFILE
				case $param in
					voltage_L1|voltage_L2|voltage_L3)
						echo "values='100-400'" >> $INFOFILE
					;;
					current_L1|current_L2|current_L3)
						echo "values='0-100000'" >> $INFOFILE
					;;
				esac
			fi
			
			
			PNAME=$param
			PTYPE="AI"
			PTAG="power"
			
			PVAL=`grep $param $TMPFILE | tail -n1 | cut -f2 -d'>' | cut -f1 -d'<' `
			OLDVAL=`cat $CTRLDIR/$DEVNAME/$PNAME.value`
			# Always, refresh the port value
			echo $PVAL  > $CTRLDIR/$DEVNAME/$PNAME.value
			if test "$PVAL" != "$OLDVAL"; then
				/bin/logevent portchange odauto "$DEVNAME/$PNAME $PVAL"
			fi
				
			# Finally, generate JSON fragment
			if test "$status" != "disabled"
			then
				echo "{\"Name\":\"$desc\",\"Type\":\"$PTYPE\",\"Tag\":\"$tag\",\"Value\":\"$PVAL\",\"Min\":\"$min\",\"Max\":\"$max\",\"Id\":\"$DEVNAME/$PNAME\"}," >> /var/www/data/$DEVNAME.odauto.tmp
			fi
		done
	else
		echo "#WARN: Device $DEVNAME not responding. We will keep trying"
	fi
	
	# A very quick replacement of the old file with the new one:
	mv /var/www/data/$DEVNAME.odauto.tmp /var/www/data/$DEVNAME.odauto
	
	# Cleanup
	rm -fr $TMPFILE $LISTFILE 
	sleep $REFRESH
done
