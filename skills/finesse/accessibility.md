# Accessibility

Accessibility is not a separate pass you do later — it is part of what "feels good" means. An interface that makes someone sick, traps a keyboard user, or vanishes in High Contrast mode is not polished, however nice it looks. These rules are non-negotiable; treat a violation as a bug, not a nice-to-have.

This file is the canonical policy. Motion files show the per-animation pattern inline and link back here.

## `prefers-reduced-motion` — honor it for every animation

A meaningful share of people experience dizziness, nausea, or headaches from motion (vestibular disorders). The OS-level "Reduce Motion" setting is their explicit request. Respect it everywhere you animate.

**Opt motion IN, don't bolt a kill-switch on after.** Author the no-motion state as the default and add motion only when the user hasn't asked to reduce it:

```css
/* Default: no transform-based motion. Add it only when motion is welcome. */
.panel { opacity: 0; }
@media (prefers-reduced-motion: no-preference) {
  .panel { transition: opacity var(--duration-base) var(--ease-out),
                       transform var(--duration-base) var(--ease-out); transform: translateY(8px); }
}
```

**Reduced motion ≠ no motion — substitute, don't delete.** Movement that carries meaning (where did this come from, what changed) should degrade to an *opacity* fade or an instant change, not disappear. Apple's own guidance is to replace sliding transitions with crossfades, not strip them. Removing meaningful motion entirely can make an interface *more* confusing.

```css
@media (prefers-reduced-motion: reduce) {
  /* Keep the meaning (the element still appears), drop the travel/scale/blur. */
  .panel { transform: none; transition: opacity var(--duration-fast) var(--ease-standard); }
}
```

**Reject the global sledgehammer.** `* { animation: 0.01ms !important; transition: 0.01ms !important }` is too blunt — it breaks meaning-carrying motion and stateful transitions. Tailor per component.

**JS / library:**
```js
const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
// React + Motion: const reduce = useReducedMotion();  // then skip transform/scale, keep opacity
```

**Especially disable under Reduce Motion:** parallax, multi-axis moves, spinning/vortex effects, large scaling/zooming, and auto-advancing carousels — Apple's named nausea triggers. See [motion.md](motion.md) for the motion catalogue.

## Don't convey information by motion or color alone

A flash, a slide, or a red border is never the *only* signal. Pair color with an icon or text label; pair motion with a persistent state change. Color-blind, low-vision, reduced-motion, and screen-reader users must all get the message. (Error states: red border **and** an inline message — see [interaction-states.md](interaction-states.md).)

## Focus must always be visible

Keyboard and switch users navigate by focus. If they can't see where they are, the interface is unusable to them.

- **Never remove the outline for looks.** If you dislike the default ring, replace it — don't delete it.
- **Use `:focus-visible`** so the ring shows for keyboard/programmatic focus but not on mouse click.
- **Render the ring with `box-shadow`, not `outline`** — `box-shadow` respects `border-radius` (an `outline` historically drew a rectangle around rounded corners; modern browsers now follow `border-radius`, but `box-shadow` remains the safe cross-version choice, and — see below — survives forced-colors differently). This is also why "shadows instead of borders" ([surfaces.md](surfaces.md)) must not eat the focus ring.

```css
:focus-visible {
  outline: none;
  box-shadow: 0 0 0 2px var(--bg), 0 0 0 4px var(--focus-ring); /* 2px gap + visible ring */
}
```

- Maintain a logical tab order (DOM order = visual order); don't add `tabindex` > 0.
- Provide a **skip-to-content** link as the first focusable element.
- On route change and on opening a modal, **move focus** into the new context; **trap** focus inside an open modal; **restore** focus to the trigger on close.
- `Esc` closes overlays; `Enter` submits when a single text input is focused; never block typing or intercept native shortcuts.

## Forced colors / Windows High Contrast

In `forced-colors: active`, the OS replaces your palette with a user-chosen one — **`box-shadow` is forced to `none` (dropped) and custom colors are replaced by system colors.** A shadow used as the *only* boundary vanishes — so give essential boundaries a real (often transparent) border the mode can paint:

```css
.card { border: 1px solid transparent; /* invisible normally; painted in forced-colors */ }
@media (forced-colors: active) {
  .card { border-color: CanvasText; }
  :focus-visible { outline: 2px solid Highlight; } /* a real outline returns here */
}
```

Use `forced-color-adjust: none` only on deliberate swatches (color pickers) where the actual color is the content.

## Contrast

- Body/UI text: **≥ 4.5:1** against its background. Large text (≥24px, or ≥18.7px bold) and meaningful non-text/UI boundaries: **≥ 3:1**.
- Colored backgrounds usually need to be fairly dark to clear 4.5:1 with white text — see the functional-scale approach in [layout-and-color.md](layout-and-color.md).
- Disabled controls are exempt from the ratio, but don't make "disabled" the only affordance for important state.

## Semantics before ARIA

The first rule of ARIA is don't use ARIA when a native element does the job — native elements come with focus, keyboard behavior, and roles for free.

- Use real `<button>`, `<a href>`, `<label>`, `<input>`, `<table>`, `<nav>`, `<dialog>` — not `<div onclick>`.
- Every control has an accessible name: a visible `<label>`, or `aria-label` on **icon-only** buttons (Rauno).
- Inline SVG icons: decorative → `aria-hidden="true"`; meaningful → `<title>` (and `role="img"`/`aria-label`).
- **Announce dynamic changes** to screen readers with a live region — toasts, async validation, and the live-updating numbers that get `tabular-nums` ([typography.md](typography.md)) are invisible to AT without one:

```html
<div aria-live="polite" aria-atomic="true"><!-- status text swapped in here --></div>
```

Use `polite` for status, `assertive` only for genuinely urgent errors.

## Touch & input

- Form inputs **≥ 16px** font size or iOS zooms on focus ([typography.md](typography.md)).
- Hit areas **≥ 44×44px** (≥40 acceptable), no overlaps ([surfaces.md](surfaces.md)).
- Gate hover styling behind `@media (hover: hover)` so it doesn't stick after a tap ([interaction-states.md](interaction-states.md)).
- If you disable the iOS tap highlight (`-webkit-tap-highlight-color: transparent`), you **must** supply your own press feedback (Rauno).

## Quick audit

- [ ] Every animation respects `prefers-reduced-motion`, substituting (not deleting) meaningful motion
- [ ] Nothing is communicated by color or motion alone
- [ ] Visible `:focus-visible` ring on every interactive element; logical tab order; skip link
- [ ] Modals trap + restore focus; `Esc` closes; route changes move focus
- [ ] Essential boundaries survive `forced-colors: active` (real/transparent border, not just shadow)
- [ ] Text ≥ 4.5:1 contrast; UI boundaries ≥ 3:1
- [ ] Native semantic elements; accessible name on every control; `aria-label` on icon-only buttons
- [ ] Dynamic updates announced via `aria-live`
- [ ] Inputs ≥ 16px; hit areas ≥ 40–44px

→ Vestibular safety and the "substitute, don't delete" principle are echoed by Apple HIG, Material, web.dev, Josh Comeau, and Cassie Evans — see [sources.md](sources.md).
