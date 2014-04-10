#!/bin/bash

while getopts "S:h:u:p:" OPT; do
    case $OPT in
        "S")
        sock="-S $OPTARG"
        ;;
        "h")
        host="-h $OPTARG"
        ;;
        "u")
        username="-u $OPTARG"
        ;;
        "p")
        password="-p$OPTARG"
        ;;
    esac

done

options="${sock} ${host} ${username} ${password}"

rm -rf /tmp/.get_grants.tmp $> /dev/null
mysql ${options} -N -e "SELECT user,host FROM  mysql.user WHERE user != 'root';" > /tmp/.get_grants.tmp

while read LINE
do
user=`echo ${LINE} | awk '{print $1}'`
host=`echo ${LINE} | awk '{print $2}'`
echo -e "\e[40;33;1m####### GRANTS FOR ${user}@${host} #######\e[0m"
mysql ${options} -e "SHOW GRANTS FOR '${user}'@'${host}'"
done < /tmp/.get_grants.tmp

rm -rf /tmp/.get_grants.tmp $> /dev/null
