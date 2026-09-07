#!/usr/bin/env bash
#
# parse_copy_ignored_excludes / classify_ignored_file / worktree_ignored_at_risk
# / sweep_is_removable — the pure guard behind bin/worktree-sweep's "safe to
# delete this gitignored entry?" and "safe to remove this worktree?" decisions.
# Offline: it SOURCES bin/worktree-sweep, whose BASH_SOURCE guard hands back
# the guard functions and stops before the sweep (no wt, no gh, no real
# machine worktree). Most cases use plain files under a mktemp dir; the
# worktree_ignored_at_risk integration cases need a real (throwaway) git repo
# to exercise actual `git ls-files` behavior, built the same way as
# tests/test-check-prose-only.sh's fixture.
#
#   tests/test-worktree-sweep.sh
#
# The classify_ignored_file cases that matter: a regenerable cache (a segment
# in sweep_excludes, at any depth) is safe-cache and never content-checked
# (L2: only when that segment names a DIRECTORY — a gitignored FILE that
# happens to share a cache's name is not); a plain file is safe-copy ONLY when
# byte-identical to the hub's copy (a copied-in file the worktree later
# edited must fall through to at-risk, or the sweep would silently drop the
# edit); a file absent from the hub is at-risk; a non-cache, non-.feature/
# ignored DIRECTORY is "recurse", never dropped as a whole unit (B7) — the
# caller (worktree_ignored_at_risk) must expand it and compare its files
# individually. The parse_copy_ignored_excludes case that matters: the
# exclude list is READ from worktrunk.toml (multi-line or inline array),
# never copied — an absent section yields nothing, which degrades the guard
# to pure content comparison (more skips, never an unsafe removal); a
# trailing `#` comment (even one that itself contains quoted words, or looks
# like a `[step.copy-ignored]` header) must never contribute tokens (B2). The
# worktree_ignored_at_risk cases that matter: a `git ls-files` failure fails
# CLOSED — printed as at-risk, never silently "nothing found" (B1); a
# byte-identical nested file inside a non-cache directory is safe, one that
# differs or is missing from the hub is at-risk BY ITS OWN PATH, not the
# directory's (B7); a non-ASCII filename byte-identical to the hub is safe
# even though plain `ls-files` would octal-quote it (L5, needs `-z`).
# sweep_is_removable's case that matters: MERGED is removable only when the
# worktree has no local-only commits (B3).

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

# shellcheck source=/dev/null
source "$repo/bin/worktree-sweep"

pass=0
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

ok()   { printf '  ok   %s\n' "$1"; pass=$(( pass + 1 )); }
bad()  { printf '  FAIL %s\n       %s\n' "$1" "$2"; fail=$(( fail + 1 )); }

echo "── sourcing bin/worktree-sweep ran no sweep (main is guarded)"
if declare -f parse_copy_ignored_excludes >/dev/null \
    && declare -f classify_ignored_file >/dev/null \
    && declare -f worktree_ignored_at_risk >/dev/null; then
    ok "guard functions available after sourcing"
else
    bad "functions not defined by sourcing" "parse_copy_ignored_excludes/classify_ignored_file/worktree_ignored_at_risk missing"
fi

echo "── parse_copy_ignored_excludes: reads the [step.copy-ignored] exclude array"
multiline="$tmp/multiline.toml"
cat > "$multiline" <<'TOML'
post-switch = "x"
[step.copy-ignored]
exclude = [
  "node_modules",
  ".venv",
  "build",
]
[other.section]
exclude = ["should-not-appear"]
TOML
got=$(parse_copy_ignored_excludes "$multiline" | tr '\n' ',')
if [[ "$got" == "node_modules,.venv,build," ]]; then
    ok "multi-line array parsed; later section's exclude ignored"
else
    bad "multi-line array" "got [$got] want [node_modules,.venv,build,]"
fi

inline="$tmp/inline.toml"
cat > "$inline" <<'TOML'
[step.copy-ignored]
exclude = ["node_modules", ".venv"]
TOML
got=$(parse_copy_ignored_excludes "$inline" | tr '\n' ',')
if [[ "$got" == "node_modules,.venv," ]]; then
    ok "inline array parsed"
else
    bad "inline array" "got [$got] want [node_modules,.venv,]"
fi

got=$(parse_copy_ignored_excludes "$tmp/does-not-exist.toml"; echo "rc=$?")
if [[ "$got" == "rc=0" ]]; then
    ok "missing toml -> empty, rc 0 (guard falls back to content compare)"
else
    bad "missing toml" "got [$got]"
fi

