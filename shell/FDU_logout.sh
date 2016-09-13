#!/bin/bash
read -p "input number: " name
#name=15210240000
read -s -p "input password: " password
pass=`echo -n "$password"|od -An -tx1 | tr ' ' %`
echo "" #for new line
wget http://10.108.255.249/cgi-bin/force_logout --post-data "username=$name&password=$pass&drop=0&type=1&n=1" -q
echo .
echo Wait for one minute!
echo .
echo "" #for new line
