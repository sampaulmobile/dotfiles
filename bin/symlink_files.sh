#!/bin/bash
############################
# symlink_files.sh — create every symlink this repo owns.
#
#   symlink_files.sh          make each link that is missing or wrong, backing
#                             up any real file in the way. Correct links are
#                             left alone and NOT printed: the output is what
#                             changed, plus a summary.
#   symlink_files.sh --check  report only (MISSING / WRONG target / a real
#                             file INPLACE) and write nothing at all — no
#                             backup dir, no mkdir, no seeding. Exit 1 if
#                             anything is off. This is what bin/doctor runs.
############################

########## Variables

check=0
[[ "${1:-}" == "--check" || "${1:-}" == "-n" ]] && check=1
issues=0      # --check: links that are not as they should be
changed=0     # normal mode: links created or replaced
unchanged=0   # normal mode: links already correct (not listed)

# ~-shorten a path for the report lines
short() { case "$1" in "$HOME"/*) printf '~%s' "${1#"$HOME"}" ;; *) printf '%s' "$1" ;; esac; }

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
(( check )) || mkdir -p "$deldir"

# mkdir that the check mode skips (a report must not create directories)
ensure_dir() { (( check )) || mkdir -p "$@"; }

# Helper: make $2 a symlink to $1. A link already pointing at $1 is left
# untouched and unlisted — a rerun is the common case, and 30 unchanged
# lines bury the two that matter. A link pointing elsewhere is REPLACED, not
# backed up: its target is safe, and moving it into a backup dir that
# already holds a same-named link nests stale links inside their own
# targets. Only a real file/dir is backed up, to $deldir.
# --check compares only: correct is silent, anything else is one report line
# and one issue.
link() {
    local got
    if [[ -L "$2" ]]; then
        got=$(readlink "$2")
        if [[ "$got" == "$1" ]]; then
            unchanged=$((unchanged + 1))
            return 0
        fi
    fi
    if (( check )); then
        if [[ -L "$2" ]]; then
            echo "  WRONG    $(short "$2") -> $(short "$got")  (want $(short "$1"))"
        elif [[ -e "$2" ]]; then
            echo "  INPLACE  $(short "$2") is a real file/dir where a link belongs  (symlink_files.sh backs it up and links)"
        else
            echo "  MISSING  $(short "$2") -> $(short "$1")"
        fi
        issues=$((issues + 1))
        return 0
    fi
    if [[ -L "$2" ]]; then
        rm "$2"
        echo "  relink   $(short "$2") -> $(short "$1")  (was $(short "$got"))"
    elif [[ -e "$2" ]]; then
        mv "$2" "$deldir/"
        echo "  link     $(short "$2") -> $(short "$1")  (real file backed up to $(short "$deldir")/)"
    else
        echo "  link     $(short "$2") -> $(short "$1")"
    fi
    ln -s "$1" "$2"
    changed=$((changed + 1))
}

# Helper: layer the tracked generic items of <src-dir> into the private
# <dst-dir> as RELATIVE symlinks, so a tracked and a private set coexist in
# one directory (~/.claude/skills, ~/.agents/skills). Relative targets keep
# the links valid after an `other.tgz` migration to another machine.
#   layer_tracked_items <tracked-src-dir> <private-dst-dir> [allowlist-file]
# With an allowlist file, only the names listed in it (one per line, '#'
# comments ignored by construction — a comment never equals a filename) are
# layered; without one, everything in <src-dir> is.
# Dangling links (tracked item removed or renamed) are pruned first; a real
# file/dir in <dst-dir> with the same name as a tracked item is a private
# entry that WINS and is left alone (warned).
layer_tracked_items() {
    local src_dir="$1" dst_dir="$2" allow="$3"
    local root=$HOME/dotfiles
    local rel_src="${src_dir#"$root"/}"
    local rel_dst="${dst_dir#"$root"/}"

    # ../ per path component of the destination, i.e. climb back to $root
    local up="" rest="$rel_dst"
    while [[ -n "$rest" ]]; do
        up="../$up"
        [[ "$rest" == */* ]] || break
        rest="${rest#*/}"
    done

    ensure_dir "$dst_dir"
    local entry src name dst want got
    for entry in "$dst_dir"/*; do
        if [[ -L "$entry" && ! -e "$entry" ]]; then
            if (( check )); then
                echo "  DANGLING $(short "$entry") -> $(readlink "$entry")  (symlink_files.sh prunes it)"
                issues=$((issues + 1))
            else
                echo "  prune    $(short "$entry") -> $(readlink "$entry")  (dangling)"
                rm "$entry"
                changed=$((changed + 1))
            fi
        fi
    done
    for src in "$src_dir"/*; do
        [[ -e "$src" ]] || continue
        name=$(basename "$src")
        [[ -n "$allow" ]] && ! grep -qxF "$name" "$allow" 2>/dev/null && continue
        dst=$dst_dir/$name
        want="${up}${rel_src}/${name}"
        if [[ -e "$dst" && ! -L "$dst" ]]; then
            # by design (private wins), so not an issue — a note in both modes
            echo "WARN: $dst is a private entry shadowing the tracked one — left as is" >&2
            continue
        fi
        got=""
        [[ -L "$dst" ]] && got=$(readlink "$dst")
        if [[ "$got" == "$want" ]]; then
            unchanged=$((unchanged + 1))
            continue
        fi
        if (( check )); then
            if [[ -n "$got" ]]; then
                echo "  WRONG    $(short "$dst") -> $got  (want $want)"
            else
                echo "  MISSING  $(short "$dst") -> $want"
            fi
            issues=$((issues + 1))
            continue
        fi
        if [[ -n "$got" ]]; then
            echo "  relink   $(short "$dst") -> $want  (was $got)"
        else
            echo "  link     $(short "$dst") -> $want"
        fi
        ln -sfn "$want" "$dst"
        changed=$((changed + 1))
    done
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
# claude block below has a settings.json to link on a fresh (or gappy) machine.
# (--check skips this: seeding is a write, and seed_other.sh --check is its own
# report, run alongside this one by bin/doctor.)
(( check )) || "$HOME/dotfiles/bin/seed_other.sh"

# ===== claude code =====
# ~/.claude itself holds machine state, so settings.json is a FILE link while
# skills/rules/agents are whole-directory links into the private
# other/claude/. The two-layer arrangement is described in CLAUDE.md.
ensure_dir ~/.claude "$other/claude/skills" "$other/claude/rules" "$other/claude/agents"
[[ -f $other/claude/settings.json ]] && link $other/claude/settings.json ~/.claude/settings.json
for kind in skills rules agents; do
    link $other/claude/$kind ~/.claude/$kind
    layer_tracked_items "$dir/claude/$kind" "$other/claude/$kind" ""
done

# ===== codex =====
# The same two layers on codex's paths. config.toml must stay private and
# writable: codex writes its own [projects] trust entries into it.
# ~/.agents/skills is codex's user-level skill dir, and the tracked skills
# named in dots/codex/shared-skills are layered in as relative links to the
# SAME files claude uses.
ensure_dir ~/.codex ~/.agents "$other/codex/skills"
[[ -f $other/codex/config.toml ]] && link "$other/codex/config.toml" ~/.codex/config.toml
[[ -f $other/codex/AGENTS.md ]] && link "$other/codex/AGENTS.md" ~/.codex/AGENTS.md
link "$dir/codex/hooks.json" ~/.codex/hooks.json
link "$other/codex/skills" ~/.agents/skills
layer_tracked_items "$dir/claude/skills" "$other/codex/skills" "$dir/codex/shared-skills"

# ===== starship =====
ensure_dir ~/.config
link $dir/starship.toml ~/.config/starship.toml

# ===== worktrunk =====
ensure_dir ~/.config/worktrunk
link $dir/worktrunk.toml ~/.config/worktrunk/config.toml

# ===== neovim (LazyVim config) =====
link $dir/nvim ~/.config/nvim

# ===== ghostty =====
link $dir/ghostty ~/.config/ghostty

if (( check )); then
    if (( issues )); then
        echo "symlink_files: $issues issue(s)  (fix: bin/symlink_files.sh)"
        exit 1
    fi
    echo "symlink_files: all links in place"
    exit 0
fi

echo "symlink_files: $changed changed, $unchanged already in place"
if ! rmdir "$deldir" 2>/dev/null; then
    echo "Old dotfiles backed up to: $deldir"
    read -p "Delete backup directory? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$deldir"
        echo "Backup deleted."
    fi
fi
