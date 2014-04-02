#!/bin/bash
# Created by Penghy 20130322
# Updated:	change dell raid level getting command from "MegaCli -CfgDsply -aALL" to "MegaCli  -LDInfo -Lall -aALL"
# Updated:	change dell raid level 1+0 identification method from matching pattern "Primary-1, Secondary-0" to "Rrimary-1.*Qualifier-0"


function print_green(){
        echo -en "\e[1;32;40m`printf \"%-20s\" \"$1\"`\e[0m"
}

function print_red(){
        echo -e "\e[1;31;40m$1\e[0m"
}

function print_yellow(){
        echo -e "\e[1;33;40m$1\e[0m"
}

function product_name(){
        product_name=`dmidecode -s system-product-name`
        vender=`dmidecode -s system-manufacturer`
        print_green "Product Name: "
        echo -e "${vender} ${product_name}"
}

function kernel_version(){
        kernel_version=`uname -rm`
        print_green "Kernel Version: "
        echo -e "${kernel_version}"
}

function os_version(){
        os_version=`cat /etc/redhat-release `
        print_green "OS Version: "
        echo -e "${os_version}"
}

function time_zone(){
        zone=`grep ZONE /etc/sysconfig/clock | cut -d'"' -f2 `
        time_offset=`date -R | awk '{print $NF}'`
        print_green "Time Zone: "
        echo -e "${zone} ${time_offset}"
}

