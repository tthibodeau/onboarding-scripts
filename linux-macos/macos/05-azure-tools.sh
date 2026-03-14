#!/usr/bin/env bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/shared.sh"

assert_not_root

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# APP LISTS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BREW_FORMULAS=(
	azure-cli
)

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INSTALL
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

init_brew_env
brew_update
install_brew_formulas "${BREW_FORMULAS[@]}"

# Azure CLI auto-completion
source $(find $HOMEBREW_CELLAR -regex '.*azure-cli.*/etc/bash_completion.d/az')
append_to_zshrc 'autoload bashcompinit && bashcompinit'
append_to_zshrc 'autoload -Uz compinit && compinit'
append_to_zshrc 'source $(find $HOMEBREW_CELLAR -regex ".*azure-cli.*/etc/bash_completion.d/az")'
