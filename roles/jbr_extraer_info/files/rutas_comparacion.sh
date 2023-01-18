#!/bin/bash

echo
echo "============================== ROUTES =============================="

for file in $(ls -1 route-*)
do
  if [ -s "/etc/sysconfig/network-scripts/$file" ]
  then
	cat /etc/sysconfig/network-scripts/$file | grep -v ^# > routefile.tmp
	while read line
    do
	  dest=$(echo "$line" | awk '{print $1}')
      grep "$dest" routefile.tmp > /dev/null
	  if [ $? -eq 1 ]
	  then
	    echo "$line" >> xxx.tmp
	  fi
    done < $file
	if [ -s xxx.tmp ]
	then
      echo
      echo "----------------- $file - Incompleto. Agregar: ----------------"
      cat xxx.tmp
	  rm -f xxx.tmp
	else
	  echo
	  echo "---------------------- $file - Completo -----------------------"
	fi
  else
    echo
    echo "------------------- $file - No Existe. Agregar -----------------"
	cat $file
  fi  
done

echo
echo "============================== RULES ==============================="

for file in $(ls -1 rule-*)
do
  if [ -s "/etc/sysconfig/network-scripts/$file" ]
  then
	cat /etc/sysconfig/network-scripts/$file | grep -v ^# > rulefile.tmp
	while read line
    do
	  rule=$(echo "$line")
      grep "$rule" rulefile.tmp > /dev/null
	  if [ $? -eq 1 ]
	  then
	    echo "$line" >> yyy.tmp
	  fi
    done < 	$file
	if [ -s yyy.tmp ]
	then
      echo
      echo "----------------- $file - Incompleto. Agregar: ----------------"
      cat yyy.tmp
	  rm -f yyy.tmp
	else
	  echo
	  echo "----------------------- $file - Completo ----------------------"
	fi
  else
    echo
    echo "------------------- $file - No Existe. Agregar -----------------"
	cat $file
  fi  
done

echo

rm -f routefile.tmp
rm -f rulefile.tmp
