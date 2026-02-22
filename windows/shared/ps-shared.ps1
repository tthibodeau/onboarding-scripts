#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Cross-Platform Functions (PowerShell 5.1+ and PowerShell 7+ Compatible)
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# This script is compatible with both Windows PowerShell 5.1 and PowerShell Core 7+
# For PowerShell 5.1 compatibility, files must be saved with UTF-8 BOM encoding to properly
# display emoji characters and special formatting. PowerShell 7+ handles UTF-8 without BOM.
#
# If running in PowerShell 5.1 and experiencing display issues:
#  - Save this file as UTF-8 with BOM encoding
#  - Emoji characters may appear as question marks or boxes without proper encoding
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Add-ModuleImportToProfile {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)][string]$ModuleName
	)

	try {
		if (-not $PROFILE) {
			Write-Error "PowerShell profile path is not set."
			return
		}

		if (-not (Test-Path -Path $PROFILE)) {
			$profileDir = Split-Path -Path $PROFILE -Parent
			if (-not (Test-Path -Path $profileDir)) {
				New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
				Write-Verbose "Created profile directory: $profileDir"
			}
			New-Item -Path $PROFILE -ItemType File -Force | Out-Null
			Write-Host "Created PowerShell profile at $PROFILE" -ForegroundColor Green
		}

		$profileContent = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue
		$importStatement = "Import-Module -Name $ModuleName"

		if ($null -eq $profileContent -or -not $profileContent.Contains($importStatement)) {
			Write-Host "Adding module '$ModuleName' to PowerShell profile..." -ForegroundColor DarkGray
			Add-Content -Path $PROFILE -Value "`n# Auto-added by Install-ModuleIfMissing"
			Add-Content -Path $PROFILE -Value "$importStatement"
			Write-Host "Added '$importStatement' to PowerShell profile" -ForegroundColor Green
		}
		else {
			Write-Host "Module '$ModuleName' already exists in PowerShell profile." -ForegroundColor Cyan
		}
	}
	catch {
		Write-Host "Failed to update PowerShell profile: $($_.Exception.Message)" -ForegroundColor Red
	}
}

function Add-ProfileContent {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)][string]$Content
	)

	try {
		$profileContent = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue
		$contentFirstLine = $Content.TrimStart() -split [Environment]::NewLine | Select-Object -First 1

		if ($null -eq $profileContent -or -not $profileContent.Contains($contentFirstLine)) {
			Add-Content $PROFILE $Content
			Write-Verbose "Added to PowerShell profile: $($Content.Split([Environment]::NewLine)[0])..."
		}
		else {
			Write-Verbose "Content already exists in profile. Skipping."
		}
	}
	catch {
		Write-Error "Failed to add content to PowerShell profile: $_"
	}
}

