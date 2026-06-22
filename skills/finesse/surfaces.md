# Surfaces & depth

How surfaces stack, separate, and catch light. This is the depth layer for the **Surfaces & depth** section of [SKILL.md](SKILL.md) — the long-form rationale, the good-vs-bad code, and the decision tables. Shadow *color* theory overlaps with [layout-and-color.md](layout-and-color.md); focus rings and forced-colors behavior live in [accessibility.md](accessibility.md); the hover/active/focus transitions these surfaces ride on live in [interaction-states.md](interaction-states.md).

Five things make a surface feel right: nested corners that agree, shadows that read as elevation instead of decoration, image edges that stay crisp without picking up dirt, alignment that satisfies the eye rather than the math, and hit areas big enough for a thumb. Get them wrong and the UI feels "off" without anyone being able to say why. That vagueness is the point — these are felt, not seen.

## Concentric border radius

Nested rounded corners must share a center. When an outer container has padding and a rounded child sits inside it, the child's radius is **not** a free choice — it's fixed by the geometry:

```
outerRadius = innerRadius + padding
```

Solve for the inner radius you actually control:

```
innerRadius = outerRadius − padding
```

If the outer radius is `20px` and the padding is `8px`, the inner radius is `12px`, because `20 = 12 + 8`. Any other inner value leaves the corners non-concentric: the gap between the two arcs is wide at the corner and narrow along the edges (inner too small) or the inner corner visibly pokes toward the outer one (inner too large). Either way the eye reads a wobble it can't name.

```css
/* Vanilla — concentric */
.card {
  border-radius: 20px;
  padding: 8px;
}
.card > .inner {
  border-radius: 12px;   /* 20 − 8, NOT 20, NOT 16 */
}
```

```html
<!-- Tailwind — rounded-2xl (16px) is the common case; here outer 20px via radius scale -->
<div class="rounded-2xl p-2">        <!-- outer: 16px radius, 8px padding -->
  <div class="rounded-lg">…</div>     <!-- inner: 8px (rounded-lg) = 16 − 8 -->
</div>
```

Tailwind's named radii line up with the math when the padding matches: `rounded-2xl` (16px) outer with `p-2` (8px) gives an inner of 8px — `rounded-lg`. `rounded-xl` (12px) outer with `p-1` (4px) gives `rounded-lg` (8px) inner. Memorize the relationship, not the table: **inner named-radius = outer minus the padding step.**

**Mismatched nested radii are one of the single most common things that make a UI feel "off."** It shows up everywhere: an avatar inside a card, a thumbnail inside a button, an input inside a rounded toolbar, a sheet inside a rounded device frame. Whenever you see a rounded thing inside another rounded thing, run the subtraction.

**Gotcha — large padding breaks the model.** Concentricity only matters when the layers visually read as *one nested object*. Once the padding exceeds roughly `24px`, the inner element is no longer "hugged" by the outer corner; the eye stops relating the two arcs. Past that point, forcing `inner = outer − padding` produces an inner radius so large it looks unrelated (e.g. `40px` outer − `32px` padding = `8px` inner reads fine, but `20px` outer − `28px` padding goes *negative*). **Treat the two layers as separate surfaces and choose each radius independently for its own size.** Big gutter → independent radii. Tight gutter → run the math.

| Outer radius | Padding | Inner radius | Notes |
| --- | --- | --- | --- |
| 20px | 8px | 12px | Classic nested case |
| 16px (`rounded-2xl`) | 8px (`p-2`) | 8px (`rounded-lg`) | Tailwind named pair |
| 12px (`rounded-xl`) | 4px (`p-1`) | 8px (`rounded-lg`) | Tight nesting |
| 24px | 24px | — | Padding at the limit; consider independent radii |
| 20px | 28px | negative | Layers are separate surfaces — choose freely |

## Shadows for elevation, not dividers

