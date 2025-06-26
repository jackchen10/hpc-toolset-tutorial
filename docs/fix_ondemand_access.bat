@echo off
REM 修复 Open OnDemand 访问问题

echo ========================================
echo  修复 Open OnDemand 访问问题
echo ========================================

echo.
echo 1. 重启 OnDemand 服务...
docker restart ondemand

echo.
echo 2. 等待服务启动...
timeout /t 45 /nobreak

echo.
echo 3. 检查服务状态...
docker-compose ps ondemand

echo.
echo 4. 检查端口连接...
powershell -Command "Test-NetConnection -ComputerName localhost -Port 3443"
powershell -Command "Test-NetConnection -ComputerName localhost -Port 5554"

echo.
echo 5. 显示最新日志...
docker logs ondemand --tail 15

echo.
echo ========================================
echo  修复完成！
echo ========================================
echo.
echo 请尝试以下步骤：
echo.
echo 1. 清除浏览器缓存和 Cookie
echo    - Chrome: Ctrl+Shift+Delete
echo    - 选择"所有时间"
echo    - 勾选"Cookie和其他网站数据"、"缓存的图片和文件"
echo.
echo 2. 重新访问：
echo    - 主页: https://localhost:3443
echo    - 认证: https://localhost:5554
echo.
echo 3. 如果仍有问题，尝试无痕模式
echo.

pause
