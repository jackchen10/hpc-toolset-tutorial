@echo off
echo ========================================
echo XDMoD Complete Fix and Initialization
echo ========================================

echo Step 1: Stopping XDMoD container...
docker compose stop xdmod

echo Step 2: Ensuring correct configuration is in place...
docker cp xdmod_portal_settings.ini xdmod:/etc/xdmod/portal_settings.ini

echo Step 3: Starting XDMoD container...
docker compose up -d xdmod

echo Step 4: Waiting for container to start...
timeout /t 30 /nobreak

echo Step 5: Setting correct permissions...
docker exec xdmod chown apache:xdmod /etc/xdmod/portal_settings.ini
docker exec xdmod chmod 640 /etc/xdmod/portal_settings.ini

echo Step 6: Initializing XDMoD database...
echo This may take several minutes...
docker exec xdmod bash -c "cd /usr/share/xdmod && php tools/etl/etl_overseer.php -c /etc/xdmod/etl/etl.json -p ingest.bootstrap"

echo Step 7: Setting up XDMoD configuration...
docker exec xdmod bash -c "echo 'yes' | xdmod-setup --setup-database"

echo Step 8: Creating admin user...
docker exec xdmod bash -c "echo -e 'admin\nadmin\nadmin@localhost\nAdmin\nUser\nyes' | xdmod-setup --create-admin"

echo Step 9: Starting Apache web server...
docker exec -d xdmod /usr/sbin/httpd -D FOREGROUND

echo Step 10: Waiting for services to start...
timeout /t 20 /nobreak

echo Step 11: Testing accessibility...
python test_ports.py

echo.
echo ========================================
echo XDMoD Complete Fix Finished!
echo ========================================
echo XDMoD should now be accessible at:
echo https://localhost:4443
echo.
echo Login: admin/admin
echo ========================================
