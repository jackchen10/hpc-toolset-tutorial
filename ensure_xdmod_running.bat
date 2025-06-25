@echo off
echo ========================================
echo Ensuring XDMoD is Running
echo ========================================

echo Step 1: Checking XDMoD container status...
docker compose ps xdmod

echo Step 2: Starting XDMoD if not running...
docker compose up -d xdmod

echo Step 3: Waiting for container to be ready...
timeout /t 20 /nobreak

echo Step 4: Ensuring Apache is running...
docker exec xdmod bash -c "if ! pgrep httpd > /dev/null; then /usr/sbin/httpd -D FOREGROUND & fi"

echo Step 5: Testing port accessibility...
python test_ports.py

echo.
echo ========================================
echo XDMoD Status Check Complete!
echo ========================================
echo If XDMoD is accessible, you can visit:
echo https://localhost:4443
echo Login: admin/admin
echo ========================================
