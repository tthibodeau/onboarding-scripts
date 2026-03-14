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
			status "✅ Docker Desktop integration is active (via WSL)"
		else
			status "⚠️  Docker Desktop not detected. Enable WSL integration in Docker Desktop settings."
		fi
		return
	fi

	case "$PKG_MANAGER" in
		apt)
			pkg_update
			pkg_install docker.io docker-compose-v2
			;;
		dnf)
			sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
			pkg_install docker-ce docker-ce-cli containerd.io docker-compose-plugin
			sudo systemctl enable --now docker
			;;
		pacman)
			pkg_install docker docker-compose
			sudo systemctl enable --now docker
			;;
	esac

	sudo groupadd docker > /dev/null 2>&1
	sudo usermod -aG docker $USER > /dev/null 2>&1
	log_note "Log out and back in for Docker group membership to take effect"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INSTALL — sudo-dependent installs first, Homebrew last
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

run_quiet "Installing Docker" install_docker

init_brew_env
brew_update
install_brew_formulas "${BREW_FORMULAS[@]}"

export KUBE_EDITOR=nano
