param(
    [switch]$Elevated
)

$ErrorActionPreference = "Stop"
$target = Join-Path $env:ProgramData "obs-studio\plugins\spotify-overlay"

if (Get-Process obs64 -ErrorAction SilentlyContinue) {
    Write-Host "OBS jest uruchomiony. Zamknij go i uruchom Install.bat ponownie." -ForegroundColor Yellow
    exit 1
}

function Install-Files {
    New-Item -ItemType Directory -Force (Join-Path $target "data\locale") | Out-Null
    Copy-Item (Join-Path $PSScriptRoot "spotify-overlay.dll") $target -Force
    Copy-Item (Join-Path $PSScriptRoot "data\*") (Join-Path $target "data") -Recurse -Force
}

try {
    Install-Files
} catch {
    if (-not $Elevated) {
        Write-Host "Poproszę o uprawnienia administratora..." -ForegroundColor Yellow
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Elevated"
        Start-Process "powershell.exe" -Verb RunAs -ArgumentList $arguments
        exit 0
    }
    throw
}

Write-Host ""
Write-Host "Gotowe. Wtyczka została zainstalowana." -ForegroundColor Green
Write-Host ""
Write-Host "Co dalej:"
Write-Host "1. Uruchom OBS Studio."
Write-Host "2. W panelu Źródła kliknij + i wybierz „Spotify – Teraz odtwarzane”."
Write-Host "3. Włącz utwór w Spotify."
Write-Host ""
