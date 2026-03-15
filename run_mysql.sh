#!/bin/bash
# Usage: ./run_mysql.sh DB_HOST DB_USER DB_PASS DB_NAME SQL_FILE

DB_HOST=$1
DB_USER=$2
DB_PASS=$3
DB_NAME=$4
SQL_FILE=$5

if [ ! -f "$SQL_FILE" ]; then
    echo "SQL file $SQL_FILE not found!"
    exit 1
fi

mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SQL_FILE"