function char_set(){
        print_green "Char Set: "
        echo -e "${LANG}"
}
function disk_cap(){
        disk_cap=`fdisk -l | grep Disk | egrep -o '/dev/.*GB'`
        print_green "Disk Capacity: "
        echo -e "${disk_cap}" | awk '{if(NR!=1) {printf ("%20s%s\n"," ",$0)} else {print $0}}'
}
function mem(){
        mem=`free -mt | grep Mem | awk '{print $2,"MB"}'`
        mem_value=`free | grep Mem | awk '{print $2}'`
        print_green "Memory: "
        if [[ ${mem_value} -gt 8000000 ]]; then
                echo -e "${mem}"
        elif [[ ${mem_value} -gt 4000000 ]]; then
                print_yellow "${mem}"
        else 
                print_red "${mem}"
        fi
}
function swap(){
        swap=`free -mt | grep Swap | awk '{print $2,"MB"}'`
        swap_value=`free | grep Swap | awk '{print $2}'`
        mem_value=`free | grep Mem | awk '{print $2}'`
        swappiness=`sysctl vm.swappiness`
        swappiness_value=`sysctl vm.swappiness | egrep -o '[0-9]+$'`
        print_green "Swap Info: "
        if [[ ${swap_value} -le ${mem_value}*2-1000000 ]] || [[ ${swappiness_value} -ne 0 ]]; then
                print_red "${swap}, ${swappiness}"
        else
                echo -e "${swap}, ${swappiness}"
        fi
}
function raid_info(){
        if [[ `/sbin/lspci | grep "RAID bus" | grep -c "Hewlett-Packard"` -eq 1 ]]; then
                raid_vender="HP"
        elif [[ `/sbin/lspci | grep "RAID bus" | grep -c "LSI Logic"` -eq 1 ]]; then
                raid_vender="DELL"
        else
                raid_vender="No Raid Controller"
        fi

        if [[ ${raid_vender} == "No Raid Controller" ]]; then
                print_green "Raid Info: "
                print_red "${raid_vender}"
        elif [[ ${raid_vender} == "HP" ]]; then
                slot_no=`hpacucli controller all show | egrep -o 'Slot [0-9]+' | cut -d' ' -f2 2>/dev/null`
                [[ ${slot_no} ]] && hpacucli_status=`hpacucli controller slot=${slot_no} show &>/dev/null && echo ok || echo false` || hpacucli_status="false"
                if [[ ${hpacucli_status} == "false" ]]; then
                        print_green "Raid Info: " && print_red "hpacucli is not available"
                elif [[ ${hpacucli_status} == "ok" ]]; then
                        card_type=`hpacucli controller slot=0 show | awk 'NR ==2 {print $0}'`
                        raid_level=`hpacucli controller slot=0 logicaldrive all show | grep -o "logicaldrive.*"`
                        is_raid_10=`hpacucli controller slot=0 logicaldrive all show | grep -o "logicaldrive.*" | grep -c '1+0'`
                        acc_ratio=`hpacucli controller slot=0 show | egrep -o "Accelerator Ratio:.*"`
                        cache_status=`hpacucli controller slot=0 show | egrep -o "Cache Status:.*"`
                        cache_size=`hpacucli controller slot=0 show | egrep -o "Total Cache Size:.*"`
                        pdisk_status=`hpacucli controller slot=0 physicaldrive all show | egrep -o "physicaldrive.*"`
                        ct_failed=`hpacucli controller slot=0 physicaldrive all show | egrep -c "Failed|Predictive Failure"`
                        print_green "Raid Info: " && echo -e "${card_type}"
                        if [[ ${is_raid_10} -eq 1 ]]; then
                                print_green && echo -e "${raid_level}"
                        else
                                print_green && print_red "${raid_level}"
                        fi
                        print_green && echo -e "${acc_ratio}"
                        print_green && echo -e "${cache_status}"
                        print_green && echo -e "${cache_size}"
                        if [[ ${ct_failed} -eq 0 ]]; then
                                echo -e "${pdisk_status}" | awk '{printf ("%20s%s\n"," ",$0)}' 
                        else
                                print_red "${pdisk_status}" | awk '{printf ("%20s%s\n"," ",$0)}'
                        fi
                else
                        print_green "Raid Info: " && print_red "UNKNOW"
                fi
        elif [[ ${raid_vender} == "DELL" ]]; then
                MegaCli_status=`MegaCli -AdpAllInfo -aALL -NoLog &>/dev/null && echo ok || echo false`
                if [[ ${MegaCli_status} == "false" ]]; then
                        print_green "Raid Info: " && print_red "MegaCli is not available"
                elif [[ ${MegaCli_status} == "ok" ]]; then
                        card_type=`MegaCli -CfgDsply -aALL | egrep -o "Product Name:.*" | cut -d: -f2 | egrep -o '[a-Z].*'`
                        raid_level=`MegaCli  -LDInfo -Lall -aALL | grep -i 'raid level'`
                        is_raid_10=`MegaCli  -LDInfo -Lall -aALL | grep -i 'raid level' | egrep -c 'Primary-1.*Qualifier-0'`
                        cache_policy=`MegaCli -CfgDsply -aALL | grep -o "Current Cache Policy:.*" | uniq`
                        is_cache_policy=`MegaCli -CfgDsply -aALL | grep -o "Current Cache Policy:.*" | uniq | grep -c "Write Cache OK if Bad BBU"`
                        error_ct_10=`MegaCli -PDList -aALL | grep -i "Error Count" | awk '$NF>=10{print $0}'`
                        ct_error_ct_10=`MegaCli -PDList -aALL | grep -i "Error Count" | egrep -o '[0-9]+$' | awk '$1>=10{print $0}' | wc -l`
                        print_green "Raid Info: " && echo -e "${card_type}"
                        if [[ ${is_raid_10} -eq 1 ]]; then
                                print_green && echo -e "${raid_level}"
                        else
                                print_green && print_red "${raid_level}"
                        fi
                        if [[ ${is_cache_policy} -eq 1 ]]; then
                                print_green && echo -e "${cache_policy}"
                        else
                                print_green && print_red "${cache_policy}"
                        fi
                        if [[ ${ct_error_ct_10} -gt 0 ]]; then
                                print_red ${error_ct_10} | awk '{printf ("%20s%s\n"," ",$0)}'
                        fi
                else
                        print_green "Raid Info: " && print_red "UNKNOW"
                fi
        else 
                print_green "Raid Info: " && print_red "UNKNOW"
        fi
}
function home_fs(){
        home_fs=`df -hT | grep /home | awk '{print $NF":",$(NF-5)}'`
        home_fs_type=`df -hT | grep /home | awk '{print $(NF-5)}'`
        if [[ ${home_fs_type} == "xfs" ]]; then
                print_green "File System: " && echo -e "${home_fs}"
        elif [[ ${home_fs_type} == "ext4" ]]; then
                print_green "File System: " && print_yellow "${home_fs}" 
        else
                print_green "File System: " && print_red "${home_fs}"
        fi
}
function nic_firmware(){
        all_nic=(`ifconfig | grep -o '^eth[0-9]' | sort | uniq`)
        for i in `seq ${#all_nic[@]}`
        do
                nic=${all_nic[${i}-1]}
                nic_firmware_verison=`ethtool -i ${nic} | egrep '^version:' | egrep -o '[0-Z.-]+$'`
                if [[ ${i} -eq 1 ]]; then
                        if [[ ${nic_firmware_verison} == "1.9.20b" ]] || [[ ${nic_firmware_verison} == "2.0.2" ]]; then
                                print_green "Nic Info: " && echo -e "${nic} ${nic_firmware_verison}"
                        else
                                print_green "Nic Info: " && print_yellow "${nic} ${nic_firmware_verison}"
                        fi
                else
                        if [[ ${nic_firmware_verison} == "1.9.20b" ]] || [[ ${nic_firmware_verison} == "2.0.2" ]]; then
                                echo -e "${nic} ${nic_firmware_verison}" | awk '{printf ("%20s%s\n"," ",$0)}'
                        else
                                print_yellow "${nic} ${nic_firmware_verison}" | awk '{printf ("%20s%s\n"," ",$0)}'
                        fi
                fi
        done
}
function io_scheduler(){
        all_block_device=(`ls -1 /sys/block/ | egrep 'sd|cciss'`)
        for i in `seq ${#all_block_device[@]}`
        do
                block=${all_block_device[${i}-1]}
                scheduler=`cat /sys/block/${block}/queue/scheduler 2>/dev/null | egrep -o '\[.*\]'`
                if [[ ${i} -eq 1 ]]; then
                        if [[ ${scheduler} == "[deadline]" ]]; then
                                print_green "I/O scheduler: " && echo -e "${block} ${scheduler}"
                        elif [[ ${scheduler} == "" ]]; then
                                print_green "I/O scheduler: " && print_yellow "${block} UNKNOW"
                        else
                                print_green "I/O scheduler: " && print_red "${block} ${scheduler}"
                        fi
                else
                        if [[ ${scheduler} == "[deadline]" ]]; then
                                echo -e "${block} ${scheduler}" | awk '{printf ("%20s%s\n"," ",$0)}'
                        else
                                print_red "${block} ${scheduler}" | awk '{printf ("%20s%s\n"," ",$0)}'
                        fi
                fi
        done
}
function mysql_info(){
        all_ls_port=(`netstat -ntlp | grep mysqld | awk '{print $4}' | awk -F: '{print $NF}'`)
        [[ ${#all_ls_port[@]} -ne 0 ]] && lc_mysqld=`ps aux | grep -v grep | egrep -o '/[0-Z\/]+/mysqld\b' --color=auto | uniq`
        [[ ${lc_mysqld} ]] && mysql_version=`${lc_mysqld} --version | sed 's/^.*mysqld  //g'`
        print_green "MySQL Info: " && echo -e "${mysql_version}"
        for port in ${all_ls_port[@]}
        do
                all_schema=`mysql --host=127.0.0.1 --port=${port} --disable-tee -e "SHOW DATABASES" | egrep -v 'mysql|information_schema|Database|Logging to file' | tr '\n' '|' | sed 's/|$/\n/g'`
                uptime=`mysqladmin --host=127.0.0.1 --port=${port} status | egrep -o 'Uptime: [0-9]+\b'`
                char_set_server=`mysql --host=127.0.0.1 --port=${port} --disable-tee -Ee 'SHOW VARIABLES LIKE '\''character_set_server'\''' | egrep Value | awk '{print $2}'`
                print_green && echo -e "Instance ${port} CharSetServer: ${char_set_server} ${uptime}  Schema: ${all_schema}"
        done
}
function hosts_info(){
        print_green "Host Name: " && echo -e `hostname`
}
function iptb_stat(){
        iptb_stat=`/etc/init.d/iptables status &>/dev/null && echo ok || echo false`
        if [[ ${iptb_stat} == 'ok' ]]; then
                print_green "Iptables Info: " && echo -e "Started"
        elif [[ ${iptb_stat} == 'false' ]]; then
                print_green "Iptables Info: " && print_red "Ended"
        else 
                print_green "Iptables Info: " && print_yellow "UNKNOW"
        fi
}

function root_passwd(){
        if [ `grep -w 'root:\$1\$CXGBMKMu\$mhiWu0L6ae1IfV6XgreIR0:15679:0:99999:7:::' /etc/shadow|grep -v '^#'|wc -l` -lt 1 ] ; then
                chattr -i /etc/shadow &&\
                sed -i -e 's/\(root:\).*\(:.*\)\(:0:.*\)$/\1\$1\$CXGBMKMu\$mhiWu0L6ae1IfV6XgreIR0:15679\3/g' /etc/shadow &&\
                chattr +i /etc/shadow
                if [ `grep -w 'root:\$1\$CXGBMKMu\$mhiWu0L6ae1IfV6XgreIR0:15679:0:99999:7:::' /etc/shadow|grep -v '^#'|wc -l` -lt 1 ] ; then
                        print_red "Illegal root password!"
                fi
        fi
}


function grub_passwd(){
        if [ `grep 'password --md5 \$1\$./2yd\$6Ijb2yl6OGRZD13HqJSBH/' /boot/grub/grub.conf|grep -v '^#'|wc -l` -lt 1 ] ; then
                sed -i -e '/password --md5 /s/\(.*\)/#\1/g' /boot/grub/grub.conf && \
                sed -i -e 's/hiddenmenu/hiddenmenu\npassword --md5 \$1$.\/2yd\$6Ijb2yl6OGRZD13HqJSBH\//g;s/default=.*/default=0/g' /boot/grub/grub.conf
                if [ `grep 'password --md5 \$1\$./2yd\$6Ijb2yl6OGRZD13HqJSBH/' /boot/grub/grub.conf|grep -v '^#'|wc -l` -lt 1 ] ; then
                        print_red "Illegal grub password!"
                fi
        fi
}

function ilo_passwd(){
        if [ `/usr/sbin/dmidecode|grep -c 'PowerEdge'` -gt 0 ] ; then
                userID=`/usr/bin/ipmitool user list 1|grep root|awk '{print $1}'`
                if [ `/usr/sbin/dmidecode|grep -c 'PowerEdge'` -eq 1 ];then
                        if [ `/usr/bin/ipmitool user test ${userID} 16 'c2twrPNV4kgRq9'|grep -w 'Success'|wc -l` -lt 1 ] ; then
                                /usr/bin/ipmitool user set password ${userID} 'c2twrPNV4kgRq9'
                                if [ `/usr/bin/ipmitool user test ${userID} 16 'c2twrPNV4kgRq9'|grep -w 'Success'|wc -l` -lt 1 ] ; then
                                        print_red "Illegal grub password!"
                                fi
                        fi
                fi
        fi
}

function time_sync(){
        if [ `crontab -l|egrep 'ntpdate'|grep -v '^#'|wc -l` -lt 1 ] && [ ! -s "/etc/cron.d/cron_comm_ntp" ] ; then
                print_green && print_red "Time Sync Unconfigured"
        else
                sync_to=`crontab -l|egrep 'ntpdate' | grep -v '^#' | egrep -o '([0-9]+\.){3}[0-9]+\b' | xargs`
                print_green && echo -e "Time Sync To: ${sync_to}"
        fi
}

function sshd_version(){
        if [ `rpm -qa|grep -i ssh|grep 'openssh'|wc -l` -lt 3 ] ; then
                echo -e "SSH version is not 3.*"
        fi
}

function cmd_history(){
        if [ `egrep -i 'HISTDIR=' /etc/profile|grep -v '^#'|wc -l` -lt 1 ] ; then
                cp -p /etc/profile /etc/profile.`date +%Y%m%d%H%M`
        sed -i -e '/################################/d' -e '/### setting for history ###/,/### setting for history ###/d' /etc/profile && cat /home/dba/Monitor_Hardware/set_history >> /etc/profile
                if [ `egrep -i 'HISTDIR=' /etc/profile|grep -v '^#'|wc -l` -lt 1 ] ; then
                        print_green && print_red "HISTDIR in profile is not set"
                fi
        fi
        if [ `egrep -i 'HISTSIZE=' /etc/profile|grep -v '^#'|wc -l` -lt 1 ] ; then
                print_green && print_red "HISTSIZE in profile is not set"
        fi
        if [ `egrep -i 'HISTSIZE=|HISTDIR=' /etc/profile | egrep -v '^#' | wc -l ` -eq 2 ] ; then
                print_green && echo -e "HISTSIZE & HISTDIR Both Configured."
        fi
}

function os_user(){
        LEGAL_USER='root:|oracle:|mysql:|cyldj:|nagios:|axis:|sshproxy:'
        LEGAL_DBA='root:|zhangwen:|penghaiyang:|zhangshan:|majianpo:|liangxiaoliang:'
        if [ `grep 'bin/bash' /etc/passwd|egrep -v "^#|${LEGAL_USER}|${LEGAL_DBA}"|wc -l` -gt 0 ] ; then
                print_green && print_red "Invalid User Exists: `grep 'bin/bash' /etc/passwd|egrep -v "^#|${LEGAL_USER}|${LEGAL_DBA}"|awk -F':' '{print $1}'|tr '\n' ' '`"
        fi
}

function rz_sz(){
        if [ `rpm -qa|grep -i lrzsz|wc -l` -gt 0 ] ; then
                rpm -qa|grep -i lrzsz|xargs rpm -e
                if [ `rpm -qa|grep -i lrzsz|wc -l` -gt 0 ] ; then
                print_red "lrzsz Installed!"
                fi
        fi
}

function admin_priv(){
        for cmd in {'reboot','shutdown','init','telinit','halt','iptables','umount','swapoff','groupdel','userdel','rmmod'}
        do
                if [ `/usr/bin/which ${cmd}|xargs ls -l|grep '^l'|wc -l` -gt 0 ] ; then
                        continue
                else
                        /usr/bin/which ${cmd}|xargs /bin/chmod o-wx
                        if [ `/usr/bin/which ${cmd}|xargs ls -l|grep '.*\-\- '|wc -l` -gt 0 ] ; then
                                print_red "Illegal other user privileges: ${cmd}"
                        fi
                fi
        done
}

function Security_Check(){
        print_green "Security Check: "
#        root_passwd && grub_passwd && ilo_passwd && echo -e "All Illegal Password Changed!"
        root_passwd  && ilo_passwd && echo -e "All Illegal Password Changed!"
        time_sync
        cmd_history
        os_user
        rz_sz
        admin_priv
}

product_name
hosts_info
kernel_version
os_version
time_zone
char_set
mem
swap
disk_cap
raid_info
home_fs
nic_firmware
io_scheduler
mysql_info
iptb_stat
Security_Check
