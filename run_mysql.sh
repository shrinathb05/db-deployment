#!/bin/bash
$1 = DB_HOST
$2 = DB_USER
$3 = DB_PASS
$4 = DATABASE
$5 = SQL_FILE

set -euo pipefail

LOG_FILE="${5%.sql}.log"

if [ ! -f "$5" ]; then
    echo "SQL file $5 not found!" | tee -a "$LOG_FILE"
    exit 1
fi

echo "Running $5 on $4@$1" | tee -a "$LOG_FILE"

mysql -h "$1" -u "$2" -p"$3" "$4" < "$5" >> "$LOG_FILE" 2>&1

echo "$5 executed successfully" | tee -a "$LOG_FILE"