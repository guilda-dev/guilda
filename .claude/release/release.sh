#!/usr/bin/env bash
# Release versionX.Y into main without the coding-assistant config.
#
# Usage (from a clean checkout of versionX.Y, in Bash on macOS/Linux or
# Git Bash on Windows):
#   bash .claude/release/release.sh X.Y
#
# Switches to main, merges versionX.Y with --no-ff, removes the assistant
# paths (ASSISTANT_PATHS in common.sh) from the merge result, commits
# "chore: release vX.Y", tags vX.Y, and checks that main has none of those
# paths. Nothing is pushed: the push command is printed at the end.
# Rules: _GUILDAdoc/developer/git-workflow.html#release
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
run_from_copy "$@"

[ $# -eq 1 ] || die "usage: bash .claude/release/release.sh X.Y"
version=$1
check_version "$version"
branch=version$version
tag=v$version

go_to_repo_root
[ "$(git symbolic-ref --short -q HEAD)" = "$branch" ] || die "run this from $branch (git switch $branch)"
require_clean
ensure_main
! has_ref "refs/tags/$tag" || die "tag $tag already exists"

# Undo the merge and go back to versionX.Y before failing.
abort() {
  git merge --abort 2>/dev/null
  git switch -q "$branch"
  die "$*"
}

git switch -q main || die "cannot switch to main"
if ! git merge --no-ff --no-commit "$branch"; then
  echo "merge stopped; checking whether only assistant paths conflict..."
fi
has_ref "MERGE_HEAD" || abort "the merge did not start (nothing new in $branch, or see the git message above)"
# -f: the merged paths are staged; ignored local files (.claude/worktrees/) are untouched.
git rm -r -q -f --ignore-unmatch -- "${ASSISTANT_PATHS[@]}" >/dev/null ||
  abort "cannot remove the assistant paths from the merge result"

conflicts=$(git diff --name-only --diff-filter=U)
[ -z "$conflicts" ] || abort "merge conflicts in:
$conflicts
Merge main into $branch, resolve them there, and run this script again."

git commit -q -m "chore: release $tag" || die "commit failed; the merge is still in progress (git merge --abort to undo)"
git tag -a "$tag" -m "GUILDA $tag" || die "tagging failed"

left=$(git ls-tree -r --name-only main -- "${ASSISTANT_PATHS[@]}")
[ -z "$left" ] || die "main still contains assistant files:
$left"

echo "Released $tag on main ($(git rev-parse --short main)); assistant paths absent: ${ASSISTANT_PATHS[*]}"
echo "Review, then push with:"
echo "  git push origin main $tag"
echo "Then start the next integration branch with start-version.sh (from $branch):"
echo "  git switch $branch && bash .claude/release/start-version.sh <next X.Y> $version"
