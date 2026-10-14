#!/bin/bash
# Pipe tests for hooks/simplify-gate.py. Usage: tests/test_gate.sh [transcript where /simplify ran in the latest turn]
# PYTHON picks the interpreter (default: python3).
G="$(cd "$(dirname "$0")/.." && pwd)/hooks/simplify-gate.py"; PY="${PYTHON:-python3}"; REAL="$1"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; cd "$T" || exit 1
q() { git -c user.name=t -c user.email=t@t "$@"; }
git init -q --bare remote.git
for r in repo_main repo_feat; do git init -q -b main "$r"; q -C "$r" commit -q --allow-empty -m init; done
q -C repo_main remote add origin "$T/remote.git"; q -C repo_main push -q origin main
q -C repo_feat remote add origin "$T/remote.git"; q -C repo_feat fetch -q origin
git -C repo_feat switch -q -c feat; git -C repo_feat branch -q --set-upstream-to=origin/main feat
cp -R repo_feat repo_up; git -C repo_up config push.default upstream

P='{"type":"user","message":{"content":"please change X"}}'
W='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Write","input":{"file_path":"/x"}}]}}'
E='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{"file_path":"/x"}}]}}'
S='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"simplify"}}]}}'
R='{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"t1","content":"ok"}]},"toolUseResult":{}}'
M='{"type":"user","isMeta":true,"message":{"content":[{"type":"text","text":"skill body"}]}}'
U='{"type":"user","message":{"content":"<command-name>/simplify</command-name>"}}'
X='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Write","input":{"content":"{\"type\":\"user\"}"}}]}}'
printf '%s\n' "$P" "$W" > t_noskill.jsonl
printf '%s\n' "$P" "$W" "$S" "$R" > t_after.jsonl
printf '%s\n' "$P" "$W" "$S" "$R" "$M" "$E" "$R" > t_fix_same_turn.jsonl
printf '%s\n' "$P" "$W" "$S" "$R" "$P" "$E" > t_new_turn_edit.jsonl
printf '%s\n' "$P" "$W" "$U" "$E" > t_slash_then_fix.jsonl
printf '%s\n' "$P" "$S" "$R" "$P" > t_simplify_then_plain_prompt.jsonl
printf '%s\n' "$P" "$S" "$R" "$P" "$X" > t_edit_mentions_user_type.jsonl

