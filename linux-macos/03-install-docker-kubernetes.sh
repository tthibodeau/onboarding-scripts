#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shared.sh"

assert_not_root
prompt_sudo

# Run platform-specific installs
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	source "$SCRIPT_DIR/linux/03-install-docker-kubernetes.sh"
elif [[ "$OSTYPE" == "darwin"* ]]; then
	source "$SCRIPT_DIR/macos/03-install-docker-kubernetes.sh"
fi

# Common: Kubernetes CLI
init_brew_env
brew update
brew install kubernetes-cli

# set kubernetes editor
export KUBE_EDITOR=nano
