# <img src="../images/Mac-logo.png" alt="Mac" width="24" height="24"> MacOS / <img src="../images/Linux-logo.svg" alt="Linux" width="24" height="24"> Linux / <img src="../images/WSL2.png" alt="WSL2" width="24" height="24"> WSL Setup Scripts

- Automated installation and configuration of development tools and environment settings.
- Scripts are organized by functional area, allowing you to run only what you need.
- Each gateway script auto-detects the OS and runs the appropriate platform-specific script from `linux/` or `macos/`

## Quick Start
```bash
./setup.sh          # interactive menu — pick what to install
./setup.sh --all    # install everything (unattended)
```

## Run Individual Scripts (Bash/Zsh, not sh)
```bash
./00-install-prerequisites.sh
./01-install-zsh-shell.sh
./02-install-development-tools.sh
./03-install-docker-kubernetes.sh
./04-install-productivity-tools.sh
./05-install-azure-tools.sh
```

## Structure
```
├── 00-05*.sh          # Gateway scripts (OS detection → platform branch → common)
├── shared.sh          # Shared functions (sudo guard, brew init, configure_git)
├── linux/             # Linux/WSL-specific scripts
│   ├── 00-install-prerequisites.sh
│   ├── 01-install-zsh-shell.sh
│   ├── 02-install-development-tools.sh
│   └── 03-install-docker-kubernetes.sh
└── macos/             # macOS-specific scripts
    ├── 00-install-prerequisites.sh
    ├── 01-install-zsh-shell.sh
    ├── 02-install-development-tools.sh
    ├── 03-install-docker-kubernetes.sh
    └── 04-install-productivity-tools.sh
```
