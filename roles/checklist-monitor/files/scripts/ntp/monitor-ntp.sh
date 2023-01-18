#!/bin/bash
############## CONTROL DE NTP ACTIVO/INACTIVO ######################
## ntpdate -d remote
####################################################################
service='ntpd'
server_ntp1="130.2.2.159"
server_ntp2="130.2.18.61"

############# RESPUESTA DE SINCRONIZACION A SERVIDORES ##################
server_ntp1_result=`ntpdate -u $server_ntp1 |grep "adjust time server"`
server_ntp2_result=`ntpdate -u $server_ntp2 |grep "adjust time server"`
date >> /tmp/ntp_sync.log
sync_ntp=`ntpstat`

echo "Respuesta Servidor 1: [$server_ntp1_result]" >> /tmp/ntp_sync.log 2> /tmp/ntp_sync.err
echo "Respuesta Servidor 2: [$server_ntp2_result]" >> /tmp/ntp_sync.log 2> /tmp/ntp_sync.err
echo ""

output=$(ntpstat | grep -vE '^at|time|polling' |awk '{print $1}')
resultado='synchronised'

if [ "$output" = "$resultado" ];
        then
        echo "$service is running"
        echo "$sync_ntp"
        echo "Satisfactorio: SincronizaciOn de $server_ntp1 y $server_ntp2"
        sed -i '1,22d' /tmp/ntp_sync.err
        #cd /home/monitor/scripts/ntp/success/
        #/usr/bin/java -jar sendMail.jar
else
        echo "Envio de correo ERROR en syncronización de $server_ntp1 y $server_ntp2"
        ntpdate -u 130.2.18.61
        sed -i '1,22d' /tmp/ntp_sync.log
        echo "$(date '+%b %d %Y %H:%M:%S') $(hostname) Hubo error de sincronizaciOn con los servers $server_ntp1 y $server_ntp2 pero fue solventado de forma automAtica" >> /tmp/ntp_sync.err
        cd /home/monitor/scripts/ntp/fail/ 
        /usr/bin/java -jar sendMail.jar
fi
#########################################################################
