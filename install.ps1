param(
    [switch]$Elevated
)

$ErrorActionPreference = "Stop"
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
}
$target = Join-Path $env:ProgramData "obs-studio\plugins\spotify-overlay"

function Get-SmartAppControlState {
    $key = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
    try {
        $value = (Get-ItemProperty -Path $key -Name "VerifiedAndReputablePolicyState" -ErrorAction Stop).VerifiedAndReputablePolicyState
    } catch {
        return "Unavailable"
    }

    switch ([int]$value) {
        0 { return "Off" }
        1 { return "On" }
        2 { return "Evaluation" }
        default { return "Unknown" }
    }
}

function Show-SacWarning {
    Write-Host ""
    Write-Host "UWAGA: Inteligentna Kontrola aplikacji (Smart App Control) jest WŁĄCZONA." -ForegroundColor Red
    Write-Host "Windows blokuje niepodpisane wtyczki, więc OBS nie wczyta tej wtyczki." -ForegroundColor Red
    Write-Host ""
    Write-Host "Co możesz zrobić (wybierz jedną opcję):" -ForegroundColor Yellow
    Write-Host "1. Wyłącz Inteligentną Kontrolę aplikacji:"
    Write-Host "   Ustawienia > Prywatność i zabezpieczenia > Zabezpieczenia Windows >"
    Write-Host "   Kontrola aplikacji i przeglądarki > Inteligentna Kontrola aplikacji > Wyłącz."
    Write-Host "   Na Windows 11 24H2 lub nowszym można ją później włączyć ponownie."
    Write-Host "2. Użyj wersji podpisanej certyfikatem zaufanego dostawcy, jeśli taka się pojawi."
    Write-Host ""
    Write-Host "Odblokowanie pliku (Właściwości > Odblokuj) ani wyłączenie SmartScreen nie wystarczy." -ForegroundColor Yellow
    Write-Host ""
}

$sac = Get-SmartAppControlState

if (Get-Process obs64 -ErrorAction SilentlyContinue) {
    Write-Host "OBS jest uruchomiony. Zamknij go i uruchom Install.bat ponownie." -ForegroundColor Yellow
    exit 1
}

if ($sac -eq "On") {
    Show-SacWarning
}

function Install-Files {
    New-Item -ItemType Directory -Force (Join-Path $target "data\locale") | Out-Null
    Copy-Item (Join-Path $PSScriptRoot "spotify-overlay.dll") $target -Force
    Copy-Item (Join-Path $PSScriptRoot "data\*") (Join-Path $target "data") -Recurse -Force
    Get-ChildItem $target -Recurse -File | Unblock-File -ErrorAction SilentlyContinue
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

$dll = Join-Path $target "spotify-overlay.dll"
$signature = Get-AuthenticodeSignature $dll
if ($signature.Status -eq "Valid") {
    Write-Host "Podpis cyfrowy: $($signature.SignerCertificate.Subject)" -ForegroundColor Green
} else {
    Write-Host "Podpis cyfrowy: brak (wtyczka niepodpisana)." -ForegroundColor DarkGray
}
Write-Host ""

Write-Host "Co dalej:"
Write-Host "1. Uruchom OBS Studio."
Write-Host "2. W panelu Źródła kliknij + i wybierz ""Spotify - Teraz odtwarzane""."
Write-Host "3. Włącz utwór w Spotify."
Write-Host ""

if ($sac -eq "On") {
    Show-SacWarning
} elseif ($sac -eq "Evaluation") {
    Write-Host "Inteligentna Kontrola aplikacji jest w trybie oceny – wtyczka powinna działać." -ForegroundColor DarkGray
    Write-Host ""
}

if ($Elevated) {
    Read-Host "Naciśnij Enter, aby zamknąć" | Out-Null
}
