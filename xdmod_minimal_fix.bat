@echo off
echo ========================================
echo XDMoD Minimal Fix - Direct Approach
echo ========================================

echo Step 1: Stopping XDMoD completely...
docker compose stop xdmod
docker compose rm -f xdmod

echo Step 2: Starting XDMoD with custom command...
docker run -d --name xdmod --network hpc-toolset-tutorial_compute ^
  -p 127.0.0.1:4443:443 ^
  -v hpc-toolset-tutorial_xdmod-etc:/etc/xdmod ^
  -v hpc-toolset-tutorial_xdmod-log:/var/log/xdmod ^
  -v hpc-toolset-tutorial_xdmod-spool:/var/spool/xdmod ^
  -v "%cd%\xdmod\hierarchy.csv:/srv/xdmod/hierarchy.csv:ro" ^
  -v "%cd%\xdmod\supremm.py:/srv/xdmod/scripts/supremm.py:ro" ^
  -v "%cd%\xdmod\xdmod-setup-sso.sh:/srv/xdmod/scripts/xdmod-setup-sso.sh:ro" ^
  ubccr/hpcts:xdmod-2025.02 bash -c "
    echo 'Starting minimal XDMoD setup...'
    
    # Wait for database
    until mysql -h mysql -u xdmodapp -pofbatgorWep0 -e 'SELECT 1' 2>/dev/null; do
      echo 'Waiting for database...'
      sleep 2
    done
    
    # Copy correct configuration
    cp /etc/xdmod/portal_settings.ini /etc/xdmod/portal_settings.ini.bak 2>/dev/null || true
    
    # Start essential services
    rm -f /var/run/sssd.pid
    /sbin/sssd --logger=stderr -d 2 -i 2>&1 &
    /usr/sbin/sshd -e
    gosu munge /usr/sbin/munged
    /usr/sbin/sshd
    
    # Start PHP-FPM
    mkdir -p /run/php-fpm
    php-fpm &
    
    # Start Apache
    rm -f /var/run/httpd/httpd.pid
    exec /usr/sbin/httpd -DFOREGROUND
  "

echo Step 3: Waiting for container to start...
timeout /t 30 /nobreak

echo Step 4: Copying correct configuration...
docker cp xdmod_portal_settings.ini xdmod:/etc/xdmod/portal_settings.ini

echo Step 5: Restarting Apache to pick up new config...
docker exec xdmod pkill httpd
docker exec -d xdmod /usr/sbin/httpd -DFOREGROUND

echo Step 6: Testing accessibility...
timeout /t 15 /nobreak
python test_ports.py

echo.
echo ========================================
echo XDMoD Minimal Fix Complete!
echo ========================================
echo XDMoD should now be accessible at:
echo https://localhost:4443
echo ========================================
