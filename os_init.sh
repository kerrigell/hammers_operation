#!/bin/bash

platform=`uname -i`
version=`lsb_release -r | awk '{print substr($2,1,1)}'`
MODBLIST_5=/etc/modprobe.d/blacklist
whole_path=`lsof | grep ${0} | awk '{print $NF}'`
current_dir=${whole_path%/*}
vender=`dmidecode -s system-manufacturer 2> /dev/null`

# Check Arch
if [ $platform != "x86_64" ];then 
	echo "this script is only for 64bit Operating System !"
	exit 1
fi

# Check Release
if [ $version != 5 ];then
	echo "this script is only for RHEL 5 !"
	exit 1
fi

# {{{ 0. secondary function
# root passwd -- called by function basic_security()
function root_passwd(){
    chattr -i /etc/shadow &&\
    sed -i -e 's/\(root:\).*\(:.*\)\(:0:.*\)$/\1\$1\$CXGBMKMu\$mhiWu0L6ae1IfV6XgreIR0:15679\3/g' /etc/shadow &&\
    chattr +i /etc/shadow
}

# grub passwd -- called by function basic_security()
function grub_passwd(){
    if [ `grep 'password --md5 \$1\$0uz8R1\$LapRBcg3/5Ep2wlUUOLUc0' /boot/grub/grub.conf|grep -v '^#'|wc -l` -lt 1 ] ; then
        sed -i -e '/password --md5 /s/\(.*\)/#\1/g' /boot/grub/grub.conf && \
        sed -i -e 's/hiddenmenu/hiddenmenu\npassword --md5 \$1\$0uz8R1\$LapRBcg3/5Ep2wlUUOLUc0//g;s/default=.*/default=0/g' /boot/grub/grub.conf
    fi
}

# ilo passwd -- called by function basic_security()
function ilo_passwd(){
    /sbin/service ipmi start 2> /dev/null
    userID=`/usr/bin/ipmitool user list 1|grep root|awk '{print $1}'`
    /usr/bin/ipmitool user set password ${userID} 'c2twrPNV4kgRq9'
}

# uninstall lrzsz -- called by function basic_security()
function rz_sz(){
    if [ `rpm -qa|grep -i lrzsz|wc -l` -gt 0 ] ; then
        rpm -qa|grep -i lrzsz|xargs rpm -e
    fi
}
# }}}