A shadow's only legitimate job is **depth** — telling the eye one surface floats above another. Apply shadows to things that genuinely lift off the page: **buttons, cards, popovers, dropdowns, modals, toasts, tooltips.** Do **not** reach for a shadow to separate two coplanar regions — a list from its header, one table row from the next, a sidebar from content. Those are *dividers*, and a divider is a `border` (a hairline), never a blurred shadow. A shadow used as a divider reads as smudge; a border used as elevation reads as a sticker. See the decision table at the end of this section.

### Light comes from above

Real light falls from above, so real shadows pool *below* the object. Every elevation shadow must be **offset downward** — a positive vertical `y`, zero or near-zero `x`. A symmetric `0 0 Npx` glow has no light source and reads as a halo, not a lift.

**Anthony Hobday's ratio: the blur radius should be roughly twice the vertical offset.** A shadow sitting `2px` below its object wants about `4px` of blur; `4px` down wants ~`8px` blur; `8px` down wants ~`16px`. Tighter than 2× looks hard and cut-out; much looser looks like fog. This single ratio is what separates a believable shadow from a default-looking one.

### Layer at least two shadows

One shadow can't model real light. Stack them:

- A tight, low, near-opaque **ambient** layer — the contact shadow directly under the object (small offset, small blur). It anchors the object to the surface.
- A softer, larger, lower-opacity **direct** layer — the cast shadow thrown further out (larger offset, larger blur). It sells the height.

Two or three layers compound into something that reads as a single, physically plausible shadow. One flat shadow never will.

### Tint the shadow with the surface hue — never pure black

Pure-black shadows (`rgba(0,0,0,…)` at any meaningful alpha over a colored or warm surface) look muddy and dead. Real shadows take on the color of the surface they fall on. **Tint every shadow toward the hue of the background it sits on, and toward a darker, slightly more saturated version of that hue** (Josh Comeau, *Refactoring UI*). On a warm off-white page, push the shadow toward a desaturated warm brown; on a cool gray app, toward a dark slate-blue. Keep alpha low and let the tint do the work. The black recipe below is the *neutral* fallback for a truly neutral surface — the moment the surface has a hue, give the shadow that hue.

### Light-mode 3-layer recipe

Define elevation as tokens and reference them; never hand-write a shadow at a call site.

```css
:root {
  /* 3 stacked layers: a 1px ring acting as a border, a 1px lift, a soft ambient pool.
     All low-alpha. On a tinted surface, replace the blacks with the surface hue. */
  --shadow-sm:
    0 0 0 1px rgba(0, 0, 0, 0.04),   /* ring  — crisp 1px edge, reads as a border */
    0 1px 1px rgba(0, 0, 0, 0.06),   /* lift  — tight contact shadow just below */
    0 2px 4px rgba(0, 0, 0, 0.06);   /* ambient — soft pool selling a little height */
}

.card {
  background: #fff;
  border-radius: 12px;
  box-shadow: var(--shadow-sm);
}
```

The `0 0 0 1px` ring is the trick worth internalizing: it's a *shadow* doing a 1px border's job, so it hugs the `border-radius` perfectly, never adds to layout size, and stacks in the same `box-shadow` declaration as the depth layers. Note the blur-to-offset ratio holds: the `1px` lift gets `1px` blur, the `2px` ambient gets `4px` blur (2×).

### Elevation scale (~5 levels)

Higher elevation = the object is *further* from the surface, so light spreads more: **bigger offset, bigger blur, lower opacity.** As things rise they cast larger, softer, fainter shadows — not larger, *darker* ones. Darkening as you go up is the classic mistake; it makes high elevations look heavy and grounded instead of floating.

```css
:root {
  --shadow-0: none;                                                 /* flush with the page */
  --shadow-1:                                                       /* resting card */
    0 0 0 1px rgba(0,0,0,0.04),
    0 1px 2px rgba(0,0,0,0.06);
  --shadow-2:                                                       /* hovered card, small popover */
    0 0 0 1px rgba(0,0,0,0.04),
    0 2px 4px rgba(0,0,0,0.06),
    0 4px 8px rgba(0,0,0,0.04);
  --shadow-3:                                                       /* dropdown, menu */
    0 0 0 1px rgba(0,0,0,0.04),
    0 4px 8px rgba(0,0,0,0.05),
    0 8px 16px rgba(0,0,0,0.04);
  --shadow-4:                                                       /* modal, dialog */
    0 0 0 1px rgba(0,0,0,0.04),
    0 8px 16px rgba(0,0,0,0.05),
    0 16px 32px rgba(0,0,0,0.04);
}
```

