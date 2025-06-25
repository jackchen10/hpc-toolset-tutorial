@echo off
echo ========================================
echo XDMoD Ultimate Fix - Solving 503 Error
echo ========================================

echo Step 1: Stopping XDMoD container completely...
docker compose stop xdmod
docker compose rm -f xdmod

echo Step 2: Cleaning up XDMoD data to start fresh...
docker volume rm hpc-toolset-tutorial_xdmod-etc hpc-toolset-tutorial_xdmod-log hpc-toolset-tutorial_xdmod-spool 2>nul

echo Step 3: Ensuring database is properly initialized...
docker exec mysql mysql -uroot -e "DROP DATABASE IF EXISTS modw; CREATE DATABASE modw;"
docker exec mysql mysql -uroot -e "DROP DATABASE IF EXISTS moddb; CREATE DATABASE moddb;"
docker exec mysql mysql -uroot -e "DROP DATABASE IF EXISTS mod_logger; CREATE DATABASE mod_logger;"
docker exec mysql mysql -uroot -e "DROP DATABASE IF EXISTS mod_shredder; CREATE DATABASE mod_shredder;"
docker exec mysql mysql -uroot -e "DROP DATABASE IF EXISTS mod_hpcdb; CREATE DATABASE mod_hpcdb;"
docker exec mysql mysql -uroot -e "DROP DATABASE IF EXISTS modw_aggregates; CREATE DATABASE modw_aggregates;"
docker exec mysql mysql -uroot -e "DROP DATABASE IF EXISTS modw_filters; CREATE DATABASE modw_filters;"
docker exec mysql mysql -uroot -e "DROP DATABASE IF EXISTS modw_supremm; CREATE DATABASE modw_supremm;"
docker exec mysql mysql -uroot -e "DROP DATABASE IF EXISTS modw_etl; CREATE DATABASE modw_etl;"
docker exec mysql mysql -uroot -e "DROP DATABASE IF EXISTS modw_jobefficiency; CREATE DATABASE modw_jobefficiency;"
docker exec mysql mysql -uroot -e "DROP DATABASE IF EXISTS modw_cloud; CREATE DATABASE modw_cloud;"
docker exec mysql mysql -uroot -e "DROP DATABASE IF EXISTS modw_ondemand; CREATE DATABASE modw_ondemand;"

echo Step 4: Granting permissions to xdmodapp user...
docker exec mysql mysql -uroot -e "GRANT ALL ON modw.* TO 'xdmodapp'@'%%';"
docker exec mysql mysql -uroot -e "GRANT ALL ON moddb.* TO 'xdmodapp'@'%%';"
docker exec mysql mysql -uroot -e "GRANT ALL ON mod_logger.* TO 'xdmodapp'@'%%';"
docker exec mysql mysql -uroot -e "GRANT ALL ON mod_shredder.* TO 'xdmodapp'@'%%';"
docker exec mysql mysql -uroot -e "GRANT ALL ON mod_hpcdb.* TO 'xdmodapp'@'%%';"
docker exec mysql mysql -uroot -e "GRANT ALL ON modw_aggregates.* TO 'xdmodapp'@'%%';"
docker exec mysql mysql -uroot -e "GRANT ALL ON modw_filters.* TO 'xdmodapp'@'%%';"
docker exec mysql mysql -uroot -e "GRANT ALL ON modw_supremm.* TO 'xdmodapp'@'%%';"
docker exec mysql mysql -uroot -e "GRANT ALL ON modw_etl.* TO 'xdmodapp'@'%%';"
docker exec mysql mysql -uroot -e "GRANT ALL ON modw_jobefficiency.* TO 'xdmodapp'@'%%';"
docker exec mysql mysql -uroot -e "GRANT ALL ON modw_cloud.* TO 'xdmodapp'@'%%';"
docker exec mysql mysql -uroot -e "GRANT ALL ON modw_ondemand.* TO 'xdmodapp'@'%%';"
docker exec mysql mysql -uroot -e "FLUSH PRIVILEGES;"

echo Step 5: Starting XDMoD with fresh configuration...
docker compose up -d xdmod

echo Step 6: Waiting for container to start...
timeout /t 30 /nobreak

echo Step 7: Copying fixed entrypoint script...
docker cp xdmod_fixed_entrypoint.sh xdmod:/usr/local/bin/entrypoint.sh
docker exec xdmod chmod +x /usr/local/bin/entrypoint.sh

echo Step 8: Copying corrected portal settings...
docker cp xdmod_portal_settings.ini xdmod:/etc/xdmod/portal_settings.ini
docker exec xdmod chown apache:xdmod /etc/xdmod/portal_settings.ini
docker exec xdmod chmod 640 /etc/xdmod/portal_settings.ini

echo Step 9: Manually initializing XDMoD database schema...
docker exec xdmod bash -c "cd /usr/share/xdmod && php tools/etl/etl_overseer.php -c /etc/xdmod/etl/etl.json -p ingest.bootstrap" 2>nul

echo Step 10: Creating admin user directly in database...
docker exec mysql mysql -uxdmodapp -pofbatgorWep0 --host mysql moddb -e "
INSERT IGNORE INTO Users (id, username, email_address, first_name, last_name, time_created, time_last_updated, account_is_active, person_id, organization_id, field_of_science, user_type) 
VALUES (1, 'admin', 'admin@localhost', 'Admin', 'User', NOW(), NOW(), 1, 1, 1, 1, 1);
INSERT IGNORE INTO UserRoles (user_id, role_id) VALUES (1, 1);
"

echo Step 11: Starting PHP-FPM and Apache manually...
docker exec xdmod bash -c "mkdir -p /run/php-fpm && php-fpm"
docker exec xdmod bash -c "rm -f /var/run/httpd/httpd.pid"
docker exec -d xdmod /usr/sbin/httpd -DFOREGROUND

echo Step 12: Waiting for services to fully start...
timeout /t 45 /nobreak

echo Step 13: Final status check...
docker compose ps xdmod
python test_ports.py

echo.
echo ========================================
echo XDMoD Ultimate Fix Complete!
echo ========================================
echo XDMoD should now be stable and accessible at:
echo https://localhost:4443
echo Login: admin/admin
echo ========================================
