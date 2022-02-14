#!/bin/bash
read -p "input number: " name
read -s -p "input password: " password
pass=`echo -n "$password"|od -An -tx1 | tr ' ' %`
echo 
wget http://10.108.255.249/cgi-bin/do_login --post-data "username=$name&password={TEXT}$pass&drop=0&type=1&n=100"i -q -O /tmp/login.log
result=`cut /tmp/login.log -f 1`
if grep -q '^[[:digit:]]*$' <<< "$result"
then
    echo -e "\nSucceed!"
else
    echo -e "\nFailed!\t$result"
fi

