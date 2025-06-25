# Fix line endings for database scripts
Write-Host "Fixing line endings for database scripts..." -ForegroundColor Green

$scripts = @(
    "database\create-coldfront-db.sh",
    "database\create-slurm-db.sh", 
    "database\create-xdmod-db.sh"
)

foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Host "Processing $script..." -ForegroundColor Yellow
        $content = Get-Content $script -Raw
        $content = $content -replace "`r`n", "`n"
        $content = $content -replace "`r", "`n"
        [System.IO.File]::WriteAllText((Resolve-Path $script), $content, [System.Text.Encoding]::UTF8)
        Write-Host "Fixed $script" -ForegroundColor Green
    } else {
        Write-Host "Script $script not found" -ForegroundColor Red
    }
}

Write-Host "Line ending fixes complete!" -ForegroundColor Green
