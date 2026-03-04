param (
	[switch]$CheckForUpdates
)

$commonModulePath = Join-Path $PSScriptRoot "./shared/ps-shared.ps1"
. $commonModulePath
# Ensure running as Admin in Powershell Core
Assert-Elevated -commandToRun $PSCommandPath -CheckForUpdates:$CheckForUpdates -RequirePSCore


# Backup previous Powershell profile
if (Test-Path -Path $PROFILE -PathType Leaf)
{
	Write-Host "Backing up previous Powershell profile to $PROFILE.backup" -ForegroundColor DarkGray
	Move-Item $PROFILE "$PROFILE.backup" -Force
}


# https://docs.microsoft.com/en-us/powershell/module/psreadline/about/about_psreadline?view=powershell-7.2
# Install power tools for Powershell
Install-ModuleIfMissing -CheckForUpdates:$CheckForUpdates -Force -AddImportToProfile -ModuleName "PSReadLine" -DisplayName "PSReadLine Tab Completion Module"



# Enable Tab Completion (w/MenuComplete) and history up/down
Add-ProfileContent -Content @'
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
'@

# Enable inline prediction from history and customize word delimiters
Add-ProfileContent -Content @'
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle InlineView
Set-PSReadLineOption -HistorySearchCursorMovesToEnd:$true
Set-PSReadlineOption -WordDelimiters ' /\()"''-.,:;<>~!@#$%^&*|+=[]{}~?│'
'@


$forwardWordAndAcceptNextSuggestionWord = @'
# `ForwardWord` accepts the entire suggestion text when the cursor is at the end of the line.
# This custom binding makes `Ctrl+RightArrow` behave similarly - accepting the next word instead of the entire suggestion text.

Set-PSReadLineKeyHandler -Chord Ctrl+RightArrow `
						 -BriefDescription ForwardWordAndAcceptNextSuggestionWord `
						 -LongDescription "Move cursor one word to the right in the current editing line and accept the next word in suggestion when it's at the end of current editing line" `
						 -ScriptBlock {
	param($key, $arg)

	$line = $null
	$cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

	if ($cursor -lt $line.Length) {
		[Microsoft.PowerShell.PSConsoleReadLine]::ForwardWord($key, $arg)
	} else {
		[Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($key, $arg)
	}
}
'@
Add-ProfileContent -Content $forwardWordAndAcceptNextSuggestionWord


$winGetAutoCompletion = @'
# Winget auto-completion
# https://docs.microsoft.com/en-us/windows/package-manager/winget/tab-completion

Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
	param($wordToComplete, $commandAst, $cursorPosition)
		[Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
		$Local:word = $wordToComplete.Replace('"', '""')
		$Local:ast = $commandAst.ToString().Replace('"', '""')
		winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
			[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
		}
}
'@
Add-ProfileContent -Content $winGetAutoCompletion


Add-ProfileContent -Content "Set-Alias ll Get-ChildItem"

# List ALL
function la
{
	param (
		$Path = "."
	)

	Get-ChildItem -Path $Path -Attributes None, ReadOnly, Hidden, System, Directory, Archive, Device, Normal, Temporary, SparseFile, ReparsePoint, Compressed, Offline, NotContentIndexed, Encrypted, IntegrityStream, NoScrubData
}

# Install Oh My Posh and related tools
$powershellTools = @(
	@{AppId = "JanDeDobbeleer.OhMyPosh"; DisplayName = "Oh My Posh"}
)

foreach ($tool in $powershellTools) {
	Install-AppIfMissing -CheckForUpdates:$CheckForUpdates -AppId $tool.AppId -DisplayName $tool.DisplayName
}

# Add OhMyPosh to the Path so calls to it work in this terminal session
$env:Path="$env:Path;$env:LOCALAPPDATA\Programs\oh-my-posh\bin"
# Install Meslo Nerd Font only if not already installed
$mesloFont = Get-ChildItem -Path "$env:SystemRoot\Fonts" -Filter "Meslo*" -ErrorAction SilentlyContinue
if (-not $mesloFont) {
	Write-Host "Meslo Nerd Font not found. Installing..." -ForegroundColor Yellow
	oh-my-posh font install Meslo
} else {
	Write-Host "Meslo Nerd Font is already installed." -ForegroundColor Green
}

# Configure Oh My Posh theme
# Create a directory for custom Oh My Posh themes if it doesn't exist
$customThemePath = Join-Path $env:USERPROFILE ".oh-my-posh-themes"
if (-not (Test-Path $customThemePath)) {
	New-Item -ItemType Directory -Path $customThemePath -Force | Out-Null
}

# Download powerlevel10k_rainbow theme if not already present
$themeFile = Join-Path $customThemePath "powerlevel10k_rainbow.omp.json"
if (-not (Test-Path $themeFile)) {
	Write-Host "Downloading powerlevel10k_rainbow theme..." -ForegroundColor Yellow
	try {
		Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/powerlevel10k_rainbow.omp.json" -OutFile $themeFile
		Write-Host "Theme downloaded successfully." -ForegroundColor Green
	} catch {
		Write-Host "Failed to download theme. Using default Oh My Posh theme instead." -ForegroundColor Yellow
		$themeFile = $null
	}
}

# Add Oh My Posh initialization to profile
if ($themeFile -and (Test-Path $themeFile)) {
	Add-ProfileContent -Content "oh-my-posh init pwsh --config '$themeFile' | Invoke-Expression"
} else {
	Add-ProfileContent -Content 'oh-my-posh init pwsh | Invoke-Expression'
}



# # Posh-CLI - https://github.com/bergmeister/posh-cli
# # posh-cli util - looks for locally installed CLIs for which tab-completion modules are available, installs them, and adds
Install-ModuleIfMissing -CheckForUpdates:$CheckForUpdates -Force -AddImportToProfile -ModuleName "posh-cli" -DisplayName "Posh-CLI Autocompletion"
Install-TabCompletion

# 1Password CLI tab completion
Add-ProfileContent -Content "op completion powershell | Out-String | Invoke-Expression" # Add to Powershell CLI completion to startup profile



Write-Host ""
Write-Host ""
Write-Host "$PROFILE updates complete." -ForegroundColor Green

Write-Host ""
Write-Host ""
Write-Host @'
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                                                                                        ┃
┃                                    Open Settings (CTRL + ,)                                         	 ┃
┃                                                                                                        ┃
┃      Set Profiles Defaults -> Additional Settings -> Appearance -> Font face: MesloLGM Nerd Font       ┃
┃                                                                                                        ┃
┃                         --------->  Restart Windows Terminal  <---------                               ┃
┃                                                                                                        ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
'@ -ForegroundColor Yellow
