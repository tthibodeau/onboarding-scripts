#!/usr/bin/env bash

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Shared functions for Linux/macOS setup scripts
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_LOG="${SETUP_LOG:-/tmp/setup-$(date +%Y%m%d-%H%M%S).log}"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Quiet execution — suppresses output, shows status, logs to file
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Run a command quietly with a spinner. Usage: run_quiet "description" command args...
run_quiet() {
	local desc="$1"
	shift

	# If not in quiet mode, run normally
	if [ "$SETUP_QUIET" != "1" ]; then
		echo "📥 $desc"
		"$@"
		return $?
	fi

	local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
	local i=0

	printf "  %-50s " "$desc"

	echo "=== $desc ===" >> "$SETUP_LOG"
	echo "CMD: $*" >> "$SETUP_LOG"

	"$@" >> "$SETUP_LOG" 2>&1 &
	local pid=$!

	while kill -0 "$pid" 2>/dev/null; do
		printf "\b%s" "${spin:i++%${#spin}:1}"
		sleep 0.1
	done

	wait "$pid"
	local exit_code=$?

	if [ $exit_code -eq 0 ]; then
		printf "\b✅\n"
	else
		printf "\b❌\n"
		# Extract the error for this specific section from the log
		local err_line
		err_line=$(sed -n "/^=== $desc ===/,/^===/p" "$SETUP_LOG" 2>/dev/null \
			| grep -iE 'error|failed|fatal|unable|not found|no such|denied' \
			| grep -viE 'warning|silentlycontinue|erroraction|already|up-to-date|autoremove' \
			| tail -1)
		if [ -n "$err_line" ]; then
			echo "    ${err_line:0:100}"
		fi
		# Mark as failed in log for post-setup parsing (desc|reason)
		echo "FAILED: $desc|${err_line:-unknown error}" >> "$SETUP_LOG"
	fi

	return $exit_code
}

# Show a status message (always visible)
status() {
	echo "  $1"
}

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
		fedora|rhel|centos|rocky|alma)
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
		apt) run_quiet "Updating package lists" bash -c 'sudo apt-get update || true' ;;
		dnf) run_quiet "Updating package lists" sudo dnf check-update || true ;;
		pacman) run_quiet "Updating package lists" sudo pacman -Sy ;;
	esac
}

pkg_install() {
	local desc="Installing $*"
	case "$PKG_MANAGER" in
		apt) run_quiet "$desc" sudo apt-get install -y "$@" ;;
		dnf) run_quiet "$desc" sudo dnf install -y "$@" ;;
		pacman) run_quiet "$desc" sudo pacman -S --needed --noconfirm "$@" ;;
	esac
}

# Install silently, log output, return exit code — caller handles messaging
pkg_try_install() {
	case "$PKG_MANAGER" in
		apt) sudo apt-get install -y "$@" >> "${SETUP_LOG:-/dev/null}" 2>&1 ;;
		dnf) sudo dnf install -y "$@" >> "${SETUP_LOG:-/dev/null}" 2>&1 ;;
		pacman) sudo pacman -S --needed --noconfirm "$@" >> "${SETUP_LOG:-/dev/null}" 2>&1 ;;
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
	# Skip if setup.sh already authenticated
	if [ "$SETUP_SUDO_ACTIVE" = "1" ]; then
		echo "🛡️ sudo access confirmed (via setup.sh)."
		return
	fi
	# Check if sudo is already available (e.g. NOPASSWD configured)
	if sudo -n true 2>/dev/null; then
		echo "🛡️ sudo access confirmed."
		return
	fi
	echo "🔑 Your sudo password is required for installation. Please enter it now:"
	sudo -v
}

brew_install() {
	local formula="$1"
	local flags="${2:-}"
	local name="${formula##*/}"  # strip tap prefix (e.g. oven-sh/bun/bun → bun)
	if [ -n "$flags" ]; then
		run_quiet "Installing $name" brew install $flags "$formula"
	else
		run_quiet "Installing $name" brew install "$formula"
	fi
}

brew_update() {
	run_quiet "Updating Homebrew" brew update
}

install_brew_formulas() {
	for formula in "$@"; do
		brew_install "$formula"
	done
}

install_brew_casks() {
	for cask in "$@"; do
		brew_install "$cask" --cask
	done
}

init_brew_env() {
	# Set the brew shell environment variables
	# Brew uses different paths for Apple Silicon, Intel Macs, and Linux
	# See https://docs.brew.sh/Installation#unattended-installation
	test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
	eval "$($(which brew) shellenv)"
}

# Append a line to ~/.zshrc only if it doesn't already exist
append_to_zshrc() {
	local line="$1"
	grep -qF "$line" ~/.zshrc 2>/dev/null || echo "$line" >> ~/.zshrc
}

# Append a line to a shell profile only if it doesn't already exist
append_to_profile() {
	local file="$1"
	local line="$2"
	grep -qF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

# Get AUR helper (yay or paru) for Arch-based distros
get_aur_helper() {
	command -v yay || command -v paru || {
		echo "❌ No AUR helper found. Install yay or paru first." >&2
		return 1
	}
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
