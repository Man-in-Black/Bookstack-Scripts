#!/bin/bash

# Directories to use in this Docker backup script
# Should not end with a slash and not be stored within
# the BookStack directory
BACKUP_ROOT_DIR="/sicherung/bookstack" # Change to your backup path
DOCKER_DIR="/docker/bookstack" # Change to your bookstack Docker folder
BOOKSTACK_DIR="$DOCKER_DIR/bookstack_app_data/www"
CONTAINER_NAME="bookstack" # Change to your container name
CONTAINER_DB_NAME="bookstack_db" # Change to you database container name

# Directory of the BookStack within docker
# Should not end with a slash.
BOOKSTACK_DOCKER="/app/www"

# Get database options from BookStack .env file
export $(cat "$BOOKSTACK_DIR/.env" | grep ^DB_ | xargs)

# Create an export name and location
DATE=$(date "+%Y-%m-%d_%H-%M-%S")
BACKUP_NAME="bookstack_backup_$DATE"
BACKUP_NAME_DOCKER="bookstack_docker_backup_$DATE"
BACKUP_DIR="$BACKUP_ROOT_DIR/$BACKUP_NAME"
BACKUP_DIR_DOCKER="$BACKUP_ROOT_DIR/$BACKUP_NAME_DOCKER"
mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR_DOCKER"

# Dump database to backup dir using the values
# we got from the BookStack .env file.
docker exec $CONTAINER_DB_NAME /usr/bin/mysqldump --single-transaction \
 --no-tablespaces \
 -u "$DB_USERNAME" \
 -p"$DB_PASSWORD" \
 $DB_DATABASE > "$BACKUP_DIR/database.sql"

# Create backup archive
tar -zcf "$BACKUP_DIR.tar.gz" \
 "$DOCKER_DIR/bookstack_app_data" \
 "$BACKUP_DIR/database.sql"
docker cp "$CONTAINER_NAME":"$BOOKSTACK_DOCKER" \
 "$BACKUP_DIR_DOCKER"
tar -czf "$BACKUP_DIR_DOCKER.tar.gz" \
 "$BACKUP_DIR_DOCKER"

# Cleanup non-archive directory
rm -rf "$BACKUP_DIR/"
rm -rf "BACKUP_DIR_DOCKER"

# delete old backups
BACKUPDAYS=14
/usr/bin/find $BACKUP_ROOT_DIR/bookstack_backup_*tar.gz -mtime +$BACKUPDAYS -exec rm -r {} \;
/usr/bin/find $BACKUP_ROOT_DIR/bookstack_docker_backup_*tar.gz -mtime +$BACKUPDAYS -exec rm -r {} \;

echo "Backup complete, archive stored at:"
echo "$BACKUP_DIR.tar.gz"
echo "$BACKUP_DIR_DOCKER.tar.gz"
