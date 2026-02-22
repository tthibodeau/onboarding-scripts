#!/usr/bin/env bash

if [ "$EUID" -eq 0 ]; then
  echo "❌ Do not run script with sudo"
  exit 1
fi

# Ask for the sudo password upfront for commands that need it later
echo "🔑 Your sudo password is required for installation. Please enter it now:"
sudo -v

install_ohmyzsh()
{
  ZSHRC="$HOME/.zshrc"
  ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

  # oh-my-zsh install (https://ohmyz.sh/)
  /bin/bash -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  # sudo /bin/bash -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --keep-zshrc --unattended
  # Install PowerLevel10k theme:
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
  # Zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
  # Zsh syntax highlighting
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

  # tweaks
  # Set theme to PowerLevel10K:
  sed -i -r 's/^ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' $ZSHRC
  # Enable a bunch of great auto-completion plugins to .zshrc:
  sed -i -r 's/^plugins=\(.*\)/plugins=\(git brew docker mvn kubectl zsh-autosuggestions zsh-syntax-highlighting\)/g' $ZSHRC

  # Fix for NTFS directory color being unreadable green background color
  # https://blog.jongallant.com/2020/06/wsl-ls-folder-highlight/
  echo 'LS_COLORS=$LS_COLORS:'\''ow=1;34:'\'' ; export LS_COLORS' >> $ZSHRC
  echo 'export SHELL=$(which zsh)' >> $ZSHRC

  echo "🔄 Changing default shell to zsh..."
  # change default shell to zsh
  if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s $(which zsh) $(whoami)
  fi

  echo
  echo '┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓'
  echo '┃                                                       ┃'
  echo '┃   ⚡ Change your terminal font to MesloLGM NerdFont   ┃'
  echo '┃                                                       ┃'
  echo '┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛'
  echo
  read -p "Press the [Enter] key when you've changed your terminal font to MesloLGM NerdFont"

  zsh
}



if [[ "$OSTYPE" == "linux-gnu"* ]]
then
	echo "🐧 Linux install..."

  sudo apt-get update && sudo apt-get install -y curl git zsh

elif [[ "$OSTYPE" == "darwin"* ]]
then
	echo "🍎 MacOS install..."
    # Set the brew shell environment variables (using command found with "which brew" to automatically use the right path)
    # as Brew uses different paths for Apple Silicon and Intel Macs
    # See https://docs.brew.sh/Installation#unattended-installation

    eval "$($(which brew) shellenv)"
    brew update
    brew install zsh
    brew install curl
    brew install zsh-completions

    # Nerd Font for proper oh-my-zsh display
    brew install --cask font-meslo-lg-nerd-font


fi

install_ohmyzsh
