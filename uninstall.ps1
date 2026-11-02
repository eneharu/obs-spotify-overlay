param(
    [switch]$Elevated
)

$ErrorActionPreference = "Stop"
$target = Join-Path $env:ProgramData "obs-studio\plugins\spotify-overlay"

if (Get-Process obs64 -ErrorAction SilentlyContinue) {
    Write-Host "OBS jest uruchomiony. Zamknij go i uruchom Uninstall.bat ponownie." -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $target)) {
    Write-Host "Wtyczka nie jest zainstalowana." -ForegroundColor Yellow
    exit 0
}

try {
    Remove-Item $target -Recurse -Force
} catch {
    if (-not $Elevated) {
        Write-Host "Poproszę o uprawnienia administratora..." -ForegroundColor Yellow
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Elevated"
        Start-Process "powershell.exe" -Verb RunAs -ArgumentList $arguments
        exit 0
    }
    throw
}

Write-Host "Wtyczka została usunięta." -ForegroundColor Green
