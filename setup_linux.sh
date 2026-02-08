#!/bin/bash
############################
# setup_linux.sh
# One-script VPS dev environment setup
# Usage: git clone <dotfiles repo> ~/dotfiles && ~/dotfiles/setup_linux.sh
############################

set -e

# get dotfiles dir
DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# get sudo privs upfront
sudo -v

echo "=============================="
echo "  Linux VPS Dev Environment"
echo "=============================="

# ===== 1. APT packages =====
echo ""
echo ">>> Installing apt packages..."
sudo apt-get update
sudo apt-get install -y \
    zsh \
    tmux \
    fzf \
    eza \
    fd-find \
    ripgrep \
    git \
    curl \
    unzip \
    build-essential \
    mosh \
    python3-pip \
    python3-venv \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncursesw5-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev

# ===== 2. Node.js (needed by Mason for LSP servers like pyright, jsonls) =====
echo ""
echo ">>> Installing node.js..."
if command -v node &>/dev/null; then
    echo "node already installed: $(node --version)"
else
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo "node installed: $(node --version)"
fi

# ===== 3. Pyenv + Python =====
echo ""
echo ">>> Installing pyenv..."
$DOTFILES/bin/install_pyenv.sh
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"

PYTHON_VERSION="3.12.8"
if pyenv versions --bare | grep -q "^${PYTHON_VERSION}$"; then
    echo "Python $PYTHON_VERSION already installed"
else
    echo "Installing Python $PYTHON_VERSION (this takes a few minutes)..."
    pyenv install $PYTHON_VERSION
fi
pyenv global $PYTHON_VERSION
echo "Python: $(python --version)"

# ===== 4. Neovim (latest stable appimage - apt version is too old) =====
echo ""
echo ">>> Installing neovim..."
if command -v nvim &>/dev/null; then
    echo "neovim already installed: $(nvim --version | head -1)"
else
    curl -Lo /tmp/nvim-linux-x86_64.tar.gz \
        https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    sudo tar -C /opt -xzf /tmp/nvim-linux-x86_64.tar.gz
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm -f /tmp/nvim-linux-x86_64.tar.gz
    echo "neovim installed: $(nvim --version | head -1)"
fi

# ===== 5. Starship prompt =====
echo ""
echo ">>> Installing starship..."
if command -v starship &>/dev/null; then
    echo "starship already installed"
else
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# ===== 6. Oh-my-zsh =====
echo ""
echo ">>> Installing oh-my-zsh..."
$DOTFILES/bin/install_oh_my_zsh.sh

# ===== 7. Zsh syntax highlighting =====
echo ""
echo ">>> Installing zsh-syntax-highlighting..."
$DOTFILES/bin/install_zsh_syntax_highlighting.sh

# ===== 8. TPM (Tmux Plugin Manager) =====
echo ""
echo ">>> Installing TPM..."
$DOTFILES/bin/install_tpm.sh

# ===== 9. Symlink dotfiles =====
echo ""
echo ">>> Symlinking dotfiles..."
$DOTFILES/bin/symlink_files.sh

# ===== 10. Set zsh as default shell =====
echo ""
echo ">>> Setting zsh as default shell..."
$DOTFILES/bin/set_zsh_linux.sh

# ===== 11. Install TPM plugins =====
echo ""
echo ">>> Installing tmux plugins..."
# TPM plugin install needs tmux server - start one if not running
if ! tmux has-session 2>/dev/null; then
    tmux new-session -d -s _setup
    $DOTFILES/bin/update_tpm_plugins.sh
    tmux kill-session -t _setup 2>/dev/null
else
    $DOTFILES/bin/update_tpm_plugins.sh
fi

echo ""
echo "=============================="
echo "  Setup complete!"
echo ""
echo "  Next steps:"
echo "  1. Log out and back in (or run: exec zsh)"
echo "  2. Start tmux: t"
echo "  3. Open nvim - LazyVim will auto-install plugins on first launch"
echo "=============================="
