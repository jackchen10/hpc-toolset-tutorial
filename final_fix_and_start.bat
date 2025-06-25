@echo off
echo ========================================
echo Final Fix and Start HPC Toolset
echo ========================================

echo.
echo Step 1: Stopping all containers and removing volumes...
docker compose down -v

echo.
echo Step 2: Converting line endings in database scripts...
powershell -Command "& {$scripts = @('database\create-coldfront-db.sh', 'database\create-slurm-db.sh', 'database\create-xdmod-db.sh'); foreach ($script in $scripts) { if (Test-Path $script) { $content = Get-Content $script -Raw; $content = $content -replace \"`r`n\", \"`n\"; $content = $content -replace \"`r\", \"`n\"; [System.IO.File]::WriteAllText((Resolve-Path $script), $content, [System.Text.Encoding]::UTF8); Write-Host \"Fixed $script\" } }}"

echo.
echo Step 3: Starting MySQL first...
docker compose up -d mysql
echo Waiting 45 seconds for MySQL initialization...
timeout /t 45 /nobreak

echo.
echo Step 4: Checking MySQL logs...
docker logs mysql --tail=5

echo.
echo Step 5: Starting all other services...
docker compose up -d

echo.
echo Step 6: Waiting for services to fully start...
echo This may take 3-5 minutes for first-time initialization...
timeout /t 180 /nobreak

echo.
echo Step 7: Final status check...
docker compose ps

echo.
echo Step 8: Testing database connections...
docker exec mysql mysql -uroot -e "SHOW DATABASES;" 2>nul && echo Database OK || echo Database ERROR

echo.
echo ========================================
echo HPC Toolset should now be accessible:
echo ========================================
echo ColdFront:  https://localhost:2443
echo OnDemand:   https://localhost:3443
echo XDMoD:      https://localhost:4443
echo SSH:        ssh -p 6222 hpcadmin@localhost
echo ========================================
echo.
echo Login credentials:
echo Admin: admin/admin
echo LDAP users: password is 'ilovelinux'
echo ========================================

pause
