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
  development branch with `git merge --no-ff`.
- Nothing is pushed without the user's approval.

## Assistant files
- No assistant files at the repository root. Assistant config lives in
  `.claude/`, `.codex/`, and `.github/copilot-instructions.md`, and never lands
  in `main`: `.claude/release/release.sh` removes it at release and
  `.claude/release/start-version.sh` restores it (see `git-workflow.html#release`).
