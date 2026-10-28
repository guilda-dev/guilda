# Shared by release.sh and start-version.sh (sourced, not run).
# Rules: _GUILDAdoc/developer/git-workflow.html#release

# Coding-assistant config: tracked on development branches, never in main.
ASSISTANT_PATHS=(.claude .codex .github/copilot-instructions.md)

die() {
  echo "error: $*" >&2
  exit 1
}

# Both scripts switch away from a branch that contains them, which deletes
# this folder from the working tree. Re-run from a temporary copy so the
# running script is never removed (also needed on Windows, where an open
# file cannot be deleted).
run_from_copy() {
  if [ -z "${GUILDA_RELEASE_TMP:-}" ]; then
    local tmp
    tmp=$(mktemp -d) || die "cannot create a temporary folder"
    cp "$(dirname "${BASH_SOURCE[1]}")"/*.sh "$tmp"/ || die "cannot copy the release scripts"
    GUILDA_RELEASE_TMP=$tmp exec bash "$tmp/$(basename "${BASH_SOURCE[1]}")" "$@"
  fi
  trap 'rm -rf "$GUILDA_RELEASE_TMP"' EXIT
}

check_version() {
  [[ $1 =~ ^[0-9]+\.[0-9]+$ ]] || die "version must look like X.Y (e.g. 4.0), got '$1'"
}

go_to_repo_root() {
  local top
  top=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a git repository"
  cd "$top" || die "cannot enter $top"
}

require_clean() {
  [ -z "$(git status --porcelain)" ] || die "working tree is not clean; commit or stash your changes first"
}

has_ref() {
  git rev-parse -q --verify "$1" >/dev/null
}

# Make sure a local main exists (created from origin/main when missing) and
# warn when it lacks commits from origin/main (fetch first: git fetch origin).
ensure_main() {
  if ! has_ref "refs/heads/main"; then
    has_ref "refs/remotes/origin/main" || die "no main branch (local or origin)"
    git branch -q --track main origin/main || die "cannot create main from origin/main"
  fi
  if has_ref "refs/remotes/origin/main" && ! git merge-base --is-ancestor origin/main main; then
    echo "warning: local main is missing commits from origin/main; update it first (git switch main && git pull)" >&2
  fi
}
