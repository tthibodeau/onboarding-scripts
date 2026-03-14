param (
	[switch]$CheckForUpdates
)


Clear-Host

# Load common functions
$commonModulePath = Join-Path $PSScriptRoot "./shared/ps-shared.ps1"
. $commonModulePath
# Automate "RunAsAdmin" in whichever shell was used (PS5 or PS7).
# Don't force the execution of this prerequisite script in Powershell Core as it's responsible for
# installing and updating PowerShell Core itself.
Assert-Elevated -commandToRun $PSCommandPath -CheckForUpdates:$CheckForUpdates

# Ensure NuGet provider is installed to avoid interactive prompt (PS5 only)
# PowerShell 7 has built-in package management and doesn't require the NuGet provider
$isPSCore = ($PSVersionTable.PSVersion.Major -ge 7) -or ($PSVersionTable.PSEdition -eq 'Core')
if (-not $isPSCore) {
	Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop > $null
}

# Install winget
# # https://learn.microsoft.com/en-us/windows/package-manager/winget/
# Nice winget install script: https://github.com/asheroto/winget-install/
Write-Host "Installing winget updater..."
Install-Script winget-install -Force > $null
winget-install -CheckForUpdate

# Accept source agreements upfront to prevent any prompts during installations
Write-Host "Accepting winget source agreements..." -ForegroundColor Cyan
winget list --accept-source-agreements --disable-interactivity > $null 2>&1

# Install Powershell Core 7+ and Windows Terminal
$prerequisites = @(
	@{AppId = "Microsoft.PowerShell"; DisplayName = "PowerShell 7" },
	@{AppId = "Microsoft.WindowsTerminal"; DisplayName = "Windows Terminal" },
	@{AppId = "OpenVPNTechnologies.OpenVPNConnect"; DisplayName = "OpenVPN Connect" },
	@{AppId = "AgileBits.1Password"; DisplayName = "1Password" },
	@{AppId = "AgileBits.1Password.CLI"; DisplayName = "1Password CLI" }
)

Write-Host "Installing prerequisites..." -ForegroundColor Green

foreach ($tool in $prerequisites) {
	Install-AppIfMissing -CheckForUpdates -AppId $tool.AppId -DisplayName $tool.DisplayName
}



# Enable required virtualization Windows features

# Windows features to enable
$windowsFeatures = @(
	@{FeatureName = "Microsoft-Hyper-V-All"; Description = "Windows Hypervisor virtualization features" },
	@{FeatureName = "HypervisorPlatform"; Description = "Hypervisor Platform" },
	@{FeatureName = "VirtualMachinePlatform"; Description = "Virtual Machine Platform" },
	@{FeatureName = "Containers-DisposableClientVM"; Description = "Windows Sandbox" },
	@{FeatureName = "Microsoft-Windows-Subsystem-Linux"; Description = "Windows Subsystem for Linux" }
)


function Enable-WindowsFeature {
	param (
		[string]$FeatureName,
		[string]$Description
	)

	Write-Host "Enabling $Description..." -ForegroundColor Green
	$result = Enable-WindowsOptionalFeature -Online -FeatureName $FeatureName -All -NoRestart -WarningAction SilentlyContinue
	return $result
}

# Track if any feature installation requires a reboot
# Track if any feature installation requires a reboot
$rebootNeeded = $false
# Enable all required Windows features
foreach ($feature in $windowsFeatures) {
	$result = Enable-WindowsFeature -FeatureName $feature.FeatureName -Description $feature.Description
	if ($result.RestartNeeded -eq $true) {
		$rebootNeeded = $true
	}
}


Write-Host ""

# Only prompt for reboot if at least one feature required it
if ($rebootNeeded) {
	$message = @'
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃     A reboot is required before running other scripts...     ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

Would you like to restart now? (y/[N]):
'@
	Write-Host $message -NoNewline -ForegroundColor Yellow
	$userInput = Read-Host
	if ($userInput -eq 'Y') {
		Restart-Computer -Force
	}
}
else {
	$message = @'
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃   All features enabled successfully. No reboot required.   ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
'@
	Write-Host $message -ForegroundColor Green
}
