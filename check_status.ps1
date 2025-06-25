Write-Host "Checking Docker status..." -ForegroundColor Green
docker --version

Write-Host "`nChecking running containers..." -ForegroundColor Green
docker ps

Write-Host "`nChecking all containers..." -ForegroundColor Green
docker ps -a

Write-Host "`nChecking Docker Compose services..." -ForegroundColor Green
docker compose ps

Write-Host "`nChecking if ports are accessible..." -ForegroundColor Green
$ports = @(2443, 3443, 4443, 6222)
foreach ($port in $ports) {
    try {
        $connection = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue
        if ($connection.TcpTestSucceeded) {
            Write-Host "Port $port is accessible" -ForegroundColor Green
        } else {
            Write-Host "Port $port is not accessible" -ForegroundColor Red
        }
    } catch {
        Write-Host "Port $port is not accessible" -ForegroundColor Red
    }
}
