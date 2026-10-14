#!/usr/bin/env python3
"""PreToolUse hook (Bash): run /simplify before committing or pushing to main.

Blocks `git commit` on main or master, and `git push` that targets main or master,
unless the simplify skill ran after the last Write or Edit in this session, or in
the same turn (those edits are its own fixes). Exit code 2 blocks the call and
sends the reason to Claude. A repo it cannot resolve counts as main; a missing
transcript lets the call through.
"""
import sys

RAW = sys.stdin.buffer.read()
if b"git" not in RAW:  # fast path: this hook runs on every Bash call
    sys.exit(0)

import json
import os
import re
import shlex
import subprocess

MAIN = {"main", "master"}
EDIT_TOOLS = {"Write", "Edit", "MultiEdit", "NotebookEdit"}
SLASH = "<command-name>/simplify</command-name>"
# skipped before the command name, along with their options and NAME=value words
PREFIXES = {"time", "command", "builtin", "exec", "nohup", "env", "sudo", "export"}
SHELLS = {"bash", "sh", "zsh"}
GIT_OPTS_WITH_ARG = {"-C", "-c", "--git-dir", "--work-tree", "--namespace"}
ASSIGNMENT = re.compile(r"[A-Za-z_]\w*=")
HEREDOC = re.compile(r"(?<!<)<<(?!<)-?\s*(['\"]?)([A-Za-z_]\w*)\1")
MENTION = re.compile(r"\bgit\b[^\n]*\b(?:commit|push)\b")
VAR = re.compile(r"\$\{?([A-Za-z_]\w*)\}?")
TOOL_USE = re.compile(r'"type":\s*"tool_use"')
USER = re.compile(r'"type":\s*"user"')
TOOL_RESULT = re.compile(r'"type":\s*"tool_result"')
META = re.compile(r'"isMeta":\s*true')


def simple_commands(cmd):
    """Token lists, one per simple command, without heredoc bodies or redirections."""
    lines, kept, i = cmd.replace("\\\n", " ").split("\n"), [], 0
    while i < len(lines):
        kept.append(lines[i])
        for m in HEREDOC.finditer(lines[i]):
            i += 1
            while i < len(lines) and lines[i].strip() != m.group(2):
                i += 1
        i += 1
    lex = shlex.shlex(" ; ".join(kept), posix=True, punctuation_chars=True)
    lex.whitespace_split = True
    cmds, words, target = [], [], False
    for tok in lex:
        if set(tok) <= set(";&|()"):
            if words:
                cmds.append(words)
            words, target = [], False
        elif target:
            target = False  # the file or fd a redirection points at
        elif set(tok) <= set("<>&|"):  # a redirection: >, >>, <, <<, >&, &>
            target = True
            if words and words[-1].isdigit():
                words.pop()  # the fd number in 2>&1
        else:
            words.append(tok)
    return cmds + [words] if words else cmds


def resolve(path, env, cwd):
    for _ in range(3):
        path = VAR.sub(lambda m: env.get(m.group(1)) or os.environ.get(m.group(1)) or "\0", path)
    if "\0" in path:
        return None
    path = os.path.expanduser(path)
    return os.path.join(cwd, path)  # an absolute path wins


def git_calls(cmds, env, cwd):
    """Yield (kind, repo, args) for each git commit or push; repo is None when unknown."""
    for words in cmds:
        i = 0
        while i < len(words) and (ASSIGNMENT.match(words[i]) or words[i] in PREFIXES or
                                  (i and words[i - 1] in PREFIXES and words[i].startswith("-"))):
            if ASSIGNMENT.match(words[i]):
                name, _, value = words[i].partition("=")
                env[name] = value
            i += 1
        if i >= len(words):
            continue
        head, args = os.path.basename(words[i]), words[i + 1:]
        if head == "cd" and args:
            cwd = resolve(args[0], env, cwd) or cwd
        elif head in SHELLS and "-c" in args and args.index("-c") + 1 < len(args):
            yield from git_calls(simple_commands(args[args.index("-c") + 1]), env, cwd)
        elif head == "git":
            repo, j = cwd, 0
            while j < len(args) and args[j].startswith("-"):
                if args[j] in GIT_OPTS_WITH_ARG and j + 1 < len(args):
                    if args[j] == "-C":
                        repo = resolve(args[j + 1], env, cwd)
                    j += 1
                j += 1
            if j < len(args) and args[j] in ("commit", "push"):
                yield args[j], repo, args[j + 1:]


def git_out(repo, *args):
    try:
        r = subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True, timeout=5)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return r.stdout.strip() if r.returncode == 0 else None


def lands_on_main(kind, repo, args):
    if repo is None:
        return True
    branch = git_out(repo, "branch", "--show-current")
    if kind == "push":
        if "--all" in args or "--mirror" in args:
            return True
        refspecs = [a for a in args if not a.startswith("-")][1:]
        if refspecs:
            dests = [r.split(":")[-1].lstrip("+").removeprefix("refs/heads/") for r in refspecs]
            return any((branch if d in ("HEAD", "@") else d) in MAIN | {None, ""} for d in dests)
        target = git_out(repo, "rev-parse", "--abbrev-ref", "@{push}")
        if target:
            return target.split("/", 1)[-1] in MAIN
    return branch is None or branch in MAIN


def simplify_covers_last_edit(transcript):
    """True when /simplify ran in or after the turn of the last edit."""
    turn, edit_turn, simplify_turn = 0, -1, None
    with open(transcript, encoding="utf-8", errors="replace") as f:
        for line in f:
            prompt = USER.search(line) and not TOOL_RESULT.search(line) and not META.search(line)
            if not (prompt or TOOL_USE.search(line)):
                continue
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            if not isinstance(entry, dict):
                continue
            if entry.get("type") == "user":
                if prompt:
                    turn += 1
                    if SLASH in line:
                        simplify_turn = turn
                continue
            content = (entry.get("message") or {}).get("content")
            for block in content if isinstance(content, list) else []:
                if not isinstance(block, dict) or block.get("type") != "tool_use":
                    continue
                if block.get("name") in EDIT_TOOLS:
                    edit_turn = turn
                elif block.get("name") == "Skill" and \
                        str((block.get("input") or {}).get("skill", "")).split(":")[-1] == "simplify":
                    simplify_turn = turn
    return simplify_turn is not None and simplify_turn >= edit_turn


def main():
    try:
        data = json.loads(RAW)
    except ValueError:
        return 0
    cmd = (data.get("tool_input") or {}).get("command") or ""
    try:
        calls = list(git_calls(simple_commands(cmd), {}, data.get("cwd") or os.getcwd()))
    except ValueError:  # unbalanced quotes: fall back to a plain mention check
        calls = [("commit or push", None, [])] if MENTION.search(cmd) else []
    kinds = sorted({kind for kind, repo, args in calls if lands_on_main(kind, repo, args)})
    transcript = data.get("transcript_path")
    if not kinds or not transcript or not os.path.isfile(transcript):
        return 0
    if simplify_covers_last_edit(transcript):
        return 0
    print(f"Blocked: this git {' and '.join(kinds)} lands on main, and /simplify has not run on the "
          "latest edits in this session. Run the simplify skill on the pending change, apply its "
          "fixes, then retry the same command. (Standing rule from CLAUDE.md: run /simplify before "
          "every commit and push to main.)", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
