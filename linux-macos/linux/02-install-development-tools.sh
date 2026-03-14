#!/usr/bin/env bash
echo "🐧 Linux install..."

curl -fsSL https://claude.ai/install.sh | bash
export PATH="$HOME/.claude/bin:$PATH"
echo 'export PATH="$HOME/.claude/bin:$PATH"' >> ~/.zshrc

brew install --cask visual-studio-code
