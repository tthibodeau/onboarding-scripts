#!/usr/bin/env pwsh
# Install-WSL-Distro.ps1 ─ menu-driven WSL installer (PowerShell Core 7+)

$ErrorActionPreference = 'Stop'

# 1. Capture WSL output as UTF-16LE ------------------------------------------
$oldEncoding = [Console]::OutputEncoding
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::Unicode   # UTF-16LE
    $raw = & wsl.exe --list --online 2>&1
    if ($LASTEXITCODE) { Write-Error "wsl.exe failed:`n$raw"; exit 1 }
}
finally { [Console]::OutputEncoding = $oldEncoding }

# 2. Parse rows: start AFTER the header --------------------------------------
$afterHeader = $false
$index       = 1
$distros     = @()

$raw -split "`r?`n" | ForEach-Object {
    if (-not $afterHeader) {
        if ($_ -match '(?i)\bNAME\b.*\bFRIENDLY\b') { $afterHeader = $true }
        return
    }

    $trim = $_.Trim()
    if (-not $trim) { return }

    if ($trim -match '^(\S+)\s+(.+)$') {
        $distros += [pscustomobject]@{
            Index    = $index++
            Name     = $Matches[1]
            Friendly = $Matches[2].Trim()
        }
    }
}

if (-not $distros) {
    Write-Error 'No distributions were parsed from the command output.'; exit 1
}

# 3. Keep only Ubuntu / Debian / Arch / Kali ---------------------------------
$distros = $distros | Sort-Object -Property Name | Where-Object {
    $_.Name -match '^(?i)(ubuntu|debian|arch|kali)'
}
if (-not $distros) {
    Write-Error 'None of the desired distributions were found.'; exit 1
}
$idx = 1; $distros | ForEach-Object { $_.Index = $idx++ }

# 4. Show menu ---------------------------------------------------------------
Write-Host ''
Write-Host 'Available WSL distributions:' -ForegroundColor Cyan
$distros | ForEach-Object {
    Write-Host ('{0,2}. {1,-30} {2}' -f $_.Index, $_.Name, $_.Friendly)
}

# 5. Prompt ------------------------------------------------------------------
Write-Host ''
$choice = Read-Host 'Enter the number to install (or press Enter to quit)'
if ([string]::IsNullOrWhiteSpace($choice)) { Write-Host 'Cancelled.'; exit }

if ($choice -notmatch '^\d+$' -or
    $choice -lt 1 -or
    $choice -gt $distros.Count) {
    Write-Error 'Invalid selection.'; exit 1
}

$sel = $distros[[int]$choice - 1]

# 6. Confirm & install -------------------------------------------------------
Write-Host ''
Write-Host ("You selected: {0} ({1})" -f $sel.Name, $sel.Friendly) -ForegroundColor Green
$response = Read-Host 'Install this distro now? (Y/n)'
if ([string]::IsNullOrEmpty($response) -or $response.ToLower() -match "[yY]") {
    Write-Host "Running: wsl --install $($sel.Name)"
    Start-Process wsl.exe -ArgumentList '--install', $sel.Name -Verb RunAs
} else {
    Write-Host 'Installation cancelled.'
}
