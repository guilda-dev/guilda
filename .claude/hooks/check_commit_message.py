"""PostToolUse hook (Bash): after `git commit`, check the new commit's first line.

Rule (_GUILDAdoc/developer/git-workflow.html#commits): the first line is
`<type>: <summary>` with type feat|fix|refactor|docs|test|chore, at most 72
characters. Merge commits ("Merge ...") are exempt. The commit already exists,
so the hook asks Claude to fix it with `git commit --amend`.
"""
import json
import re

from gitcmd import git, git_commands, read_input

SUBJECT = re.compile(r"^(feat|fix|refactor|docs|test|chore): .+")
MAX_LENGTH = 72


def problem(subject):
    if subject.startswith("Merge "):
        return None
    if not SUBJECT.match(subject):
        return "it does not match `<type>: <summary>` (type: feat|fix|refactor|docs|test|chore)"
    if len(subject) > MAX_LENGTH:
        return f"it is {len(subject)} characters long (max {MAX_LENGTH})"
    return None


def main():
    data = read_input()
    command = (data.get("tool_input") or {}).get("command") or ""
    cwds = [cwd for sub, _, cwd in git_commands(command, data.get("cwd")) if sub == "commit"]
    if not cwds:
        return
    subject = git(cwds[-1], "log", "-1", "--format=%s")
    reason = subject is not None and problem(subject)
    if reason:
        print(json.dumps({
            "decision": "block",
            "reason": (f"The commit message first line '{subject}' breaks the GUILDA rule: {reason}.\n"
                       "See _GUILDAdoc/developer/git-workflow.html#commits. "
                       "Fix it now with `git commit --amend -m \"<type>: <summary>\"` "
                       "(keep the body and trailers), e.g. `docs: add folder structure page`."),
        }))


if __name__ == "__main__":
    main()
