#!/bin/bash
DB_HOST=$1
DB_USER=$2
DB_PASS=$3
DB_NAME=$4
SQL_FILE=$5

set -euo pipefail

LOG_FILE="${SQL_FILE%.sql}.log"

if [ ! -f "$SQL_FILE" ]; then
    echo "SQL file $SQL_FILE not found!" | tee -a "$LOG_FILE"
    exit 1
fi

echo "Running $SQL_FILE on $DB_NAME@$DB_HOST" | tee -a "$LOG_FILE"

mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SQL_FILE" >> "$LOG_FILE" 2>&1

# mysql -h "$1" -u "$2" -p"$3" "$4" < "$5" 

echo "$5 executed successfully" | tee -a "$LOG_FILE"