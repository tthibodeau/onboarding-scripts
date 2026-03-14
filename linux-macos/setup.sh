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

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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

	if ! sudo -n true 2>/dev/null; then
		echo "❌ Failed to enable passwordless sudo. Run scripts individually instead."
		exit 1
	fi

	export SETUP_SUDO_ACTIVE=1
	trap 'sudo rm -f $SUDOERS_TMP 2>/dev/null; echo ""; echo "🛡️ Temporary sudo access removed."' EXIT
	echo "🛡️ sudo access granted for this session."
}

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

show_help() {
	echo "Usage: setup.sh [OPTIONS]"
	echo ""
	echo "Options:"
	echo "  --all       Install all components (unattended)"
	echo "  --verbose   Show full install output (no spinners)"
	echo "  -h, --help  Show this help message"
	echo ""
	echo "Without options, an interactive menu is shown."
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

post_setup() {
	echo ""
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo "  Post-Setup"
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo ""

	if [ ! -f "$SETUP_LOG" ]; then
		echo "  ✅ No issues"
		return
	fi

	# Find failed installs from FAILED: markers (format: FAILED: desc|reason)
	local failures
	failures=$(grep '^FAILED: ' "$SETUP_LOG" 2>/dev/null | sed 's/^FAILED: //' | sort -u)

	if [ -n "$failures" ]; then
		echo "  ❌ Failed:"
		while IFS='|' read -r desc reason; do
			echo "    • $desc"
			if [ -n "$reason" ] && [ "$reason" != "unknown error" ]; then
				echo "      ${reason:0:100}"
			fi
		done <<< "$failures"
		echo ""
	fi

	# Find actionable suggestions (e.g. "sudo apt autoremove") and run them
	local cleanup
	cleanup=$(grep -oE "Use '([^']+)'" "$SETUP_LOG" 2>/dev/null \
		| sed "s/^Use '//;s/'$//" | sort -u \
		| grep -v 'brew reinstall')

	if [ -n "$cleanup" ]; then
		echo "  Cleanup tasks:"
		while IFS= read -r cmd; do
			echo "    • ${cmd#sudo }"
		done <<< "$cleanup"
		echo ""

		read -p "  Run all cleanup tasks? [Y/n] " ans
		if [[ "${ans:-Y}" =~ ^[Yy]$ ]]; then
			echo ""
			while IFS= read -r cmd; do
				run_quiet "${cmd#sudo }" $cmd
			done <<< "$cleanup"
		fi
		echo ""
	fi

	# Collect all notes from:
	# 1. NOTE: markers from log_note() in scripts
	# 2. Installer advisories (you may need, we recommend, etc.)
	# 3. Next steps blocks from Homebrew etc.
	local notes=""

	# log_note() markers
	local log_notes
	log_notes=$(grep '^NOTE: ' "$SETUP_LOG" 2>/dev/null | sed 's/^NOTE: //') || true
	[ -n "$log_notes" ] && notes="$log_notes"

	# Installer advisories
	local advisories
	advisories=$(grep -iE 'you may need to|you should|we recommend|remember to' "$SETUP_LOG" 2>/dev/null \
		| sed 's/^- //') || true
	[ -n "$advisories" ] && notes="${notes:+$notes
}$advisories"

	# Next steps blocks (extract bullet points, filter noise)
	local next_steps
	next_steps=$(sed -n '/^==> Next steps:/,/^===/p' "$SETUP_LOG" 2>/dev/null \
		| grep -E '^\s*-' | sed 's/^\s*- //' \
		| grep -viE 'run brew help|further documentation|run these commands.*PATH') || true
	[ -n "$next_steps" ] && notes="${notes:+$notes
}$next_steps"

	# Deduplicate
	notes=$(echo "$notes" | sort -u | sed '/^$/d')

	if [ -n "$notes" ]; then
		echo "  Notes from installers:"
		while IFS= read -r note; do
			[ -z "$note" ] && continue
			# Check if this suggestion was already handled by our scripts
			local handled=false
			case "$note" in
				*"install build-essential"*) dpkg -s build-essential &>/dev/null && handled=true ;;
				*"install GCC"*|*"install gcc"*) command -v gcc &>/dev/null && handled=true ;;
				*"Homebrew's dependencies"*) handled=true ;;
				*"add Homebrew to your PATH"*) grep -q 'brew shellenv' ~/.zshrc 2>/dev/null && handled=true ;;
			esac

			if [ "$handled" = true ]; then
				echo "    ✅ $note (already done)"
			else
				echo "    ⚡ $note"
			fi
		done <<< "$notes"
		echo ""
	fi

	if [ -z "$failures" ] && [ -z "$cleanup" ] && [ -z "$notes" ]; then
		echo "  ✅ No issues"
	fi

	echo "  📋 Full log: $SETUP_LOG"
	echo ""
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

build_menu

# Parse arguments
for arg in "$@"; do
	case "$arg" in
		-h|--help) show_help; exit 0 ;;
		--verbose) export SETUP_QUIET=0 ;;
	esac
done

enable_sudo

# Unattended mode
for arg in "$@"; do
	case "$arg" in
		--all) run_all; post_setup; echo "✅ Setup complete!"; exit 0 ;;
	esac
done

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

post_setup
echo "✅ Setup complete!"
