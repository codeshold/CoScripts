#!/bin/bash

LOGFILES=`find . -type f -name "*log*"`
LOGDATE="20170821 20170822"

for curdate in ${LOGDATE};do
    rm -rf ~/${curdate}_log.txt
    for file in ${LOGFILES}; do
        filename=`basename $file`
        echo $filename | grep -q "8080"
        if [ $? -eq 0 ]; then 
            port=":8080"
        else
            port=""
        fi
        server="${filename%%.com*}.com${port}"
        datestr=`date -d ${curdate} +"%d/%b/%Y"`
        curtime=`date +"%H:%M:%S"`
        echo "====[$curtime] $file $datestr $server ====="
        cat $file | grep $datestr | awk  -F "[ [\"]" '{ print $1, $5, "'$server'"$9 }' >> ~/${curdate}_log.txt
    done
done
