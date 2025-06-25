@echo off
echo ========================================
echo XDMoD Simple Fix - Override Entrypoint
echo ========================================

echo Step 1: Starting XDMoD with overridden entrypoint...
docker compose up -d xdmod

echo Step 2: Waiting for container to start...
timeout /t 20 /nobreak

echo Step 3: Stopping the problematic setup process...
docker exec xdmod pkill -f xdmod-setup 2>nul
docker exec xdmod pkill -f expect 2>nul
docker exec xdmod pkill -f xdmod-import-csv 2>nul

echo Step 4: Copying correct configuration...
docker cp xdmod_portal_settings.ini xdmod:/etc/xdmod/portal_settings.ini

echo Step 5: Starting essential services manually...
docker exec xdmod bash -c "
  # Kill any existing httpd processes
  pkill httpd 2>/dev/null || true
  
  # Start PHP-FPM
  mkdir -p /run/php-fpm
  php-fpm &
  
  # Start Apache
  rm -f /var/run/httpd/httpd.pid
  /usr/sbin/httpd -DFOREGROUND &
  
  echo 'Services started'
"

echo Step 6: Waiting for services to start...
timeout /t 20 /nobreak

echo Step 7: Testing accessibility...
python test_ports.py

echo Step 8: Checking if XDMoD responds...
curl -k -s -o nul -w "HTTP Status: %%{http_code}" https://localhost:4443/ && echo " - XDMoD is responding" || echo " - XDMoD is not responding"

echo.
echo ========================================
echo XDMoD Simple Fix Complete!
echo ========================================
echo Try accessing: https://localhost:4443
echo Note: You may see a basic Apache page or 503 error initially
echo This is normal - XDMoD database needs to be initialized
echo ========================================
