#!/bin/bash
LogsDir=/var/log
LogFiles=$(ls -l $LogsDir/ | egrep -v '^total|^d|dmesg|btmp|messages|lastlog|secure|wtmp' |awk '{print $9}')
RotatedLogs_FullPath=$(ls -l $LogsDir/*.[0-9]* | grep -v .gz | awk '{print $9}')
MailSpoolDir=/var/spool/mail
MailSpoolUsers=$(ls -l $MailSpoolDir/ | grep ^- | awk '{print $9}')
ClientMqueue=/var/spool/clientmqueue
RM="/bin/rm -rfv"

## Depuracion de la Cola de Correos
if [ -d "$ClientMqueue" ]
   then rm -rf $ClientMqueue/*f*
fi

## Deputacion de los Buzones de Usuarios de Correo
if [ -n "$MailSpoolUsers" ] 
   then for  MailUser in $MailSpoolUsers
             do 
             > $MailSpoolDir/$MailUser
        done 
fi


## Depuracion de Archivos de Logs
for  LogFile in $LogFiles
     do  > $LogsDir/$LogFile
done

## Depuracion de Archivos de Logs Rotados
$RM $LogsDir/*.[0-9]*
$RM $LogsDir/*$(date +%Y)*
$RM $LogsDir/*.old
