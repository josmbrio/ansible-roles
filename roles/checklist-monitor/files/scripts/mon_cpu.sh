#!/bin/bash
HOSTNAME=`hostname`
IPADDR=`/sbin/ifconfig -a|grep inet|grep "[Mm]ask"|egrep -v '127.0.0.1|192.168.177'|awk '{print $2}'`
SMS_SENDERS=/home/monitor/scripts/dat/sms_senders.dat
BITACORA=/var/log/monitor/mon_cpu.log
lock=/tmp/mon_cpu.lock
sleep 20
cp=`sar |grep Average | tail -n 1 | awk  '{ print int($3+$5)}'`

if [ -e $lock ]; then
        n=$(cat $lock)
        if [ $n -gt 14 ]; then
                rm -f $lock
        else
                let n+=1
                echo $n > $lock
                echo "$logHeader Ooops, ya en ejecucion..." >> $BITACORA
        fi
        exit
else
        echo 1 > $lock
fi
if [ "$cp" -gt 95 ]; then
        logHeader="`date +"%b %d %T"` `hostname -s` `basename $0`[$$]:"
        cd /home/monitor/scripts/
        for j in `cat $SMS_SENDERS`
                do
      SMS="$HOSTNAME [$IPADDR] CPU $cp%"
                        ./ies $j "$SMS"
                done
        echo $logHeader " " $SMS >> $BITACORA
fi

rm -f $lock
