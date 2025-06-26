@echo off
REM Deploy new Interactive Apps to Open OnDemand
REM This script rebuilds the OnDemand container with new apps

echo ========================================
echo  部署新的 Interactive Apps
echo ========================================

echo.
echo 正在停止当前服务...
docker-compose down

echo.
echo 正在重新构建 OnDemand 容器...
docker-compose build ondemand

echo.
echo 正在启动服务...
docker-compose up -d

echo.
echo 等待服务启动...
timeout /t 30 /nobreak

echo.
echo 检查服务状态...
docker-compose ps

echo.
echo ========================================
echo  部署完成！
echo ========================================
echo.
echo 请访问: https://localhost:3443
echo 新的 Interactive Apps 应该已经可用
echo.
echo 如果应用没有显示，请检查：
echo 1. manifest.yml 文件格式
echo 2. form.yml 配置
echo 3. 容器日志: docker logs ondemand
echo.

pause
