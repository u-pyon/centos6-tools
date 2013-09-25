#!/bin/sh

SCRIPT_PATH=$1
source "${SCRIPT_PATH}/cleanup_backup_dir.sh"

PREFIX=$2
BACKUP_DIR="/data/${PREFIX}"
BASE_DIR=$3
DATE=`date +"%Y%m%d_%H%M%S"`
FILENAME="${PREFIX}.${DATE}"
BACKUP_PATH="${BACKUP_DIR}/${FILENAME}"
REVISION=5

if [ `expr length "$PREFIX"` = 0 ]; then
  echo 'dir.sh required 1 args.'
  exit
fi

if [ `expr length "$BASE_DIR"` = 0 ]; then
  echo 'dir.sh required 2 args.'
  exit
fi
if [ ! -d $BASE_DIR ]; then
  echo 'dir.sh required a directory path of 2nd arg.'
  exit
fi

if [ ! -d $BACKUP_DIR ]; then
  echo "Make a backup directory for $PREFIX."
  mkdir -p "$BACKUP_DIR"
  if [ ! -d $BACKUP_DIR ]; then
    echo "Failure to make a backup directory '$BACKUP_DIR'."
    exit
  fi
fi

cd $BACKUP_DIR
echo "Change directory to $BACKUP_DIR."
echo "Make tar ball $FILENAME.tar.gz."
tar -zcf "${FILENAME}.tar.gz" "${BASE_DIR}"
echo "Finish tar ball $FILENAME.tar.gz."

cleanup_backup_dir $BACKUP_DIR $PREFIX $FILENAME
