#!/bin/bash
set -e
DATE=$(date +%F_%H%M)
OUTFILE=/backup/db_${DATE}.sql.gz
echo "Creating DB dump to $OUTFILE"
mysqldump -h mysql -u root -p"${MYSQL_ROOT_PASSWORD}" --all-databases | gzip > "$OUTFILE"
echo "Backup done: $OUTFILE"
