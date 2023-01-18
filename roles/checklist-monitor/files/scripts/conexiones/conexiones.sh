#!/bin/bash

logHeader="`date +"%b %d %T"` `hostname -s` `basename $0`[$$]:"
echo $logHeader ======================= INICIO CAPTURA =================================
lock=/tmp/conexiones.lock
if [ -e $lock ]
    then n=$(cat $lock)
         if [ $n -gt 14 ]
            then rm -f $lock
            else let n+=1
                 echo $n > $lock
                 echo "$logHeader Ooops, ya en ejecucion..."
         fi
         exit
    else echo 1 > $lock
fi

cd ~monitor/scripts/conexiones/
echo "xxxxxxxxxxxxxxxxxxxxxx PROCESOS xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
ps --no-headers -A -o user | sort | uniq -c | awk -v fe="$logHeader" '{ print fe" CANTIDAD DE PROCESOS POR USUARIO: "$0 }'

echo -n $logHeader
echo "PROCESOS ORDENADOS POR MEMORIA RESIDENTE (RSS) -----"
UNIX95= ps -e -o rss,vsz,pcpu,user,pid,stime,args --sort=-rss | head -n 20 | awk -v fe="$logHeader" '{ print fe" "$0 }'

echo -n $logHeader
echo "PROCESOS ORDENADOS POR CPU (PCPU) -----"
UNIX95= ps -e -o pcpu,rss,vsz,user,pid,stime,args --sort=-pcpu | head -n 20 | awk -v fe="$logHeader" '{ print fe" "$0 }'

echo "xxxxxxxxxxxxxxxxxxxxxx CONEXIONES xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
echo
CON="ESTABLISHED"
echo "...... CONEXIONES $CON:"
netstat -an | grep tcp | grep $CON | awk '{print $5}' | awk -F. '{printf "%d.%d.%d.%d\n",$1,$2,$3,$4}' | sort | uniq -c | sort -rn | awk 'BEGIN {printf "#\tIP\n"} {printf "%d\t%s\n",$1,$2;sum+=$1} END{printf "Total = %d\n",sum}'| awk -v co=$CON -v fe="$logHeader" '{ print fe" "co" "$0 }'

echo
CON="TIME_WAIT"
echo "...... CONEXIONES $CON:"
netstat -an | grep tcp | grep $CON | awk '{print $5}' | awk -F. '{printf "%d.%d.%d.%d\n",$1,$2,$3,$4}' | sort | uniq -c | sort -rn | awk 'BEGIN {printf "#\tIP\n"} {printf "%d\t%s\n",$1,$2;sum+=$1} END{printf "Total = %d\n",sum}'| awk -v co=$CON -v fe="$logHeader" '{ print fe" "co" "$0 }'

echo
CON="FIN_WAIT"
echo "...... CONEXIONES $CON:"
netstat -an | grep tcp | grep $CON | awk '{print $5}' | awk -F. '{printf "%d.%d.%d.%d\n",$1,$2,$3,$4}' | sort | uniq -c | sort -rn | awk 'BEGIN {printf "#\tIP\n"} {printf "%d\t%s\n",$1,$2;sum+=$1} END{printf "Total = %d\n",sum}'| awk -v co=$CON -v fe="$logHeader" '{ print fe" "co" "$0 }'

rm -f $lock
