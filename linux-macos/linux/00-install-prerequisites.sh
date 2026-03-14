#!/usr/bin/env bash
echo "🐧 Linux prerequisites install..."

pkg_update
pkg_install curl wget

# Add Microsoft repository for PowerShell
install_microsoft_repo() {
	case "$PKG_MANAGER" in
		apt)
			wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
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
			# PowerShell is available via AUR — requires an AUR helper (yay or paru)
			if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
				echo "📥 Installing yay (AUR helper)..."
				sudo pacman -S --needed --noconfirm base-devel git
				git clone https://aur.archlinux.org/yay.git /tmp/yay
				(cd /tmp/yay && makepkg -si --noconfirm)
				rm -rf /tmp/yay
			fi
			;;
	esac
}

install_microsoft_repo

# Define list of required packages (distro-specific names where they differ)
case "$PKG_MANAGER" in
	apt)
		linux_packages=(
			git wget gpg unzip zip jq
			build-essential
		)
		;;
	dnf)
		linux_packages=(
			git wget gnupg2 unzip zip jq
			gcc gcc-c++ make
		)
		;;
	pacman)
		linux_packages=(
			git wget gnupg unzip zip jq
			base-devel
		)
		;;
esac

pkg_update
pkg_install "${linux_packages[@]}"

# PowerShell — install separately (may not be available for all distro versions)
if ! command -v pwsh &>/dev/null; then
	case "$PKG_MANAGER" in
		apt|dnf)
			if ! pkg_install powershell 2>/dev/null; then
				echo "⚠️  PowerShell package not available. Installing via Homebrew..."
				init_brew_env
				brew install powershell
			fi
			;;
		pacman)
			AUR_HELPER=$(command -v yay || command -v paru)
			$AUR_HELPER -S --needed --noconfirm powershell-bin
			;;
	esac
else
	echo "✅ PowerShell is already installed: $(pwsh --version)"
fi

install_1Password() {
	echo
	echo "📥 1Password Installing..."
	echo

	case "$PKG_MANAGER" in
		apt)
			# Add the key for the 1Password apt repository
			curl -sS https://downloads.1password.com/linux/keys/1password.asc \
				| sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg --yes

			# Add the 1Password apt repository
			echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" \
				| sudo tee /etc/apt/sources.list.d/1password.list

			# Add the debsig-verify policy
			sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/

			curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol \
				| sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol

			sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22

			curl -sS https://downloads.1password.com/linux/keys/1password.asc \
				| sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg --yes

			# Install 1Password
			pkg_update
			pkg_install 1password-cli 1password
			;;
		dnf)
			# Add the 1Password RPM repository
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
			# 1Password is available via AUR
			AUR_HELPER=$(command -v yay || command -v paru)
			$AUR_HELPER -S --needed --noconfirm 1password 1password-cli
			;;
	esac

	# install 1password-cli Auto-Complete
	if [ "$SHELL" = "/bin/bash" ]; then
		source <(op completion bash)
	fi

	eval $(op completion zsh)

	# Add the 1Password SSH agent to the SSH configuration
	mkdir -p ~/.ssh
	echo "\
	Host *
		IdentityAgent ~/.1password/agent.sock" \
	>> ~/.ssh/config

	# Configure 1Password / Git integration for WSL
	if [ -n "$WSL_DISTRO_NAME" ]; then
		echo "🪟 WSL detected. Configuring 1Password / Git for WSL integration..."
		# Ensure WSL support (https://developer.1password.com/docs/ssh/integrations/wsl/)
		git config --global core.sshCommand "$(which ssh.exe)"

		# Create wrapper functions to use Windows OpenSSH (required for 1Password SSH agent)
		# Use which to dynamically locate the Windows binaries
		cat >>~/.zshrc <<-'EOL'
		# 1Password SSH integration for WSL - use Windows OpenSSH
		ssh() { "$(which ssh.exe)" "$@"; }
		ssh-add() { "$(which ssh-add.exe)" "$@"; }
EOL

		echo "✅ 1Password / Git for WSL integration configured"
		echo "⚡ Follow https://developer.1password.com/docs/ssh/integrations/wsl/#sign-git-commits-with-ssh for further 1Password WSL configuration details."
	else
		git config --global core.sshCommand "$(which ssh)"
		echo "✅ 1Password / Git SSH integration configured"
	fi

	echo "✅ 1Password-CLI installed successfully"
}

install_1Password

######################################################################################
# This is only required for native Linux, not WSL
# Install Nerd-fonts
# Meslo is recommended
curl -Lo MesloNerdFont.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Meslo.zip

sudo mkdir /usr/share/fonts/MesloNerdFont/ -p
sudo unzip -o MesloNerdFont.zip -d /usr/share/fonts/MesloNerdFont/
sudo rm MesloNerdFont.zip
fc-cache -fv
######################################################################################
