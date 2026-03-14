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

BREW_CASKS=(
	fork
	jetbrains-toolbox
	visual-studio-code
	postman
	insomnia
	redisinsight
	openvpn-connect
	dotnet-sdk9
)

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CUSTOM INSTALLS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

install_claude_code() {
	run_quiet "Installing Claude Code CLI" bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
	export PATH="$HOME/.claude/bin:$PATH"
	append_to_zshrc 'export PATH="$HOME/.claude/bin:$PATH"'
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

install_dotnet_ef() {
	if ! dotnet tool list --global 2>/dev/null | grep -q dotnet-ef; then
		run_quiet "Installing dotnet-ef" dotnet tool install --global dotnet-ef
	fi
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INSTALL
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

install_claude_code

init_brew_env
brew_update
install_brew_formulas "${BREW_FORMULAS[@]}"
install_brew_casks "${BREW_CASKS[@]}"

install_bun
install_dotnet_ef
configure_nvm
configure_pnpm
