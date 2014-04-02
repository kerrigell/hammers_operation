#!/bin/bash
# General mysqldump backuping script
# Author: penghaiyang@cyou-inc.com
# Update Log:
# v1.0 Created by Penghy 2013/11/22
    #-- Just created and defined backup filename format:
    #-- region_product_ip_engine_port_dump|xtra_charset_:schemas:_full|inc_time_.sql.gz
# v1.1 Updated by Penghy 2013/12/02
    #-- Bugs fixed and updated function to log dump time cost.
# v1.2 Updated by Penghy 2014/01/01
    #-- Added function to manage and implement file reservation policy
# v1.3 Updated by Penghy 2014/01/02
    #-- Added function to dump from Amazon Web Service RDS
# v1.4 Updated by Penghy 2014/01/02
    #-- Bug fixed
# v1.5 Updated by Penghy 2014/01/28
    #-- Changed options in find command to be compatible with some old OS releas like RHEL 4.6
    #-- Changed variable names to avoid mess-up with some system variables

source /etc/profile &> /dev/null
export PATH=$PATH:/usr/local/mysql/bin

# {{{ Print Help Info
get_help()
{
    echo
    echo -e "  Usage:"
    echo -e "\t$0 Port {all|Schema,[Schema1..]} CharSet DumpPath FileNamePrefix [option]"
    echo -e "  Option:"
    echo -e "\t[-k|--keep keep_pattern] [-d|--delete delete_day] [-e|--expire keep_expire] [--rds rds_string] "
    echo -e "  Example:"
    echo -e "\t$0 3306 tlbbdb latin1 /home/databackup/ hk_tlbb_81.98 --keep d01,d15 --delete 15 --expire 100 --rds"
    echo -e "  Optional arguments:"
    echo -e "\t-k, --keep\tkeep file in specific day, eg.. y2013m03d01(keep file generated in March 01 2013) d01,d15(keep file generated in every month's 1st,15th)"
    echo -e "\t-d, --delete\tdelete file N days ago"
    echo -e "\t-e, --expire\tforce delete kept file N days ago"
    echo -e "\t--rds\t\tbackup from rds, use \"user:password@host\" to identified a rds instance"
    echo -e "\t-h, --help\tprint help info"
    echo
}
# }}}

# {{{ Options parsing
ARGS=`getopt -o "k:d:e:h" -l "keep:,delete:,expire:,help,rds:" -n "general_mysqldump.sh" -- "$@"`
## Exit if getopt failed
if [ $? -ne 0 ];
then
    echo "Parameters parsing failed!"
    exit 1
fi
## Process
eval set -- "$ARGS"
while true; do
    case "${1}" in
        -k|--keep)
        shift;
        if [ -n "${1}" ]; then
            RESERVE_PATTERN="${1}"
            shift;
        fi
        ;;
        -d|--delete)
        shift;
        if [ -n "${1}" ]; then
            DELETE_DAY="${1}"
            shift;
        fi
        ;;
        -e|--expire)
        shift;
        if [ -n "${1}" ]; then
            RESERVE_EXPIRE="${1}"
            shift;
        fi
        ;;
        --rds)
        shift;
        if [ -n "${1}" ]; then
            RDS="${1}"
            shift;
        fi
        ;;
        -h|--help)
        shift;
        get_help
        exit 0
        ;;
        --)
        shift;
        break;
        ;;
    esac
done
# }}} Prcocess end

# Gloabal aurguments
PORT=${1}
SCHEMAS=${2}
CHARSET=${3}
DIR=${4}
PREFIX=${5}

# {{{ Time Calculator
calculator()
{
    START_TIME=${1}
    END_TIME=${2}

    START_TIME=`echo ${START_TIME} | sed -r 's/../:&:/6; s/./& /8'`
    END_TIME=`echo ${END_TIME} | sed -r 's/../:&:/6; s/./& /8'`

    START_TIME=`date +%s --date="${START_TIME}"`
    END_TIME=`date +%s --date="${END_TIME}"`

    TIME_COST=$(( ${END_TIME} - ${START_TIME} ))

    echo ${TIME_COST}
}
# }}}

