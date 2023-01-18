#!/bin/bash
# AIX   /usr/bin/bash
# HP-UX /usr/local/bin/bash
# SunOS /usr/bin/bash
# Linux /bin/bash
ProgN="UnixFSmon"
LogDir="/var/log/monitor"
LogFile="UnixFSmon.log"
LogDst="$LogDir/$LogFile"
OStype=$(uname -a|awk '{print $1}')

PATH=/usr/local/bin:/usr/bin:/usr/ucb:/etc:$PATH
DatFile="/home/monitor/scripts/fsmon/fs_mon.dat"
#  CLASSPATH|<ruta de CLASSPATH java>
#VARIABLES DE AMBIENTE
#CLASSPATH
CLASSPATH=`cat $DatFile|awk -F\| '$1 == "CLASSPATH" {print $2}'`
export CLASSPATH
#PATH
PATH=`cat $DatFile|awk -F\| '$1 == "PATH" {print $2}'`:$PATH
export PATH


TmpUsageDir="/tmp/UnixFSmon"
TmpUsageFile="UnixFSUsage.tmp"
TmpUsageDst="$TmpUsageDir/$TmpUsageFile"

TmpDir="/tmp/UnixFSmon"
TmpFile="UnixFSTmp.tmp"
TmpDst="$TmpDir/$TmpFile"

#LogFSUsageDir="/var/log/monitor"
#LogFSUsageFile="UnixFSUsage.log"
#LogFSUsageDst="$LogFSUsageDir/$LogFSUsageFile"

TmpFStoSendDir="/tmp/UnixFSmon"
TmpFStoSendFile="DatFile.ies"
TmpFStoSend="$TmpFStoSendDir/$TmpFStoSendFile"


UnixFSlist="
/
/boot
/tmp
/opt
/var
/usr
/usr/local
/home
/stand
/admin
/export/home
"


if [ ! -d /var/log/monitor ]
   then mkdir /var/log/monitor
fi

if [ ! -d /tmp/UnixFSmon ]
   then mkdir /tmp/UnixFSmon
fi

DefaultMaxPercent=80
TOPEMAX_SIEMPREENVIA=99

GetOStypeInfo () {
   case $OStype in
        AIX)
          IPaddr=$(ifconfig -a|grep 'inet '|head -1|awk '{print $2}')
          FSmounted=$(cat /etc/filesystems|grep :|grep '/'|grep -v '*'|awk -F: '{print $1}')
          dfCMD="df -P"
          ;;
        HP-UX)
          IPaddr=$(nslookup $(hostname)|grep Address|head -1|awk '{print $2}')
          FSmounted=$(cat /etc/mnttab|grep -vE '/ora|host'|awk '{print $2}')
          dfCMD="df -P"
          ;;
        SunOS)
          IPaddr=$(ifconfig nge0|grep inet|awk '{print $2}')
          FSmounted=$(cat /etc/mnttab|awk '{print $2}')
          dfCMD="df"
          ;;
        Linux)
          IPaddr=$(/sbin/ifconfig|grep 'inet '|head -1|awk -F: '{print $2}'|awk '{print $1}')
          FSmounted=$(cat /etc/mtab|awk '{print $2}')
          dfCMD="df -P"
          ;;
   esac
   echo "$(date '+%b %d %Y %H:%M:%S') $(hostname|cut -d'.' -f1) $ProgN: Operating System Type $OStype" >> $LogDst
}


