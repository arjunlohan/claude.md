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
- **Workflow Orchestration** — plan mode by default for non-trivial work, delegating to subagents, a self-improvement loop that records corrections to `tasks/lessons.md`, verification before anything is called done, demanding elegance (in balance), and autonomous bug fixing.
- **Compute Escalation Ladder** — a three-rung rule for matching machinery to the job: stay in the main context, delegate to subagents, or hand-roll a dynamic workflow — and climb only when the current rung is actually failing.
- **Dynamic Workflows** — the deep section: the three failure modes they fix (agentic laziness, self-preferential bias, goal drift), the workflow API (`agent`, `parallel`, `pipeline`), the six composable patterns, where workflows shine, when **not** to use them, and practical tips.
- **Task Management** — plan to `tasks/todo.md`, verify the plan, track progress, summarize changes, document results, capture lessons.
- **Voice & Response Style** — expert-level, precise, direct; no flattery or premature validation; explicit confidence levels; accuracy over approval.
- **Output Format: Prefer HTML for Artifacts** — when to produce a self-contained HTML deliverable instead of Markdown, what to use the full expressive range of HTML for, and what stays in Markdown (chat, source-of-truth files, short todos).
- **Design & Interface Craft** — a pointer to the `finesse` skill (below) for UI, animation, and "make it feel better" work.

## Skills: `finesse`

This repo also ships an Agent Skill, **`finesse`** — a design-engineering craft layer that teaches Claude (and other skill-aware assistants) the small details that make interfaces feel polished, fast, and physical: motion, micro-interactions, surfaces, typography, performance, and accessibility.

It's an **original** skill, not a fork — though it owes its framing to Jakub Krehel's [make-interfaces-feel-better](https://github.com/jakubkrehel/make-interfaces-feel-better), which it deliberately extends with a motion-token system, a first-class reduced-motion / accessibility policy, interaction states, performance, and modern platform primitives (View Transitions, `@starting-style`, scroll-driven animation).

**Install it** (works with Claude Code, Codex, Cursor, and other skill-aware assistants):

```sh
npx skills add arjunlohan/claude.md
```

Or open Claude Code in any project and ask it to fetch `skills/finesse/SKILL.md`. Once present, it **auto-triggers** on UI/polish work, or you can invoke it manually with `/finesse`.

**What's inside** (`skills/finesse/`):

| File | Covers |
| --- | --- |
| `SKILL.md` | The spine: the motion-token system, core principles, common mistakes, a review/output contract + checklist |
| `motion.md` | Duration/easing/spring tokens, enter/exit, interruptibility, origin, stagger, when-not-to-animate, modern primitives |
| `interaction-states.md` | Hover/active/focus-visible/disabled, loading & skeletons, empty/error states, optimistic UI, menus |
| `surfaces.md` | Concentric radius, shadows vs borders & elevation, image outlines, optical alignment, hit areas |
| `typography.md` | Wrapping, smoothing, tabular numbers, hierarchy, measure, line-height, fluid sizing |
| `layout-and-color.md` | Spacing & grouping, alignment, near-black/white, functional color scales, depth |
| `performance.md` | Compositor-only animation, `will-change`, FLIP, the tool ladder, 60fps/RAIL, perceived speed |
| `accessibility.md` | `prefers-reduced-motion` policy, forced-colors, contrast, focus, semantics & ARIA |
| `sources.md` | Who each principle comes from, with links |

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
