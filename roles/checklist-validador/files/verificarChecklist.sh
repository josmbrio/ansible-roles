#!/bin/bash
RED="\033[01;31m"
GREEN="\033[01;32m"
YELLOW="\033[01;33m"
BLUE="\033[01;34m"
PURPLE="\033[01;35m"
CYAN="\033[01;36m"
WHITE="\033[01;37m"
NC="\033[00m"

servicio_status="OK"
comandos_status="OK"
kernel_status="OK"
ntp_status="OK"
seguridad_status="OK"
monitor_status="OK"
personalizacion_status="OK"

escribir_encerar_texto () {
  echo -e $texto | column -t -s "|";
  texto="";
}

if [ $(grep -i "release 6" /etc/redhat-release | wc -l) -eq 1 ]; then echo -e "${GREEN}SISTEMA OPERATIVO RHEL 6"
elif [ $(grep -i "release 7" /etc/redhat-release | wc -l) -eq 1 ]; then echo -e "${GREEN}SISTEMA OPERATIVORHEL 7"
elif [ $(grep -i "release 8" /etc/redhat-release | wc -l) -eq 1 ]; then echo -e "${GREEN}SISTEMA OPERATIVO RHEL 8"
fi
escribir_encerar_texto

#SERVICIOS
echo -e "${PURPLE}SERVICIOS"
if [ $(grep -i "release 8" /etc/redhat-release | wc -l) -eq 1 ]; then
        if [ $(systemctl status NetworkManager | grep " active " | wc -l) -eq 1 ]; then texto+="\n${WHITE}NETWORK MANAGER|(LEVANTADO)|${GREEN}OK";
        else texto+="\n${WHITE}NETWORK MANAGER|(DETENIDO)|${RED}INCORRECTO"; servicio_status="INCORRECTO"; fi
        if [ $(systemctl is-enabled NetworkManager | grep "enable" | wc -l) -eq 1 ]; then texto+="\n${WHITE}NETWORK MANAGER|(HABILITADO)|${GREEN}OK";
        else texto+="\n${WHITE}NETWORK MANAGER|(DESHABILITADO)|${RED}INCORRECTO"; servicio_status="INCORRECTO";fi
else
        if [ $(systemctl status NetworkManager | grep " active " | wc -l) -eq 1 ]; then texto+="\n${WHITE}NETWORK MANAGER|(LEVANTADO)|${RED}INCORRECTO"; servicio_status="INCORRECTO";
        else texto+="\n${WHITE}NETWORK MANAGER|(DETENIDO)|${GREEN}OK"; fi
        if [ $(systemctl is-enabled NetworkManager | grep "enable" | wc -l) -eq 1 ]; then texto+="\n${WHITE}NETWORK MANAGER|(HABILITADO)|${RED}INCORRECTO"; servicio_status="INCORRECTO";
        else texto+="\n${WHITE}NETWORK MANAGER|(DESHABILITADO)|${GREEN}OK";fi
fi
if [ $(systemctl status firewalld | grep " active " | wc -l) -eq 1 ]; then texto+="\n${WHITE}FIREWALLD|(LEVANTADO)|${RED}INCORRECTO"; servicio_status="INCORRECTO";
else texto+="\n${WHITE}FIREWALLD|(DETENIDO) |${GREEN}OK"; fi
if [ $(systemctl is-enabled firewalld | grep "enable" | wc -l) -eq 1 ]; then texto+="\n${WHITE}FIREWALLD|(HABILITADO)|${RED}INCORRECTO"; servicio_status="INCORRECTO";
else texto+="\n${WHITE}FIREWALLD|(DESHABILITADO)|${GREEN}OK"; fi
if [ $(getenforce | grep "Disabled" | wc -l) -eq 1 ]; then texto+="\n${WHITE}SELINUX|(DETENIDO)|${GREEN}OK";
else texto+="\n${WHITE}SELINUX|(LEVANTADO)|${RED}INCORRECTO"; servicio_status="INCORRECTO"; fi
if [ $(systemctl get-default | grep "multi-user" | wc -l) -eq 1 ]; then texto+="\n${WHITE}RUNLEVEL 3|(ESTABLECIDO)|${GREEN}OK";
else texto+="\n${WHITE}RUNLEVEL 3|(NO ESTABLECIDO)|${RED}INCORRECTO"; servicio_status="INCORRECTO"; fi
if [ $(grep -i ^NOZEROCONF=yes /etc/sysconfig/network | wc -l) -eq 1 ]; then texto+="\n${WHITE}ZEROCONF|(ESTABLECIDO)|${GREEN}OK";
else texto+="\n${WHITE}ZEROCONF|(NO ESTABLECIDO)|${RED}INCORRECTO"; servicio_status="INCORRECTO"; fi
escribir_encerar_texto