nosection="$tmp/nosection.toml"
printf 'post-switch = "x"\n' > "$nosection"
got=$(parse_copy_ignored_excludes "$nosection")
if [[ -z "$got" ]]; then
    ok "no [step.copy-ignored] section -> empty"
else
    bad "no section" "got [$got]"
fi

echo "── parse_copy_ignored_excludes: B2 — a trailing comment contributes nothing"
commented="$tmp/commented.toml"
cat > "$commented" <<'TOML'
# [step.copy-ignored]
exclude = ["decoy"]
[step.copy-ignored]
exclude = [
  "node_modules",  # was "cache" before
  ".venv",
]
TOML
got=$(parse_copy_ignored_excludes "$commented" | tr '\n' ',')
if [[ "$got" == "node_modules,.venv," ]]; then
    ok "commented-out header ignored; trailing comment's quoted words never harvested"
else
    bad "commented exclude line" "got [$got] want [node_modules,.venv,]"
fi

echo "── classify_ignored_file: cache / copied-in / at-risk"
# A hub and a worktree with a spread of gitignored entries.
hub="$tmp/hub"; wt="$tmp/wt"
mkdir -p "$hub" "$wt"
sweep_excludes=("node_modules" ".venv" "build")

# identical copied-in file
printf 'SHARED=1\n' > "$hub/.env"
printf 'SHARED=1\n' > "$wt/.env"
# copied-in file the worktree then edited
printf 'A=1\n' > "$hub/.config"
printf 'A=1\nB=2\n' > "$wt/.config"
# file unique to the worktree
printf 'data\n' > "$wt/local.db"

# case_ <label> <relpath> <want>
case_() {
    local label="$1" rel="$2" want="$3" got
    got=$(classify_ignored_file "$rel" "$wt" "$hub")
    if [[ "$got" == "$want" ]]; then
        ok "$label -> $got"
    else
        bad "$label" "got [$got] want [$want]"
    fi
}

case_ "cache dir (top level)"        "node_modules/"          safe-cache
case_ "cache dir (nested segment)"   "packages/x/.venv/"      safe-cache
case_ "file identical to hub"        ".env"                   safe-copy
case_ "copied-in file since edited"  ".config"                at-risk
case_ "file absent from hub"         "local.db"               at-risk
case_ "non-cache directory (not .feature/)" "data-test/"       recurse
case_ ".feature/ pipeline state"     ".feature/"               safe-cache

echo "── _seg_is_cache (L2): gitignore-style trailing slash; files never match"
sweep_excludes=("node_modules" ".venv" "build/")
case_ "exclude entry with trailing slash still matches a dir"  "build/"  safe-cache
printf 'not a cache\n' > "$hub/build"
printf 'not a cache\n' > "$wt/build"
case_ "gitignored FILE named like a cache dir is not safe-cache" "build" safe-copy
sweep_excludes=("node_modules" ".venv" "build")

echo "── worktree_ignored_at_risk: real-git integration (B1, B7, L5)"
gitwt="$tmp/gitwt"
mkdir -p "$gitwt"
git -C "$gitwt" init -q -b main 2>/dev/null || { echo "git init failed"; exit 1; }
git -C "$gitwt" config user.email test@example.invalid
git -C "$gitwt" config user.name "worktree-sweep test"
printf '*\n' > "$gitwt/.gitignore"
git -C "$gitwt" add -f .gitignore
git -C "$gitwt" commit -qm baseline

# a non-cache directory, byte-identical to the hub -> whole dir is safe
mkdir -p "$gitwt/mydir" "$hub/mydir"
printf 'same\n' > "$gitwt/mydir/file.txt"
printf 'same\n' > "$hub/mydir/file.txt"

# a non-cache directory with one file that differs from the hub (B7: the
# AT-RISK entry must be the nested file's own path, not the directory's)
mkdir -p "$gitwt/mydir2" "$hub/mydir2"
printf 'same\n' > "$gitwt/mydir2/same.txt"
printf 'same\n' > "$hub/mydir2/same.txt"
printf 'worktree edit\n' > "$gitwt/mydir2/changed.txt"
printf 'hub original\n' > "$hub/mydir2/changed.txt"

# .feature/ pipeline state, no hub counterpart at all -> always safe
mkdir -p "$gitwt/.feature"
printf 'scratch state\n' > "$gitwt/.feature/notes.md"

# a non-ASCII filename byte-identical to the hub (L5: plain `ls-files`
# octal-quotes this under core.quotePath, breaking a naive hub lookup)
printf 'café\n' > "$gitwt/café.env"
printf 'café\n' > "$hub/café.env"

