#!/bin/bash
set -uo pipefail

DB_HOST="$1"
DB_USER="$2"
DB_NAME="$3"
SQL_FILE="$4"

# Validate DB_PASS is provided via environment
if [ -z "${DB_PASS:-}" ]; then
    echo "ERROR: DB_PASS environment variable is not set."
    exit 1
fi

LOG_DIR="./logs/mysql"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
# Extract only the base filename to prevent path resolution issues
BASE_SQL_NAME=$(basename "$SQL_FILE" .sql)
LOG_FILE="${LOG_DIR}/${DB_NAME}_${BASE_SQL_NAME}_${TIMESTAMP}.log"

if [ ! -f "$SQL_FILE" ]; then
    echo "ERROR: SQL File '$SQL_FILE' not found in $(pwd)" | tee -a "$LOG_FILE"
    exit 1
fi

echo "===== Execution Summary =====" | tee "$LOG_FILE"
echo "Target Host: $DB_HOST" | tee -a "$LOG_FILE"
echo "Database:    $DB_NAME" | tee -a "$LOG_FILE"
echo "SQL Script:  $SQL_FILE" | tee -a "$LOG_FILE"
echo "=============================" | tee -a "$LOG_FILE"

export MYSQL_PWD="$DB_PASS"

# Execute SQL file and redirect output to log
mysql -v -v --connect-timeout=10 --batch -h "$DB_HOST" -u "$DB_USER" "$DB_NAME" < "$SQL_FILE" >> "$LOG_FILE" 2>&1
EXIT_CODE=$?

unset MYSQL_PWD

if [ $EXIT_CODE -eq 0 ]; then
    echo "SUCCESS: $SQL_FILE executed successfully." | tee -a "$LOG_FILE"
    echo "--- LOG OUTPUT ---"
    cat "$LOG_FILE"
    exit 0
else
    echo "ERROR: $SQL_FILE failed with exit code $EXIT_CODE." | tee -a "$LOG_FILE"
    echo "--- ERROR LOG OUTPUT ---"
    cat "$LOG_FILE"
    exit $EXIT_CODE
fi