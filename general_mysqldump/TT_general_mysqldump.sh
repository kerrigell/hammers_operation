#!/bin/bash
# author: penghaiyang
# Automatically test general_mysqldump.sh

chmod +x ./general_mysqldump.sh
#mysqladmin create COSTCO
#mysqladmin create WALLMART
#mysqladmin create SAFEWAY

date -s "`date "+%D %T" --date="-100 day"`" > /dev/null
for i in `seq 1 100`
do
    date -s "`date "+%D %T" --date="+1 day"`" > /dev/null
    # backup all schemas, keep all backup files
    ./general_mysqldump.sh 3306 all utf8 /home/databackup/ cn_test_56.101 
    # backup two schemas, keep file in 15 days, keep file in every month's 1st, delete all files 80 days ago
    ./general_mysqldump.sh 3306 COSTCO,SAFEWAY utf8 /home/databackup/ cn_test_56.101 --keep d01 --delete 15 --expire 80
    # backup two schemas, keep file in 15 days, keep file in November, delete all files 100 days ago
    ./general_mysqldump.sh 3306 SAFEWAY,WALLMART utf8 /home/databackup/ cn_test_56.101 --keep m11 --delete 15 --expire 100
done
ntpdate pool.ntp.org

#mysqladmin -f drop COSTCO
#mysqladmin -f drop WALLMART
#mysqladmin -f drop SAFEWAY
