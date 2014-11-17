#!/bin/sh
#desc:Manage scenes
#package:odauto
#type:local

# Copyright(c) 2014 OpenDomo Services SL. Licensed under GPL v3 or later

CFGPATH="/etc/opendomo/scenes"
CTRLPATH="/var/opendomo/control"

if ! test -d "$CFGPATH"; then
	mkdir -p "$CFGPATH"
fi


if ! test -z "$1" && test -f $CFGPATH/$1; then
	. $CFGPATH/$1
	echo "#> Ports stored in [$desc]"
	echo "list:`basename $0`	detailed"
	for port in $values; do
		p=`echo $port | cut -f1 -d=`
		value=`echo $port | cut -f2 -d=`
		pfile=`echo $port | cut -f1 -d= | sed 's/_/\//' `
		pname=`echo $port | cut -f1 -d= | cut -f2 -d'_'`
		desc=""
		if test -f /etc/opendomo/control/$pfile.info
		then
			. /etc/opendomo/control/$pfile.info
		fi
		echo "	$p	$desc	$value	$value"
	done

	# TODO: Permitir edición de puertos para no tener que borrar y crear
	echo "actions:"
	echo "	manageScenes.sh	Manage scenes"

else
	# Available scenes
	echo "#> Available"
	echo "list:editScene.sh	selectable"
	cd $CFGPATH
	for i in *; do
		if test "$i" != "*"; then
			CODE=`basename $i`
			DESC=`grep desc: $i | cut -f2 -d:`
			echo "	-$CODE	$DESC	scene"
		else
			echo "# There are no scenes. Please, go to Add."
		fi
	done
	echo "actions:"
	echo "	addScene.sh	Add"
	echo "	delScene.sh	Delete"
	echo "	setScene.sh	Set scenes"
	echo

fi
echo
