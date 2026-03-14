#!/usr/bin/env bash
echo "🐧 Linux install..."

curl -fsSL https://claude.ai/install.sh | bash
export PATH="$HOME/.claude/bin:$PATH"
append_to_zshrc 'export PATH="$HOME/.claude/bin:$PATH"'

# VS Code install (brew --cask is macOS-only)
case "$PKG_MANAGER" in
	apt)
		# VS Code is included in the Microsoft repo added by 00-install-prerequisites.sh
		# Only add a dedicated source if the repo isn't already configured
		if ! grep -rq "packages.microsoft.com/repos/code" /etc/apt/sources.list.d/ 2>/dev/null; then
			echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
				| sudo tee /etc/apt/sources.list.d/vscode.list
		fi
		pkg_update
		pkg_install code
		;;
	dnf)
		sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
		sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
		pkg_update
		pkg_install code
		;;
	pacman)
		AUR_HELPER=$(command -v yay || command -v paru)
		$AUR_HELPER -S --needed --noconfirm visual-studio-code-bin
		;;
esac
