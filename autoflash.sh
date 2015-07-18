#!/bin/bash

source ./config

function quit() {
	if [ x"${BASH_SOURCE[0]}" == x"$0" ]; then
		exit $*
	else
		return $*
	fi
}

function curl_admin() {
	curl -fsS --basic -u admin:admin $@
}

# download missing firmware images
models="${models} tp-link-cpe210-v1.0"
models="${models} tp-link-cpe220-v1.0"
models="${models} tp-link-cpe510-v1.0"
models="${models} tp-link-cpe520-v1.0"
models="${models} tp-link-tl-mr3020-v1"
models="${models} tp-link-tl-mr3040-v1"
models="${models} tp-link-tl-mr3040-v2"
models="${models} tp-link-tl-mr3220-v1"
models="${models} tp-link-tl-mr3220-v2"
models="${models} tp-link-tl-mr3420-v1"
models="${models} tp-link-tl-mr3420-v2"
models="${models} tp-link-tl-wa701n-nd-v1"
models="${models} tp-link-tl-wa750re-v1"
models="${models} tp-link-tl-wa801n-nd-v2"
models="${models} tp-link-tl-wa830re-v1"
models="${models} tp-link-tl-wa850re-v1"
models="${models} tp-link-tl-wa860re-v1"
models="${models} tp-link-tl-wa901n-nd-v2"
models="${models} tp-link-tl-wa901n-nd-v3"
models="${models} tp-link-tl-wdr3500-v1"
models="${models} tp-link-tl-wdr3600-v1"
models="${models} tp-link-tl-wdr4300-v1"
models="${models} tp-link-tl-wr1043n-nd-v1"
models="${models} tp-link-tl-wr1043n-nd-v2"
models="${models} tp-link-tl-wr2543n-nd-v1"
models="${models} tp-link-tl-wr703n-v1"
models="${models} tp-link-tl-wr710n-v1"
models="${models} tp-link-tl-wr740n-nd-v1"
models="${models} tp-link-tl-wr740n-nd-v3"
models="${models} tp-link-tl-wr740n-nd-v4"
models="${models} tp-link-tl-wr741n-nd-v1"
models="${models} tp-link-tl-wr741n-nd-v2"
models="${models} tp-link-tl-wr741n-nd-v4"
models="${models} tp-link-tl-wr743n-nd-v1"
models="${models} tp-link-tl-wr743n-nd-v2"
models="${models} tp-link-tl-wr841n-nd-v3"
models="${models} tp-link-tl-wr841n-nd-v5"
models="${models} tp-link-tl-wr841n-nd-v7"
models="${models} tp-link-tl-wr841n-nd-v8"
models="${models} tp-link-tl-wr841n-nd-v9"
models="${models} tp-link-tl-wr842n-nd-v1"
models="${models} tp-link-tl-wr842n-nd-v2"
models="${models} tp-link-tl-wr941n-nd-v2"
models="${models} tp-link-tl-wr941n-nd-v3"
models="${models} tp-link-tl-wr941n-nd-v4"
models="${models} tp-link-tl-wr941n-nd-v5"


for model in $models; do
	filename="${base_fw_name}-${model}.bin"
	imagefile="images/${filename}"
	if [ ! -r $imagefile ]; then
		echo -en "Downloading image for '$model' ... "
		wget -q "${base_fw_url}${filename}" -O "$imagefile"
		if [ $? -eq 0 ]; then
			echo "OK"
		else
			echo "ERROR"
			rm -f "$imagefile"
			echo "Failed to download firmware. Please ensure the firmware for '${base_fw_name}-${model}' is present in images/ directory."
			quit 3
		fi
	fi
done

ping -n -c 1 -W 1 192.168.0.1 > /dev/null
if [ $? -ne 0 ]; then
	echo "ROUTER OFFLINE? cannot ping 192.168.0.1 :("
	quit 1
fi

mac=$(arp -i eth0 -a 192.168.0.1 |grep -oE " [0-9a-f:]+ " |tr -d ' ')
echo "mac address: $mac"

model=$(curl_admin http://192.168.0.1/ | grep -oE "WD?R[0-9]+N?")
echo "found model: $model"

hwver_page="http://192.168.0.1/userRpm/SoftwareUpgradeRpm.htm"
hwver=$(curl_admin -e http://192.168.0.1/userRpm/MenuRpm.htm $hwver_page | grep -oE "$model v[0-9]+")
echo "hw version:  $hwver"

uploadurl="http://192.168.0.1/incoming/Firmware.htm"
image=""
if [ "$hwver" = "WR841N v9" ]; then
	image="${base_fw_name}-tp-link-tl-wr841n-nd-v9.bin"
elif [ "$hwver" = "WR841N v8" ]; then
	image="${base_fw_name}-tp-link-tl-wr841n-nd-v8.bin"
elif [ "$hwver" = "WR1043 v2" ]; then
        image="${base_fw_name}-tp-link-tl-wr1043n-nd-v2.bin"
elif [ "$hwver" = "WDR3500 v1" ]; then
	image="${base_fw_name}-tp-link-tl-wdr3500-v1.bin"
elif [ "$hwver" = "WDR3600 v1" ]; then
	image="${base_fw_name}-tp-link-tl-wdr3600-v1.bin"
elif [ "$hwver" = "WDR4300 v1" ]; then
	image="${base_fw_name}-tp-link-tl-wdr4300-v1.bin"
else
	echo "UNKNOWN MODEL ($hwver), SORRY :("
	quit 2
fi

# prepend images/ subdirectory to filename
image="images/$image"

echo -en "flashing image: $image ... "
#curl_admin -e $hwver_page -F Filename=@$image $uploadurl > /dev/null
#curl_admin -e $uploadurl http://192.168.0.1/userRpm/FirmwareUpdateTemp.htm > /dev/null
echo "done :)"

echo -en "waiting for router to come up again "
while ! ping -n -c 1 -W 2 192.168.1.1 > /dev/null; do
	echo -en "."
	sleep 1
done
echo " \o/"

# upload authorized keys if present
#if [ -e authorized_keys ]; then
#	echo -en "uploading authorized_keys ... "
#	keys=`cat authorized_keys`
#	curl -fsS -F cbi.submit=1 -F "cbid.system._keys._data=$keys" http://192.168.1.1/cgi-bin/luci/admin/index > /dev/null
#	if [ $? -eq 0 ]; then
#		echo "OK"
#	else
#		quit 4
#	fi
#fi

echo
