# Interaction states & feedback

How interactive elements respond to the pointer, the keyboard, the network, and the absence of data. The motion here pulls from the shared token scale — see [SKILL.md](SKILL.md) for the contract, [motion.md](motion.md) for timing/easing depth, [accessibility.md](accessibility.md) for the full focus and reduced-motion story, [performance.md](performance.md) for why optimistic UI is the biggest perceived-speed lever.

These tokens are referenced throughout; define them once at `:root` (full set in [SKILL.md](SKILL.md)):

```css
:root {
  --duration-fast: 150ms;  --duration-base: 200ms;  --duration-slow: 300ms;
  --ease-out: cubic-bezier(0.05, 0.7, 0.1, 1);   /* enter / decelerate */
  --ease-in: cubic-bezier(0.3, 0, 0.8, 0.15);    /* exit / accelerate */
  --ease-standard: cubic-bezier(0.2, 0, 0, 1);   /* small in-place change */
}
```

## The state checklist

Before you ship any interactive element, account for **every** state below. A button with only a default and a hover is unfinished. The missing states are exactly the ones that make an interface feel cheap — no press feedback, an invisible focus ring, a disabled control that still looks clickable, a spinner that flashes for 80ms.

| State | When | Non-negotiable |
| --- | --- | --- |
| **Default** | At rest | The baseline. Everything else is a delta from here. |
| **Hover** | Pointer over, fine pointer only | Gate behind `@media (hover: hover)`. Never the *only* path to an action. |
| **Active / press** | Pointer or key down | `scale(0.96)` tactile feedback. Fires on press (light) or release (destructive). |
| **Focus-visible** | Keyboard focus | A visible ring via `box-shadow`. Never removed for looks. |
| **Disabled** | Action unavailable | Visually distinct, `cursor: not-allowed`, not actionable. |
| **Loading** | Async work in flight (where it loads) | Skeleton over spinner; flicker-guarded with show-delay + min-visible. |

The element-level states (default/hover/active/focus/disabled/loading) are the per-element contract. The *screen*-level states — empty, error, optimistic — are covered further down and matter just as much: a perfect button on a blank, explanationless screen is still a broken experience.

```css
/* The skeleton of any interactive control. Fill in the visuals per component. */
.control {
  transition: background-color var(--duration-fast) var(--ease-standard),
              box-shadow var(--duration-fast) var(--ease-standard),
              transform var(--duration-fast) var(--ease-standard);
  /* Never `transition: all` — name the properties. See SKILL.md / performance.md. */
}
.control:active { transform: scale(0.96); }
.control:focus-visible { box-shadow: 0 0 0 2px var(--bg), 0 0 0 4px var(--ring); }
.control:disabled { cursor: not-allowed; /* + reduced opacity, see Disabled */ }

@media (hover: hover) and (pointer: fine) {
  .control:hover { background-color: var(--control-hover); }
}
```

## Hover

Hover is an enhancement, not a foundation. Two rules.

**1. Gate it behind `@media (hover: hover) and (pointer: fine)`.** On touch devices, a tap registers as `:hover` and the hover style *sticks* until you tap elsewhere — a card stays lit, a tooltip stays open, a color stays inverted. Gating the rule means touch devices never enter the hover branch at all. This is standard practice at Vercel Geist and in Rauno Freiberg's work.

```css
/* WRONG — sticks on touch after a tap */
.card:hover { background: var(--surface-hover); }

/* RIGHT — only devices that can actually hover */
@media (hover: hover) and (pointer: fine) {
  .card:hover { background: var(--surface-hover); }
}
```

`hover: hover` excludes touchscreens; adding `pointer: fine` further excludes coarse pointers (some styluses, TV remotes) that can technically hover but can't hit hover-revealed targets precisely. Use both for anything that *reveals* an action on hover.

**2. Never make hover the only way to reach an action.** A "delete" button that appears only on row-hover is invisible to touch users, keyboard users, and screen-reader users. Hover-reveal is fine as *progressive disclosure* — to reduce visual noise — but the action must also be reachable by keyboard focus and present (or in a menu) on touch.

