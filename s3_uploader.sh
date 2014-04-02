#!/bin/bash

# {{{ Print Help Info
get_help()
{
    echo
    echo -e "  Usage:"
    echo -e "\t$0 options"
    echo -e "  Options:"
    echo -e "\t-b, --bucket\tS3 bucket name"
    echo -e "\t-l, --dir\tLocal directiory which your files come from"
    echo -e "\t-f, --postfix\tFile name postfix of a file should be uploaded, use comma to separte multi postfix"
    echo -e "\t-k, --keep\tThe number of day files shoud be kept on S3"
    echo -e "\t-p, --past\tUpload local files in past N days, default value is 2"
    echo -e "\t-h, --help\tprint help info"
    echo
}
# }}}
 
# {{{ Parametrs parsing
ARGS=`getopt -o "b:d:f:k:p:h" -l "bucket:,dir:,postfix:,keep:,past:,help" -n "s3_uploader.sh" -- "$@"`
 
eval set -- "${ARGS}"
 
while true; do
    case "${1}" in
        -b|--bucket)
        shift;
        if [[ -n "${1}" ]]; then
            BUCKET="${1}"
            shift;
        fi
        ;;
        -d|--dir)
        shift;
        if [[ -n "${1}" ]]; then
            DIR="${1}"
            shift;
        fi
        ;;
        -f|--postfix)
        shift;
        if [[ -n "${1}" ]]; then
            POSTFIX="${1}"
            shift;
        fi
        ;;
        -k|--keep)
        shift;
        if [[ -n "${1}" ]]; then
            KEEP="${1}"
            shift;
        fi
        ;;
        -p|--past)
        shift;
        if [[ -n "${1}" ]]; then
            PAST="${1}"
            shift;
        fi
        ;;
        -h|--help)
        shift;
        get_help
        ;;
        --)
        shift;
        break;
        ;;
    esac
done
# }}}

# {{{ Check Arguments
check_argus()
{
    if [[ -z ${BUCKET} || -z ${DIR} || -z ${POSTFIX} || -z ${KEEP} ]]; then
        echo -e "Error: -b,-l,-f,-k, at leaset four argumenst needed, try -h|--help for more information!"
        exit 1
    fi
}
# }}} 

# {{{ Uploader
uploader()
{
    POSTFIXS=(`echo ${POSTFIX} | tr ',' '\n'`)
    for P in ${POSTFIXS[@]}
    do
        find ${DIR} -name "*.${P}" -mtime -${PAST:-2} -exec aws s3 mv {} s3://${BUCKET} \; 
    done
}
# }}}

# {{{ Deleter
deleter()
{
    #for FILE in `aws s3 ls s3://${BUCKET}`
    #do
    #    CREATE_DAY=`echo ${FILE} | awk '{print $1}'`
    #    BOUNDARY_DAY=`date +%Y-%m-%d --date="-${PAST} days"`
    #    FILE_PATH=`echo ${FILE} | awk '{print $NF}'`
    #    if [[ ${CREATE_DAY} < ${BOUNDARY_DAY} ]]; then
    #        aws s3 rm s3://${BUCKET}/${FILE_PATH}
    #    fi
    #done

    aws s3 ls s3://${BUCKET} | while read LINE
    do
        CREATE_DAY=`echo ${LINE} | awk '{print $1}'`
        BOUNDARY_DAY=`date +%Y-%m-%d --date="-${KEEP} days"`
        FILE_PATH=`echo ${LINE} | awk '{print $NF}'`
        if [[ ${CREATE_DAY} < ${BOUNDARY_DAY} ]]; then
            aws s3 rm s3://${BUCKET}/${FILE_PATH}
        fi
    done
}
# }}}

check_argus
uploader
deleter
