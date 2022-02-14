#!/bin/bash

# by onephone@20170709

#set -e # exit if any command return non zero
#set -x # print commands

PROJECTNAME="minipj"

[ $# -eq 0 ] && echo -e "Please input UsernameFile.txt! \n    sh $0 UsernameFile" && exit

yum install git -y > /dev/null

id git &> /dev/null
[ ! $? -eq 0 ] && useradd git -s /usr/bin/git-shell -d /git

if [ ! -d /git/${PROJECTNAME}.git ]; then
    echo "build ${PROJECTNAME}.git"
    git init --bare /git/${PROJECTNAME}.git > /dev/null
    chown git:git /git/${PROJECTNAME}.git
    chmod 0775 /git/${PROJECTNAME}.git
fi

while read username; do
    id $username &> /dev/null
    [ $? -eq 0 ] && echo "$username existed!" && continue
    useradd $username -s /usr/bin/git-shell -M -N -g git
    echo $username | passwd --stdin $username
    [ $? -eq 0 ] && echo "$username add successfully!"
done <$1  #UsernameFile

echo -e "\nsh $0 END!"
