param(
    [string]$Version = "",
    [string]$InstallDir = "$HOME\AppData\Local\Programs\phantasm\bin",
    [string]$Repo = $(if ($env:PHANTASM_INSTALL_REPO) { $env:PHANTASM_INSTALL_REPO } else { "indefiniteloop/phantasm-dist" })
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    @"
Install Phantasm from GitHub Releases.

Usage:
  ./install.ps1 [-Version 0.1.0] [-InstallDir <dir>] [-Repo <owner/repo>]
"@
}

if ($args -contains "-h" -or $args -contains "--help") {
    Show-Usage
    exit 0
}

$arch = switch ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture) {
    "X64" { "x86_64" }
    "Arm64" { "aarch64" }
    default { throw "Unsupported architecture: $($_)" }
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    $latest = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
    if (-not $latest.tag_name) {
        throw "Could not resolve the latest release for $Repo."
    }
    $Version = $latest.tag_name
}

$Version = $Version.TrimStart("v")
$tag = "v$Version"
$archiveBaseName = "phantasm-$Version-windows-$arch"
$archiveName = "$archiveBaseName.zip"
$checksumName = "phantasm-$Version-SHA256SUMS.txt"
$baseUrl = "https://github.com/$Repo/releases/download/$tag"

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("phantasm-install-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    $archivePath = Join-Path $tempDir $archiveName
    $checksumPath = Join-Path $tempDir $checksumName
    $extractDir = Join-Path $tempDir "extract"

    Write-Host "Downloading $archiveName from $Repo..."
    Invoke-WebRequest -Uri "$baseUrl/$archiveName" -OutFile $archivePath
    Invoke-WebRequest -Uri "$baseUrl/$checksumName" -OutFile $checksumPath

    $checksumLine = Select-String -Path $checksumPath -Pattern "^[0-9a-fA-F]{64}\s+$archiveName$" | Select-Object -First 1
    if (-not $checksumLine) {
        throw "Checksum entry for $archiveName was not found in $checksumName."
    }

    $expectedChecksum = ($checksumLine.Line -split "\s+")[0].ToLowerInvariant()
    $actualChecksum = (Get-FileHash -Algorithm SHA256 -Path $archivePath).Hash.ToLowerInvariant()
    if ($expectedChecksum -ne $actualChecksum) {
        throw "Checksum verification failed for $archiveName."
    }

    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Expand-Archive -Path $archivePath -DestinationPath $extractDir -Force
    Copy-Item (Join-Path $extractDir "phantasm.exe") (Join-Path $InstallDir "phantasm.exe") -Force
    $phmExtractPath = Join-Path $extractDir "phm.exe"
    if (Test-Path $phmExtractPath) {
        Copy-Item $phmExtractPath (Join-Path $InstallDir "phm.exe") -Force
    }
    else {
        Copy-Item (Join-Path $InstallDir "phantasm.exe") (Join-Path $InstallDir "phm.exe") -Force
    }

    Write-Host "Installed phantasm to $(Join-Path $InstallDir 'phantasm.exe')"
    Write-Host "Installed phm alias to $(Join-Path $InstallDir 'phm.exe')"
    & (Join-Path $InstallDir "phantasm.exe") --version

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if (-not ($userPath -split ";" | Where-Object { $_ -eq $InstallDir })) {
        Write-Host ""
        Write-Host "Add this directory to your user PATH if needed:"
        Write-Host "  $InstallDir"
    }

    Write-Host ""
    Write-Host "Next step:"
    Write-Host "  cd C:\path\to\your\project"
    Write-Host "  phm bootstrap"
}
finally {
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
}