# {{{ Check Arguments
check_argus()
{
    if [[ `echo ${SCHEMAS} | egrep -c ','` -gt 0 ]]; then
        SCHEMAS=`echo ${SCHEMAS} | tr ',' ' '`
    fi
    if [[ -z ${PORT} || -z ${SCHEMAS} || -z ${CHARSET} || -z ${DIR} || -z ${PREFIX} ]]; then
        echo -e "Error: At least five arugments needed, use -h|--help for more information!"
        exit 1
    elif [[ `echo ${PORT} | egrep -c '^[0-9]+$'` -ne 1 ]]; then
        echo -e "Error: Port should only consist of digitals"
        exit 1
    elif [[ ! -d ${DIR} ]]; then
        echo -e "Error: No such a Directory: ${DIR}"
        exit 1
    elif [[ `echo ${PREFIX} | egrep -c [\!\@\#\$\%\^\&\*\\\?\<\>]` -gt 0 ]]; then
        echo -e "Error: FileNamePrefix should not contain special character!"
        exit 1
    elif [[ -n ${RESERVE_PATTERN} ]]; then
        PATTERN_ARRAY=(`echo ${RESERVE_PATTERN} | tr ',' '\n'`)
        for PATTERN in ${PATTERN_ARRAY[@]}
        do
            echo ${PATTERN} | egrep -q "y[0-9]{4}|y[0-9]{4}m[0-9]2|y[0-9]{4}m[0-9]{2}d[0-9]{2}|m[0-9]{2}d[0-9]{2}|m[0-9]{2}|d[0-9]{2}" || \
            (echo -e "Error: keeping file Pattern format error" && exit 1)
        done
    elif [[ -n ${RDS} ]]; then
        echo ${RDS} | egrep -q ".*:.*@.*" || (echo -e "Error: RDS String format error, it should be user:password@host" && exit 1)
    fi
}
# }}} 

# {{{ Backup
backup()
{
    SCHEMA_NAMES=`echo ${SCHEMAS} | tr ' ' ':'`
    TIME=`date +%Y%m%d%H%M%S`
    FILENAME_START="${PREFIX}_mysql_${PORT}_dump_${CHARSET}_:${SCHEMA_NAMES}:_full"
    BACKUPFILE="${FILENAME_START}_${TIME}.sql.gz"
    ERRORFILE="${FILENAME_START}_${TIME}.err"

    if [[ ${SCHEMAS} == 'all' ]]; then
        SCHEMAS_OPTION="--all-databases"
    else
        SCHEMAS_OPTION="--databases ${SCHEMAS}"
    fi

    if [[ -n ${RDS} ]]; then
        M_USER=`echo ${RDS} | cut -d: -f1`
        M_PASS=`echo ${RDS} | cut -d: -f2 | cut -d@ -f1`
        M_HOST=`echo ${RDS} | cut -d@ -f2`

        M_USER="--user=${M_USER}"
        M_PASS="--password=${M_PASS}"
    fi

    mysqldump --force \
        -h${M_HOST:-127.0.0.1} \
        ${M_USER} \
        ${M_PASS} \
        -P${PORT} \
        --default-character-set=${CHARSET} \
        --single-transaction \
        --quick \
        --routines \
        --triggers \
        ${SCHEMAS_OPTION} 2>>${DIR}/${ERRORFILE} | \
        gzip > ${DIR}/${BACKUPFILE}

    END_TIME=`date +%Y%m%d%H%M%S`

    # If errorlog only includs Warning or is empty, delete it.
    if [[ `wc -l ${DIR}/${ERRORFILE} | awk '{print $1}'` -eq `egrep -c '^Warning' ${DIR}/${ERRORFILE}` ]] || [[ `wc -l ${DIR}/${ERRORFILE} | awk '{print $1}'` -eq 0 ]]; then
        # Safely delete file
        if [[ `find ${DIR}/${ERRORFILE} | wc -l` -eq 1 ]]; then
            find ${DIR}/${ERRORFILE} | xargs rm -f
        fi
    fi
        
    echo "${FILENAME_START} ${BACKUPFILE} ${TIME} ${END_TIME}"
}
# }}}

