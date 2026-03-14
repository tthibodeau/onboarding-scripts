#!/usr/bin/env bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/shared.sh"

assert_not_root
prompt_sudo

NODE_VERSION="23"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# APP LISTS — edit these to add/remove apps
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BREW_FORMULAS=(
	nvm
	pnpm
	act
	nuget
)

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CUSTOM INSTALLS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

install_claude_code() {
	run_quiet "Installing Claude Code CLI" bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
	export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"
	append_to_zshrc 'export PATH="$HOME/.local/bin:$PATH"'
	append_to_zshrc 'export PATH="$HOME/.claude/bin:$PATH"'
}

install_vscode() {
	case "$PKG_MANAGER" in
		apt)
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
			AUR_HELPER=$(get_aur_helper)
			$AUR_HELPER -S --needed --noconfirm visual-studio-code-bin
			;;
	esac
}

install_bun() {
	run_quiet "Installing Bun" bash -c 'curl -fsSL https://bun.sh/install | bash'
	append_to_zshrc 'export BUN_INSTALL="$HOME/.bun"'
	append_to_zshrc 'export PATH="$BUN_INSTALL/bin:$PATH"'
}

configure_nvm() {
	mkdir -p ~/.nvm
	append_to_zshrc 'export NVM_DIR="$HOME/.nvm"'
	append_to_zshrc '[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"'
	append_to_zshrc '[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"'

	export NVM_DIR="$HOME/.nvm"
	[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
	[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"

	if ! nvm ls "$NODE_VERSION" &>/dev/null; then
		run_quiet "Installing Node.js v$NODE_VERSION via NVM" nvm install "$NODE_VERSION"
		nvm use "$NODE_VERSION" > /dev/null
		nvm alias default "$NODE_VERSION" > /dev/null
	fi
	status "✅ Node.js $(node -v)"
}

configure_pnpm() {
	append_to_zshrc 'p() { pnpm "$@"; }'
	status "✅ pnpm $(pnpm -v)"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INSTALL — sudo-dependent installs first, Homebrew last
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

install_claude_code
run_quiet "Installing VS Code" install_vscode

init_brew_env
brew_update
install_brew_formulas "${BREW_FORMULAS[@]}"

install_bun
configure_nvm
configure_pnpm
