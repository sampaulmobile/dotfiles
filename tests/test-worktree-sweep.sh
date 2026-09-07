#!/usr/bin/env bash
#
# parse_copy_ignored_excludes / classify_ignored_file — the pure guard behind
# bin/worktree-sweep's "safe to delete this gitignored entry?" decision.
# Offline: it SOURCES bin/worktree-sweep, whose BASH_SOURCE guard hands back
# the guard functions and stops before the sweep (no git, no wt, no gh, no
# real worktree). The content checks use only files created under a mktemp
# dir, removed on exit.
#
#   tests/test-worktree-sweep.sh
#
# The classify_ignored_file cases that matter: a regenerable cache (a segment
# in sweep_excludes, at any depth) is safe-cache and never content-checked; a
# plain file is safe-copy ONLY when byte-identical to the hub's copy (a
# copied-in file the worktree later edited must fall through to at-risk, or
# the sweep would silently drop the edit); a file absent from the hub, and any
# ignored DIRECTORY, are at-risk (surfaced, never deleted blind). The
# parse_copy_ignored_excludes case that matters: the exclude list is READ from
# worktrunk.toml (multi-line or inline array), never copied — an absent
# section yields nothing, which degrades the guard to pure content comparison
# (more skips, never an unsafe removal).

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
case_ "non-cache directory"          "data-test/"             at-risk

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
