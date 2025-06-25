@echo off
echo ========================================
echo Starting HPC Toolset Tutorial
echo ========================================

echo.
echo Step 1: Pulling latest images...
docker compose pull

echo.
echo Step 2: Starting services...
docker compose up -d

echo.
echo Step 3: Waiting for services to start...
timeout /t 30 /nobreak

echo.
echo Step 4: Checking service status...
docker compose ps

echo.
echo ========================================
echo HPC Toolset Tutorial URLs:
echo ========================================
echo ColdFront:  https://localhost:2443
echo OnDemand:   https://localhost:3443
echo XDMoD:      https://localhost:4443
echo SSH Login:  ssh -p 6222 hpcadmin@localhost
echo ========================================
echo.
echo Default login credentials:
echo Username: admin
echo Password: admin
echo ========================================

pause
