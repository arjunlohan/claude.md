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

- **Core Principles** — simplicity first, no laziness (root causes, no temporary fixes), minimal impact.
- **Model Calibration** — behavioral tuning for the running model: shared rules (act when informed, ground progress claims in tool results, never end a turn on a promise, don't over-engineer) plus Claude Fable 5 notes (brief instructions, no reasoning-echo, ignore context countdowns) and Claude Opus 4.8 notes (literal instruction following, effort as the lever, deliberate subagent use).
- **Workflow Orchestration** — plan mode gated by risk (ambiguous, architectural, or hard to reverse — not step count), delegating to subagents, a self-improvement loop with one lessons home, verification before anything is called done, demanding elegance (in balance), and autonomous bug fixing.
- **Compute Escalation Ladder** — a three-rung rule for matching machinery to the job: stay in the main context, delegate to subagents, or hand-roll a dynamic workflow — and climb only when the current rung is actually failing.
- **Dynamic Workflows** — the behavioral core: the three failure modes they fix (agentic laziness, self-preferential bias, goal drift) and the rules of use (not the default, budget & pilot, `/goal` + `/loop`, quarantine). The full field guide — API, patterns, use cases — lives in the [appendix below](#appendix-dynamic-workflows-field-guide).
- **Task Management** — plan to `tasks/todo.md`, verify the plan, track progress, summarize changes, document results, capture lessons.
- **Voice & Response Style** — expert-level, precise, direct; no flattery or premature validation; explicit confidence levels; accuracy over approval.
- **Output Format: Prefer HTML for Artifacts** — when to produce a self-contained HTML deliverable instead of Markdown, what to use the full expressive range of HTML for, and what stays in Markdown (chat, source-of-truth files, short todos).
- **Design & Interface Craft** — a pointer to the `finesse` skill (its own repo; see below) for UI, animation, and "make it feel better" work.
- **Prompt & Agent Craft** — a pointer to the `sharpen` skill (its own repo; see below) for writing and refining prompts.

## Companion skills

The craft skills live in their own repos — each with its own install target, so there's never a drifting second copy. `CLAUDE.md` here points to them from its **Design & Interface Craft** and **Prompt & Agent Craft** sections.

| Skill | What it does | Install |
| --- | --- | --- |
| [**finesse**](https://github.com/arjunlohan/finesse) | Design-engineering craft — motion tokens, micro-interactions, surfaces, typography, performance, accessibility. Auto-triggers on UI / "make it feel better" work; `/finesse`. | `npx skills add arjunlohan/finesse` |
| [**sharpen**](https://github.com/arjunlohan/sharpen) | Prompt-engineering coach — scouts context, interviews for the answers that matter, rewrites prompts tuned to the target model (Claude Fable 5 / Opus 4.8). Auto-triggers on prompt work; `/sharpen`. | `npx skills add arjunlohan/sharpen` |

Add `-g` to either command for a global (user-level) install.

## Structure & philosophy

This `CLAUDE.md` is the **portable behavioral layer** — how Claude works in any repo. It is **self-contained**: it stands alone and does **not** `@import` anything (no `@AGENTS.md`).

Project-specific facts — architecture, build and test commands, naming conventions, deploy steps, paths — belong in a **per-project local `AGENTS.md`** kept inside each repo. The two **compose at runtime**: the universal behavior comes from this fetched `CLAUDE.md`, the local detail comes from that repo's `AGENTS.md`.

That separation is the whole point. Behavior is shared and centralized here; project facts stay local where they belong. You never have to reconcile the two, and updating one never disturbs the other.

## Updating

There's exactly one source of truth, so updates are trivial:

1. Edit `CLAUDE.md` in this repo.
2. Commit and push.
3. Each project re-fetches (re-run either install method above) and picks up the new version.

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
