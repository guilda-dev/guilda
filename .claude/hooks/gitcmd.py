"""Shared helpers for the GUILDA Claude Code hooks: read the hook input and
split a Bash command line into the git commands it runs.

Rules are documented in _GUILDAdoc/developer/git-workflow.html.
"""
import json
import os
import re
import shlex
import subprocess
import sys

# Work branch: <type>/<issue>-<slug> (git-workflow.html#branch-names).
# The issue number is optional for now because the team has no GitHub Issues
# yet; make "([0-9]+-)" mandatory once Issues are in use.
WORK_BRANCH = re.compile(r"^(feature|fix|refactor|docs|test)/([0-9]+-)?[a-z0-9]+(-[a-z0-9]+)*$")
# Long-lived branches: main (releases) and the integration branch versionX.Y.
PROTECTED_BRANCH = re.compile(r"^(main|version[0-9]+\.[0-9]+)$")

SEPARATORS = {"&&", "||", ";", "|", "&", "(", ")", ";;", "|&"}
# git options that take a separate value before the subcommand.
GIT_GLOBAL_WITH_VALUE = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path"}


def read_input():
    raw = sys.stdin.buffer.read().decode("utf-8", errors="replace")
    return json.loads(raw) if raw.strip() else {}


def strip_heredocs(command):
    """Drop heredoc bodies so commit messages are never parsed as commands."""
    out, end = [], None
    for line in command.split("\n"):
        if end is not None:
            if line.strip() == end:
                end = None
            continue
        out.append(line)
        m = re.search(r"<<-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1", line)
        if m:
            end = m.group(2)
    return "\n".join(out)


def simple_commands(command):
    """Yield the token list of every simple command in a Bash command line."""
    text = strip_heredocs(command).replace("\n", ";")
    try:
        lexer = shlex.shlex(text, posix=True, punctuation_chars=";&|()")
        lexer.whitespace_split = True
        tokens = list(lexer)
    except ValueError:  # unbalanced quotes: fall back to a plain split
        tokens = re.split(r"\s+|(&&|\|\||;|\|)", text)
        tokens = [t for t in tokens if t]
    current = []
    for tok in tokens:
        if tok in SEPARATORS:
            if current:
                yield current
            current = []
        else:
            current.append(tok)
    if current:
        yield current


def git_commands(command, cwd):
    """Yield (subcommand, args, cwd) for every git call, following `cd` and `git -C`."""
    cwd = cwd or os.getcwd()
    for tokens in simple_commands(command):
        while tokens and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", tokens[0]):
            tokens = tokens[1:]  # FOO=bar git ...
        if not tokens:
            continue
        if tokens[0] == "cd" and len(tokens) > 1:
            cwd = os.path.join(cwd, os.path.expanduser(tokens[1]))
            continue
        if os.path.basename(tokens[0]).lower() not in ("git", "git.exe"):
            continue
        i, git_cwd = 1, cwd
        while i < len(tokens) and tokens[i].startswith("-"):
            if tokens[i] in GIT_GLOBAL_WITH_VALUE and i + 1 < len(tokens):
                if tokens[i] == "-C":
                    git_cwd = os.path.join(git_cwd, os.path.expanduser(tokens[i + 1]))
                i += 2
            else:
                i += 1
        if i < len(tokens):
            yield tokens[i], tokens[i + 1:], git_cwd


def git(cwd, *args):
    try:
        r = subprocess.run(["git", *args], cwd=cwd, capture_output=True)
    except OSError:
        return None
    if r.returncode != 0:
        return None
    return r.stdout.decode("utf-8", errors="replace").strip()


def current_branch(cwd):
    return git(cwd, "symbolic-ref", "--short", "-q", "HEAD")


def block(message):
    """Exit code 2 blocks the tool call; stderr is shown to Claude."""
    sys.stderr.write(message.rstrip() + "\n")
    sys.exit(2)
