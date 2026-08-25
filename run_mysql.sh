#!/bin/bash
set -uo pipefail

DB_HOST="$1"
DB_USER="$2"
DB_NAME="$3"
SQL_FILE="$4"

if [ -z "${DB_PASS:-}" ]; then
    echo "ERROR: DB_PASS environment variable is not set."
    exit 1
fi

# Permanent log directory
PERM_LOG_DIR="/home/ubuntu/logs/mysql"
mkdir -p "$PERM_LOG_DIR"

# Temporary workspace directory for email attachments
BUILD_LOG_DIR="./build_logs"
mkdir -p "$BUILD_LOG_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BASE_SQL_NAME=$(basename "$SQL_FILE" .sql)
LOG_FILENAME="${DB_NAME}_${BASE_SQL_NAME}_${TIMESTAMP}.log"
PERM_LOG_FILE="${PERM_LOG_DIR}/${LOG_FILENAME}"
BUILD_LOG_FILE="${BUILD_LOG_DIR}/${LOG_FILENAME}"

if [ ! -f "$SQL_FILE" ]; then
    echo "ERROR: SQL File '$SQL_FILE' not found in $(pwd)" | tee "$PERM_LOG_FILE"
    cp "$PERM_LOG_FILE" "$BUILD_LOG_FILE" 2>/dev/null || true
    exit 1
fi

echo "================ Execution Summary ================" | tee "$PERM_LOG_FILE"
echo "Execution Time: $(date '+%Y-%m-%d %H:%M:%S %Z')" | tee -a "$PERM_LOG_FILE"
echo "Target Host:    $DB_HOST" | tee -a "$PERM_LOG_FILE"
echo "Database:       $DB_NAME" | tee -a "$PERM_LOG_FILE"
echo "SQL Script:     $SQL_FILE" | tee -a "$PERM_LOG_FILE"
echo "Log File:       $PERM_LOG_FILE" | tee -a "$PERM_LOG_FILE"
echo "===================================================" | tee -a "$PERM_LOG_FILE"

export MYSQL_PWD="$DB_PASS"

# Execute SQL script and log output
mysql -v -v --connect-timeout=10 --batch -h "$DB_HOST" -u "$DB_USER" "$DB_NAME" < "$SQL_FILE" >> "$PERM_LOG_FILE" 2>&1
EXIT_CODE=$?

unset MYSQL_PWD

# Copy log to build directory for email attachment
cp "$PERM_LOG_FILE" "$BUILD_LOG_FILE"

if [ $EXIT_CODE -eq 0 ]; then
    echo "SUCCESS: $SQL_FILE executed successfully." | tee -a "$PERM_LOG_FILE"
    echo "--- LOG OUTPUT ---"
    cat "$PERM_LOG_FILE"
    exit 0
else
    echo "ERROR: $SQL_FILE failed with exit code $EXIT_CODE." | tee -a "$PERM_LOG_FILE"
    echo "--- ERROR LOG OUTPUT ---"
    cat "$PERM_LOG_FILE"
    exit $EXIT_CODE
fi