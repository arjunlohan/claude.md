# claude.md

One canonical `CLAUDE.md` — the behavioral layer I want Claude Code to use in **every** project — kept in one place and fetched on demand.

Stop copy-pasting the same instructions into every repo. Stop letting eight slightly-different `CLAUDE.md` files drift apart. This repo holds the single source of truth: how Claude plans, escalates compute, verifies its work, manages tasks, talks, and formats deliverables. Pull it into any project with one command, and when the canonical file improves, every project re-fetches the new version.

It is deliberately **portable and project-agnostic** — it describes *how I work*, never *what this codebase is*. The repo-specific facts live elsewhere (see [Structure & philosophy](#structure--philosophy)).

## Quick start — two ways to pull it in

### 1. Tell Claude

Paste this into Claude Code in the target project:

> Fetch `https://raw.githubusercontent.com/arjunlohan/claude.md/main/CLAUDE.md` and save it to `./CLAUDE.md` in this project, overwriting any existing one.

### 2. `curl` one-liner

```sh
curl -fsSL https://raw.githubusercontent.com/arjunlohan/claude.md/main/install.sh | sh
```

The installer:

- Backs up any existing `CLAUDE.md` to `CLAUDE.md.bak` before writing.
- Accepts an optional **target-path** argument if you want it somewhere other than `./CLAUDE.md`:

  ```sh
  curl -fsSL https://raw.githubusercontent.com/arjunlohan/claude.md/main/install.sh | sh -s -- path/to/CLAUDE.md
  ```

## What's inside `CLAUDE.md`

A quick tour of the actual sections:

- **How to work**: the smallest change that fully solves the problem, literal reading of requests, planning only when a wrong plan is expensive, stopping only when the work needs you, proof before anything is called done, and a `tasks/todo.md` checklist for long or multi-session work.
- **Compute**: a three-rung ladder (main context, subagents, dynamic workflows) that climbs only when the current rung is failing. Workflows are proposed with a rough cost and wait for an explicit yes. The full field guide (API, patterns, use cases) lives in the [appendix below](#appendix-dynamic-workflows-field-guide).
- **Lessons**: one home per lesson, chosen by scope: project memory for repo facts, `~/.claude/rules/field-lessons.md` for lessons that hold across repos.
- **Voice**: answer first, correct wrong premises, be pointed, hold positions under pushback, and calibrate confidence; plus writing rules for everything produced (no em dashes, no AI tells).
- **Deliverables**: when to produce a self-contained HTML page instead of Markdown, and what stays in Markdown (chat, files committed to a repo, anything posted to GitHub).
- **Skills**: routing to the `finesse` and `sharpen` companion skills (each in its own repo; see below).

## Companion skills

The craft skills live in their own repos, each with its own install target, so there's never a drifting second copy. `CLAUDE.md` here points to them from its **Skills** section.

| Skill | What it does | Install |
| --- | --- | --- |
| [**finesse**](https://github.com/arjunlohan/finesse) | Design-engineering craft — motion tokens, micro-interactions, surfaces, typography, performance, accessibility. Auto-triggers on UI / "make it feel better" work; `/finesse`. | `npx skills add arjunlohan/finesse` |
| [**sharpen**](https://github.com/arjunlohan/sharpen) | Prompt-engineering coach — scouts context, interviews for the answers that matter, rewrites prompts tuned to the target model (Claude Fable 5 / Opus 4.8). Auto-triggers on prompt work; `/sharpen`. | `npx skills add arjunlohan/sharpen` |

Add `-g` to either command for a global (user-level) install.

## Rules and hooks

Two more pieces live here and sync into `~/.claude` on my machines:

- **`rules/field-lessons.md`**: my cross-repo lessons. Claude Code loads `~/.claude/rules/` in every session.
- **`hooks/`**: Claude Code hooks.
  - `sync-working-agreement.py` (SessionStart): fast-forwards this repo at most hourly, then copies `CLAUDE.md`, `rules/*.md`, and `hooks/*.py` into `~/.claude` as plain files. A file that is not an exact past version of its source holds local edits, so it is left alone and reported. It also refreshes a project's `CLAUDE.md` when that file is an older copy of this template.
  - `simplify-gate.py` (PreToolUse on Bash): blocks a `git commit` or `git push` that lands on main until /simplify has run on the latest edits in the session.
  - `no-em-dash.py` (PostToolUse on Write, Edit, MultiEdit): tells Claude when text it wrote contains an em dash.

To set this up on a new machine, clone this repo to `~/Downloads/GitHub/claude.md` (or point `CLAUDE_MD_CENTRAL` at your clone), run `python3 hooks/sync-working-agreement.py </dev/null` once from the clone to copy everything into `~/.claude`, then register the hooks in `~/.claude/settings.json`:

```json
"hooks": {
  "SessionStart": [{ "hooks": [{ "type": "command", "command": "python3 ~/.claude/hooks/sync-working-agreement.py", "timeout": 20 }] }],
  "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "test -f ~/.claude/hooks/simplify-gate.py && python3 -S ~/.claude/hooks/simplify-gate.py" }] }],
  "PostToolUse": [{ "matcher": "Write|Edit|MultiEdit", "hooks": [{ "type": "command", "command": "test -f ~/.claude/hooks/no-em-dash.py && python3 ~/.claude/hooks/no-em-dash.py" }] }]
}
```

Keep the `test -f` guards: `python3` exits 2 when the script is missing, and Claude Code reads exit 2 from a PreToolUse hook as "block", so a missing gate would block every Bash call.

## Structure & philosophy

This `CLAUDE.md` is the **portable behavioral layer** — how Claude works in any repo. It is **self-contained**: it stands alone and does **not** `@import` anything (no `@AGENTS.md`).

Project-specific facts — architecture, build and test commands, naming conventions, deploy steps, paths — belong in a **per-project local `AGENTS.md`** kept inside each repo. The two **compose at runtime**: the universal behavior comes from this fetched `CLAUDE.md`, the local detail comes from that repo's `AGENTS.md`.

That separation is the whole point. Behavior is shared and centralized here; project facts stay local where they belong. You never have to reconcile the two, and updating one never disturbs the other.

## Updating

There's exactly one source of truth, so updates are trivial:

1. Edit `CLAUDE.md`, `rules/`, or `hooks/` in this repo, never the copies in `~/.claude`. After changing a hook, run `tests/test_gate.sh` and `tests/test_sync.sh`.
2. Commit and push.
3. Each project re-fetches (re-run either install method above) and picks up the new version. With the [hooks](#rules-and-hooks) set up, session starts do this for you: they pull this repo at most hourly, refresh `~/.claude`, and refresh the open project's `CLAUDE.md` when it is an older copy. They never delete, so remove a retired rule or hook from `~/.claude` by hand.

Improve the behavioral layer once, and every project inherits it.

## Appendix: Dynamic Workflows field guide

Reference material for Claude Code's dynamic workflows. `CLAUDE.md` carries only the behavioral rules (the three failure modes, when **not** to use them, `/goal` + `/loop`, quarantine) because the harness documents the machinery in-session — this appendix is the human-readable field guide.

**What they are.** Claude writes its own harness on the fly — a JavaScript file, custom-built for the task — that spawns and coordinates subagents, each in its own context window. These are *dynamic*: tailor-made per use case. (A *static* workflow, built with the Claude Agent SDK or `claude -p`, must cover all edge cases, so it stays generic.)

**Trigger:** ask Claude to make a workflow, or say **"ultracode"** to force one.

### The API

A workflow is a JavaScript file using a few special functions, plus standard JS (`JSON`, `Math`, `Array`) for processing data.

- `agent(prompt, opts?)` → `Promise<string | JsonSchema>` — spawn a subagent. Without a schema it returns the agent's final text (a string); with `opts.schema` (a JSON Schema) it returns validated JSON. Options:
  - `schema` — JSON Schema; forces structured, validated JSON output.
  - `model` — `"opus" | "sonnet" | "haiku"`. Omit to inherit.
  - `isolation` — `"worktree"` (its own git checkout) or `"remote"`.
  - `agentType` — a custom or built-in subagent type.
- `parallel([fns])` — fan out, run concurrently. It is a **BARRIER**: waits for all functions before returning.
- `pipeline(items, ...stages)` — each item streams through every stage independently. **No barrier** — item A can be in stage 3 while item B is still in stage 1. This is the default for multi-stage work.

Choose the intelligence level per agent, and whether each runs isolated in its own worktree. If a workflow is interrupted (user action, quitting the terminal), resuming the session picks up where it left off.

### The six patterns (compose them)

1. **Classify-and-act** — a classifier agent decides the task type, then routes to different agents/behavior. Or classify at the end to shape the output.
2. **Fan-out-and-synthesize** — split a task into many smaller steps, run an agent on each, then synthesize. Useful when there are many small steps, or when each step benefits from its own clean context so they don't cross-contaminate. The synthesize step is a **barrier**: it waits for all fan-out agents, then merges their structured outputs into one result.
3. **Adversarial verification** — for each spawned agent, run a separate agent to adversarially verify its output against a rubric or criteria.
4. **Generate-and-filter** — generate many ideas, then filter by a rubric or verification, dedupe, and return only the highest-quality, tested ones.
5. **Tournament** — instead of dividing the work, agents compete on it. Spawn N agents that each attempt the same task with different approaches; judge agents compare results pairwise until you have a winner. (Comparative judgment beats absolute scoring.)
6. **Loop-until-done** — for tasks with an unknown amount of work, keep spawning agents until a stop condition is met (no new findings, no more errors in the logs) instead of a fixed number of passes.

### Where workflows shine

- **Migrations & refactors** — break into units (callsites, failing tests, modules); a subagent per fix in a worktree, another adversarially reviews, then merge. Tell agents to avoid resource-intensive commands so you can maximize parallelism without exhausting the machine.
- **Deep research** — `/deep-research` fans out web searches, fetches sources, adversarially verifies their claims, and synthesizes a cited report. The same shape works off-web — compiling a status report from Slack context, or learning a feature by exploring a codebase in depth.
- **Deep verification** — one agent extracts every factual claim in a report; a subagent checks each in detail; optionally a verification agent audits each source for quality. (Confirm a blog/PR/spec ships nothing wrong.)
- **Sorting** — don't sort 1000+ rows in one prompt (quality degrades, won't fit context). Run a tournament, a pipeline of pairwise-comparison agents, or bucket-rank in parallel then merge. Each comparison is its own agent; the deterministic loop holds the bracket, only the running order stays in context.
- **Memory & rule adherence** — for rules Claude keeps missing even when they're in CLAUDE.md, build one verifier agent per rule, plus a skeptic-persona agent to curb false positives. Reverse it: mine recent sessions and code-review comments for recurring corrections, cluster them with parallel agents, adversarially verify each candidate ("would this rule have prevented a real mistake?"), and distill the survivors back into CLAUDE.md.
- **Root-cause investigation** — generate several independent hypotheses from *disjoint* evidence (separate agents for logs, files, data), then send each before a panel of verifiers and refuters. Structurally prevents self-preferential bias. Works for sales ("why did sales drop in March?"), data engineering, any post-mortem — not just code.
- **Triage at scale** — classify each backlog item, dedupe against what's tracked, and act (attempt the fix or escalate). Pair with `/loop` to triage continuously.
- **Exploration & taste** — for taste-based work (design, naming), explore many solutions and give a review agent a rubric for "good"; done when its criteria are met. Order or select via a tournament.
- **Evals** — spin off agents in worktrees, then comparison agents to grade outputs against a rubric (e.g. evaluating and refining a skill you created).
- **Model & intelligence routing** — a classifier agent researches the task and routes to a smaller or larger model by expected complexity (the best model for "explain how the auth module works" depends on how many files the module has).

### Tips

- **Detailed prompting** using the named patterns produces the best results.
- **Not just for big tasks** — prompt a "quick workflow," e.g. a quick adversarial review of a single assumption.
- **Token budgets** — set an explicit cap by prompting one, e.g. "use 10k tokens."
- **Saving & sharing** — press "s" in the workflow menu to save. Saved workflows live in `~/.claude/workflows`, or distribute them via a skill: put the JavaScript workflow files in the skill folder and reference them in `SKILL.md`, treating them as *templates* rather than scripts to run verbatim.
