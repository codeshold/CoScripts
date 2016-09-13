#!/bin/bash
read -p "input number: " name
#name=15210240000
read -s -p "input password: " password
pass=`echo -n "$password"|od -An -tx1 | tr ' ' %`
echo "" #for new line
wget http://10.108.255.249/cgi-bin/do_login --post-data "username=$name&password={TEXT}$pass&drop=0&type=1&n=100"i -q
echo "" #for new line