# {{{ 1. Init System Services
function sys_services(){

	CHKCONFIG="/sbin/chkconfig"

	# Setting up on.

	$CHKCONFIG --level 2345 psacct on 2>/dev/null
	$CHKCONFIG --level 2345 microcode_ctl on 2>/dev/null
	$CHKCONFIG --level 2345 network on 2>/dev/null
	$CHKCONFIG --level 2345 syslog on 2>/dev/null
	$CHKCONFIG --level 2345 crond on 2>/dev/null
	$CHKCONFIG --level 2345 lm_sensors on 2>/dev/null
	$CHKCONFIG --level 2345 openibd on 2>/dev/null
	$CHKCONFIG --level 2345 irqbalance on 2>/dev/null
	$CHKCONFIG --level 2345 sshd on 2>/dev/null
	$CHKCONFIG --level 2345 ipmi on 2>/dev/null
	$CHKCONFIG --level 2345 iptables on 2>/dev/null
	$CHKCONFIG --level 2345 snmpd on 2>/dev/null
	$CHKCONFIG --level 2345 xinetd on 2>/dev/null

	# Setting up off.

	$CHKCONFIG --level 2345 portmap off 2>/dev/null
	$CHKCONFIG --level 2345 nfs off 2>/dev/null
	$CHKCONFIG --level 2345 anacron off 2>/dev/null
	$CHKCONFIG --level 2345 apmd off 2>/dev/null
	$CHKCONFIG --level 2345 atd off 2>/dev/null
	$CHKCONFIG --level 2345 autofs off 2>/dev/null
	$CHKCONFIG --level 2345 gpm off 2>/dev/null
	$CHKCONFIG --level 2345 httpd off 2>/dev/null
	$CHKCONFIG --level 2345 identd off 2>/dev/null
	$CHKCONFIG --level 2345 ipchains off 2>/dev/null
	$CHKCONFIG --level 2345 isdn off 2>/dev/null
	$CHKCONFIG --level 2345 keytable off 2>/dev/null
	$CHKCONFIG --level 2345 kudzu off 2>/dev/null
	$CHKCONFIG --level 2345 linuxconf off 2>/dev/null
	$CHKCONFIG --level 2345 lpd off 2>/dev/null
	$CHKCONFIG --level 2345 netfs off 2>/dev/null
	$CHKCONFIG --level 2345 nfslock off 2>/dev/null
	$CHKCONFIG --level 2345 pcmcia off 2>/dev/null
	$CHKCONFIG --level 2345 random off 2>/dev/null
	$CHKCONFIG --level 2345 rawdevices off 2>/dev/null
	$CHKCONFIG --level 2345 rhnsd off 2>/dev/null
	$CHKCONFIG --level 2345 sgi_fam off 2>/dev/null
	$CHKCONFIG --level 2345 xfs off 2>/dev/null
	$CHKCONFIG --level 2345 cups off 2>/dev/null
	$CHKCONFIG --level 2345 hpoj off 2>/dev/null
	$CHKCONFIG --level 2345 mdmpd off 2>/dev/null
	$CHKCONFIG --level 2345 firstboot off 2>/dev/null
	$CHKCONFIG --level 2345 arptables_jf off 2>/dev/null
	$CHKCONFIG --level 2345 mdmonitor off 2>/dev/null
	$CHKCONFIG --level 2345 smartd off 2>/dev/null
	$CHKCONFIG --level 2345 messagebus off 2>/dev/null
	$CHKCONFIG --level 2345 acpid off 2>/dev/null
	$CHKCONFIG --level 2345 rpcsvcgssd  off 2>/dev/null
	$CHKCONFIG --level 2345 rpcgssd off 2>/dev/null
	$CHKCONFIG --level 2345 rpcidmapd off 2>/dev/null
	$CHKCONFIG --level 2345 cpuspeed off 2>/dev/null
	$CHKCONFIG --level 2345 sysstat off 2>/dev/null
	$CHKCONFIG --level 2345 yum-updatesd off 2>/dev/null
	$CHKCONFIG cups off  2>/dev/null
	$CHKCONFIG gpm off 2>/dev/null
	$CHKCONFIG haldaemon off 2>/dev/null
	$CHKCONFIG iiim off 2>/dev/null
	$CHKCONFIG isdn off 2>/dev/null
	$CHKCONFIG kudzu off 2>/dev/null
	$CHKCONFIG mdmonitor 2>/dev/null
	$CHKCONFIG nfslock off 2>/dev/null
	$CHKCONFIG pcmcia off 2>/dev/null
	$CHKCONFIG rhnsd off 2>/dev/null
	$CHKCONFIG rpcidmapd off 2>/dev/null
	$CHKCONFIG rpcsvcgssd off 2>/dev/null
	$CHKCONFIG rpcgssd off 2>/dev/null
	$CHKCONFIG sendmail off 2>/dev/null
	$CHKCONFIG xfs off 2>/dev/null
}
# }}}

# {{{ 2. Delete useless users
function sys_users(){
	for i in  adm lp sync shutdown halt news uucp games operator mail gopher ftp; do
        /usr/sbin/userdel $i 2> /dev/null
	done

	# Delete special groups
	for i in adm lp news uucp games dip; do
        /usr/sbin/groupdel $i 2> /dev/null
	done
}
# }}}