```css
.row-action { opacity: 0; transition: opacity var(--duration-fast) var(--ease-standard); }

/* Reveal on hover AND on keyboard focus within the row — not hover alone */
@media (hover: hover) and (pointer: fine) {
  .row:hover .row-action { opacity: 1; }
}
.row:focus-within .row-action { opacity: 1; }   /* keyboard parity */

/* On touch (no hover), don't hide it at all */
@media (hover: none) {
  .row-action { opacity: 1; }
}
```

```css
@media (prefers-reduced-motion: reduce) {
  .row-action { transition-duration: 0.01ms; }   /* see accessibility.md */
}
```

Tailwind: the `hover:` variant compiles to a bare `:hover` and does **not** gate behind `@media (hover: hover)` by default. For reveal-on-hover patterns, add the gate yourself in a stylesheet or enable a custom variant — don't assume `hover:opacity-100` is touch-safe.

## Active / press

Press feedback makes a control feel physical — it acknowledges the input the instant it lands, before any result. Use `transform: scale(0.96)`.

**Never go below `scale(0.95)`.** 0.96 reads as a confident, tactile press; 0.90 looks like the button is being crushed and draws attention to itself. This is a transform-only animation, so it's cheap and composited (see [performance.md](performance.md)).

```css
.button { transition: transform var(--duration-fast) var(--ease-standard); }
.button:active { transform: scale(0.96); }   /* floor is 0.95 — never lower */

@media (prefers-reduced-motion: reduce) {
  .button { transition: none; }
  .button:active { transform: none; }   /* substitute: rely on the :active color change instead */
}
```

For the deeper rationale on scale-press, spring vs transition, and combining press with other transforms, see [motion.md](motion.md).

**Press vs release — when does the action fire?**

| Action class | Fire on | Why |
| --- | --- | --- |
| Lightweight / reversible (toggle, tab, like, expand) | **press** (`pointerdown`) | Feels instant; a few ms faster than waiting for release. |
| Destructive / irreversible (delete, send, pay, submit) | **release** (`click`) | The user can slide off the target to cancel before lifting. Releasing is the commit. |

The browser's native `click` already fires on release — which is correct for destructive actions, so you usually don't touch it. Reach for `pointerdown` only to make a *safe, high-frequency* action feel snappier (this is the same reason menus open on `mousedown` — see Menus & overlays).

```js
// Lightweight action — respond on press for instant feel
toggle.addEventListener("pointerdown", (e) => {
  if (e.button !== 0) return;        // primary button only
  applyToggle();                     // safe + reversible, so committing early is fine
});

// Destructive action — let it commit on release (native click), never on pointerdown
deleteBtn.addEventListener("click", confirmAndDelete);
```

## Focus-visible

**Never remove a focus indicator for aesthetics.** `outline: none` with no replacement is the single most common accessibility regression in polished-looking UIs — it makes the interface unusable by keyboard. If the default outline is ugly, *replace* it; don't delete it.

Replace `outline` with a `:focus-visible` ring drawn via `box-shadow`. `box-shadow` follows `border-radius`, so the ring hugs rounded corners; `outline` (pre–`outline` radius support) draws a hard rectangle that clips through them. This is Rauno Freiberg's recipe.

```css
/* The recipe: kill the default outline, draw a rounded ring on keyboard focus only */
.control:focus { outline: none; }              /* remove the default box */
.control:focus-visible {
  outline: none;
  /* two-stop ring: a gap in the page background, then the ring color —
     keeps the ring legible against the control's own fill */
  box-shadow: 0 0 0 2px var(--bg), 0 0 0 4px var(--ring);
  border-radius: inherit;                       /* ring respects the corners */
}
```

Why `:focus-visible` and not `:focus`: `:focus` fires on *mouse* clicks too, so a plain `:focus` ring flashes every time a mouse user clicks a button — noise. `:focus-visible` is the browser's heuristic for "focus that the user needs to *see*" — essentially keyboard and programmatic focus — so the ring appears for keyboard users and stays quiet for mouse users.

