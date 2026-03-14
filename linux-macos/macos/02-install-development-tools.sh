#!/usr/bin/env bash
echo "🍎 MacOS install..."

init_brew_env

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