# {{{ File deleter
deleter()
{
    FILENAME_START=${1}
    BACKUPFILE=${2}
    TIME=${3}
    END_TIME=${4}

    ## chattr +i
    if [[ -n ${RESERVE_PATTERN} ]]; then
        for PATTERN in ${PATTERN_ARRAY[@]}
        do
            year=`echo ${PATTERN} | egrep -o 'y[0-9]{4}' | egrep -o '[0-9]+'`
            month=`echo ${PATTERN} | egrep -o 'm[0-9]{2}' | egrep -o '[0-9]+'`
            day=`echo ${PATTERN} | egrep -o 'd[0-9]{2}' | egrep -o '[0-9]+'`
            YEAR=${year:-....}
            MONTH=${month:-..}
            DAY=${day:-..}
            CAN_NOT_BE_DELETE="${FILENAME_START}_${YEAR}${MONTH}${DAY}.*"
            find ${DIR} -regex "${DIR}${CAN_NOT_BE_DELETE}.sql.gz" -print -exec chattr +i {} \;
            find ${DIR} -regex "${DIR}${CAN_NOT_BE_DELETE}.md5" -print -exec chattr +i {} \;
        done
    fi

    ## delete
    if [[ -n ${DELETE_DAY} ]]; then
        find ${DIR} -name "${FILENAME_START}_*.sql.gz" -mtime +${DELETE_DAY} -exec rm -rf {} \; 2> /dev/null
        find ${DIR} -name "${FILENAME_START}_*.md5" -mtime +${DELETE_DAY} -exec rm -rf {} \; 2> /dev/null
        echo > /dev/null
    fi
    
    ## chattr -i and delete
    if [[ -n ${RESERVE_EXPIRE} ]]; then
        find ${DIR} -name "${FILENAME_START}_*" -mtime +${RESERVE_EXPIRE} -exec chattr -i {} \; 
        find ${DIR} -name "${FILENAME_START}_*.sql.gz" -mtime +${RESERVE_EXPIRE} -exec rm -rf {} \;
        find ${DIR} -name "${FILENAME_START}_*.md5" -mtime +${RESERVE_EXPIRE} -exec rm -rf {} \;
        echo > /dev/null
    fi
}
# }}}

# {{{ Log backup info
log_info()
{
    FILENAME_START=${1}
    BACKUPFILE=${2}
    TIME=${3}
    END_TIME=${4}
    INFOFILE="${FILENAME_START}.info"
    MD5FILE="${BACKUPFILE}.md5"

    TIME_COST=`calculator ${TIME} ${END_TIME}`

    md5sum ${DIR}/${BACKUPFILE} > ${DIR}/${MD5FILE}
    MD5=`cat ${DIR}/${MD5FILE} | awk '{print $1}'`
    SIZE=`du ${DIR}/${BACKUPFILE} | awk '{print $1}'`
    echo "# Start at ${TIME}" >> ${DIR}/${INFOFILE}
    echo "file: ${BACKUPFILE}" >> ${DIR}/${INFOFILE}
    echo "md5: ${MD5}" >> ${DIR}/${INFOFILE}
    echo "size: ${SIZE}" >> ${DIR}/${INFOFILE}
    echo "time_cost: ${TIME_COST}" >> ${DIR}/${INFOFILE}
}
# }}}


check_argus
A=(`backup`)
deleter ${A[@]}
log_info ${A[@]}
