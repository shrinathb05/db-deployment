#!/bin/bash
DB_HOST=$1
DB_USER=$2
DB_PASS=$3
DB_NAME=$4
SQL_FILE=$5

set -uo pipefail

# Ensure work directory is the base for finding files
LOG_DIR="/home/ubuntu/var/work/logs/mysql"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
# Adding DB_NAME to the log file helps distinguish logs if you run on different envs
LOG_FILE="${LOG_DIR}/${DB_NAME}_${SQL_FILE%.sql}_${TIMESTAMP}.log"

if [ ! -f "$SQL_FILE" ]; then
    echo "ERROR: SQL File '$SQL_FILE' not found in $(pwd)" | tee -a "$LOG_FILE"
    exit 1
fi

echo "===== Starting Execution of $SQL_FILE =====" | tee -a "$LOG_FILE"
echo "Target Host: $DB_HOST" | tee -a "$LOG_FILE"
echo "Database:    $DB_NAME" | tee -a "$LOG_FILE"

# --- SECURITY IMPROVEMENT ---
export MYSQL_PWD="$DB_PASS"

# IMPROVED: Added --connect-timeout=10 for RDS stability
# IMPROVED: Added --batch to ensure clean output for Jenkins logs
mysql -v -v --connect-timeout=10 --batch -h "$DB_HOST" -u "$DB_USER" "$DB_NAME" < "$SQL_FILE" >> "$LOG_FILE" 2>&1
EXIT_CODE=$?

unset MYSQL_PWD

if [ $EXIT_CODE -eq 0 ]; then
    echo "SUCCESS: $SQL_FILE executed perfectly." | tee -a "$LOG_FILE"
    exit 0
else
    # Output the last 10 lines of the error to Jenkins console immediately
    echo "-------------------------------------------"
    tail -n 10 "$LOG_FILE"
    echo "-------------------------------------------"
    echo "ERROR: $SQL_FILE failed with exit code $EXIT_CODE." | tee -a "$LOG_FILE"
    exit $EXIT_CODE
fi
