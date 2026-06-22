# Motion

The long-form layer behind the motion section of [SKILL.md](SKILL.md). Read this when you need the *why*, the good-vs-bad code, the decision tables, and the gotchas — not just the numbers. Every value here is the same contract `SKILL.md` commits to; this file explains how to wield it and where it breaks.

Two rules sit above everything below, from [SKILL.md](SKILL.md): **motion serves a purpose** (if you can't name what it communicates — causality, status, spatial continuity, deliberate delight — cut it), and **animate only `transform` / `opacity` / `filter`**, never layout properties, never `transition: all`. The compositor reasoning for that second rule lives in [performance.md](performance.md). Every animation in this file is `prefers-reduced-motion`-gated; the full policy is in [accessibility.md](accessibility.md).

The shared tokens — referenced throughout this file, never re-invented:

```css
:root {
  --duration-instant: 0ms;   --duration-fast: 150ms;  --duration-base: 200ms;
  --duration-slow: 300ms;     --duration-slower: 450ms;
  --ease-standard: cubic-bezier(0.2, 0, 0, 1);
  --ease-out:      cubic-bezier(0.05, 0.7, 0.1, 1);   /* enter / decelerate */
  --ease-in:       cubic-bezier(0.3, 0, 0.8, 0.15);   /* exit / accelerate */
  --ease-in-out:   cubic-bezier(0.4, 0, 0.2, 1);      /* on-screen movement / morph */
  --ease-ios:      cubic-bezier(0.32, 0.72, 0, 1);    /* drawers / sheets */
}
```

---

## Duration

Most UI motion lives in **150–300ms**. That window is not arbitrary — it is where the field converges. Rauno Freiberg treats **≤200ms** as the threshold for motion that reads as "immediate." Emil Kowalski keeps interface transitions **under 300ms**, as does Vercel's Geist guidance. Josh Comeau's default band for component transitions is **~250–450ms**. Val Head's general range is **200–500ms**. Material Design calls medium transitions **250–400ms** and uses **300ms as the canonical desktop default**. The consensus: a UI transition that crosses **~400ms starts to feel sluggish**, and one that finishes in **~100ms reads as instantaneous** (RAIL's 100ms response budget). Anything slower than 400ms had better be moving a large surface a long way.

That gives you the token scale, and each tier has a job:

| Token | Value | Use for |
| --- | --- | --- |
| `--duration-instant` | `0ms` | Keyboard-initiated and high-frequency actions — no animation at all |
| `--duration-fast` | `150ms` | Micro-feedback: hover, press, color change, icon tint/recolor |
| `--duration-base` | `200ms` | Standard: toggles, small reveals, tabs, dropdown open |
| `--duration-slow` | `300ms` | Larger surfaces: modals, drawers, popovers, sheets |
| `--duration-slower` | `450ms` | Full-screen / large-travel: route transitions, page-level morphs |

### Duration scales with distance and size

A control that moves 8px and a sheet that slides 600px should **not** take the same time. Material formalizes this with a ladder from roughly **50ms for the smallest changes up to ~1000ms for large, full-screen expansive motion** — velocity stays perceptually constant, so a bigger move simply takes longer. Apply it like this:

| Travel / surface | Duration |
| --- | --- |
| In-place tweak (color, opacity, ≤8px nudge) | `--duration-fast` (150ms) |
| Small component (toggle, chip, tooltip, ~8–24px) | `--duration-base` (200ms) |
| Medium surface (dropdown, popover, card, modal) | `--duration-slow` (300ms) — a small dropdown opens at base; a large one scales toward slow |
| Large / full-screen (drawer, sheet, route) | `--duration-slower` (450ms) and up — a panel-sized drawer sits at `--duration-slow`; a full-screen drawer scales up to `--duration-slower` |

```css
.tooltip   { transition: opacity var(--duration-fast)  var(--ease-out); }
.dropdown  { transition: transform var(--duration-base) var(--ease-out),
                         opacity   var(--duration-base) var(--ease-out); }
.modal     { transition: transform var(--duration-slow) var(--ease-out),
                         opacity   var(--duration-slow) var(--ease-out); }
```

**Don't** give a full-screen drawer `--duration-fast` — at 150ms a 600px slide moves at a violent ~4000px/s and the eye can't track where it came from. **Don't** give a tooltip `--duration-slow` — 300ms on a fade is a perceptible lag for something that should feel like it was already there.

