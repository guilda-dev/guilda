#!/usr/bin/env bash
# Rebuild the development history into coarse feature branches.
#
# Purpose: a one-off migration tool. The development branch
# refactor/design-alignment had about 2400 commits (about 460 MB of blobs,
# from GIFs, images and .mlx files replaced many times) above the base of
# version4.0. This script replaces that history with 11 feature branches
# merged with --no-ff, whose final tree is identical to the old tip.
#
# It was run once, on 2026-11-21, with OLD=2367cc26 and BASE=1610f7ae. The
# result (tip c08d691b) replaced refactor/design-alignment on origin that day;
# the old history is kept in ~/GUILDA/guilda-history-backup-20261121.bundle.
# It is not part of the normal workflow (git-workflow.html) and needs no rerun.
#
# How it works: the rebuilt branch `rebuild/design-alignment` starts at BASE
# and ends with a tree identical to OLD. Every feature branch in PLAN is cut
# from the current tip, brings its paths to their OLD state (checkout from
# OLD, git rm of files that OLD does not have), and is merged back with
# --no-ff. Before building, a coverage check makes sure that every path of
# OLD, and every BASE path that OLD no longer has, matches exactly one commit
# in PLAN; it stops and lists the paths otherwise.
#
# Usage:
#   bash .claude/release/rebuild-history.sh [--old SHA] [--base SHA] [--force] [DEST] [SRC]
#     --old SHA   tip whose tree the rebuild reproduces (default 2367cc26)
#     --base SHA  commit the rebuild starts from; must be an ancestor of OLD
#                 (default 1610f7ae)
#     DEST        rebuild clone (default ~/GUILDA/rebuild); must not exist unless --force
#     SRC         repository or bundle to clone from (default /Users/taku/GUILDA/GUILDAdev)
#     --force     delete DEST first and rebuild from scratch
#     --check     run only the coverage check in SRC (a repository, not a bundle); build nothing
#
# Rerunning (read first):
#   - The defaults are the SHAs of the 2026-11-21 run. Against today's
#     history, pass --old and --base explicitly; never use a moving branch
#     name for OLD.
#   - OLD and BASE must be reachable from a ref of SRC (a clone copies only
#     those). After the 2026-11-21 replacement, 2367cc26 is only in the
#     backup bundle; to reproduce that run, pass the bundle file as SRC:
#       bash .claude/release/rebuild-history.sh DEST ~/GUILDA/guilda-history-backup-20261121.bundle
#   - DEST is always a separate, fresh clone (made with git clone --no-local).
#     The script never touches SRC, its branches or its worktrees, and never
#     pushes; bring the result over with a fetch into a temporary ref.
#   - A new top-level folder or a new _auxiliary class fails the coverage
#     check: add it to PLAN before building.
#   - Commit SHAs differ on every run (new commit dates); only the tree is
#     reproducible. Submodules are not initialized; gitlinks come from OLD.
set -euo pipefail
export LC_ALL=C

OLD=2367cc26dea0b6411527b46f0c7f116b93259297
BASE=1610f7ae20c62024f31d4f109df4cad569dd3b8f
TARGET=rebuild/design-alignment
MERGE_INTO=refactor/design-alignment   # name used in merge messages

FORCE=0; CHECK_ONLY=0; ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=1 ;;
    --check) CHECK_ONLY=1 ;;
    --old)  [ $# -ge 2 ] || { echo "--old needs a SHA" >&2; exit 1; }; OLD=$2; shift ;;
    --base) [ $# -ge 2 ] || { echo "--base needs a SHA" >&2; exit 1; }; BASE=$2; shift ;;
    *) ARGS+=("$1") ;;
  esac
  shift
done
DEST=${ARGS[0]:-$HOME/GUILDA/rebuild}
SRC=${ARGS[1]:-/Users/taku/GUILDA/GUILDAdev}

S=_GUILDAsystem
A=_GUILDAsystem/_auxiliary

