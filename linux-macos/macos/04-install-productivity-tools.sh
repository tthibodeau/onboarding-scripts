#!/usr/bin/env bash
echo "🍎 MacOS install..."

arch=$(sysctl -n machdep.cpu.brand_string)
if [[ "$arch" == *"Apple"* ]]; then
	echo "✅ This Mac is using Apple Silicon."
else
	echo "✅ This Mac is using an Intel processor."
fi

# Set the brew shell environment variables (using command found with "which brew" to automatically use the right path)
# as Brew uses different paths for Apple Silicon and Intel Macs
# See https://docs.brew.sh/Installation#unattended-installation
eval "$($(which brew) shellenv)"

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
