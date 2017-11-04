
if [ ! -f /usr/local/bin/brew ]; then
    echo "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew bundle --no-upgrade --file=$HOME/dotfiles/links/Brewfile

