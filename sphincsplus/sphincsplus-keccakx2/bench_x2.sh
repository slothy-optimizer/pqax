#!/bin/sh

if grep -Fq "sha3" /proc/cpuinfo
then
    sha3=1
else
    sha3=0
fi

warmup=$1
if [ -z $warmup ]; then
   warmup=1
fi

for cpu in 80 10 1; do

    if [ $sha3 -eq 0 ]; then
        vars="C COTHANV8"
        if [ $cpu -eq 80 ]; then
            cpuname=X1
        elif [ $cpu -eq 10 ]; then
            cpuname=A78
        else
            cpuname=A55
        fi
    else
        vars="C BAS COTHANV8"
        if [ $cpu -eq 80 ]; then
            cpuname=X2
        elif [ $cpu -eq 10 ]; then
            cpuname=A710
        else
            cpuname=A510
        fi
    fi

    echo "CPU $cpu $cpuname"
    benchdir=benchmarks_$cpuname
    mkdir -p $benchdir
    # the high performance cores may be asleep; we need to wake them up
    if [ $warmup -eq 1 ]; then
           if [ $cpu -ge 10 ]; then
               taskset 1 dd if=/dev/zero of=/dev/null &
               taskPid0=$!
               taskset 2 dd if=/dev/zero of=/dev/null &
               taskPid1=$!
               taskset 4 dd if=/dev/zero of=/dev/null &
               taskPid2=$!
               taskset 8 dd if=/dev/zero of=/dev/null &
               taskPid3=$!
           fi
           sleep 1
           if [ $cpu -ge 80 ]; then
               taskset 10 dd if=/dev/zero of=/dev/null &
               taskPid4=$!
               taskset 20 dd if=/dev/zero of=/dev/null &
               taskPid5=$!
               taskset 40 dd if=/dev/zero of=/dev/null &
               taskPid6=$!
           fi
           sleep 1
    fi

    for level in 128 192 256; do
        for t0 in f s; do
            for t1 in simple robust; do
                for var in $vars; do
                    param=sphincs-shake-${level}${t0}-${t1}
                    echo $param
                    exe=."/bin/bench_${cpuname}_${param}_${var}"
                    echo $exe
                    out="${benchdir}/${param}_${var}"
                    taskset $cpu $exe > $out
                done
            done
        done
    done

    if [ $warmup -eq 1 ]; then
        if [ $cpu -ge 10 ]; then
            kill $taskPid0
            kill $taskPid1
            kill $taskPid2
            kill $taskPid3
        fi
        if [ $cpu -ge 80 ]; then
            kill $taskPid4
            kill $taskPid5
            kill $taskPid6
        fi
    fi
done
