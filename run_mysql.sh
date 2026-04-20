#!/bin/bash
DB_HOST=$1
DB_USER=$2
DB_PASS=$3
DB_NAME=$4
SQL_FILE=$5

set -uo pipefail

# Ensure work directory is the base for finding files
LOG_DIR="./logs/mysql"
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
    echo "--- START OF SQL LOG ---"
    cat "$LOG_FILE"  # <--- This prints it to the Jenkins Console
    echo "--- END OF SQL LOG ---"
    exit 0
else
    echo "ERROR: $SQL_FILE failed." | tee -a "$LOG_FILE"
    echo "--- START OF ERROR LOG ---"
    cat "$LOG_FILE"  # <--- This ensures the failure reason is visible in Jenkins
    echo "--- END OF ERROR LOG ---"
    exit $EXIT_CODE
fi
