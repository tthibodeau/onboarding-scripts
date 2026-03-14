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
echo 'source $(find $HOMEBREW_CELLAR -regex ".*azure-cli.*/etc/bash_completion.d/az")' >> ~/.zshrc

echo "autoload bashcompinit && bashcompinit" >> ~/.zshrc
echo "autoload -Uz compinit && compinit" >> ~/.zshrc

echo "✅ Azure-CLI installed successfully"
