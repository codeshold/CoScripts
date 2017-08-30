#/bin/bash

set -e

trap 'myexit' INT QUIT TERM
 
## 总传输文件的大小为 4*400GB==1600GB
## 总传输文件的大小为 40*400GB==16TB
DELAY_MS=5
PARALLELISM=2
COUNT_400G=20
IFPPS_SECOND=10

CURDAY=$(date +%m%d_%H%M)
POSTFIX="${CURDAY}_${COUNT_400G}x400G_${DELAY_MS}ms_${PARALLELISM}para.log"
COPYLOG="/home/testfile/copy_${POSTFIX}"
DELLOG="/home/testfile/rm_${POSTFIX}"
IFPPSLOG="/home/testfile/ifpps_${POSTFIX}"

# gen_test_file one
function gen_test_file() {
    ofdir=$1
    cmd="for i in {1..4};do dd if=/dev/zero of=/home/testfile/${ofdir}/100GB.$1.file count=100 bs=1GB; done"
    ssh root@gf02.863 "$cmd"
}

# start_transfer one
function start_transfer() {
    echo "    globus-url-copy $1 file start!    "
    begintime=`date +%s`
    globus-url-copy -r -p $PARALLELISM gsiftp://gf02.863/home/testfile/$1/ file:///home/testfile/$1/
    endtime=`date +%s`
    echo "    globus-url-copy $i file end!    "
    echo $(($endtime-$begintime)) >> $COPYLOG
}

function del_files() {
    echo "    rm $i file start!    "
    begintime=`date +%s`
    rm -rf /home/testfile/$i/*
    endtime=`date +%s`
    echo "    rm $i file end!    "
    echo "    $(($endtime-$begintime))" #>> $DELLOG
}

function myexit(){
    sleep 2
    pids=$(ps aux | grep ifpps | grep ${DELAY_MS} | grep -v grep | awk '{print $2}')
    [ ! -z "$pids" ] && (echo $pids | xargs kill -s 9)
    tc qdisc del dev p5p2 root netem delay ${DELAY_MS}ms
    echo "    myexit!!!    "
}

function init_file(){
    rm -rf /home/testfile/one/*
    rm -rf /home/testfile/two/*
    rm -rf $COPYLOG
    rm -rf $IFPPSLOG
    mkdir -p /home/testfile/one
    mkdir -p /home/testfile/two
}

###### main #####

init_file

ifpps -lcd p5p2 -t "${IFPPS_SECOND}000" > $IFPPSLOG &
IFPPS_PID=$!
echo "    $IFPPS_PID    "

# 时延设置
tc qdisc add dev p5p2 root netem delay ${DELAY_MS}ms


# 获取证书
declare -x MYPROXY_SERVER_DN="/O=Grid/OU=GlobusTest/OU=simpleCA-gf02.863/CN=host/gf02.863"
echo "111111" | myproxy-logon -s gf02 -l quser -S

echo "*****************"
date
for i in `seq 1 $COUNT_400G`; do
    #is_even=$(($i%2))
    if [ $(($i%2)) -eq 1 ]; then
        trans="one"
        del="two"
    else
        trans="two"
        del="one"
    fi
    echo "=== [ $i ] current trans: $trans, del: $del START!!! === "
    del_files $del &
    start_transfer $trans
    # wait
    echo "=== [ $i ] current trans: $trans, del: $del END!!! === "
done
date
echo "****************"

myexit
echo "=== !!! END!!! === "



# for i in {1..4};do dd if=/dev/zero of=./100GB.$i.file count=100 bs=1GB; done
# dd if=/dev/zero of=./1GB.file count=1 bs=1GB
# time globus-url-copy gsiftp://gf02.863/etc/group file:///home/test
# globus-url-copy -r gsiftp://gf02.863/home/testfile file:///home/testfile/

# tc qdisc add dev p5p2 root netem delay 10ms 2ms 30%
# tc qdisc add dev p5p2 root netem delay 10ms 10ms
# tc qdisc del dev p5p2 root netem delay 10ms
