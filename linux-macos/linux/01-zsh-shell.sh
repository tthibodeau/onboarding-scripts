#!/usr/bin/env bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/shared.sh"

assert_not_root
prompt_sudo

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# APP LISTS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SYSTEM_PACKAGES=(
	curl
	git
	zsh
)

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CUSTOM INSTALLS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

install_oh_my_zsh() {
	ZSHRC="$HOME/.zshrc"
	ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

	if [ ! -d "$HOME/.oh-my-zsh" ]; then
		run_quiet "Installing oh-my-zsh" bash -c 'curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash -s -- --unattended'
	fi

	[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ] || \
		run_quiet "Installing Powerlevel10k theme" git clone -q --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
	[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || \
		run_quiet "Installing zsh-autosuggestions" git clone -q https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
	[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || \
		run_quiet "Installing zsh-syntax-highlighting" git clone -q https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

	sed -i -r 's/^ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' "$ZSHRC"
	sed -i -r 's/^plugins=\(.*\)/plugins=\(git brew docker mvn kubectl zsh-autosuggestions zsh-syntax-highlighting\)/g' "$ZSHRC"

	append_to_zshrc "LS_COLORS=\$LS_COLORS:'ow=1;34:' ; export LS_COLORS"
	append_to_zshrc 'export SHELL=$(which zsh)'
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INSTALL
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pkg_update
pkg_install "${SYSTEM_PACKAGES[@]}"

install_oh_my_zsh

if [ "$SHELL" != "$(which zsh)" ]; then
	run_quiet "Changing default shell to zsh" sudo chsh -s $(which zsh) $(whoami)
fi

if [ -n "$WSL_DISTRO_NAME" ]; then
	status "⚡ Set your Windows Terminal font to MesloLGM NerdFont"
else
	status "⚡ Set your terminal font to MesloLGM NerdFont"
fi
status "✅ Zsh installation complete. Restart your terminal to use zsh."
