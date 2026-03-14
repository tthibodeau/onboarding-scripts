#!/usr/bin/env bash

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

	case "$PKG_MANAGER" in
		apt)
			echo "Installing Docker CLI tools..."
			pkg_update
			pkg_install docker.io
			;;
		dnf)
			echo "Installing Docker CE..."
			sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
			pkg_install docker-ce docker-ce-cli containerd.io docker-compose-plugin
			sudo systemctl enable --now docker
			;;
		pacman)
			echo "Installing Docker..."
			pkg_install docker docker-compose
			sudo systemctl enable --now docker
			;;
	esac

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
