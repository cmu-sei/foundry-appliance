#!/bin/bash
set -euo pipefail

# Show uncommitted changes in Zsh prompt
git config devcontainers-theme.show-dirty 1

sudo chown -R $(whoami): /home/vscode/.config/packer

# Install Pure prompt
mkdir -p "$HOME/.zsh"
git clone https://github.com/sindresorhus/pure.git "$HOME/.zsh/pure"
sed -i "s|^ZSH_THEME=.*|ZSH_THEME=\"\"\n\nFPATH=\$HOME/.zsh/pure:\$FPATH|" $HOME/.zshrc

cat >>$HOME/.zshrc <<'EOF'

# Pure prompt
autoload -U promptinit; promptinit
prompt pure
psvar[13]=''  # set Pure prompt username to blank
EOF
