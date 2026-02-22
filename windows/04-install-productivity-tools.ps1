param (
	[switch]$CheckForUpdates
)

$commonModulePath = Join-Path $PSScriptRoot "./shared/ps-shared.ps1"
. $commonModulePath
# Ensure running as Admin in Powershell Core
Assert-Elevated -commandToRun $PSCommandPath -CheckForUpdates:$CheckForUpdates -RequirePSCore


Write-Host "Installing productivity tools..." -ForegroundColor Green

# Define all productivity tools to install
$productivityTools = @(
	# System utilities
	@{AppId = "Microsoft.Sysinternals.Suite"; DisplayName = "Sysinternals Suite"},

	# General utilities
	@{AppId = "7zip.7zip"; DisplayName = "7-Zip"},
	@{AppId = "Adobe.Acrobat.Reader.64-bit"; DisplayName = "Adobe Acrobat Reader"},
	@{AppId = "Brave.Brave"; DisplayName = "Brave Browser"},

	# Shell utilities
	@{AppId = "Microsoft.PowerToys"; DisplayName = "Microsoft PowerToys"},
	@{AppId = "SlackTechnologies.Slack"; DisplayName = "Slack"},
	@{AppId = "VideoLAN.VLC"; DisplayName = "VLC Media Player"},
	@{AppId = "Google.GoogleDrive"; DisplayName = "Google Drive"},
	@{AppId = "Mirantis.Lens"; DisplayName = "Lens Kubernetes IDE"}
)

# Install all productivity tools
foreach ($tool in $productivityTools) {
		Install-AppIfMissing -CheckForUpdates:$CheckForUpdates -AppId $tool.AppId -DisplayName $tool.DisplayName
}


Write-Host "Done installing productivity tools..." -ForegroundColor Green
Write-Host ""