Each step up roughly doubles offset and blur and *drops* opacity. Pick the level by what the element is, not by eye: resting card `--shadow-1`, menu `--shadow-3`, modal `--shadow-4`.

### Hover transitions only the shadow

When a card lifts on hover, transition **only `box-shadow`** — never `transition: all` (see the Common mistakes table in [SKILL.md](SKILL.md)) — at `--duration-fast` with an ease-out curve. Pair it with a `translateY(-1px)` or `-2px` on `transform` if you want the object to physically rise; the transform animates on the compositor for free (see [interaction-states.md](interaction-states.md) for the full hover/active/focus pattern and [performance.md](performance.md) for why transform is cheap). Honor `prefers-reduced-motion` — wrap or drop this transition under `(prefers-reduced-motion: reduce)`; see [accessibility.md](accessibility.md).

```css
.card {
  box-shadow: var(--shadow-1);
  transition: box-shadow var(--duration-fast) var(--ease-out);
}
@media (hover: hover) {
  .card:hover { box-shadow: var(--shadow-2); }
}
```

```html
<!-- Tailwind: gate hover so it doesn't stick on touch -->
<div class="shadow-sm transition-shadow duration-150 ease-out [@media(hover:hover)]:hover:shadow-md">…</div>
```

### Dark mode: collapse the stack

**Layered depth shadows are essentially invisible in dark interfaces** — a black shadow on a near-black surface has nothing to darken. Stacking five of them buys you nothing but render cost. **Anthony Hobday's rule: don't use shadows in dark interfaces.** Elevation in dark mode is communicated by *lighter* surfaces (a raised panel is a brighter gray than the page) and by a faint **light ring**, not by a cast shadow.

Collapse the whole scale to a single hairline ring made of low-alpha *white*:

```css
@media (prefers-color-scheme: dark) {
  :root {
    --shadow-1: 0 0 0 1px rgba(255, 255, 255, 0.08);
    --shadow-2: 0 0 0 1px rgba(255, 255, 255, 0.08);
    --shadow-3: 0 0 0 1px rgba(255, 255, 255, 0.08);
    --shadow-4: 0 0 0 1px rgba(255, 255, 255, 0.08);
  }
  .card:hover { --shadow-1: 0 0 0 1px rgba(255, 255, 255, 0.13); } /* ~0.13 on hover */
}
```

The resting ring is `rgba(255,255,255,0.08)`; brighten to ~`0.13` on hover to acknowledge the interaction. That subtle edge-light is the *entire* depth budget in dark mode. Communicate any further elevation by raising the surface's own lightness, not by adding a shadow.

### Don't mix depth techniques

Anthony Hobday again, and it generalizes past dark mode: **pick one depth language per surface and commit.** Don't give the same card a cast shadow *and* a heavy border *and* a gradient *and* an inner highlight — each technique implies a slightly different light model, and stacking them muddies all of them. Shadow *or* a raised background *or* a ring — not three at once.

### Decision table — shadow vs border

| Use a **shadow** when… | Use a **border** when… |
| --- | --- |
| The element is genuinely elevated (card, popover, modal, toast) | You're separating two coplanar regions (header/body, sidebar/content) |
| It floats over a *varied* or image background where a border would look arbitrary | The surfaces sit on the *same plane* and just need a hairline between them |
| You want depth/lift that responds to hover | You need a divider, table-cell separation, or dense data gridlines |
| — | You need an **input outline** — borders are reliably visible to assistive tech and in forced-colors; a shadow is not (see [accessibility.md](accessibility.md)) |
| — | You're drawing many fine hairlines (dense lists, tables) where shadow blur would smear |

When in doubt: *is this thing floating, or is it flat next to its neighbor?* Floating → shadow. Flat → border. And prefer **fewer** of both — reach for spacing and background-color separation first (see [layout-and-color.md](layout-and-color.md)).

