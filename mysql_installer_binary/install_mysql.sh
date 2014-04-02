#!/bin/bash
##
## created by penghy 20130531

whole_path=`lsof | grep ${0} | awk '{print $NF}'`
current_dir=${whole_path%/*}

# {{{ color function
function print_green(){
        echo -en "\e[1;32;40m`printf \"%-20s\" \"$1\"`\e[0m"
}

function print_red(){
        echo -e "\e[1;31;40m$1\e[0m"
}

function print_yellow(){
        echo -e "\e[1;33;40m$1\e[0m"
}
# }}}

# {{{ print help and get arguments
usage()
{
	tip1="Install single instance in 3306"
	tip2="Install 3306 with_buffer_pool size 11G"
	tip3="Install multi instances in 3306,3307,3308"
	tip4="Install 3306 with buffer pool size 6G, install 3307 wtih buffer_pool_size 6G,etc..."
	tip5="Specific server character set, default latin1"
	tip6="Print this help info"
	echo -e "  Usage: "
	printf "    %-55s%s\n" "${0}" "${tip1}"
	printf "    %-55s%s\n" "${0} -i 3306 -b 10G" "${tip2}"
	printf "    %-55s%s\n" "${0} -i 3306,3307,3308" "${tip3}"
	printf "    %-55s%s\n" "${0} -i 3306,3307,3308 -b 6G,6G,12G" "${tip4}"
	printf "    %-55s%s\n" "${0} -c utf8" "${tip5}"
	printf "    %-55s%s\n" "${0} -h" "${tip6}"
}

while getopts "i:b:c:h" OPT; do
    case $OPT in
        "i")
        INSTANCES=(`echo $OPTARG | tr ',' ' '`)
        ;;
        "b")
        BUFFERS=(`echo $OPTARG | tr ',' ' '`)
        ;;
        "c")
        CHARSET=$OPTARG
        ;;
		"h")
		usage
		exit
		;;
    esac
done
# }}}

# {{{ check_arguments
check_arguments(){
	for port in ${INSTANCES[@]}
	do
		is_port_legal=`echo ${port} | egrep -qw '33[0-9]{2}' && echo ok || echo false`
		if [[ ${is_port_legal} != 'ok' ]]; then
			print_red "The instances parameter must be given like mysql port 33%%."
			exit 1
		fi
	done

	if [[ ${#INSTANCES[@]} -ne ${#BUFFERS[@]} ]] && [[ ${#BUFFERS[@]} -ne 0 ]]; then
		print_red "The numbers of instances and buffer parameters must be equal."
		exit 1
	else
		sum_buff=0
		for buff in ${BUFFERS[@]}
		do
			is_buff_legal=`echo ${buff} | egrep -qw '[0-9]+G' && echo ok || echo false`
			if [[ ${is_buff_legal} != 'ok' ]]; then
				print_red "The buffer parameters must be integer based on unit of G."
				exit 1
			else
				sum_buff=$(( ${sum_buff} + ${buff%*G} ))
			fi
		done
		total_mem=`grep MemTotal /proc/meminfo | awk '{print $2}'`
		sum_buff=$(( ${sum_buff} * 1024 * 1024 ))
		is_buff_ok=`awk "BEGIN{if( ${sum_buff} >= ${total_mem}*0.8 ) print \"false\"; else print \"ok\"}"`
		if [[ ${is_buff_ok} == 'false' ]]; then
			print_red "The sum of buffer must less than 80% of the physical memory"
			exit 1
		fi
	fi
}
# }}}

# {{{ basic settings
basic(){
	if [ -d $datadir ] && [ `du -sk $datadir | awk '{print $1}'` -gt 2306867 ]; then
		print_red "There is another mysqld instances exits !"
		exit 1
	fi

	if [[ -d /usr/local/mysql ]]; then
		print_red "MySQL exists!"
		exit 1
	fi
	
	[[ ${CHARSET} ]] || CHARSET=latin1

	chattr -i /etc/shadow
	/usr/sbin/groupadd mysql
	/usr/sbin/useradd -M mysql -g mysql -s /sbin/nologin
	chattr +i /etc/shadow

	mkdir /usr/local/mysql
	cp -r ${current_dir}/tools/bin ${current_dir}/tools/include ${current_dir}/tools/lib ${current_dir}/tools/libexec ${current_dir}/tools/share ${current_dir}/tools/support-files /usr/local/mysql
	[[ -e "${current_dir}/tools/support-files/mysql.server" ]] && cp ${current_dir}/tools/support-files/mysql.server /etc/init.d/mysql
	[[ -e "${current_dir}/tools/support-files/mysql" ]] && cp ${current_dir}/tools/support-files/mysql /etc/init.d/mysql
	ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql
	ln -s /usr/local/mysql/bin/mysqladmin /usr/bin/mysqladmin
	ln -s /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump
	if [[ `echo ${PATH} | grep -q /usr/local/mysql && echo ok || echo false` -eq "false" ]]; then
		echo "export PATH=\$PATH:/usr/local/mysql/bin" >> /etc/bashrc
		source /etc/bashrc
	fi
	chown -R mysql:mysql /usr/local/mysql

	hostname=`hostname`
	cat ${current_dir}/my.template | sed "s/HOSTNAME/${hostname}/g;s/CHAR/${CHARSET}/g" > /etc/my.cnf
}
# }}}

# {{{ instance initialization
auto_init(){
	[[ ${#INSTANCES[@]} -eq 0 ]] && INSTANCES=(3306)
	[[ ${CHARSET} ]] || CHARSET=latin1
	for ins in ${INSTANCES[@]}
	do
		mkdir /home/mysql_${ins}
		chown -R mysql:mysql /home/mysql_${ins}
		# {{{ auto specific innodb_buffer_pool_size 
		Mem=`grep MemTotal /proc/meminfo | awk '{print $2}'`
		if [ $Mem -lt 4194304 ] ; then
			print_red "Total memory less than 4G, exit install!"
			exit 1
		# 8G
		elif [ $Mem -gt 8088608 ] && [ $Mem -lt 8388608 ] ; then
			case ${#INSTANCES[@]} in
				'4')
				print_red "Too little memory to auto init ${#INSTANCES[@]} instances!"
				exit 1
				;;

				'3')
				print_red "Too little memory to auto init ${#INSTANCES[@]} instances!"
				exit 1
				;;

				'2')
				BUFFERS='3G'
				;;

				'1')
				BUFFERS='6G'
				;;
			esac
		# 16G
		elif [ $Mem -gt 14777216 ] && [ $Mem -lt 16777216 ] ; then
			case ${#INSTANCES[@]} in
				'4')
				print_red "Too little memory to auto init ${#INSTANCES[@]} instances!"
				exit 1
				;;

				'3')
				BUFFERS='4G'
				;;

				'2')
				BUFFERS='6G'
				;;

				'1')
				BUFFERS='12G'
				;;
			esac
		# 32G
		elif [ $Mem -gt 31554432 ] && [ $Mem -lt 33554432 ] ; then
			case ${#INSTANCES[@]} in
				'4')
				BUFFERS='6G'
				;;

				'3')
				BUFFERS='8G'
				;;

				'2')
				BUFFERS='12G'
				;;

				'1')
				BUFFERS='26G'
				;;
			esac
		else
			print_red "Unknow memory size, install exits"
			exit 1
		fi
		# }}} 
		cat ${current_dir}/single.template | sed "s/PORT/${ins}/g;s/BUFFER_G/${BUFFERS}/g;s/CHAR/${CHARSET}/g" >> /etc/my.cnf
		/usr/local/mysql/bin/mysql_install_db --user=mysql --datadir=/home/mysql_${ins} --basedir=/usr/local/mysql
	done
}

spec_init(){
	[[ ${CHARSET} ]] || CHARSET=latin1
	for i in `seq 0 $(( ${#INSTANCES[@]} - 1 ))`
	do
		cat ${current_dir}/single.template | sed "s/PORT/${INSTANCES[${i}]}/g;s/BUFFER_G/${BUFFERS[${i}]}/g;s/CHAR/${CHARSET}/g" >> /etc/my.cnf
	done
	for ins in ${INSTANCES[@]}
	do
		mkdir /home/mysql_${ins}
		chown -R mysql:mysql /home/mysql_${ins}
		/usr/local/mysql/bin/mysql_install_db --user=mysql --datadir=/home/mysql_${ins} --basedir=/usr/local/mysql
	done
}
# }}}

check_arguments
basic
if [[ ${#BUFFERS[@]} -eq 0 ]]; then
	auto_init
else
	spec_init
fi
chown mysql:mysql /etc/my.cnf
source /etc/bashrc
if [[ ${#INSTANCES[@]} -gt 1 ]]; then
    rm -rf /etc/init.d/mysql
    rm -rf /etc/init.d/mysqld
    mysqld_multi start
else
    [[ -e "/etc/init.d/mysql" ]] && service mysql start 
    [[ -e "/etc/init.d/mysqld" ]] && service mysqld start 
fi
print_red "You should execute 'source /etc/bashrc' to make \$PATH come into effect."
