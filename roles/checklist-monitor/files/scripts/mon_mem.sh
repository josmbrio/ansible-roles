#!/bin/bash
HOSTNAME=`hostname`
IPADDR=`/sbin/ifconfig -a|grep inet|grep "[Mm]ask"|egrep -v '127.0.0.1|192.168.177'|awk '{print $2}'`
SMS_SENDERS=/home/monitor/scripts/dat/sms_senders.dat
BITACORA=/var/log/monitor/mon_mem.log
lock=/tmp/mon_mem.lock
mt=`free |grep Mem|awk '{print $2}'`
mp=`free |grep Mem | awk '{print int(($3/'$mt')*100)}'`

if [ -e $lock ]; then
        n=$(cat $lock)
        if [ $n -gt 14 ]; then
                rm -f $lock
        else
                let n+=1
                echo $n > $lock
                echo "$logHeader Ooops, ya en ejecucion..."
        fi
        exit
else
        echo 1 > $lock
fi

if [ "$mp" -gt 90 ]; then
 logHeader="`date +"%b %d %T"` `hostname -s` `basename $0`[$$]:"
 cd /home/monitor/scripts/
 for j in `cat $SMS_SENDERS`
  do
      SMS="$HOSTNAME [$IPADDR] MEM $mp%"
      ./ies $j "$SMS"
  done
 echo $logHeader " " $SMS >> $BITACORA
fi

rm -f $lock
