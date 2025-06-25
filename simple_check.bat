@echo off
echo Checking HPC Toolset Status...
echo.

echo Docker containers:
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo.
echo Testing port connectivity:
powershell -Command "Test-NetConnection -ComputerName localhost -Port 2443 -InformationLevel Quiet" && echo ColdFront (2443): OK || echo ColdFront (2443): FAILED
powershell -Command "Test-NetConnection -ComputerName localhost -Port 3443 -InformationLevel Quiet" && echo OnDemand (3443): OK || echo OnDemand (3443): FAILED  
powershell -Command "Test-NetConnection -ComputerName localhost -Port 4443 -InformationLevel Quiet" && echo XDMoD (4443): OK || echo XDMoD (4443): FAILED
powershell -Command "Test-NetConnection -ComputerName localhost -Port 6222 -InformationLevel Quiet" && echo SSH (6222): OK || echo SSH (6222): FAILED

echo.
echo Service URLs:
echo ColdFront:  https://localhost:2443
echo OnDemand:   https://localhost:3443
echo XDMoD:      https://localhost:4443
echo SSH:        ssh -p 6222 hpcadmin@localhost
