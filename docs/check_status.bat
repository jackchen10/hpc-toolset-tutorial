@echo off
echo Checking Docker status...
docker --version
echo.
echo Checking running containers...
docker ps
echo.
echo Checking all containers...
docker ps -a
echo.
echo Checking Docker Compose services...
docker compose ps
