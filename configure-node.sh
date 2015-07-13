#!/bin/bash

function cmd()
{
	echo "$@" | nc -q1 192.168.1.1 23 > /dev/null
}

hostname=$1
owner=$2
latitude=$3
longitude=$4

[ -z "$hostname" ] && { echo "USAGE: $0 <hostname> <owner> [<latitude> <longitude>]"; exit 1; }
[ -z "$owner" ] && { echo "ERROR: need at least hostname and owner as params"; exit 1; }

#if [ "$IDid" != "ReadTheScript" ]; then
#	echo "WORK IN PROGRESS: Dieses Skript ist noch nicht fertig und tut nicht was es soll."
#	echo "Die uci-set Kommandos werden scheinbar nicht ausgeführt!"
#	exit 42
#fi

mac=`echo "lua -e 'print(require(\"gluon.sysconfig\").primary_mac)'" | nc -q1 192.168.1.1 23 | grep -o '^[0-9a-fA-F\:]\{17\}'`

cmd 'uci set fastd.mesh_vpn.enabled=1'
cmd 'uci set fastd.mesh_vpn.secret=$(fastd --generate-key --machine-readable)'
cmd 'uci commit fastd'
public_key=$(echo '/etc/init.d/fastd show_key mesh_vpn' | nc -q1 192.168.1.1 23 | grep -o "[0-9a-f]\{64\}")

cmd "uci set system.@system[0].hostname=${hostname}"
cmd "uci commit system"

loc_string=""
[ "$latitude" == "0" ] && latitude=""
[ "$longitude" == "0" ] && longitude=""
if [ ! -z "$latitude" -a ! -z "$longitude" ]; then
	cmd "uci set gluon-node-info.@location[0].share_location=1"
	cmd "uci set gluon-node-info.@location[0].latitude=$latitude"
	cmd "uci set gluon-node-info.@location[0].longitude=$longitude"
	loc_string="# Location: $latitude $longitude"
else
	cmd "uci set gluon-node-info.@location[0].share_location=0"
fi
cmd 'uci commit gluon-node-info'

cmd 'uci set gluon-setup-mode.@setup_mode[0]=setup_mode'
cmd 'uci set gluon-setup-mode.@setup_mode[0].enabled=0'
cmd 'uci set gluon-setup-mode.@setup_mode[0].configured=1'
cmd 'uci commit gluon-setup-mode'

cmd 'uci commit'
cmd "reboot"

echo "# Owner: $owner"
echo "# MAC: $mac"
[ ! -z "$loc_string" ] && echo $loc_string
echo "key \"${public_key/\r/}\";"