# ---------------------------------------------------------------------------
# Plan: one record per commit.
#   B|<branch>            starts a branch
#   C|<message>|<spec>... a commit on the current branch (specs are git pathspecs)
# A branch is merged when the next B record (or the end) is reached.
# ---------------------------------------------------------------------------
PLAN=$(cat <<EOF
B|refactor/repo-config
C|refactor: set up the repository files|.gitignore|.gitattributes|README.md|LICENSE
B|refactor/model-core
C|refactor: rebuild the network and element classes|$S/@PowerNetwork|$S/@Bus|$S/@Branch|$S/@Component|$A/@PowerSystemModel|$A/@Parameter|$A/PowerSystemModel.m|$A/@CsvNetHandler
C|refactor: rebuild the controller framework|$S/@LocalController|$S/@GlobalController
C|refactor: rebuild the system tools and shared resources|$S/+tools|$S/resources|$S/_VersionSupport|$A/@LayerPackage|$A/@HistoryGUILDA|$A/SystemTools|$A/auxiliary.m|$A/resources
B|feature/models
C|feature: rebuild the branch models|_GUILDAobject/+branch
C|feature: rebuild the component models|_GUILDAobject/+component
C|feature: rebuild the controller models|_GUILDAobject/+controller
C|feature: rebuild the network models|_GUILDAobject/+network
B|feature/analysis
C|feature: add the result and method base classes|$A/@ResultBase|$A/@MethodBase
C|feature: rebuild the power flow solver|$A/@Method*|:(exclude)$A/@MethodBase|$A/@SolverPF|$A/@ResultPF|$A/@NewtonRaphsonMethod|$A/@PowerFlowCalculation
C|feature: rebuild time simulation with scenarios and events|$A/@SolverODE|$A/@ResultODE|$A/@Scenario|$A/@Event*|$A/@odeEventSet|$A/@odeSimulationResult|$A/@odeSimulator
C|feature: rebuild approximate linearization|$A/@SolverLIN|$A/@ResultLIN|$A/@odeLinearizer
C|feature: rebuild optimal power flow|$A/@SolverOPF|$A/@ResultOPF
C|feature: rebuild continuation power flow|$A/@SolverCPF|$A/@ResultCPF|$A/@ContinuationPowerFlow
B|feature/graph
C|feature: add the graph classes|$A/@Graph*|$A/GraphEventData.m|$A/GraphTimeEventData.m
B|feature/gui-app
C|feature: rebuild the GUI drawers and progress display|$A/@Drawer*|$A/@ProgressGUILDA|$A/@odeProgress
C|feature: rebuild the GUILDA app package|@GUILDA
B|docs/reference-site
C|docs: rebuild the reference site|_GUILDAdoc|:(exclude)_GUILDAdoc/developer|:(exclude)_GUILDAdoc/database/list_developer.js
B|docs/developer-pages
C|docs: rebuild the developer pages|_GUILDAdoc/developer|_GUILDAdoc/database/list_developer.js
B|docs/tutorials
C|docs: rebuild the tutorials|_GUILDAtutorial
B|refactor/submodules
C|refactor: add the doc pages, slides and verification submodules|.gitmodules|_GUILDAdocPages|_GUILDAslides|_GUILDAverification
B|refactor/dev-config
C|refactor: add assistant and editor config and drop +DebugScript|.claude|.codex|.github|.vscode|+DebugScript
C|docs: add the development notes|notes
EOF
)

die() { echo "ERROR: $*" >&2; exit 1; }

# List files of commit $1 matching pathspecs "${@:2}" (NUL-separated), using a
# throwaway index so that full pathspec magic (globs, exclude) applies.
ls_commit() {
  local c=$1; shift
  local idx=$TMPD/idx_$c
  [[ -f $idx ]] || GIT_INDEX_FILE=$idx git read-tree "$c"
  GIT_INDEX_FILE=$idx git ls-files -z -- "$@" | tr '\0' '\n'
}
# All files of commit $1, one per line (raw names, no quoting).
ls_tree() { git ls-tree -r -z --name-only "$1" | tr '\0' '\n'; }

