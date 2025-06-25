#!/bin/bash

# Fix XDMoD database configuration
docker exec xdmod bash -c "
sed -i 's/host = \"localhost\"/host = \"mysql\"/g' /etc/xdmod/portal_settings.ini
sed -i 's/user = \"xdmod\"/user = \"xdmodapp\"/g' /etc/xdmod/portal_settings.ini
sed -i 's/pass = \"\"/pass = \"ofbatgorWep0\"/g' /etc/xdmod/portal_settings.ini
"

echo "XDMoD configuration updated"

# Restart XDMoD container
echo "Restarting XDMoD container..."
docker compose restart xdmod

echo "Waiting for XDMoD to start..."
sleep 30

echo "Checking XDMoD status..."
docker logs xdmod --tail=10