### Exit faster than enter

Things should **leave more quickly and quietly than they arrive**. An element arriving wants a beat to be noticed and to establish where it came from; an element leaving has already done its job and lingering on it steals attention. Drop the exit roughly one tier (e.g. a 300ms enter → ~200ms exit).

```css
.panel              { transition: opacity var(--duration-slow) var(--ease-out); }  /* enter: 300ms */
.panel[data-closing]{ transition: opacity var(--duration-base) var(--ease-in);  }  /* exit:  200ms */
```

The single most common amateur tell is the inverse — identical enter and exit timing, often with the same easing — which makes dismissals feel like they're dragging. Covered again under [Exit animations](#exit-animations).

### `prefers-reduced-motion`

Duration choices are moot under reduced motion; the substitution happens at the easing/property level (a fade replaces movement) — see [Easing](#easing) and [accessibility.md](accessibility.md). Never respond to reduced motion by *speeding up* a translate to near-zero — that's a fast jab, not calm. Replace the movement with an opacity fade or an instant change.

---

## Easing

> "Easing is the most important part of any animation." — Emil Kowalski

Linear motion does not exist in the physical world; everything accelerates and decelerates. Getting duration right but easing wrong yields motion that is technically smooth and emotionally dead. **Direction of travel picks the curve** — this is the rule that organizes the whole system:

| Situation | Token | Curve | Why |
| --- | --- | --- | --- |
| **Entering** the screen | `--ease-out` | `cubic-bezier(0.05, 0.7, 0.1, 1)` | Fast start, gentle settle — "natural arrival," decelerating into final position |
| **Exiting** the screen | `--ease-in` | `cubic-bezier(0.3, 0, 0.8, 0.15)` | Slow start, accelerating away — leaves decisively, doesn't dawdle |
| **Moving across** screen / morphing in place | `--ease-in-out` | `cubic-bezier(0.4, 0, 0.2, 1)` | Symmetric ease on both ends — object already exists, just relocating |
| Small **in-place** state change | `--ease-standard` | `cubic-bezier(0.2, 0, 0, 1)` | Snappy default for color/opacity/tiny nudges where travel is negligible |
| **Continuous loop** (spinner, marquee, progress) | `linear` | — | Constant velocity is correct *only* here; any ease makes a loop pulse |

The mnemonic: **out to enter, in to exit, in-out to move, standard for small, linear only for loops.**

### Author custom curves — the keywords are too weak

CSS's built-in `ease`, `ease-in`, `ease-out`, `ease-in-out` are real cubic-beziers, but their control points are timid (`ease-out` is `cubic-bezier(0, 0, 0.58, 1)` — barely curved). They read as generic and slightly mushy. The tokens above are deliberately more aggressive at the ends, which is what makes motion feel intentional rather than default-browser.

```css
/* DON'T — weak, generic, "default browser" feel */
.menu { transition: transform 200ms ease-out; }

/* DO — authored curve, decisive arrival */
.menu { transition: transform var(--duration-base) var(--ease-out); }
```

### `ease-in` is poison for general UI — except exits

A pure `ease-in` (slow start) applied to something *arriving* feels broken: the element creeps, then lunges into place. The eye reads the slow start as lag. **Avoid `ease-in` for anything entering or for general state changes.** Its one correct job is exits, where the slow-then-fast shape mirrors an object building momentum as it leaves. This is exactly why `--ease-in` exists in the token set and why it's the *only* place it appears.

### Vanilla, Tailwind, Motion

```css
/* Vanilla CSS */
.toast { transition: transform var(--duration-base) var(--ease-out),
                     opacity   var(--duration-base) var(--ease-out); }
```

```js
// Web Animations API
el.animate(
  [{ transform: 'translateY(8px)', opacity: 0 }, { transform: 'translateY(0)', opacity: 1 }],
  { duration: 200, easing: 'cubic-bezier(0.05, 0.7, 0.1, 1)', fill: 'both' }
);
```

```jsx
/* Tailwind — map tokens in tailwind.config, then: */
<div className="transition-transform duration-200 ease-[cubic-bezier(0.05,0.7,0.1,1)]" />
```

```jsx
/* Motion (motion / framer-motion) — only if already in package.json */
<motion.div
  initial={{ opacity: 0, y: 8 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.2, ease: [0.05, 0.7, 0.1, 1] }}
/>
```

Don't add `motion` as a dependency just to ease a fade — vanilla CSS does it with zero bytes. Check `package.json` first ([SKILL.md](SKILL.md) makes this a rule).

---

## Springs

Durations and cubic-beziers describe motion by *time*; springs describe it by *physics*. "Nothing in the real world changes instantly," and nothing in the real world follows a fixed timeline either — a flicked object settles when its energy dissipates, however long that takes. For **gesture-driven and physical** motion (a sheet you drag, a toggle that should feel tactile, an element that inherits the velocity of a swipe), a spring is the honest model.

Two parameterizations, same idea:

- **Response + bounce** (Apple's `UISpringTimingParameters`, and Motion's modern `spring`): `response` is roughly how long the spring takes to reach its target; `bounce` is how much it overshoots (0 = no overshoot, ~0.2 = a little, higher = springy).
- **Mass / tension / friction** (older react-spring / Framer style): physical constants. Harder to reason about; prefer response+bounce when the API offers it.

Apple's "Designing Fluid Interfaces" (WWDC 2018) gives the discipline: **specify damping and response, start at damping = 1 (critically damped, no bounce), and add bounce only when the gesture carried momentum.** A button tap has no momentum — it should not bounce. A card flicked off-screen does — a little overshoot on the neighbor settling into its place feels right.

```jsx
/* Functional UI — toggles, icon swaps, anything precise. NO bounce. */
transition={{ type: 'spring', duration: 0.3, bounce: 0 }}

/* Apple-style physical — sheets, playful affordances, momentum-carrying gestures. */
transition={{ type: 'spring', duration: 0.5, bounce: 0.2 }}
```

| Want | Config | Bounce |
| --- | --- | --- |
| Precise, functional, "snappy but calm" | `{ type: "spring", duration: 0.3, bounce: 0 }` | none |
| Physical, gesture-driven, a little life | `{ type: "spring", duration: 0.5, bounce: 0.2 }` | small |
| Exaggerated / toy-like | higher bounce | usually wrong for product UI |

### When NOT to use a spring

**Avoid springs where precision matters more than feel.** A progress bar, a value that must land on an exact pixel, a layout that other elements measure against — a spring's overshoot means the final frame arrives late and the element briefly sits *past* its target. Use a duration + `--ease-out` there. Also avoid bouncy springs on anything the user triggers dozens of times a day; the overshoot that delights once becomes nausea on the hundredth repeat.

For reduced motion, drop the spring to an opacity fade or instant set — never a high-bounce spring (the overshoot is exactly the vestibular trigger reduced-motion users are protecting against). See [accessibility.md](accessibility.md).

---

## Interruptibility

This is the **single most important property of how motion feels** — more than duration or easing. Apple's fluid-interface principle: motion must be **responsive, interruptible, and redirectable.** Real interfaces are interrupted constantly — a user opens a menu and immediately closes it, hovers and un-hovers, starts a drag and reverses. If the animation can't be caught mid-flight and sent somewhere new, the UI feels like it's arguing with the user.

The mechanism is a hard technical fork in CSS:

- **CSS transitions retarget mid-flight.** Change the target value while a transition is running and it smoothly redirects from the *current* interpolated position to the new target. No snap.
- **CSS keyframe animations snap or restart.** Re-trigger a `@keyframes` animation mid-play and it jumps back to frame 0 (or you fight `animation-fill-mode` and `animation-play-state` and still lose).

This is why Emil's Sonner toast library is built on transitions, not keyframes — specifically so toasts can be **"interrupted and retargeted mid-flight"** when a new toast pushes the stack while one is still animating.

### The decision table

| Use **transitions** for | Use **keyframes** for |
| --- | --- |
| Hover / un-hover | One-shot entrance of a static element |
| Toggle on/off | A looping spinner or pulse |
| Open / close (menu, dropdown, accordion) | A staged, multi-step "show off" sequence that plays once |
| Drawer / sheet drag | A confetti / celebration burst |
| Any state that can flip back before the animation ends | Anything the user can't interrupt by design |
| Anything driven by a changing value (slider, progress toward a target) | Decorative ambient motion with no interactive trigger |

The governing question: **"Can the user reverse or change this before it finishes?"** If yes — transition. If it's a fire-and-forget sequence — keyframes are fine.

```css
/* DO — transition: open and close share one declaration and retarget instantly */
.dropdown {
  opacity: 0;
  transform: translateY(-8px);
  transition: opacity var(--duration-base) var(--ease-out),
              transform var(--duration-base) var(--ease-out);
}
.dropdown[data-open] { opacity: 1; transform: translateY(0); }
/* Toggle data-open twice in 100ms and it smoothly reverses — no snap. */
```

```css
/* DON'T — keyframes for a toggle: re-opening mid-close restarts from frame 0 */
@keyframes drop-in { from { opacity: 0; transform: translateY(-8px); } to { opacity: 1; transform: none; } }
.dropdown[data-open] { animation: drop-in var(--duration-base) var(--ease-out); }
/* Rapid open→close→open visibly jumps. Wrong tool. */
```

In Motion, interruptibility is automatic — animating between `animate` targets retargets from the live value, and springs are interruptible by construction. That's a large part of why a library is worth it for genuinely gesture-driven, frequently-reversed UI; for everything else, transitions already give you this for free.

---

## Origin-awareness

Motion should respect *where things come from*. A dropdown that belongs to a button should appear to **grow out of that button**, not materialize from its own center or from the top-left of the viewport. The tool is `transform-origin`, and getting it right is the difference between a menu that feels attached to its trigger and one that feels like it teleported in.

```css
/* DON'T — scales from center, looks disconnected from the trigger */
.menu { transform: scale(0.96); /* transform-origin defaults to center */ }

/* DO — anchor to the corner nearest the trigger button */
.menu--from-top-left  { transform-origin: top left; }
.menu--from-top-right { transform-origin: top right; }  /* right-aligned trigger */
.menu {
  transform: scale(0.96) translateY(-4px);
  opacity: 0;
  transition: transform var(--duration-base) var(--ease-out),
              opacity   var(--duration-base) var(--ease-out);
}
.menu[data-open] { transform: scale(1) translateY(0); opacity: 1; }
```

Match the origin to the trigger's position: a menu opening below a left-aligned button uses `top left`; a right-aligned avatar menu uses `top right`; a context menu can be positioned at the literal click coordinates. (Note the scale starts at `0.96`, not `0` — see [Enter animations](#enter-animations).)

**Preserve spatial continuity** as a general law: things should **exit toward where they live and re-enter from there.** A panel that slid in from the right exits to the right, not upward. A notification that dropped from the top retreats upward. A detail view that expanded from a list row should collapse back toward that row (this is exactly what the [View Transitions API](#modern-primitives) automates for shared elements). Breaking continuity — entering from the right but exiting upward — destroys the user's mental map of where things are.

---

## Enter animations

Entrances communicate **arrival** and establish where new content came from. Three rules:

1. **Combine `opacity` + a small `translateY`.** Fade alone is flat and ghostly; movement alone is abrupt. Together they read as "this slid into place." Optionally add `filter: blur(4px) → 0` for a premium focus-pull. Start the translate at **8–12px** — far enough to register, close enough to feel local.
2. **Never animate from `scale(0)`.** Growing from nothing looks like the element teleports in from a singularity. **Start at ~`0.9`** so it scales up subtly. (This is a hard rule from [SKILL.md](SKILL.md).)
3. **Split into semantic groups and stagger them.** A complex surface that animates as one block is heavy; revealing it in meaningful chunks guides the eye. Stagger **~100ms between groups** (header, then body, then footer) and **~80ms between words** for text reveals. Keep total sequence time bounded — staggering 12 list items at 100ms each is a 1.2s wait; cap the count or shrink the step.

### Vanilla CSS — `fadeInUp` keyframe + `:nth-child` stagger

A one-shot entrance is the legitimate keyframe case (it won't be interrupted):

```css
@keyframes fade-in-up {
  from { opacity: 0; transform: translateY(10px); }
  to   { opacity: 1; transform: translateY(0); }
}

.stagger-group > * {
  opacity: 0;                                   /* hold pre-animation state */
  animation: fade-in-up var(--duration-slow) var(--ease-out) forwards;
}
.stagger-group > *:nth-child(1) { animation-delay: 0ms;   }
.stagger-group > *:nth-child(2) { animation-delay: 100ms; }
.stagger-group > *:nth-child(3) { animation-delay: 200ms; }

@media (prefers-reduced-motion: reduce) {
  .stagger-group > * { animation: none; opacity: 1; }   /* instant, full meaning preserved */
}
```

### Web Animations API — programmatic stagger

```js
const groups = el.querySelectorAll('.group');
const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
groups.forEach((g, i) => {
  g.animate(
    [{ opacity: 0, transform: 'translateY(10px)' }, { opacity: 1, transform: 'translateY(0)' }],
    { duration: 300, delay: reduce ? 0 : i * 100, easing: 'cubic-bezier(0.05,0.7,0.1,1)', fill: 'both' }
  );
});
```

### Motion — variants with `staggerChildren`

```jsx
const container = { show: { transition: { staggerChildren: 0.1 } } };       // 100ms between groups
const item = {
  hidden: { opacity: 0, y: 10 },
  show:   { opacity: 1, y: 0, transition: { duration: 0.3, ease: [0.05,0.7,0.1,1] } },
};

<motion.ul variants={container} initial="hidden" animate="show">
  {items.map((it) => <motion.li key={it.id} variants={item}>{it.label}</motion.li>)}
</motion.ul>
```

Under reduced motion, Motion respects a `MotionConfig reducedMotion="user"` wrapper, or gate the `y` offset to `0` yourself. **Don't** delete the stagger and dump everything in at once *and* keep a long delay — just remove the transform and let opacity (or nothing) carry it.

---

## Exit animations

Exits are the most-neglected half of motion and the easiest place to look unpolished. The discipline: **softer and faster than the matching enter.**

| Property | Enter | Exit |
| --- | --- | --- |
| Duration | full tier (e.g. 300ms) | ~one tier shorter (e.g. 200ms) |
| Easing | `--ease-out` (decelerate in) | `--ease-in` (accelerate away) |
| Translate | from `8–12px` toward final | to a **small fixed** `-8` to `-12px`, *not* full height |
| Opacity | 0 → 1 | 1 → 0 |
| Direction | from where it lives | **toward** where it lives (continuity) |

The fixed-distance point matters: an exiting panel should fade while drifting a **small** `translateY(-8px)`, **not** animate its full height off-screen. A large exit translate reads as slow and draws the eye to something that's leaving; a small drift + fade is quiet and quick.

```css
.panel {
  transition: opacity var(--duration-slow) var(--ease-out),
              transform var(--duration-slow) var(--ease-out);
}
.panel[data-closing] {
  opacity: 0;
  transform: translateY(-8px);                 /* small, fixed — not -100% */
  transition-duration: var(--duration-base);   /* faster than enter */
  transition-timing-function: var(--ease-in);  /* accelerate away */
}
@media (prefers-reduced-motion: reduce) {
  .panel, .panel[data-closing] { transition: opacity var(--duration-fast) linear; transform: none; }
}
```

**Never `display: none` with no transition.** Yanking an element out of the DOM with no exit is the jarring default that makes dismissals feel broken. The element vanishes a frame after the click with no acknowledgment. If the element lives in `display: none`, use [`@starting-style` + `transition-behavior: allow-discrete`](#modern-primitives) or Motion's `AnimatePresence` to get a real exit. In React, an unmounting component has *no* exit animation unless something defers the unmount — that's the entire reason `AnimatePresence` exists:

```jsx
<AnimatePresence>
  {open && (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -8, transition: { duration: 0.2, ease: [0.3,0,0.8,0.15] } }}
    />
  )}
</AnimatePresence>
```

---

## Contextual icon swaps

When an icon changes meaning (play → pause, copy → check, chevron-down → chevron-up), **cross-fade** between the two icons rather than hard-cutting. A hard swap is a single-frame pop; a cross-fade with a touch of scale and blur reads as one icon *becoming* another. A cross-fade swap (scale + blur + opacity) is a richer move than a recolor — it intentionally runs at `--duration-slow` (300ms), not the micro tier.

### Motion — `AnimatePresence` with a keyed span

```jsx
<AnimatePresence mode="popLayout" initial={false}>
  <motion.span
    key={copied ? 'check' : 'copy'}                 // key change drives the swap
    initial={{ opacity: 0, scale: 0.8, filter: 'blur(4px)' }}
    animate={{ opacity: 1, scale: 1,   filter: 'blur(0px)' }}
    exit={{    opacity: 0, scale: 0.8, filter: 'blur(4px)' }}
    transition={{ type: 'spring', duration: 0.3, bounce: 0 }}   // bounce MUST be 0
  >
    {copied ? <CheckIcon /> : <CopyIcon />}
  </motion.span>
</AnimatePresence>
```

`mode="popLayout"` lets the exiting icon pop out of layout flow so the incoming one isn't pushed around. **`bounce` must be `0`** — an icon swap is functional, not playful; overshoot on a tiny glyph looks like a glitch. **Don't start from `scale(0)`** — `0.8` is fine for a glyph cross-fade (surface entrances start a touch higher, ~`0.9`).

### No-Motion fallback — both icons in the DOM, cross-fade opacity

If `motion` isn't a dependency, keep both icons mounted, absolutely position one over the other, and cross-fade with a transition (interruptible, so rapid toggles reverse cleanly):

```css
.icon-swap { position: relative; display: inline-grid; place-items: center; }
.icon-swap > svg {
  grid-area: 1 / 1;                               /* stack without absolute hacks */
  transition: opacity var(--duration-slow) var(--ease-standard),
              transform var(--duration-slow) var(--ease-standard),
              filter var(--duration-slow) var(--ease-standard);
}
.icon-swap > .is-hidden {
  opacity: 0; transform: scale(0.8); filter: blur(4px);
}
@media (prefers-reduced-motion: reduce) {
  .icon-swap > svg { transition: opacity var(--duration-fast) linear; transform: none; filter: none; }
}
```

(`display: inline-grid` with both children on `grid-area: 1/1` stacks them without `position: absolute` collapsing the box — the container keeps the icon's intrinsic size.)

---

## Press feedback

A button that doesn't physically respond to a press feels dead. Scale it down slightly on `:active` over `--duration-fast`. The value is **`scale(0.96)`** — and **never below `0.95`**. Below that, the shrink is exaggerated and toy-like; the whole point is a subtle "give," like a real key depressing.

```css
.button {
  transition: transform var(--duration-fast) var(--ease-standard);
}
.button:active {
  transform: scale(0.96);
}
@media (prefers-reduced-motion: reduce) {
  .button { transition: none; }
  .button:active { transform: none; }   /* or a brief background-color shift instead */
}
```

```jsx
/* Motion */
<motion.button whileTap={{ scale: 0.96 }} transition={{ duration: 0.15 }} />
```

Pair this with the hover/focus rules in [interaction-states.md](interaction-states.md) — press is one third of the hover/active/focus-visible triad every interactive element needs. Gate any *hover* transform behind `@media (hover: hover)` so it doesn't stick on touch; the `:active` press is fine on touch.

---

## When NOT to animate

Restraint is craft. These are cases where the right amount of motion is **zero** (or far less than the default):

| Situation | What to do instead | Why |
| --- | --- | --- |
| **High-frequency actions** (a menu opened 100×/day, deleting list rows) | `--duration-instant` / no animation | Animation you see hundreds of times a day is a tax, not delight; it slows a power user down |
| **Keyboard-initiated actions** (tabbing fields, ⌘K palette, arrow-key nav) | Instant | Keyboard users move fast and expect immediacy; a 200ms fade between every focused field is maddening |
| **Theme switches** (light ↔ dark) | **Disable transitions during the switch** | Otherwise every color-transitioning property animates at once — a slow, ugly smear across the whole page |
| **Repeated triggers** (re-opening the same menu) | **Skip the entrance delay on 2nd+ open** | The reveal stagger that's pleasant once is a wait when you reopen immediately |
| **Looping animations offscreen** (spinner in a hidden tab, ambient motion below the fold) | **Pause when not visible** (`IntersectionObserver` → `animation-play-state: paused`) | Off-screen animation burns CPU/GPU and drains battery for zero benefit |
| **Scroll-entrance on fast scroll** | **Skip the animation when scroll velocity is high** | A user flinging through content doesn't want every section fading up; it just adds lag and stutter |

The theme-switch fix is worth spelling out — it's a frequent miss:

```css
/* Kill transitions for one frame while the theme attribute flips, then restore */
.theme-transitioning * {
  transition: none !important;
}
```

```js
function setTheme(next) {
  document.documentElement.classList.add('theme-transitioning');
  document.documentElement.dataset.theme = next;
  requestAnimationFrame(() =>
    requestAnimationFrame(() => document.documentElement.classList.remove('theme-transitioning'))
  );
}
```

And pausing offscreen loops:

```js
const io = new IntersectionObserver(([e]) => {
  spinner.style.animationPlayState = e.isIntersecting ? 'running' : 'paused';
});
io.observe(spinner);
```

The throughline: **the best animation is often no animation** ([SKILL.md](SKILL.md)). If you can't name what it communicates, or if it fires so often that it's friction rather than feedback, cut it.

---

## Modern primitives

Before hand-rolling motion with JS, check whether a platform primitive does it better. Each of these degrades gracefully — wrap in a feature check and the no-support path is simply an instant change, which is an acceptable baseline.

### View Transitions API — shared-element & route transitions

The native replacement for FLIP. Wrap a DOM mutation in `document.startViewTransition` and the browser snapshots before/after and cross-fades — or, with named elements, *morphs* them between positions (the list-row-expands-to-detail case, automatically continuity-preserving).

```js
if (document.startViewTransition) {
  document.startViewTransition(() => updateTheDOM());   // browser tweens old → new
} else {
  updateTheDOM();                                       // graceful: instant, no transition
}
```

```css
/* Tie two elements across states so the browser morphs one into the other */
.card     { view-transition-name: hero; }
.detail   { view-transition-name: hero; }
/* Customize the generated pseudo-elements */
::view-transition-old(hero),
::view-transition-new(hero) { animation-duration: var(--duration-slow); }

@media (prefers-reduced-motion: reduce) {
  ::view-transition-group(*),
  ::view-transition-old(*),
  ::view-transition-new(*) { animation: none !important; }   /* instant cross-cut */
}
```

### `@starting-style` + `transition-behavior: allow-discrete` — CSS-native enter for `display:none`

The long-standing problem: you can't transition *into* an element's first rendered frame, and you can't transition properties like `display` or `overlay`. These two features fix both, enabling entrance animations for popovers, dialogs, and anything toggling `display` — **with no JS**.

```css
.popover {
  opacity: 1;
  transform: translateY(0);
  transition: opacity var(--duration-base) var(--ease-out),
              transform var(--duration-base) var(--ease-out),
              display var(--duration-base) allow-discrete;   /* animate the discrete prop */
}
.popover:not([open]) { opacity: 0; transform: translateY(-8px); display: none; }

/* The state to animate FROM on first appearance */
@starting-style {
  .popover[open] { opacity: 0; transform: translateY(-8px); }
}

@media (prefers-reduced-motion: reduce) {
  .popover { transition: opacity var(--duration-fast) linear; transform: none; }
}
```

### Scroll-driven animations — `animation-timeline`

Drive an animation by scroll position or element visibility instead of time — no scroll-listener, runs off the main thread. `scroll()` ties progress to a scroll container; `view()` ties it to an element entering/leaving the viewport.

```css
@keyframes reveal { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: none; } }

.section {
  animation: reveal linear both;
  animation-timeline: view();           /* progress = element's path through viewport */
  animation-range: entry 0% entry 100%; /* play only as it enters */
}

@supports not (animation-timeline: view()) {
  .section { animation: none; opacity: 1; }   /* graceful: just show it */
}
@media (prefers-reduced-motion: reduce) {
  .section { animation: none; opacity: 1; }
}
```

### `interpolate-size: allow-keywords` — animate to `height: auto`

Animating to `height: auto` has been impossible for the entire history of CSS (you faked it with `max-height` or `grid-template-rows: 0fr → 1fr`). This opt-in makes intrinsic sizes interpolable, so an accordion can transition to its natural height directly.

```css
:root { interpolate-size: allow-keywords; }   /* opt in globally */

.accordion-content {
  height: 0;
  overflow: hidden;
  transition: height var(--duration-base) var(--ease-standard);
}
.accordion-content[data-open] { height: auto; }   /* now animatable */

@media (prefers-reduced-motion: reduce) {
  .accordion-content { transition: none; }
}
```

Where support is missing, the `grid-template-rows: 0fr → 1fr` trick remains the most robust fallback. For the compositor cost of animating `height` at all (it triggers layout — prefer `transform` when the design allows), see [performance.md](performance.md).

---

*Cross-references: [SKILL.md](SKILL.md) (the contract and headline numbers) · [accessibility.md](accessibility.md) (full `prefers-reduced-motion` policy, vestibular safety) · [performance.md](performance.md) (compositor-only animation, the tool ladder, 60fps/RAIL) · [interaction-states.md](interaction-states.md) (hover/active/focus-visible triad, feedback). Provenance for the numbers above lives in `sources.md`.*
