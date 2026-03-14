param (
	[switch]$All,
	[switch]$CheckForUpdates
)

$ScriptDir = $PSScriptRoot

function Show-Menu {
	Write-Host ""
	Write-Host "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓" -ForegroundColor Cyan
	Write-Host "┃           Workstation Setup (Windows)            ┃" -ForegroundColor Cyan
	Write-Host "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛" -ForegroundColor Cyan
	Write-Host ""
	Write-Host "  [1] Prerequisites (PowerShell 7, winget, 1Password)"
	Write-Host "  [2] PowerShell Tools (modules, profile)"
	Write-Host "  [3] Windows Subsystem for Linux"
	Write-Host "  [4] Development Tools (Git, VS Code, Docker)"
	Write-Host "  [5] Productivity Tools"
	Write-Host "  [6] Azure Tools"
	Write-Host ""
	Write-Host "  [A] Install All"
	Write-Host "  [Q] Quit"
	Write-Host ""
}

function Invoke-SetupScript {
	param (
		[string]$Script,
		[string]$Name
	)

	Write-Host ""
	Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
	Write-Host "  Running: $Name" -ForegroundColor Green
	Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
	Write-Host ""

	$scriptPath = Join-Path $ScriptDir $Script
	$args = @()
	if ($CheckForUpdates) { $args += "-CheckForUpdates" }

	& $scriptPath @args
}

function Invoke-Selected {
	param (
		[string[]]$Selections
	)

	foreach ($choice in $Selections) {
		switch ($choice.Trim()) {
			"1" { Invoke-SetupScript -Script "00-install-prerequisites.ps1" -Name "Prerequisites" }
			"2" { Invoke-SetupScript -Script "01-install-powershell-tools.ps1" -Name "PowerShell Tools" }
			"3" { Invoke-SetupScript -Script "02-install-windows-subsystem-linux.ps1" -Name "Windows Subsystem for Linux" }
			"4" { Invoke-SetupScript -Script "03-install-development-tools.ps1" -Name "Development Tools" }
			"5" { Invoke-SetupScript -Script "04-install-productivity-tools.ps1" -Name "Productivity Tools" }
			"6" { Invoke-SetupScript -Script "05-install-azure-tools.ps1" -Name "Azure Tools" }
			default { Write-Host "Unknown option: $choice" -ForegroundColor Yellow }
		}
	}
}

function Invoke-All {
	Invoke-Selected -Selections @("1", "2", "3", "4", "5", "6")
}

# Handle unattended mode
if ($All) {
	Invoke-All
	exit 0
}

# Interactive menu
while ($true) {
	Show-Menu
	$input = Read-Host "  Select options (e.g. 1 3 4)"

	switch -Regex ($input.Trim()) {
		"^[Aa]$" { Invoke-All; break }
		"^[Qq]$" { Write-Host "Goodbye."; exit 0 }
		"^\s*$" { Write-Host "No selection made." -ForegroundColor Yellow }
		default {
			$selections = $input -split '\s+'
			Invoke-Selected -Selections $selections
			break
		}
	}
}

Write-Host ""
Write-Host "✅ Setup complete!" -ForegroundColor Green
