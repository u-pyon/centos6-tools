#!/bin/sh

SCRIPT_PATH=$1
source "${SCRIPT_PATH}/cleanup_backup_dir.sh"

DATABASE=$2
USER="root"
PASSWORD="p@ssw0rd"
BACKUP_DIR=$3
DATE=`date +"%Y%m%d_%H%M%S"`
FILENAME="${DATABASE}.${DATE}.dump"
BACKUP_PATH="${BACKUP_DIR}/${FILENAME}"
REVISION=12

if [ `expr length "$DATABASE"` = 0 ]; then
  echo 'mysql.sh required 1 args.'
  exit
fi

if [ ! -d $BACKUP_DIR ]; then
  echo "Directory $BACKUP_DIR doesn't exists."
  mkdir -p $BACKUP_DIR
  echo "Create $BACKUP_DIR."
fi

echo "Process mysqldump."
`mysqldump -u${USER} -p${PASSWORD} --single-transaction "${DATABASE}" > "${BACKUP_PATH}"`
while [ ! -f $BACKUP_PATH ]; do
  sleep 1
  echo "backuping..."
done
sleep 2
echo "mysqldump done."

echo "Change current directory to $BACKUP_DIR."
cd $BACKUP_DIR
echo "Make tar ball $FILENAME.tar.gz."
tar -zcf "${FILENAME}.tar.gz" "${FILENAME}"

sleep 2
while [ ! -f "${BACKUP_PATH}.tar.gz" ]; do
  sleep 1
  echo "sleep..."
done
`rm -f "${BACKUP_PATH}"`

echo "Clean up $BACKUP_DIR"
cleanup_backup_dir $BACKUP_DIR $DATABASE $FILENAME

