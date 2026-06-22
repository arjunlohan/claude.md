---
name: finesse
description: Design-engineering craft for making interfaces feel polished, fast, and physical. Use when building or reviewing UI components, implementing animations or transitions, tuning motion/easing/duration, adding hover/active/focus states, loading/empty/error states, micro-interactions, shadows, borders, radius, typography, or spacing. Triggers on UI polish and "feel" work — "make it feel better", "feels off", "feels janky", "make it pop", "too fast"/"too slow", animation timing, stagger, spring, interruptible animation, prefers-reduced-motion, focus ring, optical alignment, tabular numbers, skeleton/loading state, optimistic UI.
---

# Finesse

Design-engineering craft for interfaces that feel polished, fast, and physical.

Great interfaces are rarely one big thing. They are an accumulation of small, individually invisible details that compound — *felt, not seen*. This skill encodes those details as concrete, committed defaults so the work is consistent instead of vibes. The numbers here are opinionated starting points distilled from the people who set the bar (see `sources.md`); commit to them, then trust your eyes — a value is right when it *feels* right.

## How to use this skill

- **When building UI**, apply these principles by default — you don't need to be asked. Reach for the motion tokens below instead of inventing one-off durations.
- **When reviewing or "making something feel better"**, audit against the [Review checklist](#review-checklist) and return the [Review output contract](#review-output-contract) — every change, grouped, before/after. Do not report a subset.
- **Load a reference file** (linked throughout) when you need the long-form rationale, the good-vs-bad code, or the decision tables. `SKILL.md` alone has every number you need to *act*.
- **Framework-agnostic first.** Examples lead with vanilla CSS / the Web Animations API. Tailwind and Motion (`motion`/`framer-motion`) variants follow. Don't add an animation dependency that isn't already in `package.json` — check first.

## The first rule: motion serves a purpose

If you can't name what an animation communicates — causality, status, spatial continuity, or deliberate delight — cut it. **The best animation is often no animation.**

- **Never animate high-frequency or keyboard-initiated actions.** Opening a menu you open 100×/day, deleting a list item, tabbing through fields — these must feel instant. Animation there is a tax, not a delight.
- **Motion's jobs:** show cause and effect, give feedback, preserve the user's spatial map (where did this come from, where did it go), and — sparingly — add character.

## Motion tokens (the shared contract)

Every animation in the product should pull from one small scale. Inconsistent, hand-picked durations are the single biggest tell of an amateur interface. Define these once at `:root` and reference them everywhere.

```css
:root {
  /* Duration — most UI lives in 150–300ms. Scale UP with travel distance / surface size. */
  --duration-instant: 0ms;     /* keyboard + high-frequency actions: no animation */
  --duration-fast:    150ms;   /* micro: hover, press, color, icon tint/recolor */
  --duration-base:    200ms;   /* standard: toggles, small reveals, tabs */
  --duration-slow:    300ms;   /* modals, drawers, popovers, larger surfaces */
  --duration-slower:  450ms;   /* full-screen / large-travel transitions */

  /* Easing — chosen by DIRECTION of travel. Custom curves beat the weak built-in keywords. */
  --ease-standard: cubic-bezier(0.2, 0, 0, 1);      /* small in-place state changes (default) */
  --ease-out:      cubic-bezier(0.05, 0.7, 0.1, 1); /* ENTERING / decelerating — settles into place */
  --ease-in:       cubic-bezier(0.3, 0, 0.8, 0.15); /* EXITING / accelerating — leaves decisively */
  --ease-in-out:   cubic-bezier(0.4, 0, 0.2, 1);    /* moving ACROSS screen / morphing in place */
  --ease-ios:      cubic-bezier(0.32, 0.72, 0, 1);  /* drawers / sheets / sliding panels */
  /* linear is ONLY for continuous loops: spinners, marquees, progress. Never for discrete UI. */
}
```

**Three rules that make the tokens work:**

1. **Exit faster than enter** — roughly one tier down (a 300ms enter → ~200ms exit). Things should leave more quickly and quietly than they arrive.
2. **Duration scales with distance and size.** A tooltip is `--duration-fast`; a full-screen route transition is `--duration-slower`. Same easing family, longer time.
3. **Direction picks the easing.** Entering → `--ease-out`. Leaving → `--ease-in`. Repositioning something already on screen → `--ease-in-out`.

**Springs** (for gesture-driven or physical motion). Specify *response* and *bounce*, not a fixed duration — "nothing in the real world changes instantly." Keep bounce low for functional UI.
- Functional (icon swap, toggle): `{ type: "spring", duration: 0.3, bounce: 0 }`
- Apple-style physical (sheets, playful): `{ type: "spring", duration: 0.5, bounce: 0.2 }`
- Avoid springs where precision matters more than feel.

**Distances:** enter from `translateY(8–12px)`, never from far away. **Never animate from `scale(0)`** — it looks like it teleports in; start from ~`0.9`. Press feedback is `scale(0.96)` — never below `0.95` (feels exaggerated).

→ Full motion guidance, enter/exit recipes, interruptibility, origin-awareness, and modern primitives: **[motion.md](motion.md)**

## Core principles

**Motion** → [motion.md](motion.md)
1. Purpose over decoration; don't animate high-frequency/keyboard actions.
2. Animate **only `transform`, `opacity`, `filter`** — never layout properties. Never `transition: all`.
3. Use the **token scale**; exit faster than enter; duration scales with size.
4. **Easing by direction:** `--ease-out` enter, `--ease-in` exit, `--ease-in-out` on-screen movement.
5. **Make animations interruptible** — CSS *transitions* (not keyframes) for stateful UI; they retarget mid-flight. Keyframes only for one-shot staged sequences.
6. **Origin-aware:** set `transform-origin` so things grow from their trigger (a dropdown opens from its button).
7. Press feedback `scale(0.96)`; stagger groups ~`100ms`, words ~`80ms`.

**States & feedback** → [interaction-states.md](interaction-states.md)
8. Every interactive element needs **hover, active, and `:focus-visible`** — but gate hover behind `@media (hover: hover)` so it doesn't stick on touch.
9. **Feedback is immediate and trigger-local:** an inline checkmark on "copied," not a toast across the screen. Toggles take effect instantly; disable submit buttons after submit.
10. **Design the unhappy paths:** loading (skeletons, with a ~150–300ms show-delay and ~300–500ms minimum visible time to avoid flicker), empty, error, disabled.
11. **Optimistic UI:** render the result immediately, reconcile/roll back on the server response. Responsiveness must never depend on network latency.

**Surfaces & depth** → [surfaces.md](surfaces.md)
12. **Concentric radius:** `outer = inner + padding`. Mismatched nested radii are the most common "off" tell.
13. **Shadows for elevation, not dividers.** Light comes from above; layer shadows and tint them with the surface hue — never pure black. Use real borders for dividers, table cells, and input outlines.
14. **Optical > mathematical alignment:** icon-side button padding is ~2px less than the text side; nudge play triangles ~2px right; fix asymmetric glyphs in the SVG.
15. **Hit area ≥ 44×44px** (≥40 acceptable); extend small controls with a pseudo-element. Never overlap two hit areas.

**Typography** → [typography.md](typography.md)
16. **Hierarchy via weight and color, not size alone.** Three text colors (primary/secondary/tertiary); never pure black. Body & inputs **≥16px** (inputs <16px trigger iOS zoom).
17. **`tabular-nums`** for any number that changes in place (timers, prices, counters) to stop layout shift. **`text-wrap: balance`** on headings, **`pretty`** on body. Antialias once at the root. Never change font-weight on hover (layout shift).

**Layout & color** → [layout-and-color.md](layout-and-color.md)
18. **Spacing signals grouping:** more space between groups, less within. Use a constrained scale on a 4/8px base. Align everything to something. No dead zones between list items — extend padding, not gaps.
19. **Near-black/near-white, saturated neutrals, functional color scales.** Prefer fewer borders (use spacing, background, shadow). Color carries meaning (red danger, green success) but never *alone*.

**Performance** → [performance.md](performance.md)
20. **`transform`/`opacity`/`filter` run on the GPU compositor; everything else costs layout/paint and drops frames.** Target 60fps. `will-change` only just-in-time and sparingly. Tool ladder: CSS → Web Animations API → JS library.

**Accessibility (never optional)** → [accessibility.md](accessibility.md)
21. **Respect `prefers-reduced-motion` for every animation.** Reduced motion ≠ no motion: *substitute* a fade or instant change, don't just delete meaning. Opt motion in via `(prefers-reduced-motion: no-preference)`. Never convey information by motion or color alone. Focus rings via `box-shadow` (respects radius). Semantics before ARIA; `aria-label` on icon-only controls.

## Modern primitives worth reaching for

Before hand-rolling, check whether a platform primitive does it better (degrade gracefully):
- **View Transitions API** (`document.startViewTransition`, `view-transition-name`) — shared-element and route transitions, the cases people used to fake with FLIP.
- **`@starting-style` + `transition-behavior: allow-discrete`** — CSS-native enter animations for popovers/dialogs/`display:none`, no JS.
- **Scroll-driven animations** (`animation-timeline: scroll()/view()`) — scroll progress without scroll listeners.
- **`interpolate-size: allow-keywords`** — animate to/from `height: auto`.

## Common mistakes

| Mistake | Fix |
| --- | --- |
| `transition: all` | Name the exact properties: `transition: transform 150ms, opacity 150ms` |
| Animating `width`/`height`/`top`/`margin` | Animate `transform`/`opacity`; use FLIP or View Transitions for layout changes |
| Same duration for enter and exit | Exit ~one tier faster than enter |
| `linear` easing on UI | `--ease-out` to enter, `--ease-in` to exit |
| Keyframes for hover/toggle/open | CSS transitions — they interrupt and retarget mid-flight |
| Animating from `scale(0)` / `opacity` only | Start from ~`scale(0.9)` + small `translateY`; combine transform + opacity |
| No `prefers-reduced-motion` | Wrap motion; substitute a fade or instant change |
| Removing the focus outline for looks | Replace with a `:focus-visible` `box-shadow` ring |
| Hover state stuck on mobile | Gate with `@media (hover: hover)` |
| Numbers jumping width as they change | `font-variant-numeric: tabular-nums` |
| Mismatched nested corner radii | `outer = inner + padding` |
| Spinner during a 120ms fetch | Optimistic update; or show-delay the loader 150–300ms |

## Review output contract

When reviewing code or "making it feel better," return findings as **before/after tables grouped by area** (Motion, States, Surfaces, Typography, Layout/Color, Performance, Accessibility). For each change: the file/element, the before, the after, and one line of why. **Report every change you'd make, not a subset — omit only the empty groups.** Lead with a one-line summary of the highest-impact fix.

## Review checklist

- [ ] Motion pulls from the token scale; no one-off durations
- [ ] Only `transform`/`opacity`/`filter` animated; no `transition: all`
- [ ] Enter uses `--ease-out`, exit uses `--ease-in` and is faster
- [ ] Stateful animations are interruptible (transitions, not keyframes)
- [ ] `transform-origin` set so motion grows from its source
- [ ] Press feedback (`scale(0.96)`), gated hover, visible `:focus-visible` ring
- [ ] Loading/empty/error/disabled states exist; loaders are flicker-guarded
- [ ] Optimistic updates where an action would otherwise wait on the network
- [ ] Concentric radii; shadows for elevation (tinted, layered), borders for dividers
- [ ] Optical alignment on icons/buttons; hit areas ≥ 40–44px
- [ ] Hierarchy via weight + color; `tabular-nums`; body/inputs ≥16px; balanced headings
- [ ] Spacing groups related items; everything aligned; constrained scale
- [ ] `prefers-reduced-motion` honored with substitutions, not deletions
- [ ] Information never conveyed by motion or color alone

## Reference files

| File | Read it for |
| --- | --- |
| [motion.md](motion.md) | Duration/easing/spring tokens in depth, enter/exit recipes, interruptibility, origin, stagger, when-NOT-to-animate, modern primitives |
| [interaction-states.md](interaction-states.md) | Hover/active/focus-visible/disabled, loading & skeletons, empty/error states, optimistic UI, menus, feedback |
| [surfaces.md](surfaces.md) | Concentric radius, shadows vs borders & elevation, image outlines, optical alignment, hit areas |
| [typography.md](typography.md) | Text wrapping, smoothing, tabular numbers, hierarchy, measure, line-height, fluid sizing |
| [layout-and-color.md](layout-and-color.md) | Spacing scale & grouping, alignment, near-black/white, functional color scales, depth/shadow theory |
| [performance.md](performance.md) | Compositor-only animation, `will-change`, FLIP, the tool ladder, perceived speed, 60fps/RAIL |
| [accessibility.md](accessibility.md) | `prefers-reduced-motion` policy, forced-colors, contrast, focus, semantics/ARIA, vestibular safety |
| [sources.md](sources.md) | Who each principle comes from, with links — credits and further reading |

*Provenance: distilled from the work of Rauno Freiberg, Emil Kowalski, Vercel Geist, Linear, Stripe, Apple HIG, Material Design, Josh Comeau, Refactoring UI, and others — see [sources.md](sources.md). Opinionated defaults; not affiliated with or endorsed by them.*
