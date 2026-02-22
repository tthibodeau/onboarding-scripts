param (
	[switch]$CheckForUpdates
)

$commonModulePath = Join-Path $PSScriptRoot "./shared/ps-shared.ps1"
. $commonModulePath
# Ensure running as Admin in Powershell Core
Assert-Elevated -commandToRun $PSCommandPath -CheckForUpdates:$CheckForUpdates -RequirePSCore


# Define all Azure and Kubernetes tools to install
$azureTools = @(
	# Kubernetes tools
	@{AppId = "Microsoft.Azure.Kubelogin"; DisplayName = "Azure Kubelogin"},
	@{AppId = "Kubernetes.kubectl"; DisplayName = "Kubernetes CLI (kubectl)"},

	# Azure tools
	@{AppId = "Microsoft.AzureCLI"; DisplayName = "Azure CLI"}
)

# Install all Azure and Kubernetes tools
foreach ($tool in $azureTools) {
	Install-AppIfMissing -CheckForUpdates:$CheckForUpdates -AppId $tool.AppId -DisplayName $tool.DisplayName
}

# kubectl completion - add to PowerShell profile
Add-Content $PROFILE "if (Get-Command kubectl -ErrorAction SilentlyContinue) {
	kubectl completion powershell | Out-String | Invoke-Expression
	}"
# Azure CLI tab completion (https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=winget#enable-tab-completion-on-powershell)
$psProfileAzureCLIAutoComplete = @'
# Azure CLI tab completion
Register-ArgumentCompleter -Native -CommandName az -ScriptBlock {
	param($commandName, $wordToComplete, $cursorPosition)
	$completion_file = New-TemporaryFile
	$env:ARGCOMPLETE_USE_TEMPFILES = 1
	$env:_ARGCOMPLETE_STDOUT_FILENAME = $completion_file
	$env:COMP_LINE = $wordToComplete
	$env:COMP_POINT = $cursorPosition
	$env:_ARGCOMPLETE = 1
	$env:_ARGCOMPLETE_SUPPRESS_SPACE = 0
	$env:_ARGCOMPLETE_IFS = "`n"
	$env:_ARGCOMPLETE_SHELL = 'powershell'
	az 2>&1 | Out-Null
	Get-Content $completion_file | Sort-Object | ForEach-Object {
		[System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", $_)
	}
	Remove-Item $completion_file, Env:\_ARGCOMPLETE_STDOUT_FILENAME, Env:\ARGCOMPLETE_USE_TEMPFILES, Env:\COMP_LINE, Env:\COMP_POINT, Env:\_ARGCOMPLETE, Env:\_ARGCOMPLETE_SUPPRESS_SPACE, Env:\_ARGCOMPLETE_IFS, Env:\_ARGCOMPLETE_SHELL
}
'@

Add-Content $PROFILE $psProfileAzureCLIAutoComplete

# https://github.com/Azure/kubelogin
$env:Path="$env:Path;$env:ProgramFiles\Microsoft SDKs\Azure\CLI2\wbin\"
Write-Host "######## az aks CLI installing..." -ForegroundColor Green
az aks install-cli
$targetDir="$env:USERPROFILE\.azure-kubelogin"
$oldPath = [System.Environment]::GetEnvironmentVariable("Path","User")
$oldPathArray=($oldPath) -split ";"
if(-Not($oldPathArray -Contains "$targetDir")) {
	Write-Host "Permanently adding $targetDir to User Path" -ForegroundColor DarkGray
	$newPath = "$oldPath;$targetDir" -replace ";+", ";"
	[System.Environment]::SetEnvironmentVariable("Path",$newPath,"User")
	Update-SessionEnvironment
}
