# Performance & perceived speed

Smoothness and speed are *felt*. A 60fps animation on a janky property still drops frames; a 300ms operation behind an optimistic update feels instant. This file covers both halves: making the frames you draw cheap (the rendering pipeline) and making the user never wait for them (perceived speed). The single highest-leverage rule lives at the top — animate only what the compositor can do alone — but the biggest *wins* usually come from the bottom: not making the user wait at all.

Back to [SKILL.md](SKILL.md) · sibling depth in [motion.md](motion.md), [interaction-states.md](interaction-states.md), [accessibility.md](accessibility.md).

## The rendering pipeline

Every visual change the browser makes runs through up to four steps, in order:

**Style → Layout → Paint → Composite.**

JavaScript typically kicks off the pipeline (a class toggle, a style write, a state change), and many changes skip stages — a compositor-only change runs Style → Composite, a paint-only change runs Style → Paint → Composite, never touching Layout.

1. **Style** — compute which CSS rules apply and their final values.
2. **Layout** ("reflow") — compute geometry: how big each box is and where it sits. Changing one element's size can reflow its siblings, children, and ancestors. Expensive.
3. **Paint** — fill in pixels: text, colors, borders, shadows, images, into layers.
4. **Composite** — assemble the painted layers into the final frame, in the right order, with the right transforms and opacity.

The property you animate decides where you *enter* this pipeline, and that decides the cost:

| Animate this | Pipeline work each frame | Where it runs |
| --- | --- | --- |
| `transform`, `opacity` | **Composite only** | **Compositor thread (GPU)** |
| `filter` | **Paint** → Composite | GPU-accelerated, but a paint-stage effect |
| `color`, `background`, `box-shadow`, `border-radius`, `visibility` | **Paint** → Composite | Main thread |
| `width`, `height`, `top`, `left`, `right`, `bottom`, `margin`, `padding`, `font-size` | **Layout** → Paint → Composite | Main thread |

The crucial fact: **`transform` and `opacity` can be handled at the Composite step alone**, and compositing runs on a **separate compositor thread, independently of the main thread.** So even when the main thread is jammed — running your JS, parsing, garbage-collecting, handling a slow event — a transform/opacity animation keeps ticking at full framerate on the GPU. Layout- and paint-triggering animations cannot; they're stuck in line behind whatever the main thread is doing, and they jank. `filter` is GPU-accelerated but a **paint-stage** effect — cheap for a small blur, increasingly expensive as the radius grows; not truly compositor-only like `transform`/`opacity`.

web.dev's canonical measurement makes the gap concrete: animating `top`/`left` (which triggers layout) can drop **~50% of frames**, while animating the equivalent motion with `transform` drops **~1% of frames**.

```css
/* BAD — animates `left`, triggers Layout every frame, ~50% frames dropped */
.toast {
  position: absolute;
  left: -320px;
  transition: left 300ms ease-out;
}
.toast.open { left: 24px; }

/* GOOD — animates `transform`, Composite only, ~1% frames dropped */
.toast {
  position: absolute;
  left: 24px;
  transform: translateX(calc(-100% - 48px));
  transition: transform 300ms cubic-bezier(0.05, 0.7, 0.1, 1);
}
.toast.open { transform: translateX(0); }
```

The rule that falls out: **animate `translate()` / `scale()` / `rotate()`, never `top`/`left`/`width`/`height`.** Same visual result, an order of magnitude cheaper, and immune to main-thread jank.

## The Golden Rule

**Animate ONLY `transform`, `opacity`, and `filter`.** Everything else forces Layout or Paint on the main thread and risks dropped frames. This is the same rule as principle #2 in [SKILL.md](SKILL.md) and #2 in [motion.md](motion.md) — it shows up everywhere because it's the foundation.

Caveat on `filter`: it's compositor-friendly, but **avoid animating `blur()` beyond ~20px** — large blur radii are genuinely expensive to compute per frame even on the GPU, and a heavy backdrop blur over a busy background can tank framerate on weaker hardware. Animate the *opacity* of a pre-blurred layer instead of animating the blur radius itself when you can.

