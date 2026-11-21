"""PreToolUse hook (Edit|Write|MultiEdit|NotebookEdit): block edits to generated files.

Rule (_GUILDAdoc/developer/folder-structure.html#generated): generated files are
rebuilt by GUILDA and must not be edited by hand. Paths are matched relative to
the repository root, so the rule also holds inside .claude/worktrees/<name>/.
"""
import os
import re

from gitcmd import block, git, read_input

SIGNATURE_FIX = "Edit the arguments blocks of the methods instead, then run GUILDA.update_keymap(Signature=true) in MATLAB; the file is generated from them."
DOC_FIX = 'Regenerate it in MATLAB with GUILDA.doc("update", true) instead.'
USER_FIX = "@GUILDA/user/ holds per-user generated settings; change them through GUILDA, not by editing files."

GENERATED = [
    (r"_GUILDAsystem/resources/functionSignatures\.json", SIGNATURE_FIX),
    (r"_GUILDAdoc/database/list_Classes\.js", DOC_FIX),
    (r"_GUILDAdoc/database/GUILDAsystem/.*", DOC_FIX),
    (r"_GUILDAdoc/database/GUILDAobject/.*", DOC_FIX),
    (r"@GUILDA/user/.*", USER_FIX),
]


def repo_relative(path, cwd):
    """Path relative to the repository (or worktree) root, with forward slashes."""
    path = os.path.abspath(os.path.join(cwd or os.getcwd(), path))
    folder = os.path.dirname(path)
    while folder and not os.path.isdir(folder) and os.path.dirname(folder) != folder:
        folder = os.path.dirname(folder)  # file may be new; find an existing parent
    root = git(folder, "rev-parse", "--show-toplevel")
    if root:
        try:
            path = os.path.relpath(path, root)
        except ValueError:  # different drive on Windows
            pass
    return path.replace("\\", "/")


def main():
    data = read_input()
    tool_input = data.get("tool_input") or {}
    path = tool_input.get("file_path") or tool_input.get("notebook_path")
    if not path:
        return
    rel = repo_relative(path, data.get("cwd"))
    for pattern, fix in GENERATED:
        # Anchor at the root, or at any folder boundary if the root was not found.
        if re.search(r"(^|/)" + pattern + "$", rel, re.IGNORECASE):
            block(f"Blocked: '{rel}' is a generated file and must not be edited "
                  "(_GUILDAdoc/developer/folder-structure.html#generated).\n" + fix)


if __name__ == "__main__":
    main()