# ---------------------------------------------------------------------------
# Coverage check: every OLD path and every BASE-only path matches exactly one
# commit's pathspec set; nothing else at the top level is unplanned.
# ---------------------------------------------------------------------------
coverage_check() {
  local all=$TMPD/cov_all hits=$TMPD/cov_hits
  ls_tree "$OLD" | sort > "$TMPD/old"
  { cat "$TMPD/old"; ls_tree "$BASE" | sort | comm -23 - "$TMPD/old"; } | sort -u > "$all"
  : > "$hits"
  local line
  while IFS= read -r line; do
    [[ $line == C\|* ]] || continue
    IFS='|' read -r -a f <<< "$line"
    { ls_commit "$OLD" "${f[@]:2}"
      ls_commit "$BASE" "${f[@]:2}" | sort | comm -23 - "$TMPD/old"
    } | sort -u >> "$hits"
  done <<< "$PLAN"
  local unassigned twice
  unassigned=$(sort -u "$hits" | comm -23 "$all" -)
  twice=$(sort "$hits" | uniq -d)
  if [[ -n $unassigned || -n $twice ]]; then
    [[ -n $unassigned ]] && { echo "Unassigned paths:"; echo "$unassigned"; }
    [[ -n $twice ]] && { echo "Paths matched by more than one commit:"; echo "$twice"; }
    die "coverage check failed"
  fi
  echo "coverage check: OK ($(wc -l < "$all" | tr -d ' ') paths, each matched once)"
}

TMPD=$(mktemp -d); trap 'rm -rf "$TMPD"' EXIT

if [[ $CHECK_ONLY == 1 ]]; then
  cd "$SRC"; coverage_check; exit 0
fi

# ---------------------------------------------------------------------------
# Fresh clone
# ---------------------------------------------------------------------------
if [[ -e $DEST ]]; then
  [[ $FORCE == 1 ]] || die "$DEST exists (pass --force to rebuild it from scratch)"
  rm -rf "$DEST"
fi
git clone -q --no-local "$SRC" "$DEST"
cd "$DEST"
git cat-file -e "$OLD^{commit}" && git cat-file -e "$BASE^{commit}" || die "OLD/BASE missing"
git merge-base --is-ancestor "$BASE" "$OLD" || die "BASE is not an ancestor of OLD"
# Author: SRC's configured user when SRC is a repository (else the global one).
if [ -d "$SRC" ]; then
  n=$(git -C "$SRC" config user.name || true);  [ -z "$n" ] || git config user.name "$n"
  e=$(git -C "$SRC" config user.email || true); [ -z "$e" ] || git config user.email "$e"
fi
git config core.quotePath false
coverage_check

git checkout -q -B "$TARGET" "$BASE"

commit_paths() {
  local msg=$1; shift
  local new=$TMPD/new del=$TMPD/del
  ls_commit "$OLD" "$@" | sort > "$new"
  git ls-files -z -- "$@" | tr '\0' '\n' | sort | comm -23 - "$new" > "$del"
  if [[ -s $del ]]; then
    tr '\n' '\0' < "$del" | GIT_LITERAL_PATHSPECS=1 git rm -r -q --pathspec-from-file=- --pathspec-file-nul
  fi
  if [[ -s $new ]]; then
    tr '\n' '\0' < "$new" | GIT_LITERAL_PATHSPECS=1 git checkout -q "$OLD" --pathspec-from-file=- --pathspec-file-nul
  fi
  git diff --cached --quiet && die "empty commit: $msg"
  git commit -q --no-verify -m "$msg"
  printf '  %s  %s\n' "$(git rev-parse --short HEAD)" "$msg"
}

merge_branch() {
  local b=$1
  git checkout -q "$TARGET"
  git merge -q --no-ff --no-verify -m "Merge branch '$b' into $MERGE_INTO" "$b"
  printf '%s  Merge %s\n' "$(git rev-parse --short HEAD)" "$b"
}

cur=""
while IFS= read -r line; do
  [[ -z $line ]] && continue
  IFS='|' read -r -a f <<< "$line"
  case ${f[0]} in
    B) [[ -n $cur ]] && merge_branch "$cur"
       cur=${f[1]}; git checkout -q -b "$cur" "$TARGET"; echo "[$cur]" ;;
    C) commit_paths "${f[1]}" "${f[@]:2}" ;;
  esac
done <<< "$PLAN"
merge_branch "$cur"

# The work tree may hold empty submodule dirs; the index is what counts.
[[ $(git rev-parse "$TARGET^{tree}") == $(git rev-parse "$OLD^{tree}") ]] \
  || { git diff --stat "$OLD" "$TARGET"; die "tree mismatch"; }
echo "tree matches $OLD"
echo "rebuilt tip: $(git rev-parse "$TARGET")"