at_risk=$(worktree_ignored_at_risk "$gitwt" "$hub")
if [[ "$at_risk" == *"mydir2/changed.txt"* ]]; then
    ok "nested at-risk file surfaced by its own path (mydir2/changed.txt)"
else
    bad "nested at-risk file" "got [$at_risk], want it to contain mydir2/changed.txt"
fi
if [[ "$at_risk" != *"mydir/file.txt"* && "$at_risk" != *"mydir2/same.txt"* ]]; then
    ok "nested files identical to the hub are not at-risk"
else
    bad "identical nested files wrongly at-risk" "got [$at_risk]"
fi
if [[ "$at_risk" != *".feature"* ]]; then
    ok ".feature/ pipeline state is never at-risk"
else
    bad ".feature/ wrongly at-risk" "got [$at_risk]"
fi
if [[ "$at_risk" != *"café.env"* ]]; then
    ok "byte-identical non-ASCII filename (café.env) is not at-risk"
else
    bad "café.env wrongly at-risk" "got [$at_risk]"
fi

echo "── worktree_ignored_at_risk: B1 — a git failure fails CLOSED"
notarepo="$tmp/notarepo"
mkdir -p "$notarepo"
at_risk=$(worktree_ignored_at_risk "$notarepo" "$hub")
if [[ -n "$at_risk" ]]; then
    ok "git ls-files failure (not a git repo) -> non-empty at-risk output, never silently safe"
else
    bad "git failure should fail closed" "got empty at-risk output"
fi

echo "── sweep_is_removable (B3): MERGED is removable only without local-only commits"
if sweep_is_removable MERGED false; then
    ok "MERGED, not unpushed -> removable"
else
    bad "MERGED not-unpushed" "expected removable"
fi
if ! sweep_is_removable MERGED true; then
    ok "MERGED, but unpushed local commits -> NOT removable"
else
    bad "MERGED unpushed" "expected NOT removable"
fi
if ! sweep_is_removable PARKED false; then
    ok "non-MERGED bucket -> never removable here"
else
    bad "PARKED bucket" "expected NOT removable"
fi

echo "── sweep_remove_cmd (L1): dry-run rendering matches what remove_worktree runs"
got=$(sweep_remove_cmd /repo /repo/wt branchname false)
want='wt -C /repo remove --foreground --no-delete-branch branchname && git -C /repo branch -D branchname'
if [[ "$got" == "$want" ]]; then
    ok "unlocked, branch present -> plain remove + branch delete"
else
    bad "sweep_remove_cmd unlocked" "got [$got] want [$want]"
fi
got=$(sweep_remove_cmd /repo /repo/wt branchname true)
want='git -C /repo worktree unlock /repo/wt && wt -C /repo remove --foreground --no-delete-branch branchname && git -C /repo branch -D branchname'
if [[ "$got" == "$want" ]]; then
    ok "locked -> unlock prefix, same remove + branch delete"
else
    bad "sweep_remove_cmd locked" "got [$got] want [$want]"
fi
got=$(sweep_remove_cmd /repo /repo/wt "" false)
want='wt -C /repo remove --foreground --no-delete-branch /repo/wt'
if [[ "$got" == "$want" ]]; then
    ok "detached (no branch) -> targets by path, no branch delete"
else
    bad "sweep_remove_cmd detached" "got [$got] want [$want]"
fi

echo "── B5: a clean --apply run (no removals, no failures) exits 0"
if ! command -v wt >/dev/null 2>&1; then
    ok "skipped (wt not on PATH)"
else
    # A single nonexistent-path entry, not an empty array: bin/project-dirs-lib's
    # project_dirs() indexes search_dirs[@] unguarded by element count (unlike
    # every array it hands back), which bash 3.2 treats as unbound under
    # `set -u` when the array has zero elements — a real repo's search_dirs is
    # never empty, so that landmine is pre-existing and out of this round's
    # scope; sidestep it rather than trip it.
    b5_conf="$tmp/b5-search-dirs.sh"
    printf 'search_dirs=("%s/no-such-project:0")\n' "$tmp" > "$b5_conf"
    b5_out=$(PROJECT_DIRS_LOCAL="$b5_conf" HOME="$tmp" bash "$repo/bin/worktree-sweep" --apply --offline 2>&1)
    b5_rc=$?
    if [[ $b5_rc -eq 0 ]]; then
        ok "clean --apply run (0 repos, 0 removals, 0 failures) exits 0"
    else
        bad "clean --apply run exit code" "got rc=$b5_rc, want 0; output:
$b5_out"
    fi
fi

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
