#!/usr/bin/env bash

if [ "$EUID" -eq 0 ]; then
  echo "Do not run script with sudo"
  exit 1
fi

# Ask for the sudo password upfront for commands that need it later
echo "Your sudo password is required for installation. Please enter it now:"
sudo -v

if [[ "$OSTYPE" == "linux-gnu"* ]]
then

	if [ -n "$WSL_DISTRO_NAME" ]; then
		echo "WSL detected. Verifying Docker Desktop integration..."
		echo ""

		# Verify Docker Desktop is accessible from WSL by testing the daemon
		if command -v docker &> /dev/null && docker info &> /dev/null; then
			echo "✅ Docker Desktop integration is active"
			echo ""
			echo "Docker (via Docker Desktop for Windows):"
			docker --version
			docker compose version
			echo ""
			echo "Note: Docker daemon runs on Windows host, accessed from WSL"
		else
			echo "⚡ Docker Desktop integration not detected or not running."
			echo ""
			echo "Please ensure Docker Desktop is configured for WSL:"
			echo "  1. Ensure Docker Desktop was installed via 02-install-development-tools.ps1"
			echo "  2. Start Docker Desktop on Windows (if not running)"
			echo "  3. In Docker Desktop settings → Resources → WSL Integration:"
			echo "     - Enable 'Use the WSL 2 based engine'"
			echo "     - Enable integration for '$WSL_DISTRO_NAME'"
			echo "  4. Apply & Restart, then restart WSL: wsl --shutdown (from PowerShell)"
			echo ""
			exit 1
		fi
	else
		# Native Linux installation
		echo "📥 Installing Docker Engine..."
		echo ""

		echo "Installing Docker CLI tools..."
		sudo apt-get update
		sudo apt-get install docker.io -y

		echo ""
		echo "Docker Installed: "
		docker --version
		docker compose version
		echo ""

		# Allow regular user to execute docker commands
		sudo groupadd docker > /dev/null 2>&1
		sudo usermod -aG docker $USER > /dev/null 2>&1

		echo "✅ Docker Engine installed successfully"
		echo "Note: You may need to log out and back in for group changes to take effect"
	fi

elif [[ "$OSTYPE" == "darwin"* ]]
then
  echo "📥 MacOS install..."


  install_docker_desktop_macos() {
    echo "Installing Docker..."

    CPU_ARCHITECTURE=$(uname -m)
    if [[ "$CPU_ARCHITECTURE" != "arm64" ]]; then
      CPU_ARCHITECTURE="amd64"
    fi

    curl https://desktop.docker.com/mac/main/$CPU_ARCHITECTURE/Docker.dmg --output docker-desktop-4.11.0-$CPU_ARCHITECTURE.dmg

    sudo hdiutil attach docker-desktop-4.11.0-$CPU_ARCHITECTURE.dmg
    sudo /Volumes/Docker/Docker.app/Contents/MacOS/install --accept-license
    sudo hdiutil detach /Volumes/Docker
  }

  install_docker_desktop_macos
fi


# Set the brew shell environment variables (using command found with "which brew" to automatically use the right path)
# as Brew uses different paths for Apple Silicon and Intel Macs
# See https://docs.brew.sh/Installation#unattended-installation
eval "$($(which brew) shellenv)"
brew update
brew install kubernetes-cli
# set kubernetes editor
export KUBE_EDITOR=nano
