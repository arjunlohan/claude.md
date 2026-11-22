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
- Measure figure lettering in the built PDF (each `Tf` size times the inclusion scale); `helvet`'s `scaled=0.92` and fake small caps shrink it below the nominal size.
- A model's copy edit can keep every number yet shift meaning (sent→used, decided→finalized, an ambiguous "which" resolved wrongly); read every changed sentence against the original.
- claude.ai's Upload a skill page takes a zip with one top-level folder holding SKILL.md and rejects a `.claude-plugin` manifest; build it with skill-creator's `package_skill.py` instead of copying the layout of a zip you were handed.
- ffmpeg's RGB to YUV conversion defaults to BT.601, but players read HD as BT.709; set `scale=out_color_matrix=bt709` and tag the stream (`-colorspace bt709 -color_primaries bt709 -color_trc bt709`), or colors shift.
- `caffeinate` does not stop sleep on a dying battery; check `pmset -g batt` before an unattended run.
- In zsh, `jobs -r | wc -l` reads 0 in a pipeline, so a job limiter built on it never waits; count jobs with `${#jobstates}`.
- Apply an additive migration (new nullable columns, a widened check) to production before its PR is open for merge, on the user's yes: a merge from another session or the GitHub button can land first and leave deployed code naming columns that do not exist.
- Run a migration as a role without superuser rights on a scratch copy before production: it can pass as the local Postgres superuser and fail on a managed database whose admin role is not one (PlanetScale refused a function whose `set` clause named an extension setting the session had not loaded yet).
- tRPC reserves the router keys `then`, `call` and `apply`: a procedure with one of those names passes `tsc` and the server throws at startup; name it after what it returns (`callRecord`).
- Unlayered CSS beats Tailwind v4 utilities, which live in a layer; before adding shadcn to an app with an older stylesheet, scope its element rules (`table`, `button`, `:focus-visible`) with `:where(.legacy)` so they stop overriding component classes and keep their old specificity.
- A CSS grid with no explicit column track grows to its widest child, so one wide table stretches the whole page on a phone; give page grids `grid-cols-1` (`minmax(0, 1fr)`) and let the table scroll inside its own wrapper.
- A Vercel deployment that fails within seconds with "Resource provisioning failed" and no build log is blocked by a connected Marketplace resource that cannot provision (a suspended database left linked after its data moved); `vercel integration list` names it and `vercel integration resource disconnect <resource> <project>` unblocks every deploy. Disconnect a retired resource when you remove its variables.
