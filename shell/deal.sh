#!/usr/bin/bash
for line in $(cat $1)
do
	name=`echo $line | cut -d "," -f1`
	tel=`echo $line | cut -d "," -f2`
	money=`echo $line | cut -d "," -f3`
	tel_md5=`echo -n $tel | md5sum`
	echo "${name},${tel},${tel_md5:8:16},${money}" >> out.csv
done