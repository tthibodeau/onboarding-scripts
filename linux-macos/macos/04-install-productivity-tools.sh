#!/usr/bin/env bash
echo "🍎 MacOS install..."

init_brew_env

mac_brew_cask_apps=(
	iterm2
	warp
	brave-browser
	slack
	notion
)

brew update

for app in "${mac_brew_cask_apps[@]}"; do
	brew install --cask "$app"
done
