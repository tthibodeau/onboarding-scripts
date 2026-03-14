#!/usr/bin/env bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/shared.sh"

assert_not_root
prompt_sudo

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# APP LISTS — edit these to add/remove apps
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BREW_FORMULAS=(
	git
	gcc
	sevenzip
	zip
	unzip
)

BREW_CASKS=(
	powershell
	1password
	1password-cli
)

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INSTALL
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Install Homebrew
run_quiet "Installing Homebrew" bash -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl --silent --show-error --location --fail https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
init_brew_env
brew_update

install_brew_formulas "${BREW_FORMULAS[@]}"
install_brew_casks "${BREW_CASKS[@]}"

# Add brew to shell profiles
append_to_profile ~/.profile 'command -v brew &>/dev/null && eval $($(which brew) shellenv)'
append_to_profile ~/.bashrc 'command -v brew &>/dev/null && eval $($(which brew) shellenv)'
append_to_zshrc 'eval $($(which brew) shellenv)'

configure_git
