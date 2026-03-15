# Workstation Setup Scripts
Automated installation and configuration of development tools, shell environments, and productivity applications. Scripts are organized by functional area, allowing you to run only what you need.

## Quick Start
```bash
# Linux / macOS / WSL
./setup.sh              # interactive menu
./setup.sh --all        # install everything

# Windows (PowerShell)
.\setup.ps1             # interactive menu
.\setup.ps1 -All        # install everything
```

## <img src="images/Mac-logo.png" alt="Mac" width="24" height="24"> MacOS / <img src="images/Linux-logo.svg" alt="Linux" width="24" height="24"> Linux / <img src="images/WSL2.png" alt="WSL2" width="24" height="24"> WSL
- Bash scripts with interactive setup menu and spinner progress
- Supports Ubuntu/Debian, Fedora/RHEL, Arch/Manjaro
- [View Linux/macOS scripts](./linux-macos)

## <img src="images/Windows-logo.png" alt="Windows" width="24" height="24"> Windows
- <img src="./windows/images/PowerShell_7_icon.svg" alt="PSCore7" style="width: 20px; height: 20px;"> PowerShell scripts with interactive setup menu
- Auto-elevates to admin and installs PowerShell Core 7+ if needed
- [View Windows scripts](./windows)
