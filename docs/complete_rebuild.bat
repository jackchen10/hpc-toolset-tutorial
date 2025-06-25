@echo off
echo ========================================
echo Complete HPC Toolset Rebuild
echo ========================================

echo.
echo Step 1: Complete cleanup...
docker compose down -v
docker system prune -f
docker volume prune -f

echo.
echo Step 2: Recreating database scripts with correct line endings...

echo #!/bin/bash > database\create-coldfront-db.sh
echo set -e >> database\create-coldfront-db.sh
echo. >> database\create-coldfront-db.sh
echo echo "Creating coldfront database.." >> database\create-coldfront-db.sh
echo mariadb -uroot -e "create database if not exists coldfront" >> database\create-coldfront-db.sh
echo echo "Creating coldfront mysql user.." >> database\create-coldfront-db.sh
echo mariadb -uroot -e "create user if not exists 'coldfrontapp'@'%%' identified by '9obCuAphabeg'" >> database\create-coldfront-db.sh
echo echo "Granting coldfront user access.." >> database\create-coldfront-db.sh
echo mariadb -uroot -e "grant all on coldfront.* to 'coldfrontapp'@'%%'" >> database\create-coldfront-db.sh
echo mariadb -uroot -e "flush privileges" >> database\create-coldfront-db.sh
echo if [ -f "/docker-entrypoint-initdb.d/coldfront.dump" ]; then >> database\create-coldfront-db.sh
echo   echo "Restoring coldfront database..." >> database\create-coldfront-db.sh
echo   mariadb -uroot coldfront ^< /docker-entrypoint-initdb.d/coldfront.dump >> database\create-coldfront-db.sh
echo fi >> database\create-coldfront-db.sh

echo #!/bin/bash > database\create-slurm-db.sh
echo set -e >> database\create-slurm-db.sh
echo. >> database\create-slurm-db.sh
echo echo "Creating slurm database.." >> database\create-slurm-db.sh
echo mariadb -uroot -e "create database if not exists slurm_acct_db" >> database\create-slurm-db.sh
echo echo "Creating slurm mysql user.." >> database\create-slurm-db.sh
echo mariadb -uroot -e "create user if not exists 'slurm'@'%%' identified by 'Ju6wreviap'" >> database\create-slurm-db.sh
echo echo "Granting slurm user access.." >> database\create-slurm-db.sh
echo mariadb -uroot -e "grant all on slurm_acct_db.* to 'slurm'@'%%'" >> database\create-slurm-db.sh
echo mariadb -uroot -e "flush privileges" >> database\create-slurm-db.sh

echo #!/bin/bash > database\create-xdmod-db.sh
echo set -e >> database\create-xdmod-db.sh
echo. >> database\create-xdmod-db.sh
echo echo "Creating xdmod mysql user.." >> database\create-xdmod-db.sh
echo mariadb -uroot -e "create user if not exists 'xdmodapp'@'%%' identified by 'ofbatgorWep0'" >> database\create-xdmod-db.sh
echo echo "Creating xdmod databases.." >> database\create-xdmod-db.sh
echo for db in mod_hpcdb mod_logger mod_shredder moddb modw modw_aggregates modw_filters modw_supremm modw_etl modw_jobefficiency modw_cloud modw_ondemand; do >> database\create-xdmod-db.sh
echo   mariadb -uroot -e "create database if not exists $db" >> database\create-xdmod-db.sh
echo   mariadb -uroot -e "grant all on $db.* to 'xdmodapp'@'%%'" >> database\create-xdmod-db.sh
echo done >> database\create-xdmod-db.sh
echo mariadb -uroot -e "flush privileges" >> database\create-xdmod-db.sh

echo.
echo Step 3: Starting MySQL and waiting for initialization...
docker compose up -d mysql
timeout /t 60 /nobreak

echo.
echo Step 4: Starting all services...
docker compose up -d

echo.
echo Step 5: Waiting for services to start...
timeout /t 120 /nobreak

echo.
echo Step 6: Final check...
docker compose ps

echo.
echo ========================================
echo Services should be available at:
echo ColdFront:  https://localhost:2443
echo OnDemand:   https://localhost:3443
echo XDMoD:      https://localhost:4443
echo ========================================
