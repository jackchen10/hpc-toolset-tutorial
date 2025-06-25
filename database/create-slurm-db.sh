#!/bin/bash 
set -e 
 
echo "Creating slurm database.." 
mariadb -uroot -e "create database if not exists slurm_acct_db" 
echo "Creating slurm mysql user.." 
mariadb -uroot -e "create user if not exists 'slurm'@'%' identified by 'Ju6wreviap'" 
echo "Granting slurm user access.." 
mariadb -uroot -e "grant all on slurm_acct_db.* to 'slurm'@'%'" 
mariadb -uroot -e "flush privileges" 
