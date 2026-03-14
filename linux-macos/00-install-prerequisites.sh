#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shared.sh"

assert_not_root
prompt_sudo

###################################################
# Add to list of common brew apps for MacOS & Linux
###################################################
common_apps=(
	git
	gcc
	sevenzip
	zip
	unzip
)

# Run platform-specific prerequisites
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	source "$SCRIPT_DIR/linux/00-install-prerequisites.sh"
elif [[ "$OSTYPE" == "darwin"* ]]; then
	source "$SCRIPT_DIR/macos/00-install-prerequisites.sh"
fi

#############################################################################
# CALL AFTER LINUX APT INSTALLS OR SUDO GETS CLEARED BY HOMEBREW INSTALL
#############################################################################

echo "📥 Homebrew package manager Installing..."
# No need for sudo here since Homebrew doesn't recommend it
NONINTERACTIVE=1 /bin/bash -c "$(curl --silent --show-error --location --fail https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

init_brew_env

brew update
echo "📦 Installing common apps..."
for app in "${common_apps[@]}"; do
	brew install "$app"
done

# Add brew shell environment variables to shell profiles
echo 'eval $($(which brew) shellenv)' >> ~/.profile
echo 'eval $($(which brew) shellenv)' >> ~/.bashrc
echo 'eval $($(which brew) shellenv)' >> ~/.zshrc

echo

configure_git
