#!/bin/bash

####################################
#   use for vn tlbb gamedb update  #
#   created by penghy 20121016     #
###################################

# init variables
serverlist="/home/dba/dblists/alldbservers.txt"
date=`date +%Y%m%d`
remote_dir="/tmp/${date}"
# please fill out your script filename here, order by your execute order
order_scriptname=(
DBUpdate_3_15_0130_mysql.sql
StatDBUpdate_3_3_15_0130_table.sql
test_scripts.sql
)
md5file="./md5.txt"
logfile="./gamedb_update_${date}.log"


iplist=`egrep -v '^#|^$' ${serverlist} | grep TLBB-[0-9].*-DB | grep -iv test | awk '{print $1}'`

while getopts "c:i:d:" OPT; do
	case $OPT in
		"c") 
		command=$OPTARG
		;;
		"i") 
		script_id=$OPTARG
		;;
		"d") 
		db_name=$OPTARG
		;;
	esac

done

upload(){
	for ip in ${iplist}
	do
		group=`grep ${ip} ${serverlist} | egrep -v '^#|^$' | awk '{print $3}'` 
		echo -e "\e[1;32;40m###################  upload ${ip}\t${group} #######################\e[0m" 
		ssh ${ip} "mkdir -p ${remote_dir}" 
		for script in ${order_scriptname[@]}
		do
			scp ${script} ${ip}:${remote_dir}
		done
		scp ${md5file} ${ip}:${remote_dir}
	done
}


verify_script(){
	for ip in ${iplist}
	do
		group=`grep ${ip} ${serverlist} | egrep -v '^#|^$' | awk '{print $3}'` 
		echo -e "\e[1;32;40m###################  verify ${ip}\t${group} #######################\e[0m" 
		for script in ${order_scriptname[@]}
		do
			ssh ${ip} "cd ${remote_dir} && md5sum ${script}"
		done
		echo -e "---------------------------------------------------"
		ssh ${ip} "cd ${remote_dir} && cat ${md5file}"
	done
}

check_connection(){
	for ip in ${iplist}
	do
		group=`grep ${ip} ${serverlist} | egrep -v '^#|^$' | awk '{print $3}'` 
		echo -e "\e[1;32;40m###################  conn ${ip}\t${group} #######################\e[0m" 
		ssh ${ip} "mysqladmin pr"
	done
	
}

backup_db(){
	for ip in ${iplist}
	do
		group=`grep ${ip} ${serverlist} | egrep -v '^#|^$' | awk '{print $3}'` 
		echo -e "\e[1;32;40m###################  backup ${ip}\t${group} #######################\e[0m" 
		ssh ${ip} "/bin/bash /home/databak/tlbb-tlbbdb-dump-gzip.sh" &
	done
}

check_backup(){
	for ip in ${iplist}
	do
		group=`grep ${ip} ${serverlist} | egrep -v '^#|^$' | awk '{print $3}'` 
		echo -e "\e[1;32;40m###################  check ${ip}\t${group} #######################\e[0m" 
		dump_ps_count=`ssh ${ip} "ps aux | grep 'dump' | grep -v grep | grep -v ssh | wc -l"`
		echo -e "dump process count: ${dump_ps_count}"
		if [[ ${dump_ps_count} -eq 0 ]]; then
			ssh ${ip} "ls -lthr /home/databak/ | tail -10"
		fi
	done
}

view_recover_file(){
	for ip in ${iplist}
	do
		group=`grep ${ip} ${serverlist} | egrep -v '^#|^$' | awk '{print $3}'` 
		echo -e "\e[1;32;40m###################  check ${ip}\t${group} #######################\e[0m" 
		ssh ${ip} "ls -1lthr /home/databak/*.gz | tail -1"
	done
}

recover(){
	for ip in ${iplist}
	do
		group=`grep ${ip} ${serverlist} | egrep -v '^#|^$' | awk '{print $3}'` 
		echo -e "\e[1;32;40m###################  check ${ip}\t${group} #######################\e[0m" 
		recover_file=`ssh ${ip} "ls -1thr /home/databak/*.gz | tail -1"`
		echo ${recover_file}
		read -p "Confirm Recover DB? {Y/n}" yon
		if [[ ${yon} == 'Y' ]]; then
			ssh ${ip} "mysql tlbbdb < ${recover_file}"
		fi
	done
}

execute_script(){
	for ip in ${iplist}
	do
		group=`grep ${ip} ${serverlist} | egrep -v '^#|^$' | awk '{print $3}'` 
		echo -e "\e[1;32;40m###################  execute ${ip}\t${group} #######################\e[0m" 
		ssh ${ip} "cd ${remote_dir} && mysql ${db_name} < ${order_scriptname[${script_id}]}"
	done
}

get_dbversion(){
	for ip in ${iplist}
	do
		group=`grep ${ip} ${serverlist} | egrep -v '^#|^$' | awk '{print $3}'` 
		echo -e "\e[1;32;40m###################  execute ${ip}\t${group} #######################\e[0m" 
		ssh ${ip} "mysql tlbbdb -e \"CALL db_getversion();\"" 
	done
}

get_help(){
	echo -e "\tusing server list: \e[1;32;40m${serverlist}\e[0m"
	echo -e "\tupdate log: \e[1;32;40m${logfile}\e[0m"
	echo -e "\tremote dir: \e[1;32;40m${remote_dir}\e[0m"
	echo -e "\tyour md5 file: \e[1;32;40m${md5file}\e[0m"
	echo -e "\tyour script list order by execute order:\t\t\e[1;32;40m"
	for i in `seq ${#order_scriptname[@]}`
	do
		id=$(($i - 1))
		echo -e "\t\t$id\t${order_scriptname[$id]}"
	done
	echo -e "\e[0m\t\e[1;31;40mPlease check all your variables has set coorectly!!\n\n\e[0m"
	
	
	echo -e "\tupdate step :\e[1;33;40m"
	echo -e "\t\t-c <upload>"
	echo -e "\t\t-c <verify_script>"
	echo -e "\t\t-c <check_connection>"
	echo -e "\t\t-c <backup_db>"
	echo -e "\t\t-c <check_backup>"
	echo -e "\t\t-c <view_recover_file>"
	echo -e "\t\t-c <recover>"
	echo -e "\t\t-c <get_dbversion>"
	echo -e "\t\t-c <execute_script> -d <db_name> -i <script_id>\n\e[0m"
	
}


case "${command}" in

	'upload')
	upload
	;;

	'verify_script')
	verify_script
	;;
	
	'check_connection')
	check_connection
	;;

	'backup_db')
	backup_db
	;;
	
	'check_backup')
	check_backup
	;;

	'view_recover_file')
	view_recover_file
	;;

	'recover')
	recover
	;;

	'get_dbversion')
	get_dbversion
	;;

	'execute_script')
	execute_script
	;;

	*)
	get_help
	;;
esac