GetFSmountedInfo () {
   if [ -f $TmpUsageDst ]
        then
        #echo "SI SE ENCUENTRA EL ARCHIVO  $TmpUsageDst"
        NoFile=0
   else
        echo "NO SE ENCUENTRA EL ARCHIVO  $TmpUsageDst SE LO CREARA"
        NoFile=1
   fi
   for UnixFS in $UnixFSlist
       do
          if echo $FSmounted 2>/dev/null|grep -q "$UnixFS "
             then
                  FSusage=$($dfCMD $UnixFS|awk '{print $5}'|tail -1|awk -F% '{print $1}')
                  echo "$(hostname|cut -d'.' -f1) $IPaddr FS $UnixFS usage $FSusage%"
		  if [ $NoFile -eq 0 ] 
			then	
                  	OldFSUsage=$(cat $TmpUsageDst |grep $UnixFS" " |tail -1|awk '{print $10}'|awk -F% '{print $1}')
                  	Nivel=$(cat $TmpUsageDst |grep $UnixFS" " |tail -1|awk '{print $12}')
		  else
			OldFSUsage=0
			Nivel=0
		  fi
                  echo "Estado Anterior del FS $UnixFS $OldFSUsage%"
                  if [ $FSusage -ge $DefaultMaxPercent ]
                        then
			echo "*******************************************************************************"
			echo "FS $UnixFS ESTADO ACTUAL $FSusage% MAYOR O IGUAL QUE UMBRAL $DefaultMaxPercent%"
                        echo "$(hostname|cut -d'.' -f1) $IPaddr $UnixFS $FSusage%" >> $TmpFStoSend
                        EnvioNotificacionNivel1
			echo "*******************************************************************************"
                        if [ $FSusage -ge $TOPEMAX_SIEMPREENVIA ]
				then echo "*******************************************************************************"
				echo "FS $UnixFS ESTADO ACTUAL $FSusage% MAYOR O IGUAL QUE TOPE MAXIMO $TOPEMAX_SIEMPREENVIA%"
				EnvioNotificacionNivel3
				echo "*******************************************************************************"
				Nivel=0
			elif [ $FSusage -eq $OldFSUsage ]
				then Nivel=0
                        elif [ $FSusage -gt $OldFSUsage ]
				echo "*******************************************************************************"
                                then echo "FS $UnixFS ESTADO ACTUAL $FSusage% MAYOR QUE ESTADO ANTERIOR $OldFSUsage%"
                                ((Nivel+=1))
                                if [ $Nivel -eq 1 ]
                                        then EnvioNotificacionNivel2
					echo "*******************************************************************************"
                                elif [ $Nivel -ge 2 ]
                                        then
                                        Nivel=2
                                        EnvioNotificacionNivel3
					echo "*******************************************************************************"
                                fi
                         else
                                Nivel=0
                         fi
                   else
                                Nivel=0
                  fi
                  if [ $NoFile -eq 0 ]
                        then
                        sed '1d' $TmpUsageDst >> $TmpDst
			cat $TmpDst > $TmpUsageDst
			rm -f $TmpDst
                  fi
                  echo "$(date '+%b %d %Y %H:%M:%S') $(hostname) $IPaddr FS $UnixFS usage $FSusage% Nivel $Nivel" >> $TmpUsageDst
                  echo "$(date '+%b %d %Y %H:%M:%S') $(hostname|cut -d'.' -f1) UnixFSmon: FS $UnixFS Mounted StatusAnterior $OldFSUsage% StatusActual $FSusage%" >> $LogDst
                  rm -f $TmpFStoSend
             else echo "$(date '+%b %d %Y %H:%M:%S') $(hostname|cut -d'.' -f1) UnixFSmon: FS $UnixFS NotMounted" >> $LogDst
          fi
   done
}

EnvioNotificacionNivel1 () {
        echo "LLEGO A UN ENVIO NIVEL1"
        java porta.monitor.Monitor FS_MON1 $TmpFStoSend
}

EnvioNotificacionNivel2 () {
        echo "LLEGO A UN ENVIO NIVEL2"
	#java porta.monitor.Monitor FS_MON1 $TmpFStoSend
        java porta.monitor.Monitor FS_MON2 $TmpFStoSend
}

EnvioNotificacionNivel3 () {
        echo "LLEGO A UN ENVIO NIVEL3"
	#java porta.monitor.Monitor FS_MON1 $TmpFStoSend
        java porta.monitor.Monitor FS_MON2 $TmpFStoSend
        java porta.monitor.Monitor FS_MON3 $TmpFStoSend
}


GetOStypeInfo
GetFSmountedInfo

