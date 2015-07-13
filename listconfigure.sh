#!/bin/sh

listfile=$1
owner=$2
peersdir=$3
if [ -z "$listfile" -o -z "$owner" -o -z "$peersdir" ]; then
	echo "USAGE: $0 <listfile> <owner> <peers-dir>"
	echo "<listfile> is a list containing lines of the format 'name' or 'name=lat lon'"
	echo "<owner> is a free text which will be embedded into the peers git"
	echo "<peersdir> is the path to the peers git's working copy"
	exit 1
fi

if [ ! -r "$listfile" ]; then
	echo "The listfile is not readable (does it exist?)."
	exit 2
fi

if [ ! -d "$peersdir" ]; then
	echo "The peers dir does not exist."
	exit 2
fi

cat $listfile | while read line; do
	[ -z "$line" ] && continue

	name=`echo $line | cut -d"=" -f 1`
	latlon=`echo $line | cut -d"=" -f 2 | awk '{print $1" "$2}'`
	echo "Next node: $name at $latlon"

    echo -n "Waiting for an uncofigured router to appear on 192.168.1.1 ..."
    while ! ping -n -c 1 -W 1 192.168.1.1 > /dev/null; do
        echo -n "."
        sleep 1
    done
    echo " found."
	echo "Waiting for router to come up completly (waiting 15 Seconds)"
	sleep 15
	echo "Let the show begin ..."
	./configure-node.sh $name $owner $latlon > "${peersdir}/${name}"
done