**`:focus-within`** styles an ancestor when any descendant has focus — use it to highlight the *container* of the focused element (a form field wrapper, a composer, a row). Pairs naturally with the keyboard-parity pattern in Hover.

```css
/* Highlight the whole field wrapper while its input is focused */
.field:focus-within { border-color: var(--ring); }
```

The focus ring itself is a state change, not motion — don't animate it appearing (a fading-in ring lags behind fast tabbing). The full story — ring contrast ratios, `forced-colors` / Windows High Contrast, `:focus-visible` polyfill fallbacks, focus management in overlays — lives in [accessibility.md](accessibility.md). The pattern above is enough to ship a correct ring today.

## Disabled

A disabled control must be unmistakably disabled and genuinely inert.

- **Visually distinct** — reduced opacity (~0.5) or a muted fill, so it reads as unavailable at a glance. Don't rely on color alone; the drop in contrast/opacity carries the meaning (info not by color alone — see Error states).
- **`cursor: not-allowed`** — the pointer signals "you can't use this" before the click.
- **Not actionable** — the native `disabled` attribute on `<button>`/`<input>` removes it from the tab order and blocks click/submit events. That is the correct mechanism. If you must keep an element focusable to explain *why* it's disabled (e.g. a tooltip), use `aria-disabled="true"` instead and block the action in JS — but prefer native `disabled` whenever you don't need that.

```css
.button:disabled,
.button[aria-disabled="true"] {
  opacity: 0.5;
  cursor: not-allowed;
  pointer-events: none;          /* with native :disabled this is belt-and-suspenders */
}
/* aria-disabled keeps pointer-events so a tooltip can fire; block the action in JS instead */
.button[aria-disabled="true"] { pointer-events: auto; }
```

**Disable submit buttons after submission.** The moment a form submits, disable its submit button until the request resolves. Otherwise an impatient double-click fires the request twice — duplicate orders, duplicate messages, duplicate charges. This is Rauno Freiberg's rule and it is not optional for anything that writes to a server. Re-enable on completion (or navigate away on success).

```js
form.addEventListener("submit", async (e) => {
  e.preventDefault();
  submitBtn.disabled = true;                 // block the duplicate request immediately
  try {
    await postForm(new FormData(form));
    // success: navigate, or show trigger-local confirmation
  } catch (err) {
    showFieldErrors(err);
    submitBtn.disabled = false;              // re-enable so they can retry
  }
});
```

Pair this with a loading state on the button (see below) so the disabled period reads as "working," not "broken."

## Loading & skeletons