## Image outlines (for depth and crispness)

Photos, avatars, thumbnails, and screenshots placed on a light surface tend to bleed into the background at the edges — especially when the image has bright or white borders of its own. A whisper-thin outline restores a crisp edge and makes the image feel set *into* the surface rather than floating loose on top of it.

```css
img {
  outline: 1px solid rgba(0, 0, 0, 0.1);
  outline-offset: -1px;        /* inset the line so the image keeps its exact size */
}
@media (prefers-color-scheme: dark) {
  img { outline-color: rgba(255, 255, 255, 0.1); }
}
```

```html
<!-- Tailwind -->
<img class="outline outline-1 -outline-offset-1 outline-black/10 dark:outline-white/10" … />
```

**Use `outline`, not `border`, and inset it with a negative offset.** Two reasons, both deliberate:

1. `outline` does **not** participate in layout — it draws over the box without nudging anything around it or changing the image's rendered dimensions. A `border` would add to the box (or, with `box-sizing: border-box`, eat into the image), shifting neighbors by a pixel.
2. `outline-offset: -1px` pulls the 1px line *inward*, so it's painted just inside the image's own edge. The image occupies precisely the same pixels it would without the outline — the line sits on top of the outermost row/column rather than wrapping outside it.

### Color rule (non-negotiable): pure black or pure white only

The outline color is **`rgba(0,0,0,0.1)` in light mode and `rgba(255,255,255,0.1)` in dark mode — and nothing else.** Never slate, zinc, neutral-gray, or any tinted near-black. Never the brand/accent color. Never a "warm gray to match the page."

The reason is concrete: **a tinted outline picks up a color the image's own edge pixels don't share, and reads as a dirty rim — like grime or a misprint around the photo.** Pure black at 10% alpha simply darkens whatever edge pixels are already there, which the eye accepts as a shadow/crease; pure white at 10% lightens them, accepted as a highlight. Any *hue* in that line is a color that doesn't belong to the image, and the eye catches it instantly as contamination. This holds even when the rest of your UI is tinted — the image outline stays achromatic regardless of surrounding palette. (Contrast this with elevation *shadows*, which you tint *toward* the surface hue — different job, different surface relationship. The shadow falls on the page and should match the page; the outline sits on the image and must not introduce a hue the image lacks.)

## Optical alignment

**The eye, not the ruler, is the judge** (Anthony Hobday). Geometric centering and equal numeric padding are *starting points*; when a shape is visually lopsided, mathematically "correct" looks wrong. Trust what you see and nudge until it sits right, even when the numbers go uneven. The fixes below are the recurring cases.

### Buttons with text and a trailing/leading icon

An icon next to a text label has visual weight concentrated differently than a glyph run, and the optical gap on the icon side looks larger than an equal numeric gap on the text side. **Make the icon-side padding about `2px` less than the text-side padding** so the two sides *look* balanced.

```css
/* Trailing icon: text on the left, icon on the right → trim the right padding */
.button {
  padding-left: 16px;
  padding-right: 14px;   /* 16 − 2 */
}
```

```html
<!-- Tailwind: pl-4 (16px) / pr-3.5 (14px) -->
<button class="pl-4 pr-3.5 …">Continue <ArrowIcon /></button>
```

Flip it for a leading icon (icon left, text right): trim the *left* padding to `14px` instead. The rule is "less padding on the icon side," not "less on the right."

### Play triangles

A right-pointing play triangle has its mass toward the flat left edge and tapers to a point on the right, so its *geometric* center sits left of its *visual* center. Centered by the box, it looks shoved to the left — most visible inside a circular play button. **Nudge it `2px` right** (`margin-left: 2px`, or `transform: translateX(2px)`) to move the geometric center onto the visual center.

```css
.play-button svg { margin-left: 2px; }   /* push the triangle to its optical center */
```

```html
<!-- Tailwind -->
<button class="play-button"><PlayIcon class="ml-0.5" /></button>   <!-- ml-0.5 = 2px -->
```

