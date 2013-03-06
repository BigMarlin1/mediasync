#!/bin/bash

FLOCK=/usr/bin/flock
RSYNC=/usr/bin/rsync
SSH=/usr/bin/ssh
PING=/usr/bin/ping
DATE=/usr/bin/date
RLFILE=/home/pi/scripts/.read_lock_file
WLFILE=/home/pi/scripts/.write_lock_file
SERVER="google.com"
CACHE="$HOME/recent"
NETLOG="$HOME/logs/network.log"
PULLLOG="$HOME/logs/pull.log"
PUSHLOG="$HOME/logs/push.log"

netcheck=`$PING -c1 $SERVER 2>&1 | grep unknown`

echo `$DATE` >> /home/pi/logs/network.log
if [ ! "$netcheck" = "" ]; then
	echo "Network down"  >> "$NETLOG"
else
	echo "Network up"  >> "$NETLOG"
fi

$FLOCK -n $RLFILE -c "$RSYNC -ravz --log-file="$PULLLOG" --remove-source-files --exclude=".*" buu:/home/rahul/videos/Scene/ /home/pi/backup/"
$FLOCK -n $WLFILE -c "rm -r $CACHE"
$FLOCK -n $WLFILE -c "mkdir $CACHE"

files=`ls -t $(find /home/pi/backup/ -type f) | head -n 50`

for original_file in $files 
do
	file=`echo $original_file | sed -e 's/\/home\/pi\/backup\///'`
	directory="$(dirname "$file")"
	filename="$(basename "$file")"
	if [ ! -d "/home/pi/recent/$directory" ]
	then
		$FLOCK -n $WLFILE -c "mkdir -p $CACHE/$directory"
	fi
	$FLOCK -n $WLFILE -c "ln -s $original_file $CACHE/$directory/$filename"
done

$FLOCK -n $WLFILE -c "$RSYNC -PravzL --delete --log-file=$PUSHLOG $CACHE duo:/home/pi/backup/"
$FLOCK -n $WLFILE -c "rm -r $CACHE"