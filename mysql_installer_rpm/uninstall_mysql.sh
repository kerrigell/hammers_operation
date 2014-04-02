#!/bin/bash
#
# Delete mysql form system and clean up data
# Created by Penghy 2013-04-22

all_datadir=(`ls -1Fd /home/mysql* 2>/dev/null | egrep '/$' | egrep "mysql_[0-9]{4}/|mysql/"`)
all_socketfiles=(`ls -1 /home/mysql*/mysql.sock 2>/dev/null`) 2> /dev/null

for sock in ${all_socketfiles[@]}
do
	conned=`mysqladmin -S ${sock} ext | grep -i threads_connected | egrep -o '[0-9]+'`
	port=`ps aux | grep ${sock} | egrep -o '\-\-port=[0-9]{4}' | egrep -o [0-9]{4} | uniq`
	if [[ ${conned} -gt 2 ]]; then
		read -p "Instances ${port} has ${conned} threads connected, UNINSTALL? (Y/n) " yon
		[[ ${yon} != 'Y' ]] && exit 1
	fi
done

killall -9 mysqld_safe 2>/dev/null
killall -9 mysqld 2>/dev/null

for datadir in ${all_datadir[@]}
do
	read -p "Datadir ${datadir} founded, Clean up? (Y/n) " yon
	[[ ${yon} == 'Y' ]] && rm -rf ${datadir}
done

(rpm -qa | grep Percona &>/dev/null) && (rpm -qa | grep Percona | tac | xargs rpm -e --nodeps)
(rpm -qa | grep '^mysql-' &>/dev/null) && (rpm -qa | grep '^mysql-' | xargs rpm -e --nodeps)

chattr -i /etc/shadow
/usr/sbin/groupdel -r mysql 2> /dev/null
/usr/sbin/userdel -r mysql 2> /dev/null
chattr +i /etc/shadow
