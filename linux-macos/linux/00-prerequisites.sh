#!/usr/bin/env bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/shared.sh"

assert_not_root
prompt_sudo

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# APP LISTS — edit these to add/remove apps
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

case "$PKG_MANAGER" in
	apt)    SYSTEM_PACKAGES=(git wget gpg unzip zip jq build-essential) ;;
	dnf)    SYSTEM_PACKAGES=(git wget gnupg2 unzip zip jq gcc gcc-c++ make) ;;
	pacman) SYSTEM_PACKAGES=(git wget gnupg unzip zip jq base-devel) ;;
esac

BREW_FORMULAS=(
	git
	gcc
	sevenzip
	zip
	unzip
	powershell
)

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CUSTOM INSTALLS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

install_microsoft_repo() {
	case "$PKG_MANAGER" in
		apt)
			wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
			sudo dpkg -i packages-microsoft-prod.deb
			rm packages-microsoft-prod.deb
			;;
		dnf)
			sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
			curl -sSL -o /tmp/microsoft.repo https://packages.microsoft.com/config/fedora/$(rpm -E %fedora)/prod.repo
			sudo cp /tmp/microsoft.repo /etc/yum.repos.d/microsoft-prod.repo
			rm /tmp/microsoft.repo
			;;
		pacman)
			if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
				sudo pacman -S --needed --noconfirm base-devel git
				git clone https://aur.archlinux.org/yay.git /tmp/yay
				(cd /tmp/yay && makepkg -si --noconfirm)
				rm -rf /tmp/yay
			fi
			;;
	esac
}

install_1password() {
	case "$PKG_MANAGER" in
		apt)
			curl -sS https://downloads.1password.com/linux/keys/1password.asc \
				| sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg --yes
			echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" \
				| sudo tee /etc/apt/sources.list.d/1password.list
			sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
			curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol \
				| sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
			sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
			curl -sS https://downloads.1password.com/linux/keys/1password.asc \
				| sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg --yes
			pkg_update
			pkg_install 1password-cli 1password
			;;
		dnf)
			sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
			sudo sh -c 'cat > /etc/yum.repos.d/1password.repo << REPO
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
REPO'
			pkg_install 1password-cli 1password
			;;
		pacman)
			AUR_HELPER=$(get_aur_helper)
			$AUR_HELPER -S --needed --noconfirm 1password 1password-cli
			;;
	esac

	if command -v op &>/dev/null; then
		eval "$(op completion zsh)"
	fi

	mkdir -p ~/.ssh
	echo "\
	Host *
		IdentityAgent ~/.1password/agent.sock" \
	>> ~/.ssh/config

	if [ -n "$WSL_DISTRO_NAME" ]; then
		git config --global core.sshCommand "$(which ssh.exe)"
		append_to_zshrc 'ssh() { "$(which ssh.exe)" "$@"; }'
		append_to_zshrc 'ssh-add() { "$(which ssh-add.exe)" "$@"; }'
		status "✅ 1Password WSL integration configured"
	else
		git config --global core.sshCommand "$(which ssh)"
		status "✅ 1Password SSH integration configured"
	fi
}

install_nerd_fonts() {
	if [ -d /usr/share/fonts/MesloNerdFont ] && [ -n "$(ls -A /usr/share/fonts/MesloNerdFont 2>/dev/null)" ]; then
		return
	fi
	curl -sLo /tmp/MesloNerdFont.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Meslo.zip
	sudo mkdir -p /usr/share/fonts/MesloNerdFont/
	sudo unzip -o /tmp/MesloNerdFont.zip -d /usr/share/fonts/MesloNerdFont/
	rm -f /tmp/MesloNerdFont.zip
	fc-cache -f
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INSTALL — sudo-dependent installs first, Homebrew last
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pkg_update
pkg_install curl wget
run_quiet "Adding Microsoft repository" install_microsoft_repo
pkg_update
pkg_install "${SYSTEM_PACKAGES[@]}"
run_quiet "Installing 1Password" install_1password
# Nerd fonts only needed on native Linux — WSL uses Windows-side fonts
if [ -z "$WSL_DISTRO_NAME" ]; then
	run_quiet "Installing Meslo Nerd Font" install_nerd_fonts
fi

# Homebrew installs last (resets sudo cache)
run_quiet "Installing Homebrew" bash -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl --silent --show-error --location --fail https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
init_brew_env
brew_update
install_brew_formulas "${BREW_FORMULAS[@]}"


append_to_profile ~/.profile 'command -v brew &>/dev/null && eval $($(which brew) shellenv)'
append_to_profile ~/.bashrc 'command -v brew &>/dev/null && eval $($(which brew) shellenv)'
append_to_zshrc 'eval $($(which brew) shellenv)'

configure_git
