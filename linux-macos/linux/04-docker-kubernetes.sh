#!/usr/bin/env bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/shared.sh"

assert_not_root
prompt_sudo

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# APP LISTS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BREW_FORMULAS=(
	kubernetes-cli
)

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CUSTOM INSTALLS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

install_docker() {
	if [ -n "$WSL_DISTRO_NAME" ]; then
		if command -v docker &> /dev/null && docker info &> /dev/null; then
			echo "Docker Desktop integration is active (via WSL)"
		else
			echo "Docker Desktop not detected. Enable WSL integration in Docker Desktop settings."
		fi
		return
	fi

	if command -v docker &>/dev/null && docker --version 2>/dev/null | grep -q "Docker"; then
		echo "Docker already installed: $(docker --version)"
		return
	fi

	# Docker Desktop for Linux (includes Engine, Compose, Kubernetes)
	case "$PKG_MANAGER" in
		apt)
			# Install Docker Desktop dependencies
			sudo apt-get update
			sudo apt-get install -y ca-certificates curl gnupg

			# Add Docker's official GPG key and repository
			sudo install -m 0755 -d /etc/apt/keyrings
			curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
			echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
				| sudo tee /etc/apt/sources.list.d/docker.list
			sudo apt-get update

			# Download and install Docker Desktop .deb
			local deb_url="https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb"
			curl -fsSLo /tmp/docker-desktop.deb "$deb_url"
			sudo apt-get install -y /tmp/docker-desktop.deb
			rm -f /tmp/docker-desktop.deb
			;;
		dnf)
			sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
			local rpm_url="https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm"
			curl -fsSLo /tmp/docker-desktop.rpm "$rpm_url"
			sudo dnf install -y /tmp/docker-desktop.rpm
			rm -f /tmp/docker-desktop.rpm
			;;
		pacman)
			AUR_HELPER=$(get_aur_helper)
			$AUR_HELPER -S --needed --noconfirm docker-desktop
			;;
	esac

	# Enable Docker Desktop service
	systemctl --user enable docker-desktop 2>/dev/null || true

	sudo groupadd docker > /dev/null 2>&1
	sudo usermod -aG docker $USER > /dev/null 2>&1

	log_note "Run 'newgrp docker' or log out/in to use Docker without sudo"
	log_note "Launch Docker Desktop from your application menu to start the engine"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INSTALL — sudo-dependent installs first, Homebrew last
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

run_quiet "Installing Docker" install_docker

init_brew_env
brew_update
install_brew_formulas "${BREW_FORMULAS[@]}"

export KUBE_EDITOR=nano
