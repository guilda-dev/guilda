"""Tests for check_git_command.py, the PreToolUse hook that enforces the git rules.

Runs the hook through run.sh with the JSON input Claude Code passes, against
throwaway repositories whose origin URL decides the rules (main-only repositories
guilda-slides / guilda-verification versus everything else). A local-path origin
is followed to that repository's own origin.

    python3 -m unittest discover -s .claude/hooks -p "test_*.py" -v
"""
import json
import os
import subprocess
import tempfile
import unittest

HOOKS = os.path.dirname(os.path.abspath(__file__))
RUN = os.path.join(HOOKS, "run.sh")


def git(cwd, *args):
    subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True)


def make_repo(root, name, url=None):
    path = os.path.join(root, name)
    os.makedirs(path)
    git(path, "init", "-q")
    git(path, "symbolic-ref", "HEAD", "refs/heads/main")
    git(path, "config", "user.name", "test")
    git(path, "config", "user.email", "test@example.com")
    git(path, "commit", "-q", "--allow-empty", "-m", "chore: init")
    if url:
        git(path, "remote", "add", "origin", url)
    return path


def make_detached(root, name, url):
    path = make_repo(root, name, url)
    git(path, "checkout", "-q", "--detach")
    return path


class CheckGitCommandTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        root = cls.tmp.name
        cls.slides = make_repo(root, "slides", "git@github.com:guilda-dev/guilda-slides.git")
        cls.verification = make_repo(root, "verification",
                                     "https://github.com/guilda-dev/guilda-verification")
        cls.guilda = make_repo(root, "guilda", "git@github.com:guilda-dev/guilda.git")
        cls.no_origin = make_repo(root, "no-origin")
        cls.slides_old = make_repo(root, "slides-old",
                                   "https://github.com/guilda-dev/guilda-slides-old.git")
        cls.slides_detached = make_repo(root, "slides-detached",
                                        "https://github.com/guilda-dev/guilda-slides.git")
        git(cls.slides_detached, "checkout", "-q", "--detach")
        cls.guilda_detached = make_repo(root, "guilda-detached",
                                        "https://github.com/guilda-dev/guilda.git")
        git(cls.guilda_detached, "checkout", "-q", "--detach")
        # A linked worktree, where .git is a file (as in a submodule checkout).
        cls.slides_linked = os.path.join(root, "slides-linked")
        git(cls.slides, "worktree", "add", "-q", "--detach", cls.slides_linked)
        # Local clones: origin is a local path whose repository has its own origin.
        cls.verif_main = make_repo(root, "verif-main",
                                   "git@github.com:guilda-dev/guilda-verification.git")
        cls.verif_local = make_detached(root, "verif-local", cls.verif_main)
        cls.verif_file = make_detached(root, "verif-file", "file://" + cls.verif_main)
        cls.verif_relative = make_detached(root, "verif-relative", "../verif-main")
        cls.verif_old = make_repo(root, "verif-old",
                                  "git@github.com:guilda-dev/guilda-verification-old.git")
        cls.local_to_old = make_detached(root, "local-to-old", cls.verif_old)
        cls.local_to_guilda = make_detached(root, "local-to-guilda", cls.guilda)
        cls.local_missing = make_detached(root, "local-missing", os.path.join(root, "missing"))
        cls.not_a_repo = os.path.join(root, "not-a-repo")
        os.makedirs(cls.not_a_repo)
        cls.local_not_repo = make_detached(root, "local-not-repo", cls.not_a_repo)
        cls.cycle_a = make_detached(root, "cycle-a", os.path.join(root, "cycle-b"))
        cls.cycle_b = make_detached(root, "cycle-b", cls.cycle_a)
        # Four local hops before the GitHub origin: one more than MAX_ORIGIN_HOPS.
        hop = cls.verif_main
        for i in range(3):
            hop = make_repo(root, f"hop{i}", hop)
        cls.too_deep = make_detached(root, "too-deep", hop)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def run_hook(self, command, cwd):
        data = {"tool_name": "Bash", "tool_input": {"command": command}, "cwd": cwd}
        return subprocess.run(["bash", RUN, "check_git_command.py"], input=json.dumps(data),
                              capture_output=True, text=True)

    def assertAllowed(self, command, cwd):
        r = self.run_hook(command, cwd)
        self.assertEqual(r.returncode, 0, f"expected allowed: {command!r}\n{r.stderr}")

    def assertBlocked(self, command, cwd):
        r = self.run_hook(command, cwd)
        self.assertEqual(r.returncode, 2, f"expected blocked: {command!r}\n{r.stderr}")
        self.assertIn("Blocked", r.stderr)

    # Commits on main
    def test_commit_main_slides_ssh_allowed(self):
        self.assertAllowed("git commit -m x", self.slides)

    def test_commit_main_verification_https_allowed(self):
        self.assertAllowed("git commit -m x", self.verification)

    def test_commit_main_guilda_blocked(self):
        self.assertBlocked("git commit -m x", self.guilda)

    def test_commit_main_no_origin_blocked(self):
        self.assertBlocked("git commit -m x", self.no_origin)

    def test_commit_main_similar_name_blocked(self):
        self.assertBlocked("git commit -m x", self.slides_old)

    # Detached HEAD
    def test_commit_detached_slides_allowed(self):
        self.assertAllowed("git commit -m x", self.slides_detached)

    def test_commit_linked_worktree_slides_allowed(self):
        self.assertTrue(os.path.isfile(os.path.join(self.slides_linked, ".git")))
        self.assertAllowed("git commit -m x", self.slides_linked)

    def test_commit_detached_guilda_blocked(self):
        self.assertBlocked("git commit -m x", self.guilda_detached)

    # Local-path origin followed to the clone's own origin
    def test_commit_detached_local_clone_verification_allowed(self):
        self.assertAllowed("git commit -m x", self.verif_local)

    def test_commit_detached_file_url_verification_allowed(self):
        self.assertAllowed("git commit -m x", self.verif_file)

    def test_commit_detached_relative_path_verification_allowed(self):
        self.assertAllowed("git commit -m x", self.verif_relative)

    def test_commit_detached_local_to_similar_name_blocked(self):
        self.assertBlocked("git commit -m x", self.local_to_old)

    def test_commit_detached_local_to_guilda_blocked(self):
        self.assertBlocked("git commit -m x", self.local_to_guilda)

    def test_commit_detached_local_missing_blocked(self):
        self.assertBlocked("git commit -m x", self.local_missing)

    def test_commit_detached_local_not_repo_blocked(self):
        self.assertBlocked("git commit -m x", self.local_not_repo)

    def test_commit_detached_local_cycle_blocked(self):
        data = {"tool_name": "Bash", "tool_input": {"command": "git commit -m x"},
                "cwd": self.cycle_a}
        r = subprocess.run(["bash", RUN, "check_git_command.py"], input=json.dumps(data),
                           capture_output=True, text=True, timeout=30)
        self.assertEqual(r.returncode, 2, r.stderr)
        self.assertIn("Blocked", r.stderr)

    def test_commit_detached_too_many_hops_blocked(self):
        self.assertBlocked("git commit -m x", self.too_deep)

    def test_force_push_main_local_clone_verification_blocked(self):
        self.assertBlocked("git push --force origin main", self.verif_local)

    def test_delete_main_local_clone_verification_blocked(self):
        self.assertBlocked("git push origin --delete main", self.verif_local)

    # Merge / cherry-pick on main
    def test_merge_main_slides_allowed(self):
        self.assertAllowed("git merge fix/foo", self.slides)

    def test_cherry_pick_main_verification_allowed(self):
        self.assertAllowed("git cherry-pick abc123", self.verification)

    def test_merge_main_guilda_blocked(self):
        self.assertBlocked("git merge fix/foo", self.guilda)

    # Push
    def test_force_push_main_slides_blocked(self):
        self.assertBlocked("git push --force origin main", self.slides)

    def test_force_push_plus_refspec_slides_blocked(self):
        self.assertBlocked("git push origin +main", self.slides)

    def test_delete_main_slides_blocked(self):
        self.assertBlocked("git push origin --delete main", self.slides)

    def test_plain_push_main_slides_allowed(self):
        self.assertAllowed("git push origin main", self.slides)

    # Effective cwd
    def test_git_C_slides_from_guilda_allowed(self):
        self.assertAllowed(f"git -C {self.slides} commit -m x", self.guilda)

    def test_cd_slides_from_guilda_allowed(self):
        self.assertAllowed(f"cd {self.slides} && git commit -m x", self.guilda)

    def test_git_C_guilda_from_slides_blocked(self):
        self.assertBlocked(f"git -C {self.guilda} commit -m x", self.slides)


if __name__ == "__main__":
    unittest.main()
