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
	case "$PKG_MANAGER" in
		apt)
			curl -fsSLo /tmp/slack.deb "https://downloads.slack-edge.com/desktop-releases/linux/x64/latest/slack-desktop-amd64.deb"
			sudo dpkg -i /tmp/slack.deb || sudo apt-get install -f -y
			rm -f /tmp/slack.deb
			;;
		dnf)
			curl -fsSLo /tmp/slack.rpm "https://downloads.slack-edge.com/desktop-releases/linux/x64/latest/slack-desktop-x64.rpm"
			pkg_install /tmp/slack.rpm
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
