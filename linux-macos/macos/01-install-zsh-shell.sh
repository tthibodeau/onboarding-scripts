#!/usr/bin/env bash
echo "🍎 MacOS install..."

# Set the brew shell environment variables (using command found with "which brew" to automatically use the right path)
# as Brew uses different paths for Apple Silicon and Intel Macs
# See https://docs.brew.sh/Installation#unattended-installation
eval "$($(which brew) shellenv)"
brew update
brew install zsh
brew install curl
brew install zsh-completions

# Nerd Font for proper oh-my-zsh display
brew install --cask font-meslo-lg-nerd-font
