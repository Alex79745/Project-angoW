#!/bin/bash
set -e
if [ -z "$1" ]; then echo "usage: restore.sh backup-file.sql.gz"; exit 1; fi
gunzip -c "$1" | mysql -h mysql -u root -p"${MYSQL_ROOT_PASSWORD}" 
echo "Restore completed"
