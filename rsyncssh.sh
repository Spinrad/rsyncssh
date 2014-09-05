#!/bin/bash
#
# This script runs incremental backups of a distant specified folder, keep logs and send a mail notification.
# Dependencies : rsync, ssh, and mail
# You need to properly configure ssh keys on distant server
# Launch script from destination host, because  --link-dest need a localpath)
# 
###Setup###
PREFIX="HostSource"
NAS="HostDest"
DEST="/home/user/mybackup"
SOURCE="user@server:/folder_to_backup/"
DATE=`date '+%F_%H-%M'`
MAIL=user@mail.org
##########
#
echo "$PREFIX Rsync incremental backup script"
echo "$PREFIX Destination directory: $NAS $DEST"
echo "$PREFIX Source directory: $SOURCE"
 
# Verify that the destination folder exists
if [ ! -d "$DEST" ]; then
    echo "$PREFIX Destination folder \"$DEST\" not found. Exiting..."
    exit 1
fi
 
cd "$DEST"
 
echo "$PREFIX Step 1: Rotating old backups..."
 
rm -rf backup.5
mv backup.4 backup.5 2>/dev/null
mv backup.3 backup.4 2>/dev/null
mv backup.2 backup.3 2>/dev/null
mv backup.1 backup.2 2>/dev/null
mv backup backup.1 2>/dev/null
mv current backup 2>/dev/null
 
echo "$PREFIX Done!"
echo "$PREFIX Step 2: Running backup..."
sleep 1
 
#Launch script from destination host, because  --link-dest need a localpath)
rsync -v -a --delete --log-file="$DEST/$PREFIX-$DATE.log" --link-dest="../backup/" "$SOURCE" "$DEST/current"
 
echo "$PREFIX Done!"
sleep 1
echo "$PREFIX Step 3: Mail notification..."
echo "$DATE - Backup rsync $PREFIX $Source to $NAS@$DEST : OK" | mail -s "Daily backup rsync $PREFIX to $NAS : OK" "$MAIL";
echo "$PREFIX Done!"
