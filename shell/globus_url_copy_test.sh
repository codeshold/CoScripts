#/bin/bash
#set -e

DELAY_SECOND=5
COUNT_400G=4
COPYLOG="/home/testfile/copy_${COUNT_400G}x400G_${DELAY_SECOND}.log"
DELLOG="/home/testfile/rm_${COUNT_400G}x400G_${DELAY_SECOND}.log"
IFPPSLOG="/home/testfile/ifpps_${COUNT_400G}x400G_${DELAY_SECOND}.log"

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
    globus-url-copy -r -p 2 gsiftp://gf02.863/home/testfile/$1/ file:///home/testfile/$1/
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
    echo $(($endtime-$begintime)) >> $DELLOG
}

###### main #####
## 总传输文件的大小为 4*400GB==1600GB
## 总传输文件的大小为 40*400GB==16TB

echo "" > $COPYLOG

# 10S统计一次
ifpps -lcd p5p2 -t 10000 > $IFPPSLOG &
IFPPS_PID=$!

# 时延设置
tc qdisc del dev p5p2 root netem delay ${DELAY_SECOND}ms &> /dev/null
tc qdisc add dev p5p2 root netem delay ${DELAY_SECOND}ms

rm -rf /home/testfile/one/*
rm -rf /home/testfile/two/*
mkdir -p /home/testfile/one
mkdir -p /home/testfile/two

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
    start_transfer $trans
    del_files $del
    # wait
    echo "=== [ $i ] current trans: $trans, del: $del END!!! === "
done

kill -s 9 $IFPPS_PID
echo "=== !!! END!!! === "

# head -n 10 ifpps_4x400G_5.log | cut -d " " -f 1-3

# for i in {1..4};do dd if=/dev/zero of=./100GB.$i.file count=100 bs=1GB; done
# dd if=/dev/zero of=./1GB.file count=1 bs=1GB
# time globus-url-copy gsiftp://gf02.863/etc/group file:///home/test
# globus-url-copy -r gsiftp://gf02.863/home/testfile file:///home/testfile/

# REF http://codeshold.me/2017/01/tc_inro.html
# tc qdisc add dev p5p2 root netem delay 10ms 2ms 30%
# tc qdisc add dev p5p2 root netem delay 10ms 10ms
# tc qdisc del dev p5p2 root netem delay 10ms
