#!/bin/bash
DB_HOST=$1
DB_USER=$2
DB_PASS=$3
DB_NAME=$4
SQL_FILE=$5

set -uo pipefail # Removed -e so we can handle the exit code manually for logging

# Create a logs directory if it doesn't exist
mkdir -p ./logs

# Define log file name with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="./logs/${SQL_FILE%.sql}_${TIMESTAMP}.log"

echo "===== Starting Execution of $SQL_FILE =====" | tee -a "$LOG_FILE"
echo "Target: $DB_NAME @ $DB_HOST" | tee -a "$LOG_FILE"
echo "Time: $(date)" | tee -a "$LOG_FILE"

# Run MySQL and capture EVERYTHING (stdout and stderr) to the log file
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SQL_FILE" >> "$LOG_FILE" 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "SUCCESS: $SQL_FILE executed perfectly." | tee -a "$LOG_FILE"
    exit 0
else
    echo "ERROR: $SQL_FILE failed with exit code $EXIT_CODE." | tee -a "$LOG_FILE"
    echo "Check $LOG_FILE for details."
    exit $EXIT_CODE
fi