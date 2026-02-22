#!/usr/bin/env bash

if [ "$EUID" -eq 0 ]; then
	echo "❌ Do not run script with sudo"
	exit 1
fi

# Ask for the sudo password upfront for commands that need it later
echo "🔑 Your sudo password is required for installation. Please enter it now:"
sudo -v

################################################
# Add to list of MacOS brew cask apps to install
################################################

common_brew_apps=(
	nvm
	pnpm
	act
	nuget
)

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

install_linux_tools() {
	# echo "Linux install..."
	return 0
	# brew update
}

install_common_tools(){
	brew update
	# Install Common brew apps
	for app in "${common_brew_apps[@]}"; do
		brew install "$app"
	done

	configure_pnpm() {
		cat >>~/.zshrc <<-'EOL'
			# pnpm shorthand
			p() { pnpm "$@"; }
		EOL
		echo "✅ Installed pnpm version: $(pnpm -v)" # Should show version
	}

	configure_nvm() {
		mkdir ~/.nvm
		# Adds NVM configuration to .zshrc for persistence in a single command
		cat >>~/.zshrc <<-'EOL'
			export NVM_DIR="$HOME/.nvm"
			[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"                                       # This loads nvm
			[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion
		EOL

		# For current shell session
		export NVM_DIR="$HOME/.nvm"
		[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"                                       # This loads nvm
		[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

		if ! nvm ls 23 &>/dev/null; then
			echo "📥 Installing Node.js v23 using NVM (Node Version Manager)..."
			nvm install 23
			nvm use 23
			nvm alias default 23
		else
			echo "✅ Node.js 23 is already installed."

		fi
		echo "✅ Installed Node.js version: $(node -v)" # Should show v23.x
	}

	configure_nvm
	configure_pnpm
	echo "✅ Common development tools installed successfully."
}

install_mac_tools() {
	echo "🍎 MacOS install..."

	# Set the brew shell environment variables (using command found with "which brew" to automatically use the right path)
	# as Brew uses different paths for Apple Silicon and Intel Macs
	# See https://docs.brew.sh/Installation#unattended-installation
	eval "$($(which brew) shellenv)"

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

}

install_V1_dev_tools() {
	read -p "Do you want to install the V1 Provision application development tools? (y/N): " install_v1
	if [[ "$install_v1" =~ ^[Yy]$ ]]; then
		echo "📥 Installing V1 Provision application development tools..."
	else
		echo "⏭️  Skipping V1 Provision application development tools installation."
		return
	fi

	brew install maven node eslint sass/sass/sass n # n - node version management

	# Install SDKMAN https://sdkman.io/install
	curl -s "https://get.sdkman.io" | bash
	source "$HOME/.sdkman/bin/sdkman-init.sh"

	# https://www.oracle.com/java/technologies/javase/jdk11-archive-downloads.html
	# Adoptium Eclipse-Temurin is the recommended Java JDK now...wait 5 minutes til that changes..https://adoptium.net/installation/
	sdk install java 11.0.16-tem 2>/dev/null #ignore all the lchmod errors. It's caused by brew/unzip compilation stuff https://github.com/sdkman/sdkman-cli/issues/790
	# sdk install java 2> /dev/null  #ignore all the lchmod errors. It's caused by brew/unzip compilation stuff https://github.com/sdkman/sdkman-cli/issues/790
}

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	install_linux_tools
elif [[ "$OSTYPE" == "darwin"* ]]; then
	install_mac_tools
fi
install_common_tools
install_V1_dev_tools

# No apt commands found - file is already compatible