**Prefer skeletons over spinners for content.** A skeleton — gray placeholder blocks shaped like the incoming content — previews the layout, communicates *what* is loading, and eliminates the layout shift that happens when a spinner is replaced by content of unknown size. A spinner says "something is happening somewhere"; a skeleton says "this specific content is arriving here." Use a spinner only for indeterminate, shapeless waits (a button's own in-flight state, a full-page boot) where there's no layout to preview.

**Two anti-flicker rules (Vercel Geist).** A naive loader that toggles on the instant a request starts and off the instant it ends produces two distinct uglinesses:

1. **Show-delay ~150–300ms** — don't show the loader at all until the request has been pending for this long. Most requests resolve faster than the eye registers; flashing a skeleton for 80ms is worse than showing nothing. If the data arrives before the delay elapses, the user never sees a loader — the content just appears.
2. **Minimum visible time ~300–500ms** — *once* the loader is shown, keep it up for at least this long even if the data arrives 50ms later. A loader that flashes on and vanishes reads as a glitch. Committing to a minimum makes the wait feel intentional and calm.

Together these define a window: requests faster than ~150–300ms show no loader; requests that cross that threshold show a loader for a *stable* ~300–500ms minimum.

```js
// Show-delay + minimum-visible loader controller. Framework-agnostic.
function createLoaderController({ showDelay = 200, minVisible = 400 } = {}) {
  let showTimer = null;
  let shownAt = 0;
  let visible = false;

  return {
    start(show, hide) {
      // arm the show-delay; if work finishes first, the loader never appears
      showTimer = setTimeout(() => {
        visible = true;
        shownAt = performance.now();
        show();
      }, showDelay);
    },
    stop(hide) {
      clearTimeout(showTimer);
      if (!visible) return;                        // resolved within show-delay: nothing to hide
      const elapsed = performance.now() - shownAt;
      const remaining = Math.max(0, minVisible - elapsed);
      setTimeout(() => { visible = false; hide(); }, remaining);   // honor min-visible
    },
  };
}

// Usage
const loader = createLoaderController();
loader.start(() => skeleton.hidden = false);
const data = await fetchThing();
loader.stop(() => skeleton.hidden = true);
renderThing(data);
```

**Skeleton shimmer — and its reduced-motion variant.** The shimmer is a gradient sweeping across the placeholder. It must have a static fallback under reduced motion: a sweeping animation across the whole screen is exactly the kind of large-area motion that triggers vestibular discomfort (see [accessibility.md](accessibility.md)). Under `prefers-reduced-motion: reduce`, drop the animation and show a flat block.

```css
.skeleton {
  background: var(--skeleton-base);
  border-radius: 6px;
}
@media (prefers-reduced-motion: no-preference) {
  .skeleton {
    background: linear-gradient(
      90deg,
      var(--skeleton-base) 25%,
      var(--skeleton-highlight) 37%,
      var(--skeleton-base) 63%
    );
    background-size: 400% 100%;
    animation: skeleton-shimmer 1.4s ease infinite;   /* continuous loop → linear-ish ease ok */
  }
}
@keyframes skeleton-shimmer {
  from { background-position: 100% 0; }
  to   { background-position: 0 0; }
}
/* Reduced motion: no @keyframes applied — the flat .skeleton block stands in. */
```

Note the inversion: the shimmer is opted *in* via `(prefers-reduced-motion: no-preference)` rather than disabled via `reduce`. That's the safe default — if the media query is unsupported or the preference is unknown, you get the static block, not the animation.

## Empty states

An empty state is a designed screen, never a blank void. A user who lands on emptiness with no explanation assumes the app is broken or that they did something wrong. Every collection that can be empty needs deliberate copy and a way forward.

A complete empty state has three parts:

1. **A one-line explanation** — what belongs here and why it's empty right now.
2. **A primary CTA** — the single most useful next action (create the first item, adjust the filter, connect a source).
3. **Optional illustration or icon** — sets tone and draws the eye; never a substitute for the copy.

**The three flavors differ — don't ship one generic "Nothing here."**

| Flavor | Trigger | Copy + CTA |
| --- | --- | --- |
| **First-run** | User has never created anything | Onboarding tone. Explain the feature's value; CTA is "Create your first ___." Optional illustration. |
| **No-results** | A search/filter matched nothing | Acknowledge the query. "No results for *'foo'*." CTA is "Clear filters" or "Adjust search" — *not* "Create." |
| **Cleared-all** | User completed/deleted everything | Affirming. "You're all caught up." Often no CTA, or a gentle secondary one. A small reward, not a prompt to do more work. |

Conflating these is a real bug: showing "Create your first project" to someone whose *filter* simply excluded everything is confusing and wrong. Branch on *why* the list is empty.

```html
<!-- No-results variant: acknowledge the query, offer to widen it -->
<div class="empty" role="status">
  <svg class="empty__icon" aria-hidden="true"><!-- magnifier --></svg>
  <p class="empty__title">No results for "<em>quarterly</em>"</p>
  <p class="empty__body">Try a different term or clear your filters.</p>
  <button class="button" type="button">Clear filters</button>
</div>
```

## Error states

Errors are a feedback channel; treat them as part of the design, not an afterthought. Three requirements.

**1. Inline and adjacent to the cause.** A field-level error belongs *next to that field*, not in a banner at the top of a long form where the user has to hunt for which input is wrong. Put the message where the eye already is.

**2. Human language with a path to recovery.** Not `Error 422: unprocessable entity`. Say what went wrong and what to do: "That email is already registered — sign in instead?" Every error should imply a next step.

**3. Never communicate an error by color alone.** A red border with no text or icon is invisible to colorblind users (~8% of men) and ambiguous to everyone (red border = error? required? just the focus color?). Pair the color with an icon **and** text — *information is never carried by color alone* (this is a hard accessibility rule; see [accessibility.md](accessibility.md)).

```html
<!-- WRONG — color is the only signal -->
<input class="input input--error" />

<!-- RIGHT — border + icon + text, programmatically linked -->
<div class="field">
  <label for="email">Email</label>
  <input id="email" class="input input--error"
         aria-invalid="true" aria-describedby="email-err" />
  <p id="email-err" class="field__error" role="alert">
    <svg aria-hidden="true"><!-- alert icon --></svg>
    Enter a valid email address.
  </p>
</div>
```

```css
.input--error { border-color: var(--danger); }
.field__error {
  display: flex; align-items: center; gap: 6px;
  color: var(--danger-text);          /* darker than the border for AA contrast on text */
}
```

`aria-describedby` ties the message to the input so screen readers announce it on focus; `role="alert"` announces it immediately when it appears. Inline validation should fire on blur or submit — not on every keystroke, which scolds the user mid-typing.

## Optimistic UI

**This is the single biggest perceived-speed lever you have** — bigger than any animation. Render the expected result *immediately* on interaction, assuming success; then reconcile against the server's actual response, rolling back with feedback only if it failed. The interface responds at the speed of thought instead of the speed of the network. Linear's core tenet: UI responsiveness must never depend on network latency. Rauno Freiberg states it directly — "optimistically update locally and roll back on server error." See also Simon Hearne's optimistic-UI patterns and [performance.md](performance.md).

Use it for high-confidence, low-stakes, reversible writes: toggling a like, checking a box, adding to a list, renaming, reordering, marking read. Do **not** use it where a wrong guess is costly or confusing: payments, irreversible deletes, anything where showing a fake success then yanking it back would mislead.

The shape: **apply locally → send request → on success, settle (often a no-op) → on error, revert to the captured previous state and tell the user.**

```js
async function toggleLike(item, button) {
  const previous = item.liked;            // 1. capture for rollback
  item.liked = !item.liked;               // 2. apply optimistically
  render(item, button);                   //    UI updates instantly — no await before this

  try {
    await api.setLike(item.id, item.liked);   // 3. fire the request
    // success: server agrees, nothing more to do
  } catch (err) {
    item.liked = previous;                // 4. roll back to the captured state
    render(item, button);
    toast("Couldn't save — tap to retry", () => toggleLike(item, button));
  }
}
```

Rollback needs feedback or it's a silent lie: if the like quietly reverts with no message, the user thinks *they* mis-tapped. The error signal is what makes optimism honest. React + Motion users have `useOptimistic` for exactly this (it auto-reverts when the real state resolves); don't add a library for it if you're not already on React.

## Trigger-local feedback

Show the result of an action *at the action*, not across the screen. After a successful "copy," swap the copy icon to a checkmark in place for a beat, then swap back — don't fire a toast in the opposite corner that costs an eye-movement to read and confirms something the user already knows where to look for. This is Rauno Freiberg's principle: feedback belongs relative to its trigger. Toasts are for *out-of-context* events (a background job finished, a message arrived) — not for confirming the thing the user is currently looking at.

```js
async function copy(text, button) {
  await navigator.clipboard.writeText(text);
  const icon = button.querySelector(".icon");
  icon.dataset.state = "copied";                    // CSS swaps glyph + color in place
  button.setAttribute("aria-label", "Copied");
  clearTimeout(button._t);
  button._t = setTimeout(() => {
    icon.dataset.state = "idle";
    button.setAttribute("aria-label", "Copy");
  }, 1200);                                          // brief, then revert
}
```

```css
.icon[data-state="copied"] { color: var(--success); }
.icon { transition: color var(--duration-fast) var(--ease-standard); }
@media (prefers-reduced-motion: reduce) { .icon { transition: none; } }
```

**Toggles take effect immediately — never gate a toggle behind a confirm step or a separate "Save."** A switch that flips and *then* asks "Are you sure?" breaks the mental model of a switch. If the action is dangerous enough to need confirmation, it shouldn't be a toggle; make it a button with a confirm flow. The toggle's own state change is the feedback; back it with optimistic UI so it flips instantly and reconciles in the background.

## Menus & overlays

**Open dropdowns on `mousedown`, not `click`.** `click` only fires after the button is *released*; `mousedown` fires the instant the button goes down. Opening on `mousedown` makes the menu feel like it was already there — it appears under the cursor before the user finishes the press. This is Rauno Freiberg's technique and it's a large, free perceived-speed win for menus you open constantly.

```js
trigger.addEventListener("mousedown", (e) => {
  if (e.button !== 0) return;       // primary only
  e.preventDefault();               // stop the focus-stealing / text-selection default
  openMenu();
});
```

(Keep keyboard parity: `Enter`/`Space`/`ArrowDown` on the trigger must also open it. `mousedown` is a pointer optimization, not a replacement for keyboard handling — see [accessibility.md](accessibility.md).)

**Submenus need a "prediction cone" / exit-delay so a diagonal pointer path doesn't dismiss them.** When the pointer moves from a parent item toward an open submenu, its path cuts diagonally across *sibling* items. Naively, hovering a sibling closes the submenu and the user can never reach it. The fix (Josh Comeau): put a `transition-delay` on the *exit* (closing) so the submenu lingers ~200–300ms after the pointer leaves the parent, giving the diagonal path time to land — but **0ms delay on enter** so opening stays instant. (The robust version actually tracks the triangle between cursor and submenu corners; the asymmetric delay is the simple, effective approximation.)

```css
.submenu {
  opacity: 0;
  pointer-events: none;
  transition: opacity var(--duration-fast) var(--ease-out);
  transition-delay: 0ms;            /* enter: open immediately */
}
.menu-item:hover > .submenu,
.menu-item:focus-within > .submenu {
  opacity: 1;
  pointer-events: auto;
}
/* When the pointer leaves, delay the close so a diagonal path can reach the submenu */
.menu-item:not(:hover) > .submenu {
  transition-delay: 250ms;          /* exit: linger */
}
@media (prefers-reduced-motion: reduce) {
  .submenu { transition: opacity 0.01ms; }   /* keep the delay logic, drop the fade — accessibility.md */
}
```

**Every overlay closes on `Esc` and on outside-click, and returns focus to the trigger.** This is table stakes for menus, dialogs, popovers, and sheets. Closing without restoring focus dumps keyboard users back at the top of the document — they lose their place entirely.

```js
function openOverlay(panel, trigger) {
  const onKey = (e) => { if (e.key === "Escape") close(); };
  const onClickOut = (e) => { if (!panel.contains(e.target)) close(); };

  document.addEventListener("keydown", onKey);
  // defer so the opening click itself doesn't immediately close it
  setTimeout(() => document.addEventListener("pointerdown", onClickOut), 0);

  function close() {
    document.removeEventListener("keydown", onKey);
    document.removeEventListener("pointerdown", onClickOut);
    panel.hidden = true;
    trigger.focus();                 // return focus to where it came from
  }
  return close;
}
```

Full overlay semantics — focus trapping inside modal dialogs, `aria-expanded`/`aria-haspopup` on triggers, `role="menu"` vs `role="dialog"`, inert background, the native `popover` attribute and top-layer — are in [accessibility.md](accessibility.md). The behaviors above are the interaction floor every overlay must clear.
