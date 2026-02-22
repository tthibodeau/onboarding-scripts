# <img src="../images/Windows-logo.png" alt="Windows" width="24" height="24"> Windows Setup Scripts


## 🚨 IMPORTANT 🚨
<img src="images/PowerShell_7_icon.svg" alt="PSCore7" style="width: 20px; height: 20px;"> **PowerShell Core (7+)** (pwsh.exe) is required to run all scripts, except `00-install-prerequisites.ps1`, which supports <img src="images/PowerShell_5_icon.png" alt="PSCore7" style="width: 20px; height: 20px;"> PowerShell 5 (powershell.exe).

## 🛡️RUN ALL IN ADMINISTRATOR SHELL
- Fresh <img src="../images/Windows-logo.png" alt="Windows" width="16" height="16"> Windows install requires:
    - Execute `Set-ExecutionPolicy Bypass` once in <img src="images/PowerShell_5_icon.png" alt="PSCore7" style="width: 20px; height: 20px;"> PowerShell 5
    - Execute `00-install-prerequisites.ps1` in <img src="images/PowerShell_5_icon.png" alt="PSCore7" style="width: 20px; height: 20px;"> PowerShell 5. 
- <img src="images/PowerShell_7_icon.svg" alt="PSCore7" style="width: 20px; height: 20px;"> **PowerShell Core (7+)** is installed by `00-install-prerequisites.ps1`. All subsequent scripts can be run in <img src="images/PowerShell_7_icon.svg" alt="PSCore7" style="width: 20px; height: 20px;"> **PowerShell Core (7+)** and will automatically open and execute in <img src="images/PowerShell_7_icon.svg" alt="PSCore7" style="width: 20px; height: 20px;"> **PowerShell Core (7+)** if accidentally run in <img src="images/PowerShell_5_icon.png" alt="PSCore7" style="width: 20px; height: 20px;"> PowerShell 5 
- Automated installation and configuration of development tools and environment settings.
- Scripts are organized by functional area, allowing you to run only what you need.
- `-CheckForUpdates` parameter will force install of newer versions of tools if found


## Run in Powershell
```powershell
## PS5 & PS7 compatible
.\00-install-prerequisites.ps1

## Only PS7 compatible
.\01-install-powershell-tools.ps1 -CheckForUpdates
.\02-install-windows-subsystem-linux.ps1
.\03-install-development-tools.ps1
.\04...
.\05...
```
