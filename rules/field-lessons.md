# Field lessons

Source: `rules/field-lessons.md` in arjunlohan/claude.md (cloned at `~/Downloads/GitHub/claude.md`), copied into `~/.claude/rules/` at session start. Add, change, or prune lessons in the source and commit; a copy edited in place stops syncing.

- Background Bash tasks die at the 2-hour limit along with their children; launch multi-hour runs with nohup in a subshell.
- The session scratchpad is wiped between sessions; work that must survive goes in the repo's gitignored `tasks/`.
- Editing a shell script while it runs corrupts the running copy (bash reads incrementally); copy it first or wait.
- In Next.js repos, run `next build` before pushing; tsc and tests can pass on builds that fail on Vercel.
- In the Browser pane, test `:focus` and `:hover` styles after a real click; programmatic focus does not trigger them.
- Resolve citations against arXiv or Crossref before expanding author initials or paraphrasing titles.
- For design or architecture deliverables, build the smallest executable slice early and test it with negative controls; passing delivery checks is not evidence the design works.
- Claude Code skips a symlinked or hard-linked `~/.claude/CLAUDE.md` in local-agent sessions; keep it a regular file (the sync-working-agreement hook copies the central template into it).
- The Bash tool runs zsh, where an unquoted `$var` does not split into words; use an array (`files=($(cmd))`, then `"${files[@]}"`) or inline command substitution.
