param (
	[switch]$CheckForUpdates
)

$commonModulePath = Join-Path $PSScriptRoot "./shared/ps-shared.ps1"
. $commonModulePath
# Ensure running as Admin in Powershell Core
Assert-Elevated -commandToRun $PSCommandPath -CheckForUpdates:$CheckForUpdates -RequirePSCore


# Manually download Windows Subsystem for Linux distro packages
# https://docs.microsoft.com/en-us/windows/wsl/install-win10#manual-installation-steps


function downloadFileFromUrl {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[string]$PackageFilePath,
		[Parameter(Mandatory)]
		[string]$PackageUrl
	)


	if (!(Test-Path $PackageFilePath -PathType Leaf)) {
		# Download the package from the specified URL to specified file path
		Invoke-WebRequest -Uri $PackageUrl -OutFile $PackageFilePath -UseBasicParsing
	}

	return $PackageFilePath
}


# WSL.exe tab completion
# https://github.com/NotTheDr01ds/WSLTabCompletion
Install-ModuleIfMissing -CheckForUpdates:$CheckForUpdates -ModuleName "WSLTabCompletion" -DisplayName "WSL Tab Completion Module" -AddImportToProfile -Force

# Download the Linux kernel update package
# Download the latest package:
# WSL2 Linux kernel update package for x64 machines
Write-Host ""

# Proper "Downloads" folder path retrieval:  https://stackoverflow.com/questions/57947150/where-is-the-downloads-folder-located
$downloadsFolder = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
$wsl_update_x64_package_file_path = "$downloadsFolder\wsl_update_x64.msi"
$path = downloadFileFromUrl -PackageFilePath $wsl_update_x64_package_file_path -PackageUrl https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi
Write-Host "Installing WSL2 Linux kernel update package for x64 machines..." -ForegroundColor Green
# Invoke WSL2 Linux kernel update package
& "$path" /quiet > $null

Write-Host "WSL2 Linux kernel update package for x64 machines installed." -ForegroundColor Green

# Update WSL to latest version first
Write-Host "Updating WSL2..." -ForegroundColor Cyan
wsl --update 2>&1 | Out-Null

# Set your distribution version to WSL 2
# https://docs.microsoft.com/en-us/windows/wsl/install-win10#set-your-distribution-version-to-wsl-1-or-wsl-2
Write-Host "Setting your distribution version to WSL 2..." -ForegroundColor Cyan
wsl --set-default-version 2 2>&1 | Out-Null
Write-Host "Enabling prerequisites Windows features for WSL2..." -ForegroundColor Green
wsl --install --no-distribution 2>&1 | Out-Null

Write-Host ""

Write-Host "Would you like to install a Linux distribution now? [Y/n] " -ForegroundColor Cyan -NoNewline
$response = Read-Host
if ([string]::IsNullOrEmpty($response) -or $response.ToLower() -match "[yY]") {
	& "$PSScriptRoot\helpers\install-wsl-distro.ps1"
	Write-Host "Run the onboarding-scripts for linux-macos in your WSL distro (00-install-prerequisites.sh, etc.)" -ForegroundColor Yellow
} else {
	Write-Host "Skipping WSL distribution installation." -ForegroundColor Yellow
}

Write-Host "WSL setup complete." -ForegroundColor Green
