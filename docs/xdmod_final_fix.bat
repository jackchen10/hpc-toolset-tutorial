@echo off
echo ========================================
echo XDMoD Final Fix and Startup
echo ========================================

echo Step 1: Ensuring XDMoD container is running...
docker compose up -d xdmod

echo Step 2: Waiting for container to start...
timeout /t 30 /nobreak

echo Step 3: Copying corrected configuration...
docker cp xdmod_portal_settings.ini xdmod:/etc/xdmod/portal_settings.ini

echo Step 4: Setting correct permissions...
docker exec xdmod chown apache:xdmod /etc/xdmod/portal_settings.ini
docker exec xdmod chmod 640 /etc/xdmod/portal_settings.ini

echo Step 5: Starting Apache web server...
docker exec -d xdmod /usr/sbin/httpd -D FOREGROUND

echo Step 6: Waiting for services to start...
timeout /t 15 /nobreak

echo Step 7: Testing port accessibility...
python test_ports.py

echo.
echo ========================================
echo XDMoD Fix Complete!
echo ========================================
echo XDMoD should now be accessible at:
echo https://localhost:4443
echo.
echo Login credentials:
echo - Local admin: admin/admin
echo - LDAP users: hpcadmin/ilovelinux
echo ========================================
