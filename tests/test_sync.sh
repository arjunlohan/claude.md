#!/bin/bash
# Tests for hooks/sync-working-agreement.py against a throwaway clone and HOME. Usage: tests/test_sync.sh
# PYTHON picks the interpreter (default: python3).
R="$(cd "$(dirname "$0")/.." && pwd)"; H="$R/hooks/sync-working-agreement.py"; PY="${PYTHON:-python3}"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
q() { git -c user.name=t -c user.email=t@t "$@"; }
fails=0
check() { # name expected actual
  if [ "$2" = "$3" ]; then r=PASS; else r=FAIL; fails=$((fails + 1)); fi
  printf '%-4s %s (got: %s)\n' "$r" "$1" "$3"
}
has() { case "$1" in *"$2"*) echo yes;; *) echo no;; esac; }
note() { printf '{"cwd":"%s"}' "$1" | HOME="$T/home" CLAUDE_MD_CENTRAL="$C" "$PY" "$H" |
  "$PY" -c 'import json,sys; s=sys.stdin.read().strip(); print(json.loads(s)["systemMessage"] if s else "")'; }
same() { git -C "$C" show "HEAD:$1" | cmp -s - "$2" && echo yes || echo no; }

# Central clone: v1 has older lessons plus files the hook must skip; v2 has the current lessons.
C="$T/central"; git clone -q "$R" "$C"; mkdir -p "$C/rules" "$C/hooks/extra"
sed '$d' "$R/rules/field-lessons.md" > "$C/rules/field-lessons.md"
cp "$R"/hooks/*.py "$C/hooks/"
echo "# not synced" > "$C/hooks/README.md"; echo "x = 1" > "$C/hooks/extra/nested.py"
q -C "$C" add -A && q -C "$C" commit -qm v1
cp "$R/rules/field-lessons.md" "$C/rules/field-lessons.md"; q -C "$C" commit -qam v2

# HOME: CLAUDE.md current, lessons at v1, one hook edited in place, the other hooks missing
D="$T/home/.claude"; mkdir -p "$D/rules" "$D/hooks"
git -C "$C" show HEAD:CLAUDE.md > "$D/CLAUDE.md"
git -C "$C" show HEAD~1:rules/field-lessons.md > "$D/rules/field-lessons.md"
echo "# my local tweak" > "$D/hooks/no-em-dash.py"
git init -q -b main "$T/bare"

n=$(note "$T/bare")
check "older lessons are updated" yes "$(same rules/field-lessons.md "$D/rules/field-lessons.md")"
check "a missing hook is created" yes "$(same hooks/simplify-gate.py "$D/hooks/simplify-gate.py")"
check "a hook edited in place is left alone" "# my local tweak" "$(cat "$D/hooks/no-em-dash.py")"
check "the edited hook is reported" yes "$(has "$n" "not in the central repo: ~/.claude/hooks/no-em-dash.py.")"
check "hooks/README.md is skipped" no "$([ -e "$D/hooks/README.md" ] && echo yes || echo no)"
check "nested hooks are skipped" no "$([ -e "$D/hooks/extra" ] && echo yes || echo no)"
check "no temp files are left" 0 "$(ls "$D/rules" "$D/hooks" | grep -c sync-tmp)"
check "a second run syncs nothing new" no "$(has "$(note "$T/bare")" Synced)"
git -C "$C" show HEAD:hooks/no-em-dash.py > "$D/hooks/no-em-dash.py"
check "all in sync: no note" "" "$(note "$T/bare")"

# Project copies of the template
old=$(git -C "$C" rev-list -2 HEAD -- CLAUDE.md | tail -1)
P="$T/proj"; git init -q -b main "$P"; git -C "$C" show "$old:CLAUDE.md" > "$P/CLAUDE.md"
n=$(note "$P")
check "an older project copy is refreshed" yes "$(same CLAUDE.md "$P/CLAUDE.md")"
check "the refresh is reported" yes "$(has "$n" "older copy of the central CLAUDE.md template")"
echo "# my project rules" > "$P/CLAUDE.md"
check "a project's own CLAUDE.md gets no note" "" "$(note "$P")"
check "a project's own CLAUDE.md is left alone" "# my project rules" "$(cat "$P/CLAUDE.md")"
git -C "$C" show "$old:CLAUDE.md" > "$C/CLAUDE.md"; note "$C" > /dev/null
check "the central clone is never refreshed as a project" no "$(same CLAUDE.md "$C/CLAUDE.md")"
echo "$fails failed"; [ "$fails" = 0 ]
