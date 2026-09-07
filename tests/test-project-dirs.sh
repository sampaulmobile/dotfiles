#!/usr/bin/env bash
#
# bin/project-dirs-lib over a throwaway fake project tree (mktemp -d): a
# plain repo with two agent worktrees (one on a branch, one detached), a
# legacy .bare/ container with one worktree, and a depth-0 entry with a
# linked-worktree sibling (included) and a non-worktree .bak sibling
# (excluded). Offline: no real ~/dev, no git plumbing — project_dirs and
# worktree_branch only ever look at directory shapes and plain files.
#
#   tests/test-project-dirs.sh
#
# The case that matters: search_dirs must be settable BEFORE sourcing the
# lib (bash 3.2 quirk noted in the lib itself) so a test never touches the
# real machine's ~/dev or other/tmux-sessionizer.local.

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

work=$(mktemp -d "${TMPDIR:-/tmp}/project-dirs-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

pass=0
fail=0
ok()  { printf '  ok   %s\n' "$1"; pass=$(( pass + 1 )); }
bad() { printf '  FAIL %s\n       %s\n' "$1" "$2"; fail=$(( fail + 1 )); }

# ---- build the fake tree ----
# $work/dev/proj1        — a repo (.git dir) with two agent worktrees
mkdir -p "$work/dev/proj1/.git"
mkdir -p "$work/dev/proj1/.claude/worktrees/agent-abc123"
mkdir -p "$work/dev/proj1/.claude/worktrees/agent-def456"
mkdir -p "$work/dev/proj1/.git/worktrees/agent-abc123"
mkdir -p "$work/dev/proj1/.git/worktrees/agent-def456"
echo "gitdir: $work/dev/proj1/.git/worktrees/agent-abc123" > "$work/dev/proj1/.claude/worktrees/agent-abc123/.git"
echo "gitdir: $work/dev/proj1/.git/worktrees/agent-def456" > "$work/dev/proj1/.claude/worktrees/agent-def456/.git"
echo "ref: refs/heads/feature/x" > "$work/dev/proj1/.git/worktrees/agent-abc123/HEAD"
echo "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef" > "$work/dev/proj1/.git/worktrees/agent-def456/HEAD"

# $work/dev/bareproj     — legacy .bare/ container with one worktree child
mkdir -p "$work/dev/bareproj/.bare"
mkdir -p "$work/dev/bareproj/feature-y"

# $work/dotfiles         — depth-0 entry (a repo), with two "path.*" siblings
mkdir -p "$work/dotfiles/.git"
mkdir -p "$work/dotfiles.bak/.git"                 # non-worktree sibling: excluded
mkdir -p "$work/dotfiles.featx"                    # .git is a FILE here: included
echo "gitdir: $work/dotfiles/.git/worktrees/featx" > "$work/dotfiles.featx/.git"

# ---- point the lib at the fake tree, not the real machine ----
search_dirs=(
    "$work/dev:1"
    "$work/dotfiles:0"
)
PROJECT_DIRS_LOCAL=/nonexistent
# shellcheck source=/dev/null
source "$repo/bin/project-dirs-lib"

echo "── search_dirs: pre-set array survives sourcing"
if [[ "${#search_dirs[@]}" -eq 2 && "${search_dirs[0]}" == "$work/dev:1" && "${search_dirs[1]}" == "$work/dotfiles:0" ]]; then
    ok "lib did not clobber a pre-set search_dirs"
else
    bad "lib did not clobber a pre-set search_dirs" "got: ${search_dirs[*]}"
fi

echo "── project_dirs: enumeration order and contents"
project_dirs
want=(
    "$work/dev/bareproj/feature-y"
    "$work/dev/proj1"
    "$work/dev/proj1/.claude/worktrees/agent-abc123"
    "$work/dev/proj1/.claude/worktrees/agent-def456"
    "$work/dotfiles"
    "$work/dotfiles.featx"
)
got_joined=$(printf '%s\n' "${project_dirs_out[@]}")
want_joined=$(printf '%s\n' "${want[@]}")
if [[ "$got_joined" == "$want_joined" ]]; then
    ok "enumeration matches expected order/contents (${#want[@]} entries)"
else
    bad "enumeration matches expected order/contents" $'want:\n'"$want_joined"$'\ngot:\n'"$got_joined"
fi

# dotfiles.bak (non-worktree sibling) must never appear
if [[ "$got_joined" == *"dotfiles.bak"* ]]; then
    bad "dotfiles.bak excluded" "found dotfiles.bak in enumeration"
else
    ok "dotfiles.bak (non-worktree sibling) excluded"
fi

echo "── worktree_branch: normal and detached"
worktree_branch "$work/dev/proj1/.claude/worktrees/agent-abc123"
if [[ "$worktree_branch_out" == "feature/x" ]]; then
    ok "worktree_branch: normal HEAD -> feature/x"
else
    bad "worktree_branch: normal HEAD" "got [$worktree_branch_out]"
fi

worktree_branch "$work/dev/proj1/.claude/worktrees/agent-def456"
if [[ -z "$worktree_branch_out" ]]; then
    ok "worktree_branch: detached HEAD -> empty"
else
    bad "worktree_branch: detached HEAD" "got [$worktree_branch_out]"
fi

worktree_branch "$work/dev/proj1"
if [[ -z "$worktree_branch_out" ]]; then
    ok "worktree_branch: not a linked worktree (.git is a dir) -> empty"
else
    bad "worktree_branch: not a linked worktree" "got [$worktree_branch_out]"
fi

echo "── session_name_for: every kind"

session_name_for "$work/dev/proj1/.claude/worktrees/agent-abc123"
if [[ "$session_name" == "proj1_feature-x" ]]; then
    ok "agent worktree, branch feature/x -> proj1_feature-x"
else
    bad "agent worktree, branch feature/x" "got [$session_name]"
fi

session_name_for "$work/dev/proj1/.claude/worktrees/agent-def456"
if [[ "$session_name" == "proj1_agent-def456" ]]; then
    ok "agent worktree, detached -> proj1_<basename>"
else
    bad "agent worktree, detached" "got [$session_name]"
fi

session_name_for "$work/dev/bareproj/feature-y"
if [[ "$session_name" == "bareproj_feature-y" ]]; then
    ok "legacy .bare/ worktree -> <project>_<dirname>"
else
    bad "legacy .bare/ worktree" "got [$session_name]"
fi

session_name_for "$work/dotfiles.featx"
if [[ "$session_name" == "dotfiles_featx" ]]; then
    ok "plain dir with dots -> dots become underscores"
else
    bad "plain dir with dots" "got [$session_name]"
fi

session_name_for "$work/dev/proj1"
if [[ "$session_name" == "proj1" ]]; then
    ok "plain project dir -> basename"
else
    bad "plain project dir" "got [$session_name]"
fi

echo "── session_name_for_branch: repo+branch, no filesystem read"

session_name_for_branch "repo" "feature/x"
if [[ "$session_name" == "repo_feature-x" ]]; then
    ok "session_name_for_branch: feature/x -> repo_feature-x"
else
    bad "session_name_for_branch: feature/x" "got [$session_name]"
fi

session_name_for_branch "repo" "release/1.2"
if [[ "$session_name" == "repo_release-1_2" ]]; then
    ok "session_name_for_branch: release/1.2 -> repo_release-1_2 (dots in branch too)"
else
    bad "session_name_for_branch: release/1.2" "got [$session_name]"
fi

echo "── session_name_for on a REMOVED path: why wt-tmux-cleanup needs the branch arg"
# worktrunk's post-remove/post-merge hooks run AFTER the worktree directory
# is gone, so session_name_for can no longer read <wt>/.git for the branch
# and falls back to the basename — a DIFFERENT (wrong) name than the one
# Ctrl+F created for the same worktree while it was alive. This is exactly
# the blocking bug the branch arg fixes: bin/wt-tmux-cleanup must use
# session_name_for_branch (above), not session_name_for, once the directory
# is gone.
removed="$work/dev/proj1/.claude/worktrees/agent-removed"
session_name_for "$removed"
if [[ "$session_name" == "proj1_agent-removed" ]]; then
    ok "session_name_for on a gone path falls back to <repo>_<basename>"
else
    bad "session_name_for on a gone path" "got [$session_name]"
fi

session_name_for_branch "proj1" "feature/x"
if [[ "$session_name" == "proj1_feature-x" ]]; then
    ok "session_name_for_branch on the same worktree gives the Ctrl+F name instead"
else
    bad "session_name_for_branch on the same worktree" "got [$session_name]"
fi

echo "── session_name_for_removed: worktrunk always passes a 3rd word; HEAD means detached"
# worktrunk's post-remove/post-merge ALWAYS supply a 3rd hook argument, and
# for a detached worktree that argument renders as the literal string "HEAD"
# (empirical, wt v0.68.0 — see .feature/NOTES.md), never empty. Both empty
# and "HEAD" must fall back to the path-basename rule (session_name_for);
# anything else is a real branch and goes through session_name_for_branch.
gone="$work/repo/.claude/worktrees/agent-x"

session_name_for_removed "repo" "$gone" "feature/x"
if [[ "$session_name" == "repo_feature-x" ]]; then
    ok "session_name_for_removed: real branch -> repo_feature-x"
else
    bad "session_name_for_removed: real branch" "got [$session_name]"
fi

session_name_for_removed "repo" "$gone" "HEAD"
if [[ "$session_name" == "repo_agent-x" ]]; then
    ok "session_name_for_removed: HEAD (detached sentinel) -> path-based repo_agent-x"
else
    bad "session_name_for_removed: HEAD sentinel" "got [$session_name]"
fi

session_name_for_removed "repo" "$gone" ""
if [[ "$session_name" == "repo_agent-x" ]]; then
    ok "session_name_for_removed: empty branch -> path-based repo_agent-x"
else
    bad "session_name_for_removed: empty branch" "got [$session_name]"
fi

sibling_gone="$work/repo.feat-x"
session_name_for_removed "repo" "$sibling_gone" "HEAD"
if [[ "$session_name" == "repo_feat-x" ]]; then
    ok "session_name_for_removed: detached worktrunk sibling -> path-based repo_feat-x"
else
    bad "session_name_for_removed: detached worktrunk sibling" "got [$session_name]"
fi

session_name_for_removed "repo" "$gone" "release/1.2"
if [[ "$session_name" == "repo_release-1_2" ]]; then
    ok "session_name_for_removed: branch with dots -> repo_release-1_2"
else
    bad "session_name_for_removed: branch with dots" "got [$session_name]"
fi

echo
if (( fail )); then
    echo "FAILED: $fail failed, $pass passed"
    exit 1
fi
echo "ok: $pass passed"
