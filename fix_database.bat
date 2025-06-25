@echo off
echo ========================================
echo Fixing HPC Toolset Database Issues
echo ========================================

echo.
echo Step 1: Stopping all containers...
docker compose down -v

echo.
echo Step 2: Removing old volumes to ensure clean start...
docker volume prune -f

echo.
echo Step 3: Starting MySQL first and waiting for initialization...
docker compose up -d mysql
echo Waiting 30 seconds for MySQL to fully initialize...
timeout /t 30 /nobreak

echo.
echo Step 4: Checking MySQL status...
docker logs mysql --tail=10

echo.
echo Step 5: Starting remaining services...
docker compose up -d

echo.
echo Step 6: Waiting for all services to start...
echo This may take 2-3 minutes...
timeout /t 120 /nobreak

echo.
echo Step 7: Checking final status...
docker compose ps

echo.
echo ========================================
echo Services should now be accessible at:
echo ColdFront:  https://localhost:2443
echo OnDemand:   https://localhost:3443
echo XDMoD:      https://localhost:4443
echo ========================================
