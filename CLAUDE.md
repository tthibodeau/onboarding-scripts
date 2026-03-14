# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Workstation onboarding scripts that automate installation and configuration of development tools, shell environments, and productivity applications. Scripts are split into two platform tracks:

- **`linux-macos/`** — Bash scripts (`*.sh`) for Linux, macOS, and WSL environments
- **`windows/`** — PowerShell scripts (`*.ps1`) for Windows environments

## Architecture

### Linux/macOS scripts (`linux-macos/`)

Numbered shell scripts run sequentially in Bash or Zsh (not `sh`). Each script:
- Guards against running as root (`sudo` is requested at runtime via `sudo -v`)
- Detects OS via `$OSTYPE` to branch between Linux (`apt-get`) and macOS (`brew`) paths
- Uses Homebrew as the common package manager across both platforms
- Appends shell config to `~/.zshrc` (and `~/.bashrc`/`~/.profile` where needed)

### Windows scripts (`windows/`)

PowerShell scripts use `winget` for app installation and PSGallery for modules. Key patterns:
- `00-install-prerequisites.ps1` is the only script compatible with PowerShell 5; all others require PowerShell Core 7+
- Scripts auto-elevate to admin and auto-relaunch in PS7 if run from PS5 (via `Assert-Elevated` in shared module)
- `shared/ps-shared.ps1` is dot-sourced by all scripts — contains shared helpers: `Install-AppIfMissing`, `Install-ModuleIfMissing`, `Assert-Elevated`, `Update-SessionEnvironment`
- The `-CheckForUpdates` switch enables upgrade checks for already-installed tools

### Conventions

- Scripts are organized by functional area (prerequisites, shell, dev tools, Docker/K8s, productivity, Azure) — each can be run independently
- All scripts are idempotent: they check for existing installations before installing
- WSL-specific configuration is auto-detected via `$WSL_DISTRO_NAME` in bash scripts
- PowerShell scripts must be saved with UTF-8 BOM encoding for PS5.1 emoji compatibility
