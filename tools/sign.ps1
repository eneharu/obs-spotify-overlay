param(
    [Parameter(Mandatory = $true)]
    [string]$Certificate,

    [string]$Password,

    [string]$File = (Join-Path (Split-Path -Parent $PSScriptRoot) "spotify-overlay.dll"),

    [string]$TimestampUrl = "http://timestamp.digicert.com"
)

$ErrorActionPreference = "Stop"

function Find-SignTool {
    $command = Get-Command signtool.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $kits = Join-Path ${env:ProgramFiles(x86)} "Windows Kits\10\bin"
    if (Test-Path $kits) {
        $candidate = Get-ChildItem $kits -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match '\\x64\\signtool\.exe$' } |
            Sort-Object FullName -Descending |
            Select-Object -First 1
        if ($candidate) {
            return $candidate.FullName
        }
    }

    throw "signtool.exe not found. Install the Windows SDK."
}

if (-not (Test-Path $File)) {
    throw "File not found: $File"
}

$tool = Find-SignTool
$signArgs = @("sign", "/fd", "sha256", "/tr", $TimestampUrl, "/td", "sha256")

if ($Certificate -match '\.pfx$') {
    $signArgs += @("/f", (Resolve-Path $Certificate).Path)
    if ($Password) {
        $signArgs += @("/p", $Password)
    }
} else {
    $signArgs += @("/sha1", $Certificate)
}

$signArgs += (Resolve-Path $File).Path

& $tool @signArgs
if ($LASTEXITCODE -ne 0) {
    throw "Signing failed."
}

Get-AuthenticodeSignature $File | Format-List Status, StatusMessage, SignerCertificate
