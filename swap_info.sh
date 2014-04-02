#!/bin/bash
#######################################################
# Featrue:check swap
#######################################################
#echo -e "PID\t\tSwap\t\tProc_Name"
printf "%-15s%-15s%-15s\n" "PID" "Swap" "Proc_name"

for pid in `ls -l /proc | grep ^d | awk '{print $9}'| grep -v [^0-9]`
do
        if [ ${pid} -eq 1 ];then
                continue
        fi # Do not check init process
        grep -q "Swap" /proc/${pid}/smaps 2>/dev/null
        if [ $? -eq 0 ];then
                swap=`grep Swap /proc/${pid}/smaps | gawk '{ sum+=$2;} END{ print sum }'`
                proc_name=`ps aux | grep -w "$pid" | grep -v grep | awk '{ for(i=11;i<=NF;i++){ printf("%s ",$i); }}'`
                if [ $swap -gt 0 ];then
                        #echo -e "$pid\t\t${swap}\t\t$proc_name"
                        printf "%-15s%-15s%-15s\n" "${pid}" "${swap}" "${proc_name}"
                fi
        fi
done | sort -k2 -nr | gawk '{
pid[NR]=$1;
size[NR]=$2;
name[NR]=$3;
}
END{
for(id=1;id<=length(pid);id++)
{
if(size[id]<1024)
printf("%-15s%-15s%-s\n",pid[id],size[id]"K",name[id]);
else if(size[id]<1048576)
printf("%-15s%-15s%-s\n",pid[id],size[id]/1024"M",name[id]);
else
printf("%-15s%-15s%-s\n",pid[id],size[id]/1048576"G",name[id]);
}
}'
