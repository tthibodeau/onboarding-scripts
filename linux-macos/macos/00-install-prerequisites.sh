#!/usr/bin/env bash
echo "🍎 MacOS install..."

arch=$(sysctl -n machdep.cpu.brand_string)
if [[ "$arch" == *"Apple"* ]]; then
	echo "✅ This Mac is using Apple Silicon."
else
	echo "✅ This Mac is using an Intel processor."
fi

mac_brew_cask_apps=(
	powershell
	1password
	1password-cli
)

brew update

for app in "${mac_brew_cask_apps[@]}"; do
	brew install --cask "$app"
done
