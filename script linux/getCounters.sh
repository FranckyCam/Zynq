#!/bin/ash

if [ ! -f /sys/class/gpio/gpio56/value ]
then
    echo 56 > /sys/class/gpio/export
fi
echo in > /sys/class/gpio/gpio56/direction
        
if [ ! -f /sys/class/gpio/gpio60/value ]
then
    echo 60 > /sys/class/gpio/export
fi
echo in > /sys/class/gpio/gpio60/direction
    
if [ ! -f /sys/class/gpio/gpio61/value ]
then
    echo 61 > /sys/class/gpio/export
fi
echo in > /sys/class/gpio/gpio61/direction
        
if [ ! -f /sys/class/gpio/gpio62/value ]
then
    echo 62 > /sys/class/gpio/export
fi
echo in > /sys/class/gpio/gpio62/direction

while [ 1 ]
do
   echo -n "Word clk : "
   word_freq=$(printf "%d" `devmem 0x18000000 32`)
   word_freq_mhz=$(expr $word_freq / 1000000)
   printf "%d MHz \t" $word_freq_mhz
   bit_freq_mhz=$(expr $word_freq_mhz \* 8)
   echo -n "Bit clk : "
   printf "%d MHz \t" $bit_freq_mhz
   echo -n "Match errors : "
   printf "%d \t" `devmem 0x18000004 32`
   echo -n "Match : "
   printf "%d|" `cat /sys/class/gpio/gpio56/value`
   printf "%d|" `cat /sys/class/gpio/gpio60/value`
   printf "%d|" `cat /sys/class/gpio/gpio61/value`
   printf "%d\r" `cat /sys/class/gpio/gpio62/value`
   getCh=""
   read -s -t 1 -n 1 getCh
   if [ "$getCh" != "" ]; then
      echo ""
      exit 0
   fi
done
