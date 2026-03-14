#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shared.sh"

assert_not_root
prompt_sudo

common_brew_apps=(
	nvm
	pnpm
	act
	nuget
)

# Run platform-specific installs
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	source "$SCRIPT_DIR/linux/02-install-development-tools.sh"
elif [[ "$OSTYPE" == "darwin"* ]]; then
	source "$SCRIPT_DIR/macos/02-install-development-tools.sh"
fi

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

	if ! nvm ls 23 &>/dev/null; then
		echo "📥 Installing Node.js v23 using NVM (Node Version Manager)..."
		nvm install 23
		nvm use 23
		nvm alias default 23
	else
		echo "✅ Node.js 23 is already installed."
	fi
	echo "✅ Installed Node.js version: $(node -v)" # Should show v23.x
}

configure_pnpm() {
	append_to_zshrc 'p() { pnpm "$@"; }'
	echo "✅ Installed pnpm version: $(pnpm -v)" # Should show version
}

configure_nvm
configure_pnpm
echo "✅ Common development tools installed successfully."
