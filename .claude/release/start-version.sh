#!/usr/bin/env bash
# Create the next snapshot branch versionX.Y from main after a release.
#
# Usage (from any checkout, in Bash on macOS/Linux or Git Bash on Windows):
#   bash .claude/release/start-version.sh X.Y
#   e.g. bash .claude/release/start-version.sh 4.1
#
# Creates versionX.Y at the tip of main without switching to it. The branch
# carries no assistant config: development continues on DEV_BRANCH
# (common.sh), and integrate.sh adds snapshots on top of versionX.Y.
# Nothing is pushed.
# Rules: _GUILDAdoc/developer/git-workflow.html#release
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

[ $# -eq 1 ] || die "usage: bash .claude/release/start-version.sh X.Y"
version=$1
check_version "$version"
branch=version$version

go_to_repo_root
ensure_main
! has_ref "refs/heads/$branch" || die "branch $branch already exists"

git branch -q "$branch" main || die "cannot create $branch from main"

echo "Created $branch from main ($(git rev-parse --short main))."
echo "Snapshot $DEV_BRANCH into it with:"
echo "  bash .claude/release/integrate.sh $version"
echo "Push with:"
echo "  git push -u origin $branch"
