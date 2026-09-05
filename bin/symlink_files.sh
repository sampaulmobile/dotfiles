#!/bin/bash
############################
# symlink_files.sh
# This script creates symlinks for ALL THE FILES
############################

########## Variables

# dotfiles directory
dir=$HOME/dotfiles/dots

# machine-local config (untracked — see other/README.md)
other=$HOME/dotfiles/other

# backup directory (per run, so reruns never collide with an older backup)
deldir=$HOME/DELETE_dotfiles-$(date +%Y%m%d-%H%M%S)

# detect OS
OS="$(uname -s)"

##########

# create backup dir
mkdir -p $deldir

# Helper: backup existing file, then symlink. An existing SYMLINK is just
# removed (its target is safe; a rerun of this script is the common case) —
# moving it into a backup dir that already held a same-named link is what
# used to nest stale links inside their own targets. Real files/dirs are
# backed up to $deldir.
link() {
    if [[ -L "$2" ]]; then
        rm "$2"
    elif [[ -e "$2" ]]; then
        mv "$2" "$deldir/"
    fi
    ln -sv "$1" "$2"
}

# ===== Common dotfiles (both platforms) =====
common_files="gitconfig gitignore tmux.conf tmux.remote.conf"

for file in $common_files; do
    link $dir/$file ~/.$file
done

# ===== zshrc (platform-specific) =====
if [[ "$OS" == "Linux" ]]; then
    link $dir/zshrc_linux ~/.zshrc
else
    link $dir/zshrc ~/.zshrc
fi

# ===== other/ seeding =====
# create any missing other/**/<name> from its <name>.example first, so the
# claude block below has a settings.json to link on a fresh (or gappy) machine
echo "Seeding other/ machine-local config"
$HOME/dotfiles/bin/seed_other.sh

# ===== claude code =====
# settings.json is a file link (~/.claude itself holds machine state).
# ~/.claude/{skills,rules,agents} are whole-directory links into other/claude/
# (private, gitignored) — anything dropped there is private by default. The
# tracked generic set in dots/claude/ is layered in as per-item RELATIVE links
# inside those dirs, so both kinds show up under ~/.claude. Promote a private
# item by moving it to dots/claude/<kind>/ and re-running this script; a
# private entry with the same name as a tracked one is left alone (warned).
mkdir -p ~/.claude $other/claude/skills $other/claude/rules $other/claude/agents
[[ -f $other/claude/settings.json ]] && link $other/claude/settings.json ~/.claude/settings.json
for kind in skills rules agents; do
    link $other/claude/$kind ~/.claude/$kind
    # prune dangling links (tracked item removed or renamed)
    for entry in $other/claude/$kind/*; do
        [[ -L "$entry" && ! -e "$entry" ]] && rm -v "$entry"
    done
    for src in $dir/claude/$kind/*; do
        [[ -e "$src" ]] || continue
        name=$(basename "$src")
        dst=$other/claude/$kind/$name
        if [[ -e "$dst" && ! -L "$dst" ]]; then
            echo "WARN: $dst is a private $kind entry shadowing the tracked one — left as is" >&2
            continue
        fi
        ln -sfnv "../../../dots/claude/$kind/$name" "$dst"
    done
done

# ===== starship =====
mkdir -p ~/.config
link $dir/starship.toml ~/.config/starship.toml

# ===== worktrunk =====
mkdir -p ~/.config/worktrunk
link $dir/worktrunk.toml ~/.config/worktrunk/config.toml

# ===== neovim (LazyVim config) =====
link $dir/nvim ~/.config/nvim

# ===== ghostty =====
link $dir/ghostty ~/.config/ghostty

echo ""
echo "Symlinks created successfully!"
if rmdir "$deldir" 2>/dev/null; then
    echo "Nothing needed backing up."
else
    echo "Old dotfiles backed up to: $deldir"
    read -p "Delete backup directory? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$deldir"
        echo "Backup deleted."
    fi
fi
