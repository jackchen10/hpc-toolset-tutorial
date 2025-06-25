#!/bin/bash 
set -e 
 
echo "Creating coldfront database.." 
mariadb -uroot -e "create database if not exists coldfront" 
echo "Creating coldfront mysql user.." 
mariadb -uroot -e "create user if not exists 'coldfrontapp'@'%' identified by '9obCuAphabeg'" 
echo "Granting coldfront user access.." 
mariadb -uroot -e "grant all on coldfront.* to 'coldfrontapp'@'%'" 
mariadb -uroot -e "flush privileges" 
if [ -f "/docker-entrypoint-initdb.d/coldfront.dump" ]; then 
  echo "Restoring coldfront database..." 
  mariadb -uroot coldfront < /docker-entrypoint-initdb.d/coldfront.dump 
fi 