| Cheap (compositor-only — animate freely) | Expensive (forces layout/paint — avoid) |
| --- | --- |
| `transform: translate()` | `top`, `left`, `right`, `bottom` |
| `transform: scale()` | `width`, `height` |
| `transform: rotate()` | `margin`, `padding` |
| `opacity` | `box-shadow` (animate a layered pseudo-element's opacity instead) |
| `filter` (blur ≤ ~20px) | `border-radius`, `border-width` |
| | `background`, `background-position`, `color` |
| | `font-size`, `line-height`, `letter-spacing` |

**Cheap substitutions for the expensive cases:**

```css
/* Don't animate box-shadow. Layer two shadows, cross-fade their opacity. */
.card { position: relative; box-shadow: 0 1px 2px rgb(0 0 0 / 0.08); }
.card::after {
  content: ""; position: absolute; inset: 0; border-radius: inherit;
  box-shadow: 0 8px 24px rgb(0 0 0 / 0.16);
  opacity: 0; transition: opacity 200ms ease-out;
  pointer-events: none;
}
.card:hover::after { opacity: 1; }   /* composites; the shadow itself never re-paints */
```

```css
/* Don't animate width to "grow" something. Scale it. */
.bar { transform: scaleX(0); transform-origin: left; transition: transform 200ms ease-out; }
.bar.full { transform: scaleX(1); }
/* If scaleX distorts child content (text, icons), that's the signal to reach for FLIP instead. */
```

## Never `transition: all`

`transition: all` tells the browser to watch **every** animatable property for changes. Three costs:

1. **Unintended transitions.** Change a class that also tweaks `color`, `padding`, or `box-shadow`, and now those animate too — usually at the wrong duration, producing the smeary, laggy "everything eases" feel that reads as amateur.
2. **It blocks optimizations.** The browser can't pre-plan layer promotion or skip work when it doesn't know which specific properties will change.
3. **It invites layout-triggering animations by accident** — a `padding` change you only meant to be instant now reflows on every frame.

**Always name the exact properties:**

```css
/* BAD */
.button { transition: all 150ms ease; }

/* GOOD — explicit, only compositor properties */
.button { transition: transform 150ms ease, opacity 150ms ease; }
```

### Tailwind nuance

Tailwind's transition utilities are not all equivalent — know what each expands to:

| Utility | Expands to | Verdict |
| --- | --- | --- |
| `transition` | curated list — incl. `transform`, `opacity`, `box-shadow`, `background-color`, `color`, `filter`, … | **Caution** — the curated list still includes paint-triggering props (`box-shadow`, `background-color`, `color`) |
| `transition-all` | `transition-property: all` | **Avoid** |
| `transition-transform` | `transform, translate, scale, rotate` | Fine — transform-only, compositor-safe |
| `transition-opacity` | `opacity` | Fine |
| `transition-colors` | `color, background-color, border-color, …` | Fine for color, but these *paint* — keep them short |
| `transition-[transform,opacity]` | exactly those two | **Preferred for mixed sets** |

For an element that animates both transform and opacity, use the bracket syntax `transition-[transform,opacity]` rather than the bare `transition`. Tailwind's bare `transition` isn't `transition-property: all` — it applies a curated list. But that list still includes paint-triggering properties (`box-shadow`, `background-color`, `color`), so prefer `transition-[transform,opacity]` (or `transition-transform`/`transition-opacity`) when you want compositor-only animation.

## `will-change` — sparingly, just-in-time

`will-change` promotes an element to its **own GPU compositor layer ahead of time.** The payoff: the browser does the layer-promotion work *before* the animation starts, so the first frame doesn't stutter while it sets up. **Safari benefits most** — it's the engine most prone to a visible hitch on the first frame of an un-promoted transform.

But it is a hint with real costs, and it's widely misused:

- **Each promoted layer consumes memory** (GPU texture memory). Promote everything and you blow the memory budget and *degrade* overall performance — the opposite of the goal.
- **It only helps GPU-compositable properties.** Hinting `will-change: top` or `will-change: background` does nothing useful, because those can't be lifted to the compositor anyway.
- **`will-change: all` is never correct** — it asks the browser to prepare for everything, which it can't, so it just wastes resources.

web.dev's rule, stated precisely: **only set `will-change` if the animation may begin within ~200ms, and remove it once the animation is done.** Apply it just-in-time (on `pointerenter`, on focus, right before you trigger), and clear it on transition end.

| Property | GPU-compositable? | `will-change` worth it? |
| --- | --- | --- |
| `transform` | Yes | Yes (esp. Safari, just-in-time) |
| `opacity` | Yes | Yes |
| `filter` | Yes | Yes |
| `clip-path` | Yes | Yes |
| `top` / `left` / `width` / `height` | No | **No** — useless |
| `background` / `color` / `box-shadow` | No | **No** — useless |

```css
/* Static default: do NOT leave will-change set. */
.sheet { transform: translateY(100%); transition: transform 300ms cubic-bezier(0.32, 0.72, 0, 1); }
```

```js
// Promote just before it could move, remove it once settled.
const trigger = document.querySelector('.sheet-trigger');
const sheet = document.querySelector('.sheet');

trigger.addEventListener('pointerenter', () => {
  sheet.style.willChange = 'transform';        // animation likely within ~200ms
});
sheet.addEventListener('transitionend', () => {
  sheet.style.willChange = 'auto';             // release the layer + its memory
});
```

If you can't cleanly add/remove it, prefer leaving it off. A momentary first-frame hitch is cheaper than a permanent memory leak across hundreds of elements.

## FLIP for layout-change animation

Sometimes the thing that changed *is* layout — an item moves to a new position in a reordered list, a card expands from a grid into a detail view, an element reflows when a sibling appears. You can't animate that with a static `transform` because you don't know the start and end coordinates ahead of time. **FLIP** (Paul Lewis) is the technique: it converts an unavoidable layout change into a cheap compositor-only transform animation.

**F**irst · **L**ast · **I**nvert · **P**lay:

1. **First** — measure the element's start rect (`getBoundingClientRect()`).
2. **Last** — apply the final DOM/layout state, then measure the end rect. The element is now *visually* in its new place.
3. **Invert** — apply a `transform` that maps it *back* to where it started (the delta between First and Last). To the eye, nothing has moved yet.
4. **Play** — transition that inverting transform to `0`. The element glides from old to new position, animating only `transform` — compositor-only, 60fps.

The deep reason this is fast: **you front-load the one expensive layout/measure into the ~100ms perception window** (see RAIL below — work under ~100ms reads as instantaneous), and then *every animated frame* moves only `transform`/`opacity`. The browser never reflows mid-animation.

```js
// FLIP a single element across a layout change.
function flip(el, mutate) {
  const first = el.getBoundingClientRect();      // First
  mutate();                                      // Last — apply the new layout
  const last = el.getBoundingClientRect();

  const dx = first.left - last.left;             // Invert — delta back to start
  const dy = first.top  - last.top;
  const sx = first.width  / last.width;
  const sy = first.height / last.height;

  el.animate(
    [
      { transform: `translate(${dx}px, ${dy}px) scale(${sx}, ${sy})`, transformOrigin: 'top left' },
      { transform: 'none', transformOrigin: 'top left' },           // Play → 0
    ],
    { duration: 300, easing: 'cubic-bezier(0.4, 0, 0.2, 1)' }       // --ease-in-out: moving across
  );
}
```

**You rarely need to hand-roll this anymore — but you must recognize when something is doing it for you:**

- **View Transitions API** (`document.startViewTransition`) implements FLIP for you across a DOM mutation, including shared-element transitions. Reach for it first for route/state changes.
- **Library layout animations** — Motion's `layout` prop (`<motion.div layout />`) is FLIP under the hood; it measures before/after and animates the transform. So is the `<AnimatePresence>` reorder behavior.

Cross-link: enter/exit recipes, interruptibility, and the View-Transitions vs layout-animation decision live in [motion.md](motion.md).

## Tool ladder

Climb only as high as the job needs. Each rung up is more power and more weight — and crucially, more risk of running the animation on the main thread where it can jank.

| Rung | Tool | Reach for it when |
| --- | --- | --- |
| 1 | **CSS transitions** | State changes between two values (hover, open/close, toggle). Interruptible, retarget mid-flight. The default. |
| 2 | **CSS keyframes** (`@keyframes`) | One-shot multi-step sequences (a staged entrance, a loading pulse). Not interruptible — don't use for stateful UI. |
| 3 | **Web Animations API** (`element.animate()`) | You need JS control — dynamic values (FLIP deltas), `.cancel()`/`.reverse()`/`.finished`, sequencing, computed keyframes — but still want the engine compositing it. |
| 4 | **JS animation library** | Orchestration CSS/WAAPI can't express: shared layout transitions, gesture-driven springs, complex timelines, scroll-linked sequences. |

**Stripe's stated ladder is the model:** start at CSS, climb only when you hit a wall, and prefer a small WAAPI-based implementation over a heavyweight library — their animation primitive is on the order of **~5KB** built on the Web Animations API. The point isn't the exact number; it's that they resisted pulling in a large main-thread animation runtime for what the platform already composites for free.

**The performance reason to prefer WAAPI / compositor-thread libraries over main-thread JS animation:** an animation driven frame-by-frame in JavaScript (a `requestAnimationFrame` loop setting `style.transform` each tick, or older libraries that do so) runs **on the main thread.** The moment the main thread gets busy — a big render, data parsing, a slow handler — those frames stall and the animation janks. CSS transitions, CSS keyframes, and WAAPI animations of `transform`/`opacity` are handed to the **compositor thread** and keep running smoothly through main-thread load. So:

- Prefer libraries that compile to WAAPI or CSS (compositor-thread) over ones that tween in JS each frame.
- Be actively wary of any animation that reads/writes layout in a `requestAnimationFrame` loop — that's main-thread work that *will* jank under load.
- If you must animate in JS, animate only `transform`/`opacity` so at least the compositing stays off the main thread.

## 60fps & the RAIL budget

**60fps means a frame every ~16.67ms.** But the browser itself needs part of that frame for its own housekeeping (style, compositing, paint flushing), so your practical budget for *your* work is **~10ms per frame**, not 16. Blow past it and you miss the vsync deadline and drop a frame. Aim to keep **~99% of frames** under budget — the occasional dropped frame is invisible; a sustained 50% drop is the difference between silk and stutter (see the pipeline section).

**RAIL** is the user-centric budget model. Four contexts, four numbers:

| Phase | Budget | Why this number |
| --- | --- | --- |
| **Response** | **≤ 100ms** | Acknowledge any user input within 100ms and it feels **instantaneous** — cause and effect are perceived as linked. Past ~100ms the connection starts to fray. |
| **Animation** | **~10ms / frame** | Per frame, after browser overhead, inside the 16ms vsync window. Each frame must finish its work in this slice. |
| **Idle** | **50ms chunks** | Do deferred/background work in ≤50ms blocks so you can always yield to an incoming input and still answer it within the 100ms Response budget. |
| **Load** | **~5s** | Make the page interactive within ~5s on a mid-tier device over a slow (e.g. 3G) network. |

**~100ms is the causality window.** It's the single most important number for "feel": any feedback delivered inside ~100ms of the user's action is perceived as a *direct consequence* of that action. This is why trigger-local feedback (a button that depresses on `:active`, an inline checkmark on copy) feels so much better than a network-gated response — the local feedback lands inside the window even when the real work doesn't. See [interaction-states.md](interaction-states.md) for the feedback patterns; honor `prefers-reduced-motion` throughout per [accessibility.md](accessibility.md).

## Perceived speed beats actual speed

This is the section that matters most, and the one most often skipped for micro-optimizing easing curves. **The largest perceived-speed lever is not shaving milliseconds off animations — it's not making the user wait at all.** A snappy spinner is still a spinner. The fastest interaction is the one that appears already done.

The techniques, in rough order of impact (full treatment in [interaction-states.md](interaction-states.md) — this is the summary):

- **Optimistic updates + rollback.** Render the success state *immediately* on action, fire the request in the background, and reconcile or roll back only if the server disagrees. The like-count increments on tap; the row appears in the list before the POST resolves. This converts a network round-trip into a 0ms interaction in the common (success) case.
- **Local-first data.** Keep state on the client; treat the server as sync, not as the source of truth you block on. Reads and writes hit memory, not the wire.
- **Skeletons over spinners.** A layout-shaped placeholder communicates *what* is coming and *where*, and reads as faster than a blank screen with a spinner — the user's eye has already parsed the structure by the time content lands.
- **Latency hiding.** Use the moments you already own — prefetch on hover/intent, start the request on `pointerdown` instead of `click`, begin the open animation while data loads so the two overlap instead of queue.
- **Instant trigger-local feedback.** Always acknowledge within the ~100ms window at the point of interaction, even when the underlying work is slow. Never let the *acknowledgment* wait on the work.

The governing principle (Linear): **UI responsiveness must never depend on network latency.** The interface should respond to the user at memory speed; the network reconciles afterward, invisibly. If any interaction's feedback is gated on a server response, that's the bug to fix before you touch a single easing curve.

→ Optimistic UI mechanics, rollback patterns, skeleton timing (the ~150–300ms show-delay and ~300–500ms minimum-visible guard against flicker), and feedback recipes: **[interaction-states.md](interaction-states.md)**.

## Pause / skip wasted work

Animation you can't see is pure cost — CPU/GPU cycles, battery, and main-thread pressure that janks the animations you *can* see. Cut it.

- **Pause looping animations when offscreen** (Rauno). A spinner, marquee, gradient, or any infinite `@keyframes` running below the fold burns cycles for nothing. Pause it when it scrolls out of view, resume when it returns.
- **Use `IntersectionObserver`, not scroll listeners.** It fires off the main thread's scroll path, so observing visibility doesn't itself cost you scroll performance.
- **Skip scroll-entrance animations on fast scroll.** If the user is flinging the page, don't play a 400ms fade-up on every card as it whips past — it produces a stuttery cascade and delays content. Detect high scroll velocity and just show the elements.
- **Kill scroll listeners entirely where you can.** Replace `scroll`-event-driven reveal/parallax/sticky logic with `IntersectionObserver` (visibility) or native scroll-driven animations (`animation-timeline: scroll()` / `view()`) — both run without a main-thread `scroll` handler firing on every frame.

```js
// Pause an offscreen loop; resume when visible. Animation runs only when seen.
const io = new IntersectionObserver((entries) => {
  for (const e of entries) {
    e.target.style.animationPlayState = e.isIntersecting ? 'running' : 'paused';
  }
});
document.querySelectorAll('.loops').forEach((el) => io.observe(el));
```

```js
// Skip entrance animations during a fast fling; just reveal.
let lastY = scrollY, lastT = performance.now();
const revealIO = new IntersectionObserver((entries) => {
  const now = performance.now();
  const velocity = Math.abs(scrollY - lastY) / Math.max(now - lastT, 1); // px/ms
  lastY = scrollY; lastT = now;
  for (const e of entries) {
    if (!e.isIntersecting) continue;
    if (velocity > 2) e.target.classList.add('revealed');           // too fast → no animation
    else e.target.classList.add('revealed', 'animate');             // calm → animate in
    revealIO.unobserve(e.target);
  }
});
```

Reduced-motion users should skip these entrance animations entirely — see [accessibility.md](accessibility.md).
