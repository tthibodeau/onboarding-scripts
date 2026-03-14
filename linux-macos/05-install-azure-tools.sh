#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shared.sh"

assert_not_root

# Common: Azure CLI (same for both platforms via Homebrew)
init_brew_env

echo '📥 Azure-CLI Installing...'
brew update
brew install azure-cli

# Azure command-line auto-completion
source $(find $HOMEBREW_CELLAR -regex '.*azure-cli.*/etc/bash_completion.d/az')
append_to_zshrc 'autoload bashcompinit && bashcompinit'
append_to_zshrc 'autoload -Uz compinit && compinit'
append_to_zshrc 'source $(find $HOMEBREW_CELLAR -regex ".*azure-cli.*/etc/bash_completion.d/az")'

echo "✅ Azure-CLI installed successfully"
