#!/bin/ash

if [ $# != 1 ]
then
	echo "need arg 0/1"
else
	if [ ! -f /sys/class/gpio/gpio58/value ]
	then
		echo 58 > /sys/class/gpio/export
		echo out > /sys/class/gpio/gpio58/direction
	fi
	echo $1 > /sys/class/gpio/gpio58/value
fi
