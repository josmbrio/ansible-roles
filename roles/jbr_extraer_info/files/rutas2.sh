#!/bin/bash


cd /root


#ROUTES
interfaces=$(ip route show | grep -v "169.254.0.0" | grep "proto kernel" | grep -o "dev [A-Za-z0-9]* " | awk '{print $2}' | sort -n | uniq)
for interface in ${interfaces[@]}
do
  ip route show table all | grep -e ^default -e ^"[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | egrep -v '(proto kernel|169.254.0.0)' | grep -v "$(ip route | grep default)" | grep $interface > route-$interface
  if [ ! -s route-$interface ]
  then
    rm -f route-$interface
  fi 
done


#RULES
ips=$(ip rule | egrep -v '(table local|table main|table default)' | awk '{print $3}' | grep ".*\..*\..*\..*" | sort -n | uniq)
for ip in ${ips[@]}
do
   interface=$(ip addr | grep -w $ip | awk '{printf $NF}')
   ip rule | sed -e 's/.*from/from/g' -e 's/lookup/table/g' | egrep -v '(table local|table main|table default)' | grep $ip | sort | uniq > rule-$interface
done




