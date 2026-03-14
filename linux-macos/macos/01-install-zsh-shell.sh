#!/usr/bin/env bash
echo "🍎 MacOS install..."

init_brew_env
brew update
brew install zsh
brew install curl
brew install zsh-completions

# Nerd Font for proper oh-my-zsh display
brew install --cask font-meslo-lg-nerd-font
