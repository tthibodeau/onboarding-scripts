#!/usr/bin/env bash

if [ "$EUID" -eq 0 ]; then
  echo "❌ Do not run script with sudo"
  exit 1
fi

# Ask for the sudo password upfront for commands that need it later
echo "🔑 Your sudo password is required for installation. Please enter it now:"
sudo -v


###################################################
# Add to list of common brew apps for MacOS & Linux
###################################################
common_apps=(
  git
  gcc
  sevenzip
  zip
  unzip
)

################################################
# Add to list of MacOS brew cask apps to install
################################################
mac_brew_cask_apps=(
  powershell
  1password
  1password-cli
)

install_common()
{
    #############################################################################
    # CALL THIS AFTER LINUX APT INSTALLS OR SUDO GETS CLEARED BY HOMEBREW INSTALL
    #############################################################################

    echo "📥 Homebrew package manager Installing..."
    # No need for sudo here since Homebrew doesn't recommend it
    NONINTERACTIVE=1 /bin/bash -c "$(curl --silent --show-error --location --fail https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Set the brew shell environment variables (using command found with "which brew" to automatically use the right path)
    # as Brew uses different paths for Apple Silicon and Intel Macs and Linux
    # See https://docs.brew.sh/Installation#unattended-installation

    # Must be done on first run for Linux
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    eval "$($(which brew) shellenv)"

    brew update
    echo "📦 Installing common apps..."
    for app in "${common_apps[@]}"; do
        brew install "$app"
    done

    # Add brew shell environment variables to shell profiles
    echo 'eval $($(which brew) shellenv)' >> ~/.profile
    echo 'eval $($(which brew) shellenv)' >> ~/.bashrc
    echo 'eval $($(which brew) shellenv)' >> ~/.zshrc

    echo
}

configure_git() {
	echo "🔧 Configuring Git..."

	# Configure Git to ensure line endings are correct
	# For compatibility, line endings are converted to Unix style when you commit files
	git config --global core.autocrlf false

	# Check if Git user.name and user.email are already set
	currentGitName=$(git config --global user.name)
	currentGitEmail=$(git config --global user.email)

	if [ -z "$currentGitName" ]; then
		read -p "Enter your Git commit Name (for commits): " gitName
		git config --global user.name "$gitName"
		echo "✅ Git commit Name set to: $gitName"
	else
		echo "Git commit Name is already set to: $currentGitName"
	fi

	if [ -z "$currentGitEmail" ]; then
		read -p "Enter your Git commit Email (for commits): " gitEmail
		git config --global user.email "$gitEmail"
		echo "✅ Git commit Email set to: $gitEmail"
	else
		echo "Git commit Email is already set to: $currentGitEmail"
	fi

	echo "✅ Git configuration complete"
	echo
}


install_macos_prerequisites() {
    echo "🍎 MacOS install..."
    arch=$(sysctl -n machdep.cpu.brand_string)
    if [[ "$arch" == *"Apple"* ]]; then
      echo "✅ This Mac is using Apple Silicon."
    else
      echo "✅ This Mac is using an Intel processor."
    fi


    brew update

    for app in "${mac_brew_cask_apps[@]}"; do
      brew install --cask "$app"
    done
}

install_linux_prerequisites() {
  echo "🐧 Linux install..."

  # powershell requires the Microsoft repository to be added
  wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
  sudo dpkg -i packages-microsoft-prod.deb
  rm packages-microsoft-prod.deb
  # Define list of required packages
  linux_packages=(
    curl
    git
    wget
    gpg
    unzip
    zip
    jq
    build-essential
    powershell
  )

  sudo apt-get update && sudo apt-get install -y "${linux_packages[@]}"


    install_1Password_CLI(){
      echo
      echo "📥 1Password-CLI Installing..."
      echo

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

      # Install 1Password CLI
      sudo apt-get update && sudo apt-get install -y 1password-cli

      # brew install --cask 1password-cli

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

    install_1Password_CLI

    ######################################################################################
    # This is only required for native Linux, not WSL
    # Install Nerd-fonts
    # Meslo is recommended
    # curl -Lo MesloNerdFont.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Meslo.zip

    # sudo mkdir /usr/share/fonts/MesloNerdFont/ -p
    # sudo unzip MesloNerdFont.zip -d /usr/share/fonts/MesloNerdFont/
    # sudo rm MesloNerdFont.zip
    # fc-cache -fv
    ######################################################################################
}

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  install_linux_prerequisites
elif [[ "$OSTYPE" == "darwin"* ]]; then
  install_macos_prerequisites
fi


#############################################################################
# CALL install_common AFTER LINUX APT INSTALLS OR SUDO GETS CLEARED BY HOMEBREW INSTALL
#############################################################################

install_common
configure_git
