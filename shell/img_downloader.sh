#!/bin/bash

if [ $# -ne 3 ];
then
    echo "Usage: $0 URL -d DIRECTORY"
    exit -1
fi

for i in {1..4};
do
    case $1 in
    -d) shift; directory=$1; shift ;;
    *) url=${url:-$1}; shift ;;
    esac
done

mkdir -p $directory

baseurl=${url%/*}

echo Downloading $url
curl -s $url | grep -o -e "<img src=[^>]*>" | 
sed 's/<img src=\"\([^"]*\).*/\1/g' > /tmp/$$.list

sed -i '.bak' "s|^/\{0,1\}|$baseurl/|" /tmp/$$.list
cp /tmp/$$.list .

cd $directory

while read filename;
do
    echo Downloading $filename
    curl -s -O "$filename"
done < /tmp/$$.list
