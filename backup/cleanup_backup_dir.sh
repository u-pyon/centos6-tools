#!/bin/sh

cleanup_backup_dir () {
  result=`find ${1}`
  prefix=$2
  filename=$3
  count=0
  cat /dev/null >> "/tmp/${filename}.in"
  for file in `find ${1}`; do
    if [ -f $file ]; then
      if [[ "$file" =~ \/${prefix}[^\/]+?$ ]]; then
        echo $file >> "/tmp/${filename}.in"
        count=$((count+1))
      fi
    fi
  done

  sort -d "/tmp/${filename}.in" > "/tmp/${filename}.out"

  backup_files=()
  while read LINE
  do
    backup_files=("${backup_files[@]}" $LINE)
  done < "/tmp/${filename}.out"

  rm -f "/tmp/${filename}.in"
  rm -f "/tmp/${filename}.out"

  if [ ${#backup_files[@]} -ge $REVISION ]; then
    num_diff=`expr ${#backup_files[@]} - ${REVISION}`
    if [ $num_diff -gt 0 ]; then
      for p in ${backup_files[@]}; do
        if [ $num_diff -le 0 ]; then
          break;
        fi
        `rm -f ${p}`
        num_diff=$((num_diff-1))
      done
    fi
  fi
}
