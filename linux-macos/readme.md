# <img src="../images/Mac-logo.png" alt="Mac" width="24" height="24"> MacOS / <img src="../images/Linux-logo.svg" alt="Linux" width="24" height="24"> Linux / <img src="../images/WSL2.png" alt="WSL2" width="24" height="24"> WSL Setup Scripts

- Automated installation and configuration of development tools and environment settings.
- Scripts are organized by functional area, allowing you to run only what you need.
- `setup.sh` auto-detects the OS and shows only the relevant platform scripts.

## Quick Start
```bash
./setup.sh          # interactive menu — pick what to install
./setup.sh --all    # install everything (unattended)
```

## Run Individual Scripts (Bash/Zsh, not sh)
```bash
# Linux
bash linux/00-prerequisites.sh
bash linux/01-zsh-shell.sh
bash linux/02-dev-tools.sh
bash linux/03-docker-kubernetes.sh
bash linux/04-azure-tools.sh

# macOS
bash macos/00-prerequisites.sh
bash macos/01-zsh-shell.sh
bash macos/02-dev-tools.sh
bash macos/03-docker-kubernetes.sh
bash macos/04-productivity-tools.sh
bash macos/05-azure-tools.sh
```

## Structure
```
├── setup.sh           # Interactive menu (auto-detects OS)
├── shared.sh          # Shared helpers (run_quiet, pkg_install, brew_install, etc.)
├── linux/             # Linux/WSL standalone scripts
│   ├── 00-prerequisites.sh
│   ├── 01-zsh-shell.sh
│   ├── 02-dev-tools.sh
│   ├── 03-docker-kubernetes.sh
│   └── 04-azure-tools.sh
└── macos/             # macOS standalone scripts
    ├── 00-prerequisites.sh
    ├── 01-zsh-shell.sh
    ├── 02-dev-tools.sh
    ├── 03-docker-kubernetes.sh
    ├── 04-productivity-tools.sh
    └── 05-azure-tools.sh
```

## Adding Apps
Each script follows a consistent pattern — add to the list at the top:
```bash
BREW_FORMULAS=(...)     # Homebrew formulas
BREW_CASKS=(...)        # Homebrew casks (macOS)
SYSTEM_PACKAGES=(...)   # apt/dnf/pacman packages (Linux)
```
For complex installs (custom repos, curl scripts), add a function in the CUSTOM INSTALLS section.
