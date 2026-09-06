#!/bin/bash
############################
# symlink_files.sh
# This script creates symlinks for ALL THE FILES
#
#   symlink_files.sh          create every link that is missing or wrong (backs
#                             up real files in the way). Links already pointing
#                             at the right target are left alone and NOT
#                             listed — the output is what changed, plus a
#                             summary; a rerun with nothing to do prints only
#                             the summary.
#   symlink_files.sh --check  report only: every link this script would make
#                             is compared with what's there — MISSING, WRONG
#                             target, or a real file INPLACE — and nothing is
#                             changed (no backup dir, no mkdir, no seeding;
#                             seed_other.sh has its own --check). Exit 1 if
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
# untouched and unlisted (a rerun is the common case, and listing 30
# unchanged links buried the two that mattered). A link elsewhere is just
# replaced (its target is safe) — moving it into a backup dir that already
# held a same-named link is what used to nest stale links inside their own
# targets. A real file/dir is backed up to $deldir first.
# In --check mode: compare only. Correct is silent; anything else is one
# report line and one issue.
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
# settings.json is a file link (~/.claude itself holds machine state).
# ~/.claude/{skills,rules,agents} are whole-directory links into other/claude/
# (private, gitignored) — anything dropped there is private by default. The
# tracked generic set in dots/claude/ is layered in as per-item RELATIVE links
# inside those dirs, so both kinds show up under ~/.claude. Promote a private
# item by moving it to dots/claude/<kind>/ and re-running this script; a
# private entry with the same name as a tracked one is left alone (warned).
ensure_dir ~/.claude "$other/claude/skills" "$other/claude/rules" "$other/claude/agents"
[[ -f $other/claude/settings.json ]] && link $other/claude/settings.json ~/.claude/settings.json
for kind in skills rules agents; do
    link $other/claude/$kind ~/.claude/$kind
    layer_tracked_items "$dir/claude/$kind" "$other/claude/$kind" ""
done

# ===== codex =====
# Same two layers as claude, mapped onto codex's paths: ~/.codex holds machine
# state, so config.toml and AGENTS.md are FILE links into other/codex/
# (private, gitignored — codex writes its own [projects] trust entries into
# config.toml) while the generic hooks.json is a file link into dots/codex/.
# Skills: ~/.agents/skills is codex's user-level skill dir, linked to
# other/codex/skills so anything dropped there is private by default; the
# harness-neutral tracked skills named in dots/codex/shared-skills are layered
# in as per-item relative links to the SAME files claude uses.
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