# COMANDOS
echo -e "\n${PURPLE}COMANDOS";
for i in bc vim-enhanced tar zip java*jdk tcpdump nmap-ncat bind-utils iotop sysstat net-tools filesystem lsof traceroute bash-completion rsync chrony cockpit htop zabbix-agent2;
do
        if [ $(rpm -qa $i | wc -l) -eq 0 ]; then texto+="\n${WHITE}PAQUETE $i|(NO INSTALADO)|${RED}INCORRECTO"; comandos_status="INCORRECTO";
        else texto+="\n${WHITE}PAQUETE $i|(INSTALADO)|${GREEN}OK"; fi
done;
if [ $(systemctl is-active netdata | grep "^active" | wc -l) -eq 1 ]; then texto+="\n${WHITE}NETDATA|(LEVANTADO)|${GREEN}OK";
else texto+="\n${WHITE}NETDATA|(DETENIDO)|${RED}INCORRECTO"; comandos_status="INCORRECTO"; fi
escribir_encerar_texto


# KERNEL
echo -e "\n${PURPLE}KERNEL";
for i in net.ipv4.ip_forward net.ipv4.conf.default.accept_source_route net.ipv4.conf.all.accept_source_route net.ipv4.conf.all.accept_redirects net.ipv4.conf.default.accept_redirects net.ipv4.conf.all.secure_redirects net.ipv4.conf.default.secure_redirects;
do
        if [ $(sysctl $i -b) -eq 0 ]; then texto+="\n${WHITE}VARIABLE $i|(ESTABLECIDO)|${GREEN}OK";
        else texto+="\n${WHITE}VARIABLE $i|(NO ESTABLECIDO)|${RED}INCORRECTO"; kernel_status="INCORRECTO"; fi
done;
for i in net.ipv4.conf.default.rp_filter net.ipv4.tcp_syncookies net.ipv4.icmp_echo_ignore_broadcasts net.ipv4.icmp_ignore_bogus_error_responses net.ipv4.conf.all.log_martians net.ipv4.conf.default.log_martians net.ipv4.conf.all.rp_filter;
do
        if [ $(sysctl $i -b) -eq 1 ]; then texto+="\n${WHITE}VARIABLE $i|(ESTABLECIDO)|${GREEN}OK";
        else texto+="\n${WHITE}VARIABLE $i|(NO ESTABLECIDO)|${RED}INCORRECTO"; kernel_status="INCORRECTO"; fi
done;
if [ $(sysctl net.ipv4.tcp_fin_timeout -b) -eq 25 ]; then texto+="\n${WHITE}VARIABLE sysctl net.ipv4.tcp_fin_timeout|(ESTABLECIDO)|${GREEN}OK";
else texto+="\n${WHITE}VARIABLE sysctl net.ipv4.tcp_fin_timeout|(NO ESTABLECIDO)|${RED}INCORRECTO"; kernel_status="INCORRECTO"; fi

if [ $(cat /sys/module/ipv6/parameters/disable) -eq 1 ]; then texto+="\n${WHITE}IPV6 DESHABILITADO $i|(ESTABLECIDO)|${GREEN}OK";
else texto+="\n${WHITE}IPV6 DESHABILITADO $i|(NO ESTABLECIDO)|${RED}INCORRECTO"; kernel_status="INCORRECTO"; fi

escribir_encerar_texto
sleep 2;

# NTP Y ZONA HORARIA
echo -e "\n${PURPLE}NTP Y ZONA HORARIA"
if [ $(timedatectl | grep zone | awk '{ print $3 }') = America/Guayaquil ]; then texto+="\n${WHITE}ZONA HORARIA|(ESTABLECIDO)|${GREEN}OK";
else texto+="\n${WHITE}ZONA HORARIA (NO ESTABLECIDO)\t${RED}INCORRECTO"; ntp_status="INCORRECTO"; fi
if [ $(systemctl is-active chronyd | grep "^active" | wc -l) -eq 1 ]; then texto+="\n${WHITE}CHRONY|(LEVANTADO)|${GREEN}OK";
else texto+="\n${WHITE}CHRONY|(DETENIDO)|${RED}INCORRECTO"; ntp_status="INCORRECTO"; fi
if [ $(grep "130.2.2.159" /etc/chrony.conf | wc -l) -eq 1 ]; then texto+="\n${WHITE}SERVER NTP 1|(ESTABLECIDO)|${GREEN}OK";
else texto+="\n${WHITE}SERVER NTP 1|(NO ESTABLECIDO)|${RED}INCORRECTO"; ntp_status="INCORRECTO"; fi
if [ $(grep "130.2.18.61" /etc/chrony.conf | wc -l) -eq 1 ]; then texto+="\n${WHITE}SERVER NTP 1|(ESTABLECIDO)|${GREEN}OK";
else texto+="\n${WHITE}SERVER NTP 2|(NO ESTABLECIDO)|${RED}INCORRECTO"; ntp_status="INCORRECTO"; fi
escribir_encerar_texto
sleep 2;