function Assert-Elevated {
	<#
	.SYNOPSIS
	Ensures the script is running with administrator privileges in the appropriate PowerShell version.

	.DESCRIPTION
	Checks for admin privileges and relaunches elevated if needed.
	For Assert-PS5Elevated: runs in current PowerShell version (PS5 or PS7).
	For Assert-PSCoreElevated: ensures PowerShell Core is installed and runs in PS7 elevated.

	.PARAMETER commandToRun
	The full path to the script that should be run elevated.

	.PARAMETER CheckForUpdates
	Optional switch to pass through to the elevated script.

	.PARAMETER RequirePSCore
	If specified, ensures PowerShell Core is installed and switches to it if needed.
	#>
	[CmdletBinding()]
	param (
		[string]$commandToRun = $MyInvocation.PSCommandPath,
		[switch]$CheckForUpdates,
		[switch]$RequirePSCore
	)

	$isElevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
	$isPSCore = ($PSVersionTable.PSVersion.Major -ge 7) -or ($PSVersionTable.PSEdition -eq 'Core')

	# Always show PowerShell version
	Write-Host "PowerShell detected: $($PSVersionTable.PSVersion)" -ForegroundColor DarkGray

	# If already elevated and in correct PS version, we're done
	if ($isElevated -and (-not $RequirePSCore -or $isPSCore)) {
		Write-Host "🛡️ Running with administrator privileges." -ForegroundColor Green
		return
	}

	# Determine target executable
	$targetExecutable = $null
	if ($RequirePSCore) {

		# Ensure PowerShell Core is installed
		$pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
		if (-not $pwshCommand) {
			if (-not (Assert-PSCoreInstalled)) {
				Write-Host "PowerShell Core is required but could not be installed." -ForegroundColor Red
				Read-Host "Press Enter to exit"
				exit 1
			}
			$pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
		}

		# Use pwsh if not already in PS Core
		if (-not $isPSCore) {
			$targetExecutable = "pwsh"
		}
	}

	# If no target specified, use current executable
	if (-not $targetExecutable) {
		$targetExecutable = (Get-Process -Id $PID).Path
	}

	# Launch elevated session
	if (-not $isElevated -or $targetExecutable -ne (Get-Process -Id $PID).Path) {
		if (-not $isElevated) {
			Write-Host "🛡️ Administrator privileges required. Relaunching with elevation..." -ForegroundColor Yellow
		}

		$workingDirectory = Split-Path -Parent $commandToRun
		$fileArgs = @($commandToRun)
		if ($CheckForUpdates) { $fileArgs += "-CheckForUpdates" }

		# Determine if launching in Windows Terminal or directly
		$useWindowsTerminal = Get-Command wt.exe -ErrorAction SilentlyContinue
		$processName = if ($useWindowsTerminal) { "wt.exe" } else { $targetExecutable }
		$launchTarget = if ($useWindowsTerminal) { "Windows Terminal" } else { "PowerShell session" }

		# Build argument list
		$argumentList = @()
		if ($useWindowsTerminal) {
			$argumentList += @("new-tab", "$targetExecutable")
		}
		if ($targetExecutable -like "*pwsh*" -or $targetExecutable -eq "pwsh") {
			$argumentList += @("-WorkingDirectory", "`"$workingDirectory`"")
		}
		$argumentList += @("-NoProfile", "-NoExit", "-ExecutionPolicy", "Bypass", "-File") + $fileArgs

		# Launch the process
		try {
			if (-not $isElevated) {
				Start-Process $processName -ArgumentList $argumentList -Verb RunAs > $null
				Write-Host "🛡️ Launched elevated session in $launchTarget." -ForegroundColor Green
			} else {
				Start-Process $processName -ArgumentList $argumentList > $null
				Write-Host "Launched session in $launchTarget." -ForegroundColor Green
			}
			exit 0
		}
		catch {
			Write-Host "Failed to start ${launchTarget}: $($_.Exception.Message)" -ForegroundColor Red
			Read-Host "Press Enter to exit"
			exit 1
		}
	}
}

function Assert-PSCoreInstalled {
	# Check if PowerShell Core (pwsh) is installed
	$pwshCommand = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
	if ($pwshCommand) { return $true }

	Write-Host "PowerShell 5 detected. PowerShell Core not found. Installing PowerShell Core..." -ForegroundColor Yellow
	# Ensure NuGet provider is installed to avoid interactive prompt
	Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop > $null

	# Ensure winget is available
	$wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
	if (-not $wingetCmd) {
		Install-Script winget-install -Force > $null
		winget-install
	}

	# Install PowerShell Core using winget
	winget install --id "Microsoft.PowerShell" --accept-package-agreements --accept-source-agreements

	# Update the PATH environment variable for the current session
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

	# Check if PowerShell Core (pwsh) is installed
	$pwshCommand = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
	if (-not $pwshCommand) {
		Write-Host "PowerShell Core installation failed or not found. Please install PowerShell Core manually." -ForegroundColor Red
		return $false
	}

	return $true
}

function Get-LocalInstalledModule {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)][string]$Name
	)

	# Try to find installed modules using -ListAvailable first
	$modules = Get-Module -Name $Name -ListAvailable -ErrorAction SilentlyContinue
	if (-not $modules) {
		# Fallback to currently imported modules
		$modules = Get-Module -Name $Name -ErrorAction SilentlyContinue
	}

	if ($modules) {
		return $modules | Sort-Object Version -Descending | Select-Object -First 1
	}

	return $null
}

function Install-AppIfMissing {
	param (
		[Parameter(Mandatory = $true)][string]$AppId,
		[string]$DisplayName,
		[string]$Source = "winget",
		[switch]$CheckForUpdates
	)

	# Check for winget availability
	if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
		Write-Host "winget is not available. Skipping $DisplayName." -ForegroundColor Yellow
		return
	}

	Write-Host "📥 Starting install of $DisplayName..." -ForegroundColor Cyan

	$installedInfo = winget list --id $AppId --accept-source-agreements --disable-interactivity 2>$null
	$isInstalled = $installedInfo | Select-String -SimpleMatch "$AppId"

	if (-not $isInstalled) {
		Write-Host "📥 Installing $DisplayName..." -ForegroundColor Green
		$installArgs = "install --force --id $AppId -s $Source --accept-package-agreements --accept-source-agreements --disable-interactivity"
		Start-Process winget -ArgumentList $installArgs -NoNewWindow -Wait
		Update-SessionEnvironment
		Write-Host "✅ $DisplayName has been successfully installed." -ForegroundColor Green
		Write-Host ""
	}
	else {
		if ($CheckForUpdates.IsPresent) {
			Write-Host "🔍 $DisplayName is already installed. Checking for updates..." -ForegroundColor Cyan

			$currentVersion = $null
			$newVersion = $null

			# Use a regex pattern that matches the entire line and extracts current and available versions
			# Match: <some text> <AppId> <currentVersion> <newVersion>
			$versionPattern = [string]::Format('{0}\s+(\d+(\.\d+)+)\s+(\d+(\.\d+)+)', [regex]::Escape($AppId))
			$versionMatch = $installedInfo | Select-String -Pattern $versionPattern

			if ($versionMatch -and $versionMatch.Matches.Count -gt 0) {
				$currentVersion = $versionMatch.Matches[0].Groups[1].Value
				$newVersion = $versionMatch.Matches[0].Groups[3].Value
				Write-Host "Current version: $currentVersion" -ForegroundColor DarkGray
				Write-Host "Available version: $newVersion" -ForegroundColor DarkYellow
			}

			if ($newVersion -and $currentVersion -and ([version]$newVersion -gt [version]$currentVersion)) {
				Write-Host "⬆️ $DisplayName upgrade available: $currentVersion to $newVersion." -ForegroundColor Yellow
				Write-Host "    Preparing to upgrade..." -ForegroundColor Yellow
				Write-Host ""
				$upgradeArgs = "install --force --id $AppId --accept-package-agreements --accept-source-agreements --disable-interactivity"
				Start-Process winget -ArgumentList $upgradeArgs -NoNewWindow -Wait
				Update-SessionEnvironment
				Write-Host "✅ $DisplayName has been successfully updated to $newVersion." -ForegroundColor Green
				Write-Host ""
			}
			else {
				Write-Host "✅ $DisplayName is up to date." -ForegroundColor Green
				Write-Host ""
			}
		}
		else {
			Write-Host "🔍 $DisplayName is already installed. Update checking is disabled." -ForegroundColor Cyan
			Write-Host ""
		}
	}
}

function Install-ModuleIfMissing {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)][string]$ModuleName,
		[Parameter()][string]$DisplayName,
		[Parameter()][switch]$Force,
		[Parameter()][switch]$AllowPrerelease,
		[Parameter()][ValidateSet("CurrentUser", "AllUsers")][string]$Scope = "CurrentUser",
		[Parameter()][string]$Repository = "PSGallery",
		[Parameter()][switch]$AddImportToProfile,
		[Parameter()][switch]$CheckForUpdates
	)

	if (-not $DisplayName) { $DisplayName = $ModuleName }

	$psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
	if ($psGallery -and $psGallery.InstallationPolicy -ne 'Trusted') {
		Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
	}

	# Use new helper function to check for installed module
	$installedModule = Get-LocalInstalledModule -Name $ModuleName


	if (-not $installedModule -or $Force.IsPresent) {
		Write-Host "📥 Installing $DisplayName..." -ForegroundColor Green
		$installParams = @{
			Name        = $ModuleName
			Force       = $true
			AllowClobber = $true
			ErrorAction = "Stop"
			Scope       = $Scope
		}
		if ($Repository) {
			$installParams["Repository"] = $Repository
		}
		if ($AllowPrerelease.IsPresent) {
			$installParams["AllowPrerelease"] = $true
		}

		try {
			Install-Module @installParams
			Import-Module $ModuleName -Force -ErrorAction SilentlyContinue
			if ($AddImportToProfile) {
				Add-ModuleImportToProfile -ModuleName $ModuleName
			}

			$newModule = Get-Module -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1
			Write-Host "✅ $DisplayName version $($newModule.Version) installed successfully." -ForegroundColor Green
			Update-SessionEnvironment
			Write-Host ""
		}
		catch {
			Write-Host "❌ Failed to install $DisplayName. Error: $($_.Exception.Message)" -ForegroundColor Red
			Write-Host ""
		}
	}
	elseif ($CheckForUpdates.IsPresent) {
		$highestInstalledVersion = $installedModule.Version
		Write-Host "🔍 $DisplayName is already installed (version $highestInstalledVersion)." -ForegroundColor Cyan

		try {
			$onlineModule = Find-Module -Name $ModuleName -Repository $Repository -ErrorAction SilentlyContinue
			if ($onlineModule -and ($onlineModule.Version -gt $highestInstalledVersion)) {
				Write-Host "⬆️ Updating $DisplayName from $highestInstalledVersion to $($onlineModule.Version)..." -ForegroundColor Yellow
				Update-Module -Name $ModuleName -Force
				Import-Module $ModuleName -Force -ErrorAction SilentlyContinue
				Write-Host "✅ $DisplayName updated to version $($onlineModule.Version)." -ForegroundColor Green
			}
			else {
				Write-Host "✅ $DisplayName is up to date." -ForegroundColor Green
			}
		}
		catch {
			Write-Host "❓ Unable to check for updates: $($_.Exception.Message)" -ForegroundColor Yellow
		}

		if ($AddImportToProfile) {
			Add-ModuleImportToProfile -ModuleName $ModuleName
		}
		Write-Host ""
	}
	else {
		$version = $installedModule.Version
		Write-Host "✅ $DisplayName is already installed (version $version)." -ForegroundColor Cyan
		if ($AddImportToProfile) {
			Add-ModuleImportToProfile -ModuleName $ModuleName
		}
		Write-Host ""
	}
}

function Update-SessionEnvironment {
	try {
		$machineVars = [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Machine)
		$userVars = [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::User)

		foreach ($level in @{Machine = $machineVars; User = $userVars }.GetEnumerator()) {
			foreach ($var in $level.Value.GetEnumerator()) {
				if ($var.Key -ne 'Path') {
					[System.Environment]::SetEnvironmentVariable($var.Key, $var.Value, [System.EnvironmentVariableTarget]::Process)
				}
			}
		}

		$machinePath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
		if (-not $machinePath) { $machinePath = "" }
		$userPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
		if (-not $userPath) { $userPath = "" }
		[System.Environment]::SetEnvironmentVariable("Path", "$machinePath;$userPath", [System.EnvironmentVariableTarget]::Process)
	}
	catch {
		Write-Warning "Error refreshing environment variables: $_"
	}
}
