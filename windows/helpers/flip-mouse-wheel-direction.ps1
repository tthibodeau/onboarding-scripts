
$commonModulePath = Join-Path $PSScriptRoot "../shared/ps-shared.ps1"
. $commonModulePath
Assert-Elevated -commandToRun $PSCommandPath -CheckForUpdates:$CheckForUpdates -RequirePSCore

do {
    $mode = Read-Host "How do you like your mouse scroll (0-Windows or 1-Mac?)"
} while ($mode -notmatch "^[01]$")

Get-PnpDevice -Class Mouse -PresentOnly -Status OK | ForEach-Object {
    "$($_.Name): $($_.DeviceID)"
    Set-ItemProperty -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Enum\\$($_.DeviceID)\\Device Parameters" -Name FlipFlopWheel -Value $mode
    "+--- Value of FlipFlopWheel is set to " + (Get-ItemProperty -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Enum\\$($_.DeviceID)\\Device Parameters").FlipFlopWheel + ""
}

