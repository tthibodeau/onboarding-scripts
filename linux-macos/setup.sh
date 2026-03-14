#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Grant temporary passwordless sudo for the duration of setup.
# Homebrew resets sudo timestamps and sudo-rs uses per-process auth,
# so this is the only reliable way to avoid repeated password prompts.
SUDOERS_TMP="/etc/sudoers.d/setup-temp-nopasswd"

enable_sudo() {
	if sudo -n true 2>/dev/null; then
		echo "🛡️ sudo access confirmed."
		export SETUP_SUDO_ACTIVE=1
		return
	fi

	echo "🔑 Your sudo password is required for installation."
	echo "   Temporary passwordless sudo will be enabled for this session."
	echo ""
	sudo sh -c "echo '$(whoami) ALL=(ALL) NOPASSWD: ALL' > $SUDOERS_TMP && chmod 440 $SUDOERS_TMP"
	export SETUP_SUDO_ACTIVE=1
	trap 'sudo rm -f $SUDOERS_TMP 2>/dev/null; echo ""; echo "🛡️ Temporary sudo access removed."' EXIT
	echo "🛡️ sudo access granted for this session."
}

disable_sudo() {
	if [ -f "$SUDOERS_TMP" ]; then
		sudo rm -f "$SUDOERS_TMP"
		echo "🛡️ Temporary sudo access removed."
	fi
}

show_menu() {
	echo ""
	echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
	echo "┃                Workstation Setup                ┃"
	echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
	echo ""
	echo "  [1] Prerequisites (git, brew, 1Password)"
	echo "  [2] Zsh Shell (oh-my-zsh, powerlevel10k)"
	echo "  [3] Development Tools (Node, VS Code, Claude)"
	echo "  [4] Docker & Kubernetes"
	echo "  [5] Productivity Tools"
	echo "  [6] Azure Tools"
	echo ""
	echo "  [A] Install All"
	echo "  [Q] Quit"
	echo ""
}

run_script() {
	local script="$1"
	local name="$2"
	echo ""
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo "  Running: $name"
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo ""
	# Source scripts in the current shell so sudo credentials are shared
	source "$SCRIPT_DIR/$script"
}

run_selected() {
	local selections="$1"
	for choice in $selections; do
		case "$choice" in
			1) run_script "00-install-prerequisites.sh" "Prerequisites" ;;
			2) run_script "01-install-zsh-shell.sh" "Zsh Shell" ;;
			3) run_script "02-install-development-tools.sh" "Development Tools" ;;
			4) run_script "03-install-docker-kubernetes.sh" "Docker & Kubernetes" ;;
			5) run_script "04-install-productivity-tools.sh" "Productivity Tools" ;;
			6) run_script "05-install-azure-tools.sh" "Azure Tools" ;;
			*) echo "Unknown option: $choice" ;;
		esac
	done
}

run_all() {
	run_selected "1 2 3 4 5 6"
}

# Enable sudo for the session
enable_sudo

# Handle command-line arguments for unattended mode
if [[ "$1" == "--all" ]]; then
	run_all
	exit 0
fi

# Interactive menu
while true; do
	show_menu
	read -p "  Select options (e.g. 1 3 4): " input

	case "$input" in
		[Aa]) run_all; break ;;
		[Qq]) echo "Goodbye."; exit 0 ;;
		"") echo "No selection made." ;;
		*) run_selected "$input"; break ;;
	esac
done

echo ""
echo "✅ Setup complete!"
