#!/bin/bash
# 统计文件信息显示各类文件的数目

if [ $# -ne 1 ];
then
    echo "Usage is $0 basepath";
    exit
fi

path=$1

declare -A statarray;

while read line;
do
    ftype=`file -b "$line" | cut -d, -f1`;
    let statarray["$ftype"]++;
done < <(find $path -type f -print) 

echo ====== File types and couts ======
for ftype in "${!statarray[@]}";
do
    echo -e $ftype : "\e[1;31m" ${statarray["$ftype"]} "\e[0m"
done
