# GUILDA: Claude Code workflow

Git, naming, placement, and documentation rules are in the For Developer pages
(`_GUILDAdoc/developer/`), which are the source of truth. Follow them; this file
only covers how Claude sessions split the work.

## Coordinator and sub-sessions
- The session the user starts is the coordinator. It investigates, settles
  specifications with the user, writes briefs for sub-sessions, reviews their
  diffs, and merges them. It does not edit code itself.
- Code development is split by feature into sub-sessions that run in parallel.
  Each sub-session gets its own worktree, cut from the coordinator's current
  development branch.
- Parallel sub-sessions must not touch the same files. Shared files such as
  `_GUILDAdoc/style.css` are edited by only one session at a time.
- A sub-session's title starts with its work branch name, e.g.
  `docs/visualize-git-workflow: Git Workflow page`.
- A sub-session's first step is renaming the `claude/<name>-<suffix>` branch the
  app creates: `git branch -m <type>/<slug>` (see `git-workflow.html#branch-names`).

## Merging and pushing
- After review, the coordinator merges each sub-session branch into the
  development branch `refactor/design-alignment` with `git merge --no-ff`.
- The development branch reaches `versionX.Y` only as snapshot commits made by
  `bash .claude/release/integrate.sh X.Y` (see `git-workflow.html#integration`);
  never merge into or commit on `versionX.Y` directly.
- Nothing is pushed without the user's approval.
- Exception: the submodules `_GUILDAslides` and `_GUILDAverification` use `main`
  only. Commit directly on `main` (no work branches, no `--no-ff` merges), and
  Claude may push them, but never force-push or delete their `main`.

## Assistant files
- No assistant files at the repository root. Assistant config lives in
  `.claude/`, `.codex/`, and `.github/copilot-instructions.md`, is tracked only
  on the development and work branches, and never lands in `versionX.Y` or
  `main`: `integrate.sh` leaves it (and `notes/`, `.vscode/`) out of every
  snapshot, and `release.sh` removes any that reaches a release merge (see
  `git-workflow.html#integration` and `#release`).