# SEGURIDAD
echo -e "\n${PURPLE}SEGURIDAD"
if [ $(grep ^PASS_MAX_DAYS /etc/login.defs | awk '{ print $2 }') -eq 45 ]; then texto+="\n${WHITE}PASS_MAX_DAYS|(ESTABLECIDO)|${GREEN}OK";
else texto+="\n${WHITE}PASS_MAX_DAYS|(NO ESTABLECIDO)|${RED}INCORRECTO"; seguridad_status="INCORRECTO"; fi
if [ $(grep ^PASS_MIN_DAYS /etc/login.defs | awk '{ print $2 }') -eq 20 ]; then texto+="\n${WHITE}PASS_MIN_DAYS|(ESTABLECIDO)|${GREEN}OK";
else texto+="\n${WHITE}PASS_MIN_DAYS|(NO ESTABLECIDO)|${RED}INCORRECTO"; seguridad_status="INCORRECTO"; fi
if [ $(grep ^PASS_MIN_LEN /etc/login.defs | awk '{ print $2 }') -eq 8 ]; then texto+="\n${WHITE}PASS_MIN_LEN|(ESTABLECIDO)|${GREEN}OK";
else texto+="\n${WHITE}PASS_MIN_LEN|(NO ESTABLECIDO)|${RED}INCORRECTO"; seguridad_status="INCORRECTO"; fi
if [ $(grep ^PASS_WARN_AGE /etc/login.defs | awk '{ print $2 }') -eq 30 ]; then texto+="\n${WHITE}PASS_WARN_AGE|(ESTABLECIDO)|${GREEN}OK";
else texto+="\n${WHITE}PASS_WARN_AGE|(NO ESTABLECIDO)|${RED}INCORRECTO"; seguridad_status="INCORRECTO"; fi
if [ $(grep ^INACTIVE /etc/default/useradd | awk -F '=' '{ print $2 }') -eq 15 ]; then texto+="\n${WHITE}INACTIVE|(ESTABLECIDO)|${GREEN}OK";
else texto+="\n${WHITE}INACTIVE|(NO ESTABLECIDO)|${RED}INCORRECTO"; seguridad_status="INCORRECTO"; fi
if [ $(grep ^CREATE_MAIL_SPOOL /etc/default/useradd | awk -F '=' '{ print $2 }') = no ]; then texto+="\n${WHITE}CREATE_MAIL_SPOOL|(ESTABLECIDO)|${GREEN}OK";
else texto+="\n${WHITE}CREATE_MAIL_SPOOL|(NO ESTABLECIDO)|${RED}INCORRECTO"; seguridad_status="INCORRECTO"; fi
if [ $(grep ^TMOUT /etc/profile | awk -F '=' '{ print $2 }') -eq 1200 ]; then texto+="\n${WHITE}TMOUT|(ESTABLECIDO)|${GREEN}OK";
else texto+="\n${WHITE}TMOUT|(NO ESTABLECIDO)|${RED}INCORRECTO"; seguridad_status="INCORRECTO"; fi
if [ $(grep ^'export TMOUT' /etc/profile | awk '{ print $2 }' | wc -l ) -eq 1 ]; then texto+="\n${WHITE}EXPORT DEL PROFILE|(ESTABLECIDO)|${GREEN}OK";
else texto+="\n${WHITE}EXPORT DEL PROFILE|(NO ESTABLECIDO)|${RED}INCORRECTO"; seguridad_status="INCORRECTO"; fi
if [ $(grep "pam_cracklib.so try_first_pass retry=3 minlen=8 lcredit=-1 ucredit=-1 dcredit=-1 ocredit=-1" /etc/pam.d/system-auth | awk '{ print $2 }' | wc -l) -eq 1 ]; then texto+="\n${WHITE}COMPLEJIDAD DE PASSWORD|(ESTABLECIDO)|${GREEN}OK";
else texto+="\n${WHITE}COMPLEJIDAD DE PASSWORD|(NO ESTABLECIDO)|${RED}INCORRECTO"; seguridad_status="INCORRECTO"; fi
if [ $(grep "pam_unix.so md5 shadow nullok try_first_pass use_authtok remember=3" /etc/pam.d/system-auth | awk '{ print $2 }' | wc -l) -eq 1 ]; then texto+="\n${WHITE}HISTORIAL DE PASSWORD|(ESTABLECIDO)|${GREEN}OK";
else texto+="\n${WHITE}HISTORIAL DE PASSWORD|(NO ESTABLECIDO)|${RED}INCORRECTO"; seguridad_status="INCORRECTO"; fi
escribir_encerar_texto
sleep 2;

