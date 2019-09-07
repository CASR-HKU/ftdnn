#! /bin/bash

if [ $# != 2 ];then
    echo " Usage: ./run_sol.sh nn_model_file.csv hw_conf.csv";
    exit
fi

if ! [ -f $1 ] || ! [ -f $2 ] ; then
    echo "input file does not exist!"
fi

# set the interneal field separator
IFS=$'\n'

for hw_line in `awk 'NR>1' $2`
do
    # obtain the hw config from csv
    hw_conf=`echo $hw_line | awk -F ',' '{ for(idx=2;idx<8;idx++) print  " " $idx }'`
    echo "[hardware] config:" $hw_conf
    for line in `awk 'NR>1' $1`
    do
        # obtain the workload from csv
        workload=`echo $line | awk -F ',' '{ for(idx=3;idx<10;idx++) print  " " $idx }'`
        # check the status of CPU and memory (vmstat measured for each 2 seconds)
        while [ `vmstat 2 2 | awk 'NR==4{print $13}'` -gt 90 ] || [ $((`free -m | awk '/Mem/{print $3}'`)) -gt 150000 ] || [ `ps -A | grep python | awk 'END{ print NR }'` -gt 10 ]; do
        # while [ `ps -A | grep python | awk 'END{ print NR }'` -gt 10 ]; do
            echo "[wait] CPU:" `vmstat 2 2 | awk 'NR==4{print $13}'` "Memory:" $((`free -m | awk '/Mem/{print $3}'`))
            sleep 10
        done
        # execute the solution finder
        exec python fun_sim_conv.py --hw_conf $hw_conf --workload $workload &
        # print the issued workload
        echo "[issue] workload:" $workload
    done
done

echo "Finished reading."