#!/usr/bin/env bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/shared.sh"

assert_not_root
prompt_sudo

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# APP LISTS — edit these to add/remove apps
# (iTerm2 is macOS-only, no Linux equivalent here)
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BREW_FORMULAS=()

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CUSTOM INSTALLS — apt repos required for Linux
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

install_brave() {
	if command -v brave-browser &>/dev/null; then return; fi
	case "$PKG_MANAGER" in
		apt)
			curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
				https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
			echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" \
				| sudo tee /etc/apt/sources.list.d/brave-browser-release.list
			pkg_update
			pkg_install brave-browser
			;;
		dnf)
			sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
			sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
			pkg_install brave-browser
			;;
		pacman)
			AUR_HELPER=$(get_aur_helper)
			$AUR_HELPER -S --needed --noconfirm brave-bin
			;;
	esac
}

install_warp() {
	if command -v warp-terminal &>/dev/null; then return; fi
	case "$PKG_MANAGER" in
		apt)
			curl -fsSLo /tmp/warp.deb 'https://app.warp.dev/download?package=deb'
			sudo dpkg -i /tmp/warp.deb || sudo apt-get install -f -y
			rm -f /tmp/warp.deb
			# Warp's .deb adds a broken apt source — remove it
			sudo rm -f /etc/apt/sources.list.d/warpdotdev.list /etc/apt/trusted.gpg.d/warpdotdev.gpg 2>/dev/null
			;;
		dnf)
			curl -fsSLo /tmp/warp.rpm 'https://app.warp.dev/download?package=rpm'
			sudo dnf install -y /tmp/warp.rpm
			rm -f /tmp/warp.rpm
			;;
		pacman)
			AUR_HELPER=$(get_aur_helper)
			$AUR_HELPER -S --needed --noconfirm warp-terminal
			;;
	esac
}

install_slack() {
	if command -v slack &>/dev/null; then return; fi
	# Scrape current download URL from Slack (they don't support a 'latest' URL)
	local slack_deb_url
	slack_deb_url=$(curl -fsSL 'https://slack.com/downloads/instructions/linux?ddl=1&build=deb' 2>/dev/null \
		| grep -oE 'https://downloads.slack-edge.com/[^"]*\.deb' | head -1)

	case "$PKG_MANAGER" in
		apt)
			if [ -z "$slack_deb_url" ]; then
				echo "Could not find Slack download URL" >&2
				return 1
			fi
			curl -fsSLo /tmp/slack.deb "$slack_deb_url"
			sudo dpkg -i /tmp/slack.deb || sudo apt-get install -f -y
			rm -f /tmp/slack.deb
			;;
		dnf)
			local slack_rpm_url
			slack_rpm_url=$(curl -fsSL 'https://slack.com/downloads/instructions/linux?ddl=1&build=rpm' 2>/dev/null \
				| grep -oE 'https://downloads.slack-edge.com/[^"]*\.rpm' | head -1)
			if [ -z "$slack_rpm_url" ]; then
				echo "Could not find Slack download URL" >&2
				return 1
			fi
			curl -fsSLo /tmp/slack.rpm "$slack_rpm_url"
			sudo dnf install -y /tmp/slack.rpm
			rm -f /tmp/slack.rpm
			;;
		pacman)
			AUR_HELPER=$(get_aur_helper)
			$AUR_HELPER -S --needed --noconfirm slack-desktop
			;;
	esac
}

# Notion has no official Linux app — use https://notion.so in browser

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INSTALL
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

run_quiet "Installing Brave Browser" install_brave
run_quiet "Installing Warp Terminal" install_warp
run_quiet "Installing Slack" install_slack
