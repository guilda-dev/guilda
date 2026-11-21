#!/usr/bin/env bash
# Snapshot the development branch into versionX.Y without the assistant config.
#
# Usage (from any checkout of the repository, in Bash on macOS/Linux or
# Git Bash on Windows):
#   bash .claude/release/integrate.sh X.Y
#
# Makes one commit on top of versionX.Y whose tree is the tip of DEV_BRANCH
# (common.sh) minus INTEGRATION_EXCLUDE (common.sh) and minus the dev-only
# blocks below, with the message "chore: integrate <DEV_BRANCH> (<short sha>)". The development history is
# not brought in: the commit's only parent is the previous versionX.Y tip.
# The branch ref is moved by fast-forward with git plumbing, so no checkout,
# branch switch or working-tree change is needed. Nothing is pushed: the push
# command is printed at the end. If the new tree still has an excluded path or
# a match of ASSISTANT_NAMES, the branch is not moved.
# Rules: _GUILDAdoc/developer/git-workflow.html#integration
set -u
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

[ $# -eq 1 ] || die "usage: bash .claude/release/integrate.sh X.Y"
version=$1
check_version "$version"
branch=version$version

# Lines that open and close a dev-only block. The block stays in the
# development files but is cut out of every snapshot, marker lines included:
#   # >>> dev-only ...      ...  # <<< dev-only ...     (.gitignore and similar)
#   <!-- dev-only:start --> ...  <!-- dev-only:end -->   (HTML)
DEV_ONLY_START='^[[:space:]]*(# >>> dev-only|<!-- dev-only:start)([[:space:]].*)?$'
DEV_ONLY_END='^[[:space:]]*(# <<< dev-only|<!-- dev-only:end)([[:space:]].*)?$'
# Names that must not appear anywhere in a snapshot (case-insensitive).
ASSISTANT_NAMES='claude|codex|copilot|anthropic'

# Copy stdin to stdout without the dev-only blocks; fail on unmatched markers.
# $1 is the file name for the error messages.
strip_dev_only() {
  awk -v s="$DEV_ONLY_START" -v e="$DEV_ONLY_END" -v f="$1" '
    $0 ~ s { if (inside) { print f ":" NR ": dev-only start inside a block" > "/dev/stderr"; bad = 1; exit 1 }
             inside = 1; next }
    $0 ~ e { if (!inside) { print f ":" NR ": dev-only end without a start" > "/dev/stderr"; bad = 1; exit 1 }
             inside = 0; next }
    !inside { print }
    END { if (!bad && inside) { print f ": dev-only block not closed" > "/dev/stderr"; exit 1 } }'
}

go_to_repo_root
has_ref "refs/heads/$DEV_BRANCH" || die "no local branch $DEV_BRANCH"
has_ref "refs/heads/$branch" || die "no local branch $branch (create it from origin: git branch --track $branch origin/$branch)"
if has_ref "refs/remotes/origin/$branch" && ! git merge-base --is-ancestor "origin/$branch" "$branch"; then
  die "local $branch is behind origin/$branch; update it first (git fetch origin $branch:$branch)"
fi
# update-ref would leave a worktree that has the branch checked out out of sync.
if git worktree list --porcelain | grep -qx "branch refs/heads/$branch"; then
  die "$branch is checked out in a worktree (git worktree list); switch that worktree to another branch first"
fi

dev=$(git rev-parse "refs/heads/$DEV_BRANCH^{commit}")
dev_short=$(git rev-parse --short "$dev")
old=$(git rev-parse "refs/heads/$branch^{commit}")

last=$(git log -1 --format=%s "$old")
if [[ $last =~ ^chore:\ integrate\ .+\ \(([0-9a-f]+)\)$ ]]; then
  last_dev=$(git rev-parse -q --verify "${BASH_REMATCH[1]}^{commit}")
  [ "$last_dev" != "$dev" ] || die "$DEV_BRANCH ($dev_short) is unchanged since the last integration into $branch"
fi

# Build the snapshot tree in a temporary index; the real index is untouched.
tmp=$(mktemp -d) || die "cannot create a temporary folder"
trap 'rm -rf "$tmp"' EXIT
export GIT_INDEX_FILE=$tmp/index
git read-tree "$dev" || die "cannot read the tree of $DEV_BRANCH"
git rm -r -q -f --cached --ignore-unmatch -- "${INTEGRATION_EXCLUDE[@]}" >/dev/null ||
  die "cannot remove the excluded paths from the snapshot"
# Replace each file that has dev-only markers (outside the excluded paths) by
# a stripped copy.
not_excluded=()
for p in "${INTEGRATION_EXCLUDE[@]}"; do not_excluded+=(":(exclude)$p"); done
stripped=()
while IFS= read -r f; do
  [ -n "$f" ] || continue
  mode=$(git ls-tree "$dev" -- "$f" | cut -d' ' -f1)
  git cat-file blob "$dev:$f" | strip_dev_only "$f" >"$tmp/stripped" ||
    die "unmatched dev-only markers in $f on $DEV_BRANCH"
  blob=$(git hash-object -w "$tmp/stripped") || die "cannot write the stripped $f"
  git update-index --cacheinfo "$mode,$blob,$f" || die "cannot stage the stripped $f"
  stripped+=("$f")
done < <(git grep -l -I -E -e "$DEV_ONLY_START" -e "$DEV_ONLY_END" "$dev" -- . "${not_excluded[@]}" | sed "s|^$dev:||")
tree=$(git write-tree) || die "cannot write the snapshot tree"
unset GIT_INDEX_FILE

[ "$tree" != "$(git rev-parse "$old^{tree}")" ] || die "the snapshot of $DEV_BRANCH ($dev_short) is identical to $branch; nothing to integrate"

new=$(git commit-tree "$tree" -p "$old" -m "chore: integrate $DEV_BRANCH ($dev_short)") ||
  die "cannot create the integration commit"

left=$(git ls-tree -r --name-only "$new" -- "${INTEGRATION_EXCLUDE[@]}")
[ -z "$left" ] || die "the integration commit still contains excluded paths ($branch not moved):
$left"
# git grep on a commit does not enter submodules (gitlinks).
hits=$(git grep -n -i -E "$ASSISTANT_NAMES" "$new" | sed "s|^$new:||")
[ -z "$hits" ] || die "the integration commit still mentions $ASSISTANT_NAMES ($branch not moved).
Mark these lines dev-only on $DEV_BRANCH or reword them:
$hits"

git update-ref -m "integrate: $DEV_BRANCH ($dev_short)" "refs/heads/$branch" "$new" "$old" ||
  die "cannot move $branch to the integration commit"

echo "Integrated $DEV_BRANCH ($dev_short) into $branch: $(git rev-parse --short "$old") -> $(git rev-parse --short "$new")"
echo "Excluded paths absent: ${INTEGRATION_EXCLUDE[*]}"
echo "Dev-only blocks removed from: ${stripped[*]:-(none)}"
echo "No match of '$ASSISTANT_NAMES' in the snapshot (submodules not searched)"
git diff --shortstat "$old" "$new"
echo "Review (git show --stat $branch), then push with:"
echo "  git push origin $branch"
