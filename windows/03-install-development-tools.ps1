param (
	[switch]$CheckForUpdates
)

$commonModulePath = Join-Path $PSScriptRoot "./shared/ps-shared.ps1"
. $commonModulePath
# Ensure running as Admin in Powershell Core
Assert-Elevated -commandToRun $PSCommandPath -CheckForUpdates:$CheckForUpdates -RequirePSCore

# Main script execution
Write-Host "Starting development tools installation..." -ForegroundColor Cyan
Write-Host ""

# Install common development tools
$developmentTools = @(
	@{AppId = "Git.Git"; DisplayName = "Git" },
	@{AppId = "GitHub.cli"; DisplayName = "GitHub CLI" },
	@{AppId = "Fork.Fork"; DisplayName = "Git Fork Desktop Client" },
	@{AppId = "Microsoft.DotNet.SDK.9"; DisplayName = ".NET Core 9 SDK" },
	@{AppId = "Microsoft.VisualStudioCode"; DisplayName = "Visual Studio Code" },
	@{AppId = "Docker.DockerDesktop"; DisplayName = "Docker Desktop" },
	@{AppId = "CoreyButler.NVMforWindows"; DisplayName = "NVM for Windows" },
	@{AppId = "pnpm.pnpm"; DisplayName = "pnpm" },
	@{AppId = "nektos.act"; DisplayName = "GitHub Actions Tester" },
	@{AppId = "Anthropic.ClaudeCode"; DisplayName = "Claude Code" }
)



foreach ($tool in $developmentTools) {
	Install-AppIfMissing -CheckForUpdates:$CheckForUpdates -AppId $tool.AppId -DisplayName $tool.DisplayName
}
function Set-GitConfiguration {
	Write-Host "Configuring Git..." -ForegroundColor Cyan

	# Add git to the Path so calls to it work in this terminal session
	$env:Path = "$env:Path;$env:ProgramFiles\Git\cmd"

	# Configure Git to ensure line endings in files you checkout are correct for Windows.
	# For compatibility, line endings are converted to Unix style when you commit files.
	git config --global core.autocrlf false

	# Required for 1Password CLI / SSH integration
	git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"

	# Check if Git user.name and user.email are already set
	$currentGitName = git config --global user.name
	$currentGitEmail = git config --global user.email

	if ([string]::IsNullOrWhiteSpace($currentGitName)) {
		Write-Host "Enter your Git user name (for commits):" -ForegroundColor White
		$gitName = Read-Host
		git config --global user.name $gitName
		Write-Host "✅ Git user.name set to: $gitName" -ForegroundColor Green
	}
 else {
		Write-Host "Git user.name is already set to: $currentGitName" -ForegroundColor Gray
	}

	if ([string]::IsNullOrWhiteSpace($currentGitEmail)) {
		Write-Host "Enter your Git user email (for commits):" -ForegroundColor White
		$gitEmail = Read-Host
		git config --global user.email $gitEmail
		Write-Host "✅ Git user.email set to: $gitEmail" -ForegroundColor Green
	}
 else {
		Write-Host "Git user.email is already set to: $currentGitEmail" -ForegroundColor Gray
	}

	Write-Host "✅ Git configuration complete" -ForegroundColor Green
	Write-Host ""
}

Set-GitConfiguration

function Install-DotnetEfTool {
	Write-Host "Setting up Entity Framework Core tools..." -ForegroundColor Cyan

	# Install Entity Framework Core tools
	# $dotnetEfInstalled = $false
	# $dotnetEfInstalled = dotnet tool list --global 2>$null | Select-String -SimpleMatch "dotnet-ef" -Quiet


	Write-Host "📥 Installing dotnet-ef..." -ForegroundColor Green

	# Fixed for issue As of 2025-11-12 (https://github.com/dotnet/efcore/issues/37124)

	# Clean up anything half-installed
	dotnet tool uninstall --global dotnet-ef 2>&1 | Out-Null
	dotnet nuget locals all --clear 2>&1 | Out-Null

	# (Optional) nuke stale tool store
	$store = Join-Path $HOME ".dotnet\tools\.store\dotnet-ef"
	if (Test-Path $store) { Remove-Item $store -Recurse -Force }

	# Install a known-good version (adjust to match your project's EF Core major)
	dotnet tool install --global dotnet-ef --version 9.*
	# dotnet tool install --global dotnet-ef

	Write-Host "✅ Entity Framework Core tools installation complete" -ForegroundColor Green
	Write-Host ""
}

Install-DotnetEfTool

function Install-NodeJs {
	Write-Host "Setting up Node.js..." -ForegroundColor Cyan

	# UI development with error handling for nvm
	if (Get-Command nvm -ErrorAction SilentlyContinue) {
		try {
			Write-Host "Checking installed Node.js versions with nvm..." -ForegroundColor Gray
			$nvmList = nvm list 2>&1 | Out-Null
			$nodeInstalled = ($null -ne $nvmList) -and ($nvmList -match "23")
		}
		catch {
			Write-Host "nvm list failed: $_" -ForegroundColor Yellow
			$nodeInstalled = $false
		}
		if (-not $nodeInstalled) {
			Write-Host "Installing Node.js v23 using NVM (Node Version Manager)..." -ForegroundColor Green
			try {
				nvm install 23 > $null
				nvm use 23
				# nvm alias default 23 # Not implemented in nvm-windows
			}
			catch {
				Write-Host "nvm install/use failed: $_" -ForegroundColor Red
			}
		}
		else {
			Write-Host "Node.js v23 is already installed via nvm." -ForegroundColor Cyan
		}
	}
	else {
		Write-Host "nvm is not available in this session. Please restart your shell or check your installation." -ForegroundColor Yellow
	}

	Write-Host "✅ Node.js setup complete" -ForegroundColor Green
	Write-Host ""
}

function Set-PnpmAlias {
	Write-Host "Setting up pnpm alias..." -ForegroundColor Cyan

	Set-Alias p pnpm
	Add-Content $PROFILE "Set-Alias p pnpm"

	Write-Host "✅ pnpm alias 'p' configured" -ForegroundColor Green
	Write-Host ""
}

Install-NodeJs
Set-PnpmAlias

Write-Host "Attemping install of DockerCompletion Module." -ForegroundColor Yellow
Write-Host "If it hangs, CTRL+C to exit. It's the last item and not required" -ForegroundColor Yellow
Write-Host "Run 'Install-Module DockerCompletion' manually." -ForegroundColor Yello
Install-ModuleIfMissing -CheckForUpdates:$CheckForUpdates -Force -ModuleName "DockerCompletion" -AddImportToProfile -DisplayName "Docker Completion Module"

Write-Host "Development tools installation completed!" -ForegroundColor Green
Write-Host "Please restart your shell to ensure all tools are properly configured." -ForegroundColor Yellow
