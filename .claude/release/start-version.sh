#!/usr/bin/env bash
# Start the next integration branch versionX.Y from main and restore the
# coding-assistant config that release.sh removed from main.
#
# Usage (from a clean checkout, in Bash on macOS/Linux or Git Bash on Windows):
#   bash .claude/release/start-version.sh X.Y PREV
#   e.g. bash .claude/release/start-version.sh 4.1 4.0
#
# Creates versionX.Y from main, restores the assistant paths
# (ASSISTANT_PATHS in common.sh) from versionPREV, and commits
# "chore: restore assistant config for vX.Y". Nothing is pushed.
# Rules: _GUILDAdoc/developer/git-workflow.html#release
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
run_from_copy "$@"

[ $# -eq 2 ] || die "usage: bash .claude/release/start-version.sh X.Y PREV"
version=$1
prev=$2
check_version "$version"
check_version "$prev"
branch=version$version

go_to_repo_root
require_clean
ensure_main
! has_ref "refs/heads/$branch" || die "branch $branch already exists"
source_ref=version$prev
if ! has_ref "refs/heads/$source_ref"; then
  has_ref "refs/remotes/origin/$source_ref" || die "no branch $source_ref (local or origin) to restore from"
  source_ref=origin/$source_ref
fi

restore=()
for p in "${ASSISTANT_PATHS[@]}"; do
  if git cat-file -e "$source_ref:$p" 2>/dev/null; then
    restore+=("$p")
  else
    echo "warning: $p is not in $source_ref; skipped" >&2
  fi
done
[ ${#restore[@]} -gt 0 ] || die "$source_ref has none of: ${ASSISTANT_PATHS[*]}"

git switch -q -c "$branch" main || die "cannot create $branch from main"
git checkout "$source_ref" -- "${restore[@]}" || die "cannot restore assistant paths from $source_ref"
git commit -q -m "chore: restore assistant config for v$version" || die "commit failed"

echo "Created $branch from main and restored from $source_ref: ${restore[*]}"
echo "Push with:"
echo "  git push -u origin $branch"
