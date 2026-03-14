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

install_docker_desktop() {
	CPU_ARCHITECTURE=$(uname -m)
	if [[ "$CPU_ARCHITECTURE" != "arm64" ]]; then
		CPU_ARCHITECTURE="amd64"
	fi

	curl -sL https://desktop.docker.com/mac/main/$CPU_ARCHITECTURE/Docker.dmg --output /tmp/Docker.dmg
	sudo hdiutil attach /tmp/Docker.dmg
	sudo /Volumes/Docker/Docker.app/Contents/MacOS/install --accept-license
	sudo hdiutil detach /Volumes/Docker
	rm -f /tmp/Docker.dmg
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INSTALL
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

run_quiet "Installing Docker Desktop" install_docker_desktop

init_brew_env
brew_update
install_brew_formulas "${BREW_FORMULAS[@]}"

export KUBE_EDITOR=nano
