#!/bin/bash
###################################
#
# Automated server backups
#
###################################

# what to backup
# backup folders
backup_files="/var/www/my-website.de /var/www/wordpress /etc"

# backup databases
backup_databases="mywebsite wordpress"

# where to backup
dest="/mnt/backup"

# create backup folder if not exist
mkdir -p $dest

# create archive filenames
day=$(date +%y-%m-%d)
hostname=$(hostname -s)
archive_file="$hostname-$day.tar"
mysql_file="$hostname-mysql-$day.tar"

# print start status message
echo "Backing up $backup_files to $dest/$archive_file ..."
echo "Backing up $backup_databases to $dest/$mysql_file ..."
date
echo
echo "================================================================"
echo
echo "Download database backup with $ scp root@111.222.333.444:backups/$mysql_file backup"
echo
echo "Unpack files with $ tar -xvzf backup/$mysql_file"
echo
echo "Download the full backup with with $ scp root@111.222.333.444:backups/$archive_file backup"
echo
echo "Unpack files with $ tar -xvzf backup/$archive_file"
echo 
echo "================================================================="
echo ""

# database dump in temp file
tar czvfP $dest/$archive_file $backup_files

# pack the sql dump with tar and remove dump
mysqldump --user root --routines --triggers --single-transaction --databases $backup_databases > "$dest/sql_dump.sql"
tar czfP $dest/$mysql_file "$dest/sql_dump.sql"
rm $dest/sql_dump.sql

# print end status message
echo
echo "Backup SUCCESS"
date
echo
echo "Delete old files"
find $dest -mtime +14 -type f -delete
echo

# echo generated files
ls -lh $dest
