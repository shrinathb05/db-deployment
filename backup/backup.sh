#!/bin/bash
DB_HOST=$1
DB_USER=$2
DB_PASS=$3
DB_NAME=$4
DATE=$(date +%Y%m%d_%H%M)
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME > backup_$DATE.sql
