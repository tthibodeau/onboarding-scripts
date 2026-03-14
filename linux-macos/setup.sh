#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Enable quiet mode — suppresses install output, shows spinners
export SETUP_QUIET=1
export SETUP_LOG="/tmp/setup-$(date +%Y%m%d-%H%M%S).log"

# Detect platform
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	PLATFORM_DIR="$SCRIPT_DIR/linux"
	PLATFORM="Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
	PLATFORM_DIR="$SCRIPT_DIR/macos"
	PLATFORM="macOS"
else
	echo "❌ Unsupported platform: $OSTYPE"
	exit 1
fi

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

	# Verify NOPASSWD is working
	if ! sudo -n true 2>/dev/null; then
		echo "❌ Failed to enable passwordless sudo. Run scripts individually instead."
		exit 1
	fi

	export SETUP_SUDO_ACTIVE=1
	trap 'sudo rm -f $SUDOERS_TMP 2>/dev/null; echo ""; echo "🛡️ Temporary sudo access removed."' EXIT
	echo "🛡️ sudo access granted for this session."
}

# Build menu dynamically from available scripts in platform directory
declare -A MENU_SCRIPTS
declare -A MENU_NAMES

build_menu() {
	local i=1
	for script in "$PLATFORM_DIR"/*.sh; do
		[ -f "$script" ] || continue
		local basename=$(basename "$script")
		local name=$(echo "$basename" | sed 's/^[0-9]*-//;s/\.sh$//;s/-/ /g;s/\b\(.\)/\u\1/g')
		MENU_SCRIPTS[$i]="$script"
		MENU_NAMES[$i]="$name"
		((i++))
	done
	MENU_COUNT=$((i - 1))
}

show_menu() {
	echo ""
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo "           Workstation Setup ($PLATFORM)"
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo ""
	for i in $(seq 1 $MENU_COUNT); do
		echo "  [$i] ${MENU_NAMES[$i]}"
	done
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
	source "$script"
}

run_selected() {
	local selections="$1"
	for choice in $selections; do
		if [ -n "${MENU_SCRIPTS[$choice]}" ]; then
			run_script "${MENU_SCRIPTS[$choice]}" "${MENU_NAMES[$choice]}"
		else
			echo "Unknown option: $choice"
		fi
	done
}

run_all() {
	local all_choices=$(seq 1 $MENU_COUNT | tr '\n' ' ')
	run_selected "$all_choices"
}

# Build menu from platform scripts
build_menu

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

post_setup() {
	echo ""
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo "  Post-Setup"
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo ""

	if [ ! -f "$SETUP_LOG" ]; then
		echo "  📋 No log file found."
		return
	fi

	# Check log for errors
	local errors
	errors=$(grep -ciE '^E:|error:|failed|fatal' "$SETUP_LOG" 2>/dev/null || echo 0)
	if [ "$errors" -gt 0 ]; then
		echo "  ⚠️  $errors issue(s) detected — review: $SETUP_LOG"
	else
		echo "  ✅ No errors detected"
	fi
	echo ""

	# Parse log for suggested commands and actionable items
	local actions
	actions=$(grep -oiE \
		"(sudo [a-z]+ [a-z-]+|use '[^']+')|(log out|restart|reboot|you may need to)[^.]*" \
		"$SETUP_LOG" 2>/dev/null | sort -u)

	if [ -z "$actions" ]; then
		echo "  📋 Full log: $SETUP_LOG"
		echo ""
		return
	fi

	# Extract runnable commands (lines starting with sudo or wrapped in quotes)
	local runnable
	runnable=$(echo "$actions" | grep -oE "sudo [a-z]+ [a-z-]+" | sort -u)

	# Extract non-runnable reminders
	local reminders
	reminders=$(echo "$actions" | grep -ivE "^sudo " | sed "s/^[Uu]se '//;s/'$//" | sort -u)

	# Show everything found
	if [ -n "$runnable" ]; then
		echo "  Cleanup tasks:"
		while IFS= read -r cmd; do
			echo "    • ${cmd#sudo }"
		done <<< "$runnable"
		echo ""
	fi

	if [ -n "$reminders" ]; then
		echo "  Manual steps:"
		while IFS= read -r reminder; do
			echo "    ⚡ $reminder"
		done <<< "$reminders"
		echo ""
	fi

	# Offer to run all commands at once
	if [ -n "$runnable" ]; then
		read -p "  Run all cleanup tasks? [Y/n] " ans
		if [[ "${ans:-Y}" =~ ^[Yy]$ ]]; then
			echo ""
			while IFS= read -r cmd; do
				run_quiet "${cmd#sudo }" $cmd
			done <<< "$runnable"
		fi
		echo ""
	fi

	echo "  📋 Full log: $SETUP_LOG"
	echo ""
}

post_setup
echo "✅ Setup complete!"
