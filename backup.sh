#!/bin/bash
###################################
#
# Backup to NFS mount script.
#
###################################

# give your script a name
host=hostname

# what to backup
backup_files="/var/www/wordpress /var/www/mywebsite /etc"
#backup_files="/home/deploy/repositories /etc"

# which databases
backup_databases="wordpress mywebsite"

# where to backup
dest="/mnt/backup"

# create backup folder if not exist
mkdir -p $dest

# create archive filenames
day=$(date +%y-%m-%d)
archive_file="$host-$day.tar"
mysql_file="$host-mysql-$day.tar"

# print start status message
echo "Dear $host product owner,"
echo ""
echo "a new backup of your server was generated on your server." 
echo "You can find the files and folder under $dest/$archive_file and databases here $dest/$mysql_file. The backup included the follwing data:"
echo ""
echo "Folders: $backup_files"
echo "Databases: $backup_databases"
echo ""
echo ""
echo ""
echo "==================== DOWNLOAD WITH SCP ======================"
echo ""
echo "SQL database"
echo "Download database backup with $ scp root@111.222.333.444:/backups/$mysql_file backup"
echo "Unpack files with $ tar -xvzf backup/$mysql_file"
echo ""
echo "Files and Folders:"
echo "Download the full backup with with $ scp root@111.222.333.444:/backups/$archive_file backup"
echo "Unpack files with $ tar -xvzf backup/$archive_file"
echo 
echo "====================== FTP DOWNLOAD ========================="
echo ""
echo "Acces with FTP:"
echo "USER: root"
echo "PASS: X"
echo "SERV: 111.222.333.444"
echo "Download with FTP client manually"
echo ""
echo "=============================================================="
echo ""
echo ""
echo "I wish you a nice day !"
echo ""
echo ""
echo "========================== LOG ==============================="
echo ""
echo "Starting script..."
date

# backup the files using tar.
tar czvfP $dest/$archive_file $backup_files

# database backup 
mysqldump --user root --routines --triggers --single-transaction --databases $backup_databases > "$dest/sql_dump.sql"
tar czfP $dest/$mysql_file "$dest/sql_dump.sql" && rm $dest/sql_dump.sql

# print end status message
echo "."
echo "."
echo "."
echo "... Backup SUCCESS!"
date
echo ""
echo "Delete old files !"
find $dest -mtime +14 -type f
find $dest -mtime +14 -type f -delete
echo ""

# echo generated files
echo "Files generated"
ls -lh $dest
