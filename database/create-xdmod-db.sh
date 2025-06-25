#!/bin/bash 
set -e 
 
echo "Creating xdmod mysql user.." 
mariadb -uroot -e "create user if not exists 'xdmodapp'@'%' identified by 'ofbatgorWep0'" 
echo "Creating xdmod databases.." 
for db in mod_hpcdb mod_logger mod_shredder moddb modw modw_aggregates modw_filters modw_supremm modw_etl modw_jobefficiency modw_cloud modw_ondemand; do 
  mariadb -uroot -e "create database if not exists $db" 
  mariadb -uroot -e "grant all on $db.* to 'xdmodapp'@'%'" 
done 
mariadb -uroot -e "flush privileges" 