# {{{ 3. Init System arguments
function sys_args(){
	# kernel args
	grep -q 'vm.swappiness' /etc/sysctl.conf && sed -i 's/vm.swappiness.*/vm.swappiness = 0/g' /etc/sysctl.conf || echo "vm.swappiness = 0" >> /etc/sysctl.conf
	grep -q 'net.core.rmem_max' /etc/sysctl.conf && sed -i 's/net.core.rmem_max.*/net.core.rmem_max = 20971520/g' /etc/sysctl.conf || echo "net.core.rmem_max=20971520" >> /etc/sysctl.conf
	grep -q 'net.core.wmem_max' /etc/sysctl.conf && sed -i 's/net.core.wmem_max.*/net.core.wmem_max = 15728640/g' /etc/sysctl.conf || echo "net.core.wmem_max=15728640" >> /etc/sysctl.conf
	grep -q 'net.ipv4.tcp_rmem' /etc/sysctl.conf && sed -i 's/net.ipv4.tcp_rmem.*/net.ipv4.tcp_rmem = 4096 10485760 20971520/g' /etc/sysctl.conf || echo "net.ipv4.tcp_rmem=4096 10485760 20971520" >> /etc/sysctl.conf
	grep -q 'net.ipv4.tcp_wmem' /etc/sysctl.conf && sed -i 's/net.ipv4.tcp_wmem.*/net.ipv4.tcp_wmem = 4096 10485760 15728640/g' /etc/sysctl.conf || echo "net.ipv4.tcp_wmem=4096 10485760 15728640" >> /etc/sysctl.conf 
	grep -q 'net.ipv4.ip_local_port_range' /etc/sysctl.conf && sed -i 's/net.ipv4.ip_local_port_range.*/net.ipv4.ip_local_port_range = 1024 65000/g' /etc/sysctl.conf || echo "net.ipv4.ip_local_port_range = 1024 65000" >> /etc/sysctl.conf 
	grep -q 'net.ipv4.tcp_syncookies' /etc/sysctl.conf && sed -i 's/net.ipv4.tcp_syncookies.*/net.ipv4.tcp_syncookies = 1/g' /etc/sysctl.conf || echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf 
	grep -q 'net.ipv4.tcp_max_syn_backlog' /etc/sysctl.conf && sed -i 's/net.ipv4.tcp_max_syn_backlog.*/net.ipv4.tcp_max_syn_backlog = 8192/g' /etc/sysctl.conf || echo "net.ipv4.tcp_max_syn_backlog = 8192" >> /etc/sysctl.conf
	grep -q 'net.ipv4.tcp_window_scaling' /etc/sysctl.conf && sed -i 's/net.ipv4.tcp_window_scaling.*/net.ipv4.tcp_window_scaling = 0/g' /etc/sysctl.conf || echo "net.ipv4.tcp_window_scaling = 0" >> /etc/sysctl.conf
	grep -q 'net.ipv4.tcp_timestamps' /etc/sysctl.conf && sed -i 's/net.ipv4.tcp_timestamps.*/net.ipv4.tcp_timestamps = 0/g' /etc/sysctl.conf || echo "net.ipv4.tcp_timestamps = 0" >> /etc/sysctl.conf
	grep -q 'kernel.shmmax' /etc/sysctl.conf && sed -i 's/kernel.shmmax.*/kernel.shmmax = 1024000000/g' /etc/sysctl.conf || echo "kernel.shmmax = 1024000000" >> /etc/sysctl.conf
	/sbin/sysctl -p

	# Selinux
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

	# sshd
	sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config
	mkdir -p /root/.ssh
	echo "StrictHostKeyChecking no" >> /root/.ssh/config

	sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config

	# bash
	grep -q 'stty erase ^H' /etc/profile || echo 'stty erase ^H' >> /etc/profile

	# vim
	grep -q 'set syntax=on' /etc/vimrc || echo "set syntax=on" >> /etc/vimrc
	grep -q 'set fdm=marker' /etc/vimrc || echo "set fdm=marker" >> /etc/vimrc
	grep -q 'set nu' /etc/vimrc || echo "set nu" >> /etc/vimrc

	# module
	chattr -i $MODBLIST_5
	! grep 'usb_storage' $MODBLIST_5 && echo 'blacklist usb_storage' >> $MODBLIST_5
	! grep 'edac_mc' $MODBLIST_5 && echo 'blacklist edac_mc' >> $MODBLIST_5
	! grep 'i5000_edac' $MODBLIST_5 && echo 'blacklist i5000_edac' >> $MODBLIST_5
	! grep 'power_meter' $MODBLIST_5 && echo blacklist 'power_meter' >> $MODBLIST_5

	# unblock ctrl+alt+del
	sed -e 's/\(ca::ctrlaltdel\)\(.*\)/#\1\2/g' /etc/inittab > /tmp/inittab && cp -f /tmp/inittab /etc/inittab
}
# }}}

# {{{ 4. Basic Security
function basic_security(){
	root_passwd
	ilo_passwd
	grub_passwd
	rz_sz
}
# }}}

# {{{ 5. /home File System
function home_fstm(){
	rpm -iUvh ${current_dir}/tools/kernel-module-xfs-2.6.18-128.el5-0.4-4.slc5.x86_64.rpm ${current_dir}/tools/xfsprogs-2.9.4-4.el5.x86_64.rpm ${current_dir}/tools/xfsprogs-devel-2.9.4-4.el5.x86_64.rpm
	read -p "This program now will kill all processes are running in /home directory and umount /home, go on {Y/n}?" Yon
	if [[ ${Yon} == "Y" ]]; then
		lsof | grep /home | awk '{print $2}' | xargs kill -9 2> /dev/null
		home_pt=`df | grep home | awk '{print $1}'`
		umount /home
		mkfs.xfs -f -L /home ${home_pt}
		sed -i '/\/home/s/.*/LABEL=\/home\t\t\/home\t\t\txfs\tdefaults,noatime,nodiratime\t1 2/g' /etc/fstab
		mount -a
	fi
}
# }}}

