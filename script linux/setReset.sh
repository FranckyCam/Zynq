#!/bin/ash

if [ $# != 1 ]
then
	echo "need arg 0/1"
else
	if [ ! -f /sys/class/gpio/gpio59/value ]
	then
		echo 59 > /sys/class/gpio/export
		echo out > /sys/class/gpio/gpio59/direction
	fi
	echo $1 > /sys/class/gpio/gpio59/value
fi
