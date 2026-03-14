#!/usr/bin/env bash
echo "🍎 MacOS install..."

# Set the brew shell environment variables (using command found with "which brew" to automatically use the right path)
# as Brew uses different paths for Apple Silicon and Intel Macs
# See https://docs.brew.sh/Installation#unattended-installation
eval "$($(which brew) shellenv)"

curl -fsSL https://claude.ai/install.sh | bash
export PATH="$HOME/.claude/bin:$PATH"
append_to_zshrc 'export PATH="$HOME/.claude/bin:$PATH"'

macos_brew_cask_apps=(
	fork
	jetbrains-toolbox
	visual-studio-code
	postman
	insomnia
	redisinsight
	openvpn-connect
	dotnet-sdk9
)

brew update

# Install MacOS brew cask apps
for app in "${macos_brew_cask_apps[@]}"; do
	brew install --cask "$app"
done

# Install .NET Entity Framework Core tools
if ! dotnet tool list --global | grep -q dotnet-ef; then
	dotnet tool install --global dotnet-ef
else
	echo "✅ dotnet-ef is already installed."
fi
