#!/bin/bash
# AIX   /usr/bin/bash
# HP-UX /usr/local/bin/bash
# SunOS /usr/bin/bash
# Linux /bin/bash

ProgN="UnixFSmon"

#Carga el archivo de configuracion
. /home/monitor/scripts/fsmon/fs_mon.conf

OStype=$(uname -a|awk '{print $1}')
 
#Export de variables de entorno
export CLASSPATH
#PATH
PATH=$JAVA_PATH:$PATH
export PATH
 
#Agrega FileSystem ingresado por consola a la lista de FileSystems
fsadd="$@"
UnixFSlist="$UnixFSlist ${fsadd}"

#Validacion de existencia de directorios 
if [ ! -d /var/log/monitor ]
   then mkdir /var/log/monitor
fi
 
if [ ! -d /tmp/UnixFSmon ]
   then mkdir /tmp/UnixFSmon
fi
 
#Banderas
flagHPUX=0
flagAIX=0
flagSed=0
 
 
GetOStypeInfo () {
   case $OStype in
        AIX)
          IPaddr=$(/usr/sbin/ifconfig -a|grep 'inet '|head -n 1|awk '{print $2}')
          FSmounted=$(cat /etc/filesystems|grep :|grep '/'|grep -v '*'|awk -F: '{print $1}')
          dfCMD="df -P"
	  dfCMDi="df -i"
          flagAIX=1
          ;;
        HP-UX)
          IPaddr=$(/usr/bin/nslookup $(hostname)|grep Address|head -1|awk '{print $2}')
          FSmounted=$(cat /etc/mnttab|awk '{print $2}')
          dfCMD="df -P"
          dfCMDi="bdf -i"
          flagHPUX=1
        ;;
        SunOS)
          IPaddr=$(ifconfig nge0|grep inet|awk '{print $2}')
          FSmounted=$(cat /etc/mnttab|awk '{print $2}')
          dfCMD="df"
          ;;
        Linux)
	  hostnamectl &> /dev/null
	  if [ $? == 0 ]
	  then 
          	IPaddr=$(/sbin/ifconfig|grep 'inet '|head -1|awk -F: '{print $1}'|awk '{print $2}')
	  else
          	IPaddr=$(/sbin/ifconfig|grep 'inet '|head -1|awk -F: '{print $2}'|awk '{print $1}')
	  fi
          FSmounted=$(cat /etc/mtab|awk '{print $2}')
          dfCMD="df -P"
          dfCMDi="df -Pi"
          ;;
   esac
   echo "$(date '+%b %d %Y %H:%M:%S') $(hostname|cut -d'.' -f1) $ProgN: Operating System Type $OStype" >> $LogDst
}
 
 
GetFSmountedInfo () {
   if [ -f $TmpUsageDst ]
        then
        NoFile=0
   else
        echo "NO SE ENCUENTRA EL ARCHIVO  $TmpUsageDst SE LO CREARA"
        NoFile=1
   fi
   for UnixFS in $UnixFSlist
       do
	  UnixFSName=$(echo $UnixFS | awk -F, '{print $1}')
	  FSSizeWarning=$(echo $UnixFS | awk -F, '{print $2}')
	  FSSizeAlert=$(echo $UnixFS | awk -F, '{print $3}')
	  FSInodoWarning=$(echo $UnixFS | awk -F, '{print $4}')
	  FSInodoAlert=$(echo $UnixFS | awk -F, '{print $5}')
          if echo $FSmounted 2>/dev/null|grep -q "$UnixFSName"
             then
                  FSusage=$($dfCMD $UnixFSName |awk '{print $5}'|tail -n 1|awk -F% '{print $1}')
                  if [ $flagHPUX -eq 1 ]
                        then
                                FSusageI=$($dfCMDi $UnixFSName |awk '{print $8}'|tail -n 1|awk -F% '{print $1}')
		  elif [ $flagAIX -eq 1 ]
                        then
                                FSusageI=$($dfCMDi $UnixFSName |awk '{print $6}'|tail -n 1|awk -F% '{print $1}')
                  else
                                FSusageI=$($dfCMDi $UnixFSName |awk '{print $5}'|tail -n 1|awk -F% '{print $1}')
                  fi
                  echo "$(hostname|cut -d'.' -f1) $IPaddr FS $UnixFSName Usage Size = $FSusage% Usage Inodos = $FSusageI%"
                  if [ $NoFile -eq 0 ]
                        then
                        OldFSUsage=$(cat $TmpUsageDst |grep $UnixFSName" " |tail -n 1|awk '{print $10}'|awk -F% '{print $1}')
                        Nivel=$(cat $TmpUsageDst |grep $UnixFSName" " |tail -n 1|awk '{print $12}')
                        OldFSUsageI=$(cat $TmpUsageDst |grep $UnixFSName" " |tail -n 1|awk '{print $14}'|awk -F% '{print $1}')
                        NivelI=$(cat $TmpUsageDst |grep $UnixFSName" " |tail -n 1|awk '{print $16}')
                  else
                        OldFSUsage=0
                        Nivel=0
                        OldFSUsageI=0
                        NivelI=0
                  fi
		  if [ ! -n "$OldFSUsage" ]
		 	then 
			OldFSUsage=0
		 	OldFSUsageI=0
			Nivel=0
			NivelI=0
			flagSed=1
		  fi
                  echo "Estado Anterior del FS $UnixFSName Size $OldFSUsage% Inodo $OldFSUsageI%"
                  if [ $FSusage -ge $FSSizeWarning ]
                        then
                        echo "*******************************************************************************"
                        echo "FS $UnixFSName ESTADO ACTUAL SIZE $FSusage% MAYOR O IGUAL QUE UMBRAL $FSSizeWarning%"
                        echo "$(hostname|cut -d'.' -f1) $IPaddr $UnixFSName size $FSusage%" >> $TmpFStoSend
                        EnvioNotificacionNivel1
                        echo "*******************************************************************************"
                        if [ $FSusage -ge $FSSizeAlert ]
                                then echo "*******************************************************************************"
                                echo "FS $UnixFSName ESTADO ACTUAL SIZE $FSusage% MAYOR O IGUAL QUE TOPE MAXIMO $FSSizeAlert%"
                                EnvioNotificacionNivel3
                                echo "*******************************************************************************"
                                Nivel=0
                        elif [ $FSusage -eq $OldFSUsage ]
                                then Nivel=0
                        elif [ $FSusage -gt $OldFSUsage ]
                                echo "*******************************************************************************"
                                then echo "FS $UnixFSName ESTADO ACTUAL SIZE $FSusage% MAYOR QUE ESTADO ANTERIOR $OldFSUsage%"
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
                  rm -f $TmpFStoSend
                  if [ $FSusageI -ge $FSInodoWarning ]
                        then
                        echo "*******************************************************************************"
                        echo "FS $UnixFSName ESTADO ACTUAL INODO $FSusageI% MAYOR O IGUAL QUE UMBRAL $FSInodoWarning%"
                        echo "$(hostname|cut -d'.' -f1) $IPaddr $UnixFSName inodo $FSusageI%" >> $TmpFStoSend
                        EnvioNotificacionNivel1
                        echo "*******************************************************************************"
                        if [ $FSusageI -ge $FSInodoAlert ]
                                then echo "*******************************************************************************"
                                echo "FS $UnixFSName ESTADO ACTUAL INODO $FSusageI% MAYOR O IGUAL QUE TOPE MAXIMO $FSInodoAlert%"
                                EnvioNotificacionNivel3
                                echo "*******************************************************************************"
                                NivelI=0
                        elif [ $FSusageI -eq $OldFSUsageI ]
                                then NivelI=0
                        elif [ $FSusageI -gt $OldFSUsageI ]
                                echo "*******************************************************************************"
                                then echo "FS $UnixFSName ESTADO ACTUAL INODO $FSusageI% MAYOR QUE ESTADO ANTERIOR $OldFSUsageI%"
                                ((NivelI+=1))
                                if [ $NivelI -eq 1 ]
                                        then EnvioNotificacionNivel2
                                        echo "*******************************************************************************"
                                elif [ $NivelI -ge 2 ]
                                        then
                                        NivelI=2
                                        EnvioNotificacionNivel3
                                        echo "*******************************************************************************"
                                fi
                         else
                                NivelI=0
                         fi
                   else
                                NivelI=0
                  fi
                  if [ $NoFile -eq 0 ] && [ $flagSed -eq 0 ]
                       then
                   	sed '1d' $TmpUsageDst >> $TmpDst
                        cat $TmpDst > $TmpUsageDst
                        rm -f $TmpDst
                  fi
                  echo "$(date '+%b %d %Y %H:%M:%S') $(hostname) $IPaddr FS $UnixFSName Usage_Size $FSusage% Nivel_Size $Nivel Usage_Inodo $FSusageI% Nivel_Inodo $NivelI" >> $TmpUsageDst
                  echo "$(date '+%b %d %Y %H:%M:%S') $(hostname|cut -d'.' -f1) UnixFSmon: FS $UnixFSName Mounted StatusAnterior Size $OldFSUsage% Inodo $OldFSUsageI% StatusActual Size $FSusage% Inodo $FSusageI%" >> $LogDst
                  rm -f $TmpFStoSend
             else echo "$(date '+%b %d %Y %H:%M:%S') $(hostname|cut -d'.' -f1) UnixFSmon: FS $UnixFSName NotMounted" >> $LogDst
          fi
   done
}
 
