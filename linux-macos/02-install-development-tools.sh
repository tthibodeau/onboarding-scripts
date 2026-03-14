#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shared.sh"

assert_not_root
prompt_sudo

NODE_VERSION="23"

common_brew_apps=(
	nvm
	pnpm
	act
	nuget
)

# Run platform-specific installs (sudo-dependent — must run before Homebrew)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	source "$SCRIPT_DIR/linux/02-install-development-tools.sh"
elif [[ "$OSTYPE" == "darwin"* ]]; then
	source "$SCRIPT_DIR/macos/02-install-development-tools.sh"
fi

# Claude Code CLI (cross-platform)
curl -fsSL https://claude.ai/install.sh | bash
export PATH="$HOME/.claude/bin:$PATH"
append_to_zshrc 'export PATH="$HOME/.claude/bin:$PATH"'

# Common development tools
init_brew_env
brew update

for app in "${common_brew_apps[@]}"; do
	brew install "$app"
done

# Bun - use official install script (brew bottle not available on Linux)
curl -fsSL https://bun.sh/install | bash
append_to_zshrc 'export BUN_INSTALL="$HOME/.bun"'
append_to_zshrc 'export PATH="$BUN_INSTALL/bin:$PATH"'

configure_nvm() {
	mkdir -p ~/.nvm
	# Adds NVM configuration to .zshrc for persistence
	append_to_zshrc 'export NVM_DIR="$HOME/.nvm"'
	append_to_zshrc '[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"'
	append_to_zshrc '[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"'

	# For current shell session
	export NVM_DIR="$HOME/.nvm"
	[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"                                       # This loads nvm
	[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

	if ! nvm ls "$NODE_VERSION" &>/dev/null; then
		echo "📥 Installing Node.js v$NODE_VERSION using NVM (Node Version Manager)..."
		nvm install "$NODE_VERSION"
		nvm use "$NODE_VERSION"
		nvm alias default "$NODE_VERSION"
	else
		echo "✅ Node.js $NODE_VERSION is already installed."
	fi
	echo "✅ Installed Node.js version: $(node -v)"
}

configure_pnpm() {
	append_to_zshrc 'p() { pnpm "$@"; }'
	echo "✅ Installed pnpm version: $(pnpm -v)" # Should show version
}

configure_nvm
configure_pnpm
echo "✅ Common development tools installed successfully."