### Asymmetric glyphs (arrows, carets, chevrons, stars)

Many icons are drawn with uneven whitespace inside their own viewBox — an arrow with more empty space on one side, a star whose points don't center its visual mass. They look misaligned no matter how perfectly you center the box.

**The correct fix is to edit the SVG itself** — adjust the `viewBox` or shift the `path` so the glyph's visual center coincides with the box center. Do this once in the asset and every usage is fixed for free, at every size, with no layout hacks. **A 1px CSS nudge is the fallback** for when you can't touch the asset (third-party icon set, sprite you don't own) — it's a patch, not the fix, and it has to be re-tuned per size.

## Minimum hit area

Every interactive control needs a touch/click target of at least **44×44px** (the WCAG 2.5.5 *Target Size (Enhanced)* figure, and Apple HIG's minimum) — **≥40×40px** is an acceptable floor in dense desktop UI (close to WCAG 2.5.8's 24px AA minimum but far more comfortable). This is about the *hit area*, not the *visible size*. A 16px icon button, a 20px checkbox, a small close "×" — all are visually fine and all have hit areas far too small for a thumb.

**When the visible control is smaller than the minimum, extend the target with a pseudo-element** instead of bloating the visible box. Put the control in `position: relative`, then lay an invisible, centered `::after` over it sized to 40–44px:

```css
.icon-button {
  position: relative;
  /* visible size stays small, e.g. a 24px icon */
}
.icon-button::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  width: 44px;
  height: 44px;
  transform: translate(-50%, -50%);   /* center the hit area on the control */
  /* invisible: no background; it only catches pointer events */
}
```

```html
<!-- Tailwind: relative host + centered, sized pseudo-element -->
<button class="relative after:absolute after:left-1/2 after:top-1/2
               after:size-11 after:-translate-x-1/2 after:-translate-y-1/2">
  <Icon />
</button>
<!-- after:size-11 = 44px; use after:size-10 (40px) for the dense-UI floor -->
```

The pseudo-element catches the pointer because it overlays the control inside the same relatively-positioned box. The icon stays 24px; the tap target is 44px.

**Two interactive elements must never have overlapping hit areas.** If extending one control's `::after` would make it collide with an adjacent control's target, a tap in the overlap is ambiguous — the user can't reliably hit what they aim at. **Shrink the pseudo-element just enough to clear the neighbor, but keep it as large as it can be** without overlapping. Closely-spaced icons (a toolbar of 24px buttons with 8px gaps) may only allow a 32px target each — take the largest non-overlapping size rather than forcing 44px and creating ambiguity. (This pairs with the hover/active/focus targets in [interaction-states.md](interaction-states.md) — the hit area and the visible affordance are designed together.)

## Borders — when they ARE right

Shadows get the glory, but borders are correct more often than the depth-everything instinct suggests. Reach for a real `border` (or `outline` for inputs that need a layout-neutral ring) in exactly these cases:

- **Dividers and hairlines** — a 1px rule between sections that sit on the same plane.
- **Table cell separation** — gridlines in dense tabular data, where a shadow's blur would smear into neighboring cells.
- **Form input outlines** — borders are reliably perceivable by assistive tech and survive forced-colors / high-contrast modes, where shadows are dropped (see [accessibility.md](accessibility.md)). An input's edge should be a border, not a shadow.
- **Dense data** — lists, grids, and tables where you need many fine separators and shadow blur would muddy the layout.

**Color the border to a near-neutral that contrasts with *both* the container and the background** (Anthony Hobday). A border the same value as the surface it's on disappears; one too dark turns into a harsh frame. Aim for a low-contrast gray that's distinct from the fill on one side and the page on the other — visible but quiet.

**But prefer fewer borders overall.** Every border is a line the eye has to process; a page full of boxed-in regions feels busy and heavy. Separate with **spacing and background-color** first, then a shadow if the element is genuinely elevated, and reach for a border only when those don't fit the job (dividers, cells, inputs, dense data). The full "fewer borders" argument and the spacing-first hierarchy live in [layout-and-color.md](layout-and-color.md) — defer to it for the broader call.