EnvioNotificacionNivel1 () {
        echo "LLEGO A UN ENVIO NIVEL1"
	echo "$(date '+%b %d %Y %H:%M:%S') $(hostname|cut -d'.' -f1) UnixFSmon: FS $UnixFSName Size $FSusage% Inodo $FSusageI% Sobre lo permitido - Alarma Nivel1" >> $LogDst
        java porta.monitor.Monitor FS_MON1 $TmpFStoSend &> $TmpJavaErrorDst
	JavaErrorLog
}
 
EnvioNotificacionNivel2 () {
        echo "LLEGO A UN ENVIO NIVEL2"
	echo "$(date '+%b %d %Y %H:%M:%S') $(hostname|cut -d'.' -f1) UnixFSmon: FS $UnixFSName Size $FSusage% Inodo $FSusageI% Sobre lo permitido - Alarma Nivel2" >> $LogDst
        java porta.monitor.Monitor FS_MON2 $TmpFStoSend &> $TmpJavaErrorDst
	JavaErrorLog
}
 
EnvioNotificacionNivel3 () {
        echo "LLEGO A UN ENVIO NIVEL3"
	echo "$(date '+%b %d %Y %H:%M:%S') $(hostname|cut -d'.' -f1) UnixFSmon: FS $UnixFSName Size $FSusage% Inodo $FSusageI% Sobre lo permitido - Alarma Nivel3" >> $LogDst
        java porta.monitor.Monitor FS_MON3 $TmpFStoSend &> $TmpJavaErrorDst 
        java porta.monitor.Monitor FS_MON2 $TmpFStoSend
	JavaErrorLog
}
 
