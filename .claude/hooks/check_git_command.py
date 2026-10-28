"""PreToolUse hook (Bash): enforce the GUILDA git rules before a git command runs.

- New branch names must be <type>/<issue>-<slug>       (git-workflow.html#branch-names)
- No commits on main, version*, or non-work branches   (git-workflow.html#branches, #dont)
- No force-push or deletion of main or version*         (git-workflow.html#dont)

Rules are documented in _GUILDAdoc/developer/git-workflow.html.
Merging (`git merge`) is not checked: integrating branches is the coordinator's job.
"""
import re

from gitcmd import PROTECTED_BRANCH, WORK_BRANCH, block, current_branch, git, git_commands, read_input

NAME_HELP = (
    "Rule (_GUILDAdoc/developer/git-workflow.html#branch-names): work branches are named\n"
    "  <type>/<issue>-<slug>   type: feature|fix|refactor|docs|test\n"
    "  slug: lowercase a-z0-9 words joined by hyphens (issue number optional for now)\n"
    "  e.g. feature/42-add-gfm-controller, docs/folder-structure-page\n"
    "main and versionX.Y are long-lived branches: switch to them, never create them."
)

# git branch options that list/delete/configure instead of creating a branch.
BRANCH_NO_CREATE = {
    "-d", "-D", "--delete", "-l", "--list", "-a", "--all", "-r", "--remotes", "-v", "-vv",
    "--verbose", "--show-current", "--contains", "--no-contains", "--merged", "--no-merged",
    "--points-at", "-u", "--set-upstream-to", "--unset-upstream", "--edit-description",
}
BRANCH_WITH_VALUE = {"--sort", "--format", "--column", "-t", "--track"}


def positionals(args, with_value=()):
    out, skip = [], False
    for a in args:
        if skip:
            skip = False
        elif a in with_value:
            skip = True
        elif not a.startswith("-") or a == "-":
            out.append(a)
    return out


def option_value(args, names):
    for i, a in enumerate(args):
        if a in names and i + 1 < len(args):
            return args[i + 1]
    return None


def new_branch_name(sub, args):
    """Return the branch a command creates or renames to, or None."""
    if sub == "switch":
        return option_value(args, ("-c", "-C", "--create", "--force-create"))
    if sub == "checkout":
        return option_value(args, ("-b", "-B", "--orphan"))
    if sub == "worktree" and args[:1] == ["add"]:
        return option_value(args, ("-b", "-B"))
    if sub == "branch":
        if any(a.split("=")[0] in BRANCH_NO_CREATE for a in args):
            return None
        names = positionals(args, BRANCH_WITH_VALUE)
        if not names:
            return None
        if any(a in ("-m", "-M", "--move", "-c", "-C", "--copy") for a in args):
            return names[-1]
        return names[0]
    return None


def check_branch_name(name):
    if WORK_BRANCH.match(name):
        return
    if PROTECTED_BRANCH.match(name):
        block(f"Blocked: do not create or rename a branch to '{name}'.\n{NAME_HELP}")
    block(f"Blocked: branch name '{name}' does not follow the GUILDA naming rule.\n{NAME_HELP}\n"
          "Fix: choose a matching name, e.g. `git branch -m docs/<slug>`.")


def check_commit(branch, cwd):
    if git(cwd, "rev-parse", "--git-dir") is None:
        return  # not a repository: git itself will fail
    if git(cwd, "rev-parse", "-q", "--verify", "MERGE_HEAD"):
        return  # concluding a merge is allowed
    if branch and WORK_BRANCH.match(branch):
        return
    if branch is None:
        block("Blocked: HEAD is detached. Commit on a work branch instead.\n" + NAME_HELP)
    if PROTECTED_BRANCH.match(branch):
        block(f"Blocked: do not commit directly to '{branch}' "
              "(_GUILDAdoc/developer/git-workflow.html#dont).\n"
              "Fix: create a work branch (e.g. `git switch -c fix/<slug>`), commit there, "
              "and merge it by pull request.")
    block(f"Blocked: '{branch}' is not a work branch, so commits are not allowed on it.\n"
          f"{NAME_HELP}\nFix: rename it first, e.g. `git branch -m feature/<slug>`.")


def check_push(args, branch):
    force = any(a in ("-f", "--force") or a.startswith("--force-with-lease")
                or re.fullmatch(r"-[a-zA-Z]*f[a-zA-Z]*", a) for a in args)
    delete = any(a in ("-d", "--delete") for a in args)
    if any(a in ("--all", "--mirror") for a in args) and (force or delete):
        block("Blocked: force-push with --all/--mirror can overwrite main or the integration branch.")
    refspecs = positionals(args, ("-o", "--push-option", "--repo", "--receive-pack", "--exec"))[1:]
    targets = []
    for spec in refspecs or [branch or ""]:
        plus = spec.startswith("+")
        dst = spec.lstrip("+").split(":")[-1]
        dst = re.sub(r"^refs/heads/", "", dst)
        if dst == "HEAD":
            dst = branch or ""
        targets.append((dst, plus or (":" in spec and spec.split(":")[0] == "")))
    for dst, risky in targets:
        if PROTECTED_BRANCH.match(dst) and (force or delete or risky):
            block(f"Blocked: do not force-push or delete '{dst}' "
                  "(_GUILDAdoc/developer/git-workflow.html#dont).\n"
                  "Fix: push without --force/-f/--force-with-lease/'+'; integrate changes by merging.")


def main():
    data = read_input()
    command = (data.get("tool_input") or {}).get("command") or ""
    if "git" not in command:
        return
    switched = {}  # cwd -> branch switched to earlier in the same command line
    for sub, args, cwd in git_commands(command, data.get("cwd")):
        name = new_branch_name(sub, args)
        if name:
            check_branch_name(name)
        if sub in ("switch", "checkout"):
            target = name or (positionals(args)[:1] or [None])[0]
            if name or (target and git(cwd, "rev-parse", "-q", "--verify", "refs/heads/" + target)):
                switched[cwd] = target
        elif sub == "branch" and name and any(a in ("-m", "-M", "--move") for a in args):
            if len(positionals(args, BRANCH_WITH_VALUE)) == 1:
                switched[cwd] = name
        branch = switched.get(cwd) or current_branch(cwd)
        if sub == "commit":
            check_commit(branch, cwd)
        elif sub == "push":
            check_push(args, branch)


if __name__ == "__main__":
    main()
