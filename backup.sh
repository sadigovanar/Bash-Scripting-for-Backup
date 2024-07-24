#!/bin/bash

DES="/path/to/backup"
SQLFILE="alldatabases.sql"
SEAFILE="Seafile"
SEAF="/opt/seafile"
DATE=$(date +%Y%m%d)
FILE="$DES/$SQLFILE"
FILE1="$DES/$SEAFILE.$DATE.tar.bz2"
IP="server_ip"

# Check if MySQL is running
if ! pgrep -x "mysqld" > /dev/null; then
    systemctl stop mariadb > /dev/null
fi

# Backup all databases
mysqldump -u root --password='sql_root_password_here' --all-databases > "$DES/$SQLFILE"

# Check if Seafile is running
if ! pgrep -x "seafile" > /dev/null; then
    systemctl stop seafile.service > /dev/null
fi

# Check if Seahub is running
if ! pgrep -x "seahub" > /dev/null; then
    systemctl stop seahub.service > /dev/null
fi

# Create a tarball of the Seafile directory
tar cfj "$DES/$SEAFILE.$DATE.tar.bz2" --exclude=/opt/seafile/ccnet/ccnet.sock --absolute-names "$SEAF"

# Secure copy the backup files to the remote server
scp "$FILE" "$FILE1" user@$IP:/home/user/bk-server

# Delete the local backup files if the directory is not empty
if [ "$(ls -A $DES)" ]; then
    echo "Deleting backup files"
    find $DES -type f \( -name "*.sql" -o -name "*.tar.bz2" \) -delete
fi

# Start MariaDB if it was stopped
if ! pgrep -x "mysqld" > /dev/null; then
    systemctl start mariadb > /dev/null
fi

# Start Seafile if it was stopped
if ! pgrep -x "seafile" > /dev/null; then
    systemctl start seafile.service > /dev/null
fi

# Start Seahub if it was stopped
if ! pgrep -x "seahub" > /dev/null; then
    systemctl start seahub.service > /dev/null
fi

# Stop all services (useful for restoring)
systemctl stop mariadb
systemctl stop seafile.service
systemctl stop seahub.service
systemctl stop nginx

# Restore the database
mysql -u root --password='sql_root_password_here' < alldatabases.sql

# Extract the Seafile tarball
tar xvfj Seafile.tar.bz2 -C /opt/

# Start all services
systemctl start mariadb
systemctl start seafile.service
systemctl start seahub.service
systemctl start nginx