UpdateTmpUsageDst () {
	for UnixFS in $UnixFSlist
		do
		UnixFSName=$(echo $UnixFS | awk -F, '{print $1}')
          	if echo $FSmounted 2>/dev/null|grep -q "$UnixFSName"
             		then
			numFS=$(cat $TmpUsageDst | grep -c $UnixFSName" ")
			if [ $numFS -gt 1 ]
				then
				linea=$(cat $TmpUsageDst | grep -n $UnixFSName" " | cut -d: -f1 | head -1)
                        	l=$linea"d"
                        	sed "1,$l" $TmpUsageDst >> $TmpDst
				cat $TmpDst > $TmpUsageDst
                       		rm -f $TmpDst	
			fi
		fi
	done	
}

JavaErrorLog (){
	grep -i "error" $TmpJavaErrorDst ||  grep -i "time" $TmpJavaErrorDst
	if [ $? == 0 ]
	then 
	JavaErrorMessage=$(grep -i "error" $TmpJavaErrorDst ||  grep -i "time" $TmpJavaErrorDst)
	echo "$(date '+%b %d %Y %H:%M:%S') $(hostname|cut -d'.' -f1) Error de envio de mensaje: $JavaErrorMessage" >> $LogDst
	fi
}
 
GetOStypeInfo
GetFSmountedInfo
UpdateTmpUsageDst
JavaErrorLog
