#!/bin/sh

BACKUP_DIR=$1
USER=root
REMOTE_HOST=$2
REMOTE_DIR=$3
PORT=$4
LOG=$5
DATE=`date +"%Y-%m-%d %H:%M:%S"`

echo "Start rsync $BACKUP_DIR"
echo "[${DATE}]" >> $LOG
`/usr/bin/rsync -avz --delete -e "ssh -p ${PORT}" ${BACKUP_DIR} ${REMOTE_HOST}:${REMOTE_DIR} >> ${LOG}`
echo "" >> $LOG
echo "Done rsync $BACKUP_DIR"
