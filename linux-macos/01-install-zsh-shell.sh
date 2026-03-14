#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shared.sh"

assert_not_root
prompt_sudo

# Run platform-specific installs
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	source "$SCRIPT_DIR/linux/01-install-zsh-shell.sh"
elif [[ "$OSTYPE" == "darwin"* ]]; then
	source "$SCRIPT_DIR/macos/01-install-zsh-shell.sh"
fi

# Common: install oh-my-zsh and plugins
ZSHRC="$HOME/.zshrc"
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# oh-my-zsh install (https://ohmyz.sh/)
/bin/bash -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

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
# change default shell to zsh (use sudo to avoid password prompt)
if [ "$SHELL" != "$(which zsh)" ]; then
	sudo chsh -s $(which zsh) $(whoami)
fi

echo
echo '┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓'
echo '┃                                                       ┃'
echo '┃   ⚡ Change your terminal font to MesloLGM NerdFont   ┃'
echo '┃                                                       ┃'
echo '┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛'
echo
echo "✅ Zsh installation complete. Restart your terminal to use zsh."