# {{{ 6. I/O Scheduler
function io_schd(){
	default_id=$(( `awk -F= '/^default/ {print $2}' /etc/grub.conf` + 1 ))
	default_title=`grep title /etc/grub.conf | sed -n "${default_id}p"`
	default_kernel_n=`grep "${default_title}" -nA 2 /etc/grub.conf | grep kernel | cut -d- -f1`
	`sed -n "${default_kernel_n}p" /etc/grub.conf | grep -q "deadline"` || sed -i "${default_kernel_n}s/.*/& elevator=deadline/g" /boot/grub/grub.conf
}
# }}}

# {{{ 7. Char Set
function charset(){
	grep -q "LANG=" /etc/sysconfig/i18n && sed -i 's/LANG.*/LANG="en_US.UTF-8"/g' /etc/sysconfig/i18n || echo 'LANG="en_US.UTF-8"' >> /etc/sysconfig/i18n
}
# }}}

# {{{ 8. Time Sync
function time_sync(){
        if [ `crontab -l|egrep 'ntpdate'|grep -v '^#'|wc -l` -lt 1 ] && [ ! -s "/etc/cron.d/cron_comm_ntp" ] ; then
        	echo "* */10 * * * /usr/sbin/ntpdate TIME_SERVER;/sbin/clock -w > /dev/null 2>&1" >> /var/spool/cron/root
        fi
}
# }}}

# {{{ 9. SSH Auth
function ssh_auth(){
	[[ -e ${current_dir}/config/keys.file ]] && cat ${current_dir}/config/keys.file | egrep -v '^#' >> /root/.ssh/authorized_keys
	egrep -v '^$' /root/.ssh/authorized_keys | sort | uniq > /root/.ssh/authorized_keys.tmp && mv -f /root/.ssh/authorized_keys{.tmp,}
	chmod 700 /root/.ssh
	chmod 600 /root/.ssh/authorized_keys
}
# }}}

# {{{ 10. Create Dir
function mk_dir(){
	mkdir -p /home/dba/update
	mkdir -p /home/dba/query
	mkdir -p /home/dba/dbinit
	mkdir -p /home/dba/merge
	mkdir -p /home/dba/load_card
	mkdir -p /home/dba/migrate
	mkdir -p /home/dba/maintain
	mkdir -p /home/dba/iptalbes
	mkdir -p /home/dba/packages
	mkdir -p /home/databak
	mkdir -p /home/dba/backup_file/iptables
	mkdir -p /home/dba/backup_file/scripts
	mkdir -p /home/dba/backup_file/dblists
	mkdir -p /home/dba/backup_file/crontab
	mkdir -p /home/dba/backup_file/others
}
# }}}

# {{{ 11. Install tools
function install_tools(){
	if [[ ${vender} == 'Dell Inc.' ]] && [[ -e ${current_dir}/tools/MegaCli-8.07.07-1.noarch.rpm ]]; then
		rpm -ivh ${current_dir}/tools/MegaCli-8.07.07-1.noarch.rpm 
		cp -f /opt/MegaRAID/MegaCli/MegaCli64 /usr/sbin/MegaCli 2> /dev/null
	elif [[ ${vender} == 'HP' ]] && [[ -e ${current_dir}/tools/hpacucli-9.10-22.0.x86_64.rpm ]]; then
		[[ -e ${current_dir}/tools/hpacucli-9.10-22.0.x86_64.rpm ]] && rpm -ivh ${current_dir}/tools/hpacucli-9.10-22.0.x86_64.rpm
		[[ -e ${current_dir}/tools/hp-health-9.1.0.42-54.rhel6.x86_64.rpm ]] && rpm -ivh ${current_dir}/tools/hp-health-9.1.0.42-54.rhel6.x86_64.rpm
	fi

	if [[ -e ${current_dir}/tools/sysstat-9.0.1.tgz ]]; then
		tar zxf ${current_dir}/tools/sysstat-9.0.1.tgz -C /
		rm -rf /var/log/sa/*
	fi
}
# }}}


# do something
sys_services
sys_users
sys_args
basic_security
home_fstm
io_schd
charset
time_sync
ssh_auth
mk_dir
install_tools
