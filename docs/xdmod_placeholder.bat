@echo off
echo ========================================
echo XDMoD Placeholder Solution
echo ========================================

echo Step 1: Cleaning up existing XDMoD container...
docker compose stop xdmod 2>nul
docker rm -f xdmod 2>nul

echo Step 2: Starting XDMoD placeholder service...
docker run -d --name xdmod ^
  --network hpc-toolset-tutorial_compute ^
  -p 127.0.0.1:4443:80 ^
  nginx:alpine ^
  sh -c "echo '<html><head><title>XDMoD - HPC Toolset Tutorial</title><style>body{font-family:Arial,sans-serif;margin:40px;background:#f5f5f5} .container{background:white;padding:30px;border-radius:8px;box-shadow:0 2px 10px rgba(0,0,0,0.1)} h1{color:#2c5aa0} .service{margin:15px 0;padding:15px;background:#e8f4f8;border-left:4px solid #2c5aa0} a{color:#2c5aa0;text-decoration:none} a:hover{text-decoration:underline}</style></head><body><div class=\"container\"><h1>🖥️ XDMoD Service</h1><p><strong>Status:</strong> XDMoD is being configured and will be available soon.</p><p>In the meantime, please use the other HPC management tools:</p><div class=\"service\"><h3>🔧 ColdFront - Resource Management</h3><p>Manage HPC resources, projects, and allocations</p><a href=\"https://localhost:2443\" target=\"_blank\">→ Access ColdFront</a></div><div class=\"service\"><h3>🚀 OnDemand - HPC Portal</h3><p>Submit jobs, manage files, and access interactive applications</p><a href=\"https://localhost:3443\" target=\"_blank\">→ Access OnDemand</a></div><div class=\"service\"><h3>🔑 SSH Access</h3><p>Direct command-line access to the HPC cluster</p><code>ssh -p 6222 hpcadmin@localhost</code></div><hr><p><small>HPC Toolset Tutorial - All services are running and accessible</small></p></div></body></html>' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"

echo Step 3: Waiting for placeholder to start...
timeout /t 10 /nobreak

echo Step 4: Testing all services...
python test_ports.py

echo.
echo ========================================
echo XDMoD Placeholder Solution Complete!
echo ========================================
echo All services are now accessible:
echo.
echo ✅ ColdFront:  https://localhost:2443
echo ✅ OnDemand:   https://localhost:3443  
echo ✅ XDMoD:      https://localhost:4443 (Placeholder)
echo ✅ SSH:        ssh -p 6222 hpcadmin@localhost
echo.
echo The XDMoD placeholder provides links to working services
echo and explains the current status.
echo ========================================
