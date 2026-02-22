#!/usr/bin/env bash

if [[ "$OSTYPE" == "linux-gnu"* ]]
then
	echo "🐧 Linux install..."


elif [[ "$OSTYPE" == "darwin"* ]]
then
	echo "🍎 MacOS install..."


fi

# Set the brew shell environment variables (using command found with "which brew" to automatically use the right path)
# as Brew uses different paths for Apple Silicon and Intel Macs
# See https://docs.brew.sh/Installation#unattended-installation
eval "$($(which brew) shellenv)"

echo '📥 Azure-CLI Installing...'
brew update
brew install azure-cli

# Azure command-line auto-completion
source $(find $HOMEBREW_CELLAR -regex '.*azure-cli.*/etc/bash_completion.d/az')
echo 'source $(find $HOMEBREW_CELLAR -regex ".*azure-cli.*/etc/bash_completion.d/az")' >> ~/.zshrc

echo "autoload bashcompinit && bashcompinit" >> ~/.zshrc
echo "autoload -Uz compinit && compinit" >> ~/.zshrc

echo "✅ Azure-CLI installed successfully"


