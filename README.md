


# Automated Server Backups!

### The Mission
1. __Weekly backups of folder and mysql databases on a ubuntu server__
2. __Email notification about finished backups and easy way to download the files__

I came across a lot of weird server backup software with design and UX from the 90th coupled with hundred of options. So I decided to create this simple script to do the backups of files and databases. 

### Steps:
1. Access server and create script
2. Define what and where to backup
3. Automate with crontabs
4. Sending email notification
5. Download server backup

### Prerequisites:

 1. SSH access
 2. Installed [tar](https://www.systutorials.com/docs/linux/man/1-tar/), [mysqldump](https://mariadb.com/kb/en/library/mysqldump/), [crontabs](https://linux.die.net/man/1/crontab) and [mail](https://mailutils.org/manual/html_section/mail.html) on server
 3. Basic knowledge in using a CLI


## 1. Access server and create script

Let's login into your server and create a script for your backups. To make it easy we are using the user `root`. For production system you should create an extra user with access to only these files and folders you want to include.

### Login with SSH

```bash
$ ssh root@111.222.333.444
root@111.222.333.444's password:
```

After successful login you might see:
```bash
Welcome to Ubuntu 16.04.2 LTS (GNU/Linux 4.4.0-109-generic x86_64)
 
 root@host:~#
```

You are now in the home folder of the root user. 

### Create a new script file

```bash
$ vi backup.sh
```
 To start `editing` mode in VIM you can press `i`. You file should look like the following:

```bash
#!/bin/bash
echo Hello
```

Save file with `: + w + Enter` and close with `: + q + Enter`. Make the script executable and test it.

```bash
$ chmod +x backup.sh
$ ./backup.sh
Hello
```
If you got stuck in VIM here is a [list](https://kb.iu.edu/d/afdc) of helpful commands.

## 2. Define what and where to backup

`backup.sh` of this repository looks larger than it is. 90% are `echo`s to generate a useful email notification. Let's cut out all the non important stuff and walk through the script.

### What to Backup ?
Define paths to folders and databases you want to include in the backup. Most of the time you want to backup a running application, so you should include the app sources and the database. __Don't include the whole file system__ -> You will get problems with disk space ;-) 

```bash
# backup folders
backup_files="/var/www/my-website.de /var/www/wordpress /etc"

# backup databases
backup_databases="mywebsite wordpress"
```

> We only include sources we really need in case of an emergency. We are using GIT for our projects, so there is no need to include the source code in the server backups. But upload folders, databases, config files, php settings, ssl certificates are the import things to think of. 

### Where to backup ?
Define a destination folder for your backup files. The folder should be placed somewhere on your system where it is persisted. (If you don't use root user you have to be sure that you have access to that location and btw that user also needs access to the files you want to back up.)

```bash
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
```

### Backup folder with tar

This is actually the magic command which backups your system. 
```bash
# backup the files using tar.
tar czvfP $dest/$archive_file $backup_files
```
Confused by `czvfP` ? 

 - `-c` create a new archive 
 - `-z` filter the archive through gzip 
 - `-v` verbosely list files processed 
 - `-f` use archive file or device ARCHIVE 
 - `-p` extract information about file permissions

Type `$ man tar` or visit the [docs](https://www.systutorials.com/docs/linux/man/1-tar/) for more information.


### Backup MariaDB databases with mysqldump
```bash
# database dump in temp file
mysqldump --user root --routines --triggers --single-transaction --databases $backup_databases > "$dest/sql_dump.sql"

# pack the sql dump with tar and remove dump
tar czfP $dest/$mysql_file "$dest/sql_dump.sql" 
rm $dest/sql_dump.sql

# print end status message
echo "Backup SUCCESS"

# echo generated files
ls -lh $dest
```

Save the file and test it with 
```bash
$ ./backup.sh
```
If everything went well your backup files are now located in your defined `$dest` path.

```bash
$ ls -la /mnt/backups/
```

**The full script is available [here](https://github.com/zauberware/automated-server-backups/blob/master/backup.sh)**

## 3. Automate with crontabs
With crontab we can automate the script execution. If you have never used crontab just use one of my examples or read through the [docs](https://linux.die.net/man/1/crontab). To make it short: There is a file in where you place line by line jobs which will then be executed defined by parameters.

A job has the following structure:

```bash
* * * * * <command>
| | | | | |------------------ command to execute
| | | | |-------------------- day of the week (0-7) 0 and 7 is sunday
| | | |---------------------- month of the year (1-12)
| | |------------------------ day of the month (1-31)
| |-------------------------- hour (0-23)
|---------------------------- minute (0-59)
```

### Add a job
Use the below command to add or update job in crontab. It opens the crontab file where a job can be added/updated.
```bash
$ crontab -e
```

Let's add a basic job which runs **every 5 minutes**.

```bash
*/5 * * * * /bin/sh backup.sh
```
Press `ctrl + O + Enter` to save the file and `ctrl + X` to close the crontab window. Relax for 5 minutes and see what happened ;)

### List all crontabs
```bash
$ crontab -l
```

### Crontab examples
Running a full backup every 5 minutes might be not a good approach. Here are some examples you could use:

```bash
# every day at 3 a.m.
0 3 * * * /bin/sh backup.sh

# every day at 3 a.m. and 4 p.m
0 3,16 * * * /bin/sh backup.sh

# every sunday at 5 a.m.
0 5 * * 0 /bin/sh backup.sh

# every sunday and friday at 3 a.m.
0 3 * * sun,fri  /bin/sh backup.sh

# every 6 hours
0 */6 * * * /bin/sh backup.sh
```


### Save log output in file

To store output in a log file:
```bash
*/1 * * * * /bin/sh backup.sh >>backup.log
```


## 4. Sending email notification
If you want to get informed if a new backup is available you can use `mail` to send you an email. 

```bash
*/1 * * * * /bin/sh backup.sh | mail -s "NEW BACKUP - Your server" -a "Your server Backup Scheduler <backup@yourserver.de>" your@company.com
```

## 5. Download backup
In our script we already gave a hint about how to download the files. You might give someone else an access with an extra user and he or she can download the files with SFTP client or the CLI. While backups are stored under `/mnt/backups` you can create a symlink from users home to that location.

```bash
# logged in with root@111.222.333.444
# will fail if symlink exists already
$ ln -s /mnt/backup backups 

# to create or update a symlink
$ ln -sf /mnt/backup backups
```
Logout of your server and try to download the files with one line
```bash
# on you local machine
$ cd ~/Downloads
$ scp root@111.222.333.444:backups/host-mysql-18-03-25.tar .
```
Unpack the downloaded file
```bash
$ tar -xvzf host-mysql-18-03-25.tar
```

## Enhancements

### Delete old backup files
What to do with old back up files? You may don't need them anymore. If you run jobs on a daily basis you will hit the disk space limit soon. You could include a "old-file-deleter" in your script. Let's say we want to delete all files which are older than 14 days.

```bash
# place at the end of backup.sh
find /mnt/backup -mtime +14 -type f -delete
```
 - `/mnt/backup` to search in
 - `-mtime +14` older than 14 days
 - `-type f` only files
 - `-delete` no surprise. **Remove it to test your `find` filter before executing the whole command**

## Thoughts:

 - Currently we are generating the file names for our server backup with
   the current date. This could be a problem if you are running the
   script more than once a day. Currently the file will be overwritten.
 - What would this script look like for a windows server backup?

## Links:

 - Commands for vim editor https://kb.iu.edu/d/afdc
 - Using mysqldump https://mariadb.com/kb/en/library/mysqldump/
 - Crontabs https://www.computerhope.com/unix/ucrontab.htm
 - Crontab examples https://tecadmin.net/crontab-in-linux-with-20-examples-of-cron-schedule/

## Author

__Script:__ <https://github.com/zauberware/automated-server-backups>  

__Author website:__ [https://www.zauberware.com](https://www.zauberware.com)    
__Author:__ zauberware technologies / Simon Franzen <simon@zauberware.com>  

![zauberware technologies](https://avatars3.githubusercontent.com/u/1753330?s=200&v=4)

