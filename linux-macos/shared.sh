#!/usr/bin/env bash

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Shared functions for Linux/macOS setup scripts
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Distro detection and package manager abstraction
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

detect_distro() {
	if [ -f /etc/os-release ]; then
		. /etc/os-release
		DISTRO_ID="$ID"
		DISTRO_VERSION="$VERSION_ID"
	else
		echo "❌ Unable to detect Linux distribution (/etc/os-release not found)"
		exit 1
	fi

	case "$DISTRO_ID" in
		ubuntu|debian|linuxmint|pop)
			PKG_MANAGER="apt"
			;;
		fedora)
			PKG_MANAGER="dnf"
			;;
		rhel|centos|rocky|alma)
			PKG_MANAGER="dnf"
			;;
		arch|manjaro|endeavouros)
			PKG_MANAGER="pacman"
			;;
		*)
			echo "❌ Unsupported Linux distribution: $DISTRO_ID"
			echo "Supported: Ubuntu, Debian, Fedora, RHEL/CentOS/Rocky/Alma, Arch/Manjaro/EndeavourOS"
			exit 1
			;;
	esac

	echo "🐧 Detected: $DISTRO_ID $DISTRO_VERSION (package manager: $PKG_MANAGER)"
}

pkg_update() {
	case "$PKG_MANAGER" in
		apt) sudo apt-get update ;;
		dnf) sudo dnf check-update || true ;;
		pacman) sudo pacman -Sy ;;
	esac
}

pkg_install() {
	case "$PKG_MANAGER" in
		apt) sudo apt-get install -y "$@" ;;
		dnf) sudo dnf install -y "$@" ;;
		pacman) sudo pacman -S --needed --noconfirm "$@" ;;
	esac
}

# Auto-detect distro on Linux
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	detect_distro
fi

assert_not_root() {
	if [ "$EUID" -eq 0 ]; then
		echo "❌ Do not run script with sudo"
		exit 1
	fi
}

prompt_sudo() {
	echo "🔑 Your sudo password is required for installation. Please enter it now:"
	sudo -v
}

init_brew_env() {
	# Set the brew shell environment variables
	# Brew uses different paths for Apple Silicon, Intel Macs, and Linux
	# See https://docs.brew.sh/Installation#unattended-installation
	test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
	eval "$($(which brew) shellenv)"
}

configure_git() {
	echo "🔧 Configuring Git..."

	# Configure Git to ensure line endings are correct
	# For compatibility, line endings are converted to Unix style when you commit files
	git config --global core.autocrlf false

	# Check if Git user.name and user.email are already set
	currentGitName=$(git config --global user.name)
	currentGitEmail=$(git config --global user.email)

	if [ -z "$currentGitName" ] || [ -z "$currentGitEmail" ]; then
		echo ""
		echo "⚠️  Git identity is not fully configured."
		echo "Please set the following before continuing:"
		echo ""
		[ -z "$currentGitName" ] && echo "  git config --global user.name \"Your Name\""
		[ -z "$currentGitEmail" ] && echo "  git config --global user.email \"you@example.com\""
		echo ""
		echo "❌ Aborting. Configure Git identity and re-run this script."
		exit 1
	fi

	echo "  user.name:  $currentGitName"
	echo "  user.email: $currentGitEmail"
	echo "✅ Git configuration complete"
	echo
}