# MONITOR
echo -e "\n${PURPLE}MONITOR";
if [ $(getent passwd monitor) ]; then texto+="\n${WHITE}USUARIO MONITOR|(CREADO)|${GREEN}OK";
else texto+="\n${WHITE}USUARIO MONITOR|(NO CREADO)|${RED}INCORRECTO"; monitor_status="INCORRECTO"; fi
if [ -d /var/log/monitor ]; then texto+="\n${WHITE}DIRECTORIO DE LOGS|(CREADO)|${GREEN}OK";
else texto+="\n${WHITE}DIRECTORIO DE LOGS|(NO CREADO)|${RED}INCORRECTO";  monitor_status="INCORRECTO"; fi
if [ -f /etc/logrotate.d/monitorlog ]; then texto+="\n${WHITE}LOGROTATE DE MONITOR|(CREADO)|${GREEN}OK";
else texto+="\n${WHITE}LOGROTATE DE MONITOR|(NO CREADO)|${RED}INCORRECTO";  monitor_status="INCORRECTO"; fi
escribir_encerar_texto
sleep 2;

# PERSONALIZACION
echo -e "\n${PURPLE}PERSONALIZACION";
if [ -f /etc/profile.d/sysinfo.sh ]; then texto+="\n${WHITE}INFORMACION DEL SISTEMA|(CREADO)|${GREEN}OK";
else texto+="\n${WHITE}INFORMACION DEL SISTEMA|(NO CREADO)|${RED}INCORRECTO";  personalizacion_status="INCORRECTO"; fi
escribir_encerar_texto
sleep 2;

#RESUMEN
echo -e "\n${PURPLE} - - - - - - - - - - - - R E S U M E N - - - - - - - - - - -";
texto+="\n${YELLOW}| ═══════════════════════ | ══════════════════════| ";
texto+="\n${YELLOW}| - - - -  ITEM - - - - | - - - - STATUS - - - - | ";
texto+="\n${YELLOW}| ═══════════════════════ | ══════════════════════| ";

if [[ $servicio_status = "OK" ]]; then texto+="\n${GREEN}|║SERVICIOS|║OK|║";
else texto+="\n${RED}|║ SERVICIOS|║INCORRECTO|║"; fi
if [[ $comandos_status = "OK" ]]; then texto+="\n${GREEN}|║COMANDOS|║OK|║";
else texto+="\n${RED}|║COMANDOS|║INCORRECTO|║"; fi
if [[ $kernel_status = "OK" ]]; then texto+="\n${GREEN}|║KERNEL|║OK|║";
else texto+="\n${RED}|║KERNEL|║INCORRECTO|║"; fi
if [[ $ntp_status = "OK" ]]; then texto+="\n${GREEN}|║NTP Y ZONA|║OK|║";
else texto+="\n${RED}|║NTP Y ZONA|║INCORRECTO|║"; fi
if [[ $seguridad_status = "OK" ]]; then texto+="\n${GREEN}|║SEGURIDAD|║OK|║";
else texto+="\n${RED}|║SEGURIDAD|║INCORRECTO|║"; fi
if [[ $monitor_status = "OK" ]]; then texto+="\n${GREEN}|║MONITOR|║OK|║";
else texto+="\n${RED}|║MONITOR|║INCORRECTO|║"; fi
if [[ $personalizacion_status = "OK" ]]; then texto+="\n${GREEN}|║PERSONALIZACION|║OK|║";
else texto+="\n${RED}|║PERSONALIZACION|║INCORRECTO|║"; fi
texto+="\n${YELLOW}| ═══════════════════════ | ═════════════════════| ";

escribir_encerar_texto
echo -e "${NC}";
