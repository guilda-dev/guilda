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
import urllib.parse

# Work branch: <type>/<issue>-<slug> (git-workflow.html#branch-names).
# The issue number is optional for now because the team has no GitHub Issues
# yet; make "([0-9]+-)" mandatory once Issues are in use.
WORK_BRANCH = re.compile(r"^(feature|fix|refactor|docs|test)/([0-9]+-)?[a-z0-9]+(-[a-z0-9]+)*$")
# Long-lived branches: main (releases) and the version branch versionX.Y (snapshots).
PROTECTED_BRANCH = re.compile(r"^(main|version[0-9]+\.[0-9]+)$")
# Internal repositories that use a single main branch (no work branches): the
# submodules _GUILDAslides and _GUILDAverification. Matched on the repository
# name at the end of the origin URL, SSH or HTTPS, with or without ".git".
MAIN_ONLY_REPO = re.compile(r"(^|[/:])guilda-(slides|verification)(\.git)?/*$")
# A local-path origin (a local clone) is followed to that clone's own origin, at
# most this many times (is_main_only_repo).
MAX_ORIGIN_HOPS = 3

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


def local_origin_path(url, base):
    """The directory a local-path origin URL points to, or None for a remote URL.

    Local forms: an absolute or relative path, "~/...", or a file:// URL. A URL with
    a scheme other than file://, or an scp-style address (host:path, no slash before
    the colon), is remote.
    """
    if url.startswith("file://"):
        path = urllib.parse.unquote(urllib.parse.urlsplit(url).path)
    elif "://" in url:
        return None
    elif ":" in url and "/" not in url.split(":", 1)[0]:
        return None  # scp-style user@host:path
    else:
        path = os.path.expanduser(url)
    return os.path.realpath(os.path.join(base, path))


def is_repo_root(path):
    """True if path itself is a repository: a work tree (.git dir or file) or a bare repo."""
    if os.path.exists(os.path.join(path, ".git")):
        return True
    return (os.path.isfile(os.path.join(path, "HEAD"))
            and os.path.isdir(os.path.join(path, "objects")))


def is_main_only_repo(cwd):
    """True if cwd is in a main-only repository (decided by its origin URL).

    When origin is a local path to another repository (a local clone, as in the
    verification procedure), that repository's own origin is followed, up to
    MAX_ORIGIN_HOPS local hops. A missing or unreadable origin, a path that is not a
    repository, a cycle or too many hops returns False, so the strict rules apply.
    """
    seen, repo = set(), cwd
    for _ in range(MAX_ORIGIN_HOPS + 1):
        url = git(repo, "config", "--get", "remote.origin.url")
        if not url:
            return False
        path = local_origin_path(url, repo)
        if path is None:
            return bool(MAIN_ONLY_REPO.search(url))
        if path in seen or not os.path.isdir(path) or not is_repo_root(path):
            return False
        seen.add(path)
        repo = path
    return False


def block(message):
    """Exit code 2 blocks the tool call; stderr is shown to Claude."""
    sys.stderr.write(message.rstrip() + "\n")
    sys.exit(2)
