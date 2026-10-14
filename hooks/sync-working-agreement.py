#!/usr/bin/env python3
"""SessionStart hook: keep the working agreement current everywhere.

The central repo (arjunlohan/claude.md) is the source of truth for
    CLAUDE.md   -> ~/.claude/CLAUDE.md
    rules/*.md  -> ~/.claude/rules/
    hooks/*.py  -> ~/.claude/hooks/
1. Fast-forward the central repo from GitHub, at most hourly and only when it
   sits clean on main.
2. Copy each file's latest committed version into ~/.claude as a plain file
   (Claude Code skips a symlinked or hard-linked user CLAUDE.md in some
   session types).
3. If the session's repo vendors an older copy of the template as its CLAUDE.md,
   replace it with the latest and say so.
A file that is not byte-identical to some past version of its source holds
someone's edits, so it is never overwritten.
"""
import hashlib
import json
import os
import subprocess
import sys
import time
from fnmatch import fnmatchcase
from pathlib import Path

HOME = Path.home()
CENTRAL = Path(os.environ.get("CLAUDE_MD_CENTRAL", HOME / "Downloads" / "GitHub" / "claude.md"))
CLAUDE_DIR = HOME / ".claude"
SYNCED = ("CLAUDE.md", "rules/*.md", "hooks/*.py")  # each lands at the same path under CLAUDE_DIR
STAMP = CLAUDE_DIR / "state" / "working-agreement-pull"
PULL_EVERY_S = 3600


def git(*args, cwd=CENTRAL, text=True):
    r = subprocess.run(["git", "-C", str(cwd), *args], capture_output=True, text=text, timeout=8)
    return r.returncode, (r.stdout.strip() if text else r.stdout)


def pull_central(notes):
    if STAMP.exists() and time.time() - STAMP.stat().st_mtime < PULL_EVERY_S:
        return
    STAMP.parent.mkdir(parents=True, exist_ok=True)
    STAMP.touch()
    if git("branch", "--show-current")[1] != "main" or git("status", "--porcelain")[1]:
        return  # leave local work in the central repo alone
    before = git("rev-parse", "HEAD")[1]
    if git("pull", "--ff-only", "-q")[0] != 0:
        return
    after = git("rev-parse", "HEAD")[1]
    if after != before:
        notes.append(f"Pulled the latest working agreement from the central repo ({before[:7]} to {after[:7]}).")


def synced_blobs():
    """{path in the central repo: blob id at HEAD} for each file that matches SYNCED."""
    out = git("ls-tree", "-z", "HEAD", "--", "CLAUDE.md", "rules/", "hooks/")[1]  # one level deep
    entries = (entry.partition("\t") for entry in out.split("\0") if entry)
    return {name: meta.split()[2] for meta, _, name in entries if any(fnmatchcase(name, p) for p in SYNCED)}


def refresh(copy, name, blob, create=False):
    """Write `blob` to `copy` when `copy` is missing (if allowed) or an older version of `name`.
    Returns "updated", "custom", or None."""
    if copy.is_symlink() or (not copy.exists() and not create):
        return None
    if copy.is_file():
        data = copy.read_bytes()
        mine = hashlib.sha1(b"blob %d\0" % len(data) + data).hexdigest()  # git's id for these bytes
        if mine == blob:
            return None
        if not git("log", "-1", "--format=%H", f"--find-object={mine}", "--", name)[1]:
            return "custom"
    rc, latest = git("cat-file", "blob", blob, text=False)
    if rc != 0:
        return None
    copy.parent.mkdir(parents=True, exist_ok=True)
    tmp = copy.with_name(copy.name + ".sync-tmp")
    tmp.write_bytes(latest)
    os.replace(tmp, copy)  # atomic: a session reading the file never sees half of it
    return "updated"


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        data = {}
    notes = []
    try:
        if not (CENTRAL / ".git").exists():
            return 0
        pull_central(notes)
        blobs = synced_blobs()
        updated, custom = [], []
        for name, blob in blobs.items():
            status = refresh(CLAUDE_DIR / name, name, blob, create=True)
            if status:
                (updated if status == "updated" else custom).append(f"~/.claude/{name}")
        if updated:
            head = git("rev-parse", "--short", "HEAD")[1]
            notes.append(f"Synced {', '.join(updated)} from the central repo ({head}).")
        if custom:
            notes.append(f"Not synced because of local edits that are not in the central repo: "
                         f"{', '.join(custom)}. Move those edits into arjunlohan/claude.md.")
        rc, top = git("rev-parse", "--show-toplevel", cwd=data.get("cwd") or os.getcwd())
        if "CLAUDE.md" in blobs and rc == 0 and not Path(top).samefile(CENTRAL):
            copy = Path(top) / "CLAUDE.md"
            if refresh(copy, "CLAUDE.md", blobs["CLAUDE.md"]) == "updated":
                notes.append(f"{copy} was an older copy of the central CLAUDE.md template; it now matches "
                             "the latest version. Mention this uncommitted change and commit it with the next change.")
    except (OSError, subprocess.SubprocessError, ValueError):
        pass
    if notes:
        msg = " ".join(notes)
        print(json.dumps({"systemMessage": msg,
                          "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": msg}}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