fails=0
run() { # name expected cwd transcript command
  "$PY" -I -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]},"cwd":sys.argv[2],"transcript_path":sys.argv[3]}))' "$5" "$3" "$4" | "$PY" -S "$G" 2>/dev/null
  rc=$?; if [ "$rc" = "$2" ]; then r=PASS; else r=FAIL; fails=$((fails + 1)); fi
  printf '%-4s exit=%s want=%s  %s\n' "$r" "$rc" "$2" "$1"
}
C="git commit -m x"; N=t_noskill.jsonl
echo "-- transcript evidence"
run "never simplified" 2 "$T/repo_main" $N "$C"
run "simplify after edit" 0 "$T/repo_main" t_after.jsonl "$C"
run "simplify's own fixes, same turn" 0 "$T/repo_main" t_fix_same_turn.jsonl "$C"
run "edit in a later turn" 2 "$T/repo_main" t_new_turn_edit.jsonl "$C"
run "typed /simplify, then its fixes" 0 "$T/repo_main" t_slash_then_fix.jsonl "$C"
run "simplify, then a prompt with no edits" 0 "$T/repo_main" t_simplify_then_plain_prompt.jsonl "$C"
run "later-turn Write whose content mentions a user entry" 2 "$T/repo_main" t_edit_mentions_user_type.jsonl "$C"
run "missing transcript fails open" 0 "$T/repo_main" /nonexistent.jsonl "$C"
[ -n "$REAL" ] && run "real transcript, simplify ran this turn" 0 "$T/repo_main" "$REAL" "$C"
echo "-- what lands on main"
run "commit on feature branch" 0 "$T/repo_feat" $N "$C"
run "push feature branch" 0 "$T/repo_feat" $N "git push -u origin feat"
run "push HEAD:main" 2 "$T/repo_feat" $N "git push origin HEAD:main 2>&1 | tail -2"
run "push --all" 2 "$T/repo_feat" $N "git push --all origin"
run "push HEAD from main" 2 "$T/repo_main" $N "git push origin HEAD"
run "push +refs/heads/main" 2 "$T/repo_feat" $N "git push origin +refs/heads/main"
run "bare push, upstream main, push.default=upstream" 2 "$T/repo_up" $N "git push"
run "bare push from main" 2 "$T/repo_main" $N "git push"
run "bare push from main, stderr redirected" 2 "$T/repo_main" $N "git push 2>&1"
run "push to origin from main, output discarded" 2 "$T/repo_main" $N "git push origin > /dev/null"
run "push feature branch, stderr redirected" 0 "$T/repo_feat" $N "git push origin feat 2>&1"
echo "-- parsing"
run "-C via variable to main repo" 2 /tmp $N "R=$T/repo_main; git -C \"\$R\" commit -m x"
run "-C via variable to feature repo" 0 "$T/repo_main" $N "R=$T/repo_feat; git -C \"\$R\" commit -m x"
run "export then -C to feature repo" 0 "$T/repo_main" $N "export R=$T/repo_feat; git -C \"\$R\" commit -m x"
run "export -p, then -C to main repo" 2 "$T/repo_feat" $N "export -p >/dev/null; export R=$T/repo_main; git -C \"\$R\" commit -m x"
run "cd into main repo first" 2 /tmp $N "cd $T/repo_main && git commit -m x"
run "cd into feature repo first" 0 "$T/repo_main" $N "cd $T/repo_feat && git commit -m x"
run "chained switch, merge, push" 2 "$T/repo_feat" $N "git switch main && git merge --ff-only feat && git push origin main"
run "time git push origin main" 2 "$T/repo_feat" $N "time git push origin main"
run "command git commit on main" 2 "$T/repo_main" $N "command git commit -m x"
run "git --no-pager commit on main" 2 "$T/repo_main" $N "git --no-pager commit -m x"
run "bash -c git push origin main" 2 "$T/repo_feat" $N "bash -c 'git push origin main'"
run "unresolvable -C counts as main" 2 "$T/repo_feat" $N 'git -C "$NOPE_UNSET" commit -m x'
run "quoted git push in -m, feature" 0 "$T/repo_feat" $N 'git commit -m "remember: git push origin main"'
run "heredoc body mentions git push, feature" 0 "$T/repo_feat" $N "$(printf 'git commit -F - <<%s\nFix it\nthen git push origin main\nEOF' "'EOF'")"
run "heredoc body with apostrophe, feature" 0 "$T/repo_feat" $N "$(printf "git commit -F - <<'EOF'\nDon't break it\ngit push origin main\nEOF")"
run "heredoc commit on main" 2 "$T/repo_main" $N "$(printf "git commit -F - <<'EOF'\nmsg\nEOF")"
run "unbalanced quote falls back to mention" 2 "$T/repo_feat" $N 'git commit -m "unterminated'
run "git push inside echo" 0 "$T/repo_main" $N 'echo "remember to git push later"'
run "git log only" 0 "$T/repo_main" $N "git log --oneline -3"
run "no git at all" 0 "$T/repo_main" $N "ls -la"
start=$("$PY" -c 'import time; print(time.time())')
for i in 1 2 3 4 5 6 7 8 9 10; do echo '{"tool_input":{"command":"ls -la"}}' | "$PY" -S "$G"; done
"$PY" -c "import time; print(f'fast path, mean of 10 non-git calls: {(time.time() - $start) / 10 * 1000:.0f} ms')"
echo "$fails failed"; [ "$fails" = 0 ]
