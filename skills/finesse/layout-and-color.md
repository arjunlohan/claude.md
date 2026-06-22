# Layout & color

The two systems that decide whether an interface reads as *structured* or as *noise* before a single pixel of polish lands. Spacing and color do the work that borders and decoration get blamed for. Get them systematic and the rest of [SKILL.md](SKILL.md) has something solid to sit on. Depth, shadow, and optical-alignment detail live in [surfaces.md](surfaces.md); text colors in [typography.md](typography.md); contrast math in [accessibility.md](accessibility.md) — this file points to them rather than repeating them.

---

## Layout & spacing

### Whitespace is removed, not added

Start with **too much** space, then tighten until it feels right. Designs that feel cramped are the default failure mode of someone adding space reluctantly; designs that feel generous come from someone who started loose and pulled in. Give every element room to breathe first, then close the gaps that are clearly too wide. This is the opposite of the instinct to fill space — and that instinct is the bug.

**Don't feel obligated to fill the width.** A form does not become better by stretching its fields to 1400px. Content has a natural size; honor it with `max-width` and let the viewport be larger than the content. Centering a 640px column in a 1440px window is not wasted space — it's a reading measure (see [typography.md](typography.md) for the `ch`-based version).

```css
/* Constrain content; let the page be wider than the column. */
.prose      { max-width: 65ch;  margin-inline: auto; }
.form       { max-width: 28rem; }   /* ~448px — a form is not a billboard */
.dashboard  { max-width: 80rem;  margin-inline: auto; padding-inline: 1.5rem; }
```

```html
<!-- Tailwind -->
<article class="max-w-prose mx-auto">…</article>
<div class="max-w-md">…</div>            <!-- form -->
<div class="max-w-7xl mx-auto px-6">…</div> <!-- dashboard -->
```

### Spacing signals grouping

Space is the cheapest structural device you have — cheaper than borders, cheaper than boxes. **More space *between* groups, less space *within* them.** Elements that sit closer together read as more related; elements pushed apart read as separate. This single relationship conveys hierarchy without a single line drawn.

Anthony Hobday's rule: **spacing goes between points of high contrast.** The gap belongs at the seam between two groups, not scattered evenly through both. The classic tell of an amateur layout is a label sitting equidistant between its *own* input above and the *next* field's input below — so it's ambiguous which it belongs to. Pull the label toward its input.

```css
/* WRONG — uniform gap, no grouping. Label floats between two fields. */
.field > * { margin-block: 12px; }

/* RIGHT — tight within a field, loose between fields. */
.field            { display: grid; gap: 6px; }   /* label ↔ input: related */
.field + .field   { margin-top: 24px; }           /* field ↔ field: separate */
```

| Relationship | Spacing | Reads as |
| --- | --- | --- |
| Label → its input | `4–8px` (tight) | One unit |
| Input → its helper text | `4–8px` (tight) | One unit |
| Field → next field | `20–32px` (loose) | Distinct items |
| Section → next section | `48–96px` (very loose) | Distinct regions |

If two groups feel like one, you have too little space between them or too much within them. Fix the ratio before reaching for a divider.

### A constrained spacing scale

Define the scale **upfront**, on a `4px` or `8px` base, with **non-linear** steps. Linear scales (4, 8, 12, 16, 20, 24, 28…) give you adjacent values too close to distinguish; you waste decisions agonizing between `20px` and `24px` that no user will ever perceive. Geometric-ish growth gives each step a *job*.

```css
:root {
  --space-1:  4px;
  --space-2:  8px;
  --space-3: 12px;
  --space-4: 16px;
  --space-5: 24px;   /* note the jump — no 20px */
  --space-6: 32px;
  --space-7: 48px;
  --space-8: 64px;
  --space-9: 96px;
}
```

Two rules keep the scale honest:

1. **No two values within ~25% of each other.** `24` then `32` is a 33% jump — fine. `24` then `28` is 17% — drop one. If two steps are nearly the same, you don't have a scale, you have indecision.
2. **Measurements should be mathematically related** (Anthony Hobday). Every value is a clean multiple of the base. `8 / 16 / 24 / 32` relate; `8 / 15 / 23 / 30` are noise. Arbitrary numbers (`13px`, `17px`, `7px`) are the spacing equivalent of hand-picked animation durations — the single biggest tell that nothing was systematized.

Tailwind ships this for you: its default scale (`p-1`=4px, `p-2`=8px, `p-4`=16px, `p-6`=24px…) is already 4px-based and non-linear at the top. Use the tokens; don't reach for arbitrary `p-[13px]` values — that defeats the system.

### Alignment

**Everything aligns to something else.** A free-floating element with no shared edge or center is the visual equivalent of a typo. Pick edges and commit.

- **Use a grid for horizontal layout.** If you lay things out across the page, use a **12-column grid** — 12 divides into halves, thirds, quarters, and sixths, so it absorbs almost any column count. Snap content to grid lines, not eyeballed pixels.
- **Outer padding ≥ inner padding.** The space *around* a container must be at least the space *between* its children, or the group bleeds into its surroundings and stops reading as a unit. A card with `16px` gaps between rows needs **≥16px** of its own padding.
- **Button horizontal padding ≈ 2× vertical** (Anthony Hobday). A button reads as a button when it's wider than it is tall around the label: `padding: 8px 16px`, `10px 20px`, `12px 24px`. Equal padding makes a cramped square; this ratio makes a control.

```css
.card   { padding: var(--space-4); display: grid; gap: var(--space-4); } /* outer ≥ inner */
.button { padding: var(--space-2) var(--space-4); }                      /* 8px / 16px = 2× */
```

```html
<!-- Tailwind -->
<div class="grid grid-cols-12 gap-6">…</div>
<button class="px-4 py-2">…</button>   <!-- px = 2 × py -->
```

**Optical alignment beats mathematical alignment.** The eye, not the pixel ruler, is the judge — a centered triangle, an arrow glyph, or an icon beside a label often needs a 1–2px nudge to *look* centered even when it measures off. That detail (icon-side padding, play-triangle nudge, asymmetric-glyph fixes) lives in [surfaces.md](surfaces.md).

### No dead zones in lists

In a vertical or horizontal list of **interactive** items, there must be **no inert gaps** between them. A 12px `margin` between two menu rows is 12px where the cursor is over *nothing* — the click does nothing, the hover highlight flickers off, and a fast user misses. It feels broken even though nothing is "wrong" (Rauno).

The fix is to **grow each item's `padding`, not the space between them.** Every pixel between adjacent items belongs to one of them and is therefore clickable. The visual rhythm is identical; the hit behavior is continuous.

```css
/* WRONG — 8px dead gap between every row; hovers flicker, clicks miss. */
.menu-item { padding: 8px 12px; }
.menu-item + .menu-item { margin-top: 8px; }

/* RIGHT — no gap; the breathing room lives inside each row's padding. */
.menu-item { padding: 12px; }     /* taller rows, zero dead space */
```

```html
<!-- Tailwind: no space-y between interactive rows; pad the rows instead -->
<nav class="flex flex-col">
  <a class="px-3 py-3 hover:bg-neutral-100" href="#">Item</a>
  <a class="px-3 py-3 hover:bg-neutral-100" href="#">Item</a>
</nav>
```

This applies to menus, tabs, list rows, segmented controls, sidebars — anything where adjacent targets are clickable. Reserve `gap`/`margin` between items for *non-interactive* lists (paragraphs, cards with their own clear boundaries) where a miss costs nothing.

---

## Color

### Near-black and near-white, never pure

Pure `#000` and pure `#FFF` are harsh. Pure black text on a pure white background vibrates — the contrast is *higher* than real-world ink on paper ever is, and it reads as cheap. Use a **near-black** for text and a **near-white** for backgrounds (Anthony Hobday; Refactoring UI).

```css
:root {
  --bg:   hsl(40, 12%, 98%);   /* warm near-white, not #fff */
  --text: hsl(220, 18%, 12%);  /* near-black with a cool cast, not #000 */
}
```

Note these aren't grey — which is the next rule.

### Saturate your neutrals

Pure grey (`hsl(0, 0%, X%)`) is lifeless. Real-world surfaces carry a temperature. Give every neutral a **hint of hue** — a few points of saturation — so the interface has an undertone instead of reading as a default stylesheet.

Pick **warm OR cool, not both.** A warm-grey background with cool-grey text looks like two different design systems collided. Commit to a temperature and run it through the whole neutral ramp. (Often the smart move is to tint neutrals toward your *primary* hue, so greys feel like part of the same family.)

```css
:root {
  /* Cool neutrals — a single hue (220) at low saturation, top to bottom. */
  --neutral-0:  hsl(220, 20%, 99%);
  --neutral-1:  hsl(220, 16%, 96%);
  --neutral-2:  hsl(220, 14%, 91%);
  --neutral-3:  hsl(220, 12%, 84%);
  --neutral-4:  hsl(220, 10%, 64%);
  --neutral-5:  hsl(220, 12%, 46%);
  --neutral-6:  hsl(220, 16%, 32%);
  --neutral-7:  hsl(220, 18%, 22%);
  --neutral-8:  hsl(220, 20%, 14%);
  --neutral-9:  hsl(220, 24%, 9%);
}
```

Don't rely on pure grey for personality — there is none in it.

### You need more shades than you think

A real palette is larger than beginners expect. Plan for:

| Role | How many | Notes |
| --- | --- | --- |
| Greys / neutrals | **8–10 shades** | The workhorse ramp — backgrounds through text |
| Primary hue(s) | **1–2 hues × 5–10 shades** | Your brand; needs a full ramp, not one value |
| Accent / semantic | **red, yellow, green, blue × 5–10** | Danger, warning, success, info — each a ramp |

**Author in HSL or OKLCH, never hand-tuned hex.** Hex hides the three things you actually manipulate — hue, saturation, lightness. In HSL you walk lightness down a column and keep hue fixed; in OKLCH, steps are **perceptually even**, so equal numeric jumps look like equal visual jumps (HSL lies about this — its mid-tones bunch up). Prefer OKLCH where browser support allows.

```css
:root {
  /* OKLCH: lightness% chroma hue — perceptually even steps */
  --blue-1: oklch(97% 0.02 250);
  --blue-5: oklch(62% 0.19 250);   /* mid — the "real" blue */
  --blue-9: oklch(28% 0.10 250);
}
```

**Boost saturation at the lightness extremes.** As a color approaches very light or very dark, perceived saturation drains out and the shade looks washed-out and grey. Compensate by **increasing saturation** at both ends of the ramp so the lightest and darkest steps still read as *colored*, not as dirty grey. (This is also why OKLCH's `chroma` often needs a hand-tuned bump at the top and bottom.)

### Functional color scales

Map color steps to a **role**, not a name — this is what makes theming and contrast systematic. Two references: **Radix Colors** (a 12-step functional scale) and **Vercel Geist** (a 10-step scale numbered 100–1000). Geist's role mapping:

| Steps | Role |
| --- | --- |
| 100–200 | App / subtle element backgrounds |
| 300 | Subtle borders, hover backgrounds |
| 400–600 | Borders and separators (interactive at the higher end) |
| 700–800 | Solid / high-contrast backgrounds (e.g. primary buttons) |
| 900 | Secondary (low-contrast) text |
| 1000 | Primary text and icons (highest contrast) |

Pick the step by the job, and switching light/dark themes becomes swapping the scale rather than rewriting every color.

```css
/* Reference the ROLE, not a literal lightness. */
.card        { background: var(--neutral-2); }
.card:hover  { background: var(--neutral-3); }
.card        { border: 1px solid var(--neutral-6); }
.text-strong { color: var(--neutral-9); }    /* primary text — highest contrast */
.text-muted  { color: var(--neutral-7); }    /* secondary text */
```

### Contrast & color-as-meaning

**Body text contrast ≥ 4.5:1** against its background (WCAG AA; large text ≥ 3:1). This is a hard floor, not a guideline — see [accessibility.md](accessibility.md) for the full contrast policy, the large-text exception, and tooling.

Two consequences that catch people:

- **Colored backgrounds usually have to be fairly dark to carry white text at 4.5:1.** A cheerful mid-blue button with white text often *fails*. Either darken the background (down the ramp) or rethink the text color. Test it; don't eyeball it.
- **Never put grey text on a colored background.** Grey is computed against a neutral, not your accent, so it muddies. Instead use **reduced-opacity white** (`rgba(255,255,255,0.7)`) — which picks up the background hue automatically — or a **hand-picked color of the same hue**, a few steps lighter on that hue's ramp.

```css
/* WRONG — grey text on a colored surface goes muddy. */
.alert--danger .subtext { color: hsl(220, 10%, 50%); }

/* RIGHT — same-hue, or translucent white that inherits the bg hue. */
.alert--danger          { background: oklch(45% 0.16 25); color: #fff; }
.alert--danger .subtext { color: rgba(255, 255, 255, 0.78); }
```

**Use accent colors semantically, and consistently:**

| Color | Meaning |
| --- | --- |
| Red | Danger / destructive / error |
| Yellow / amber | Warning / caution |
| Green | Success / confirmation |
| Blue | Info / neutral emphasis |

But **never convey state by color alone.** ~8% of men have some red-green color-vision deficiency; a red-vs-green status dot is invisible to them. Always pair color with a **second channel** — an icon, a label, a shape, a position. This is a hard accessibility rule, restated in [accessibility.md](accessibility.md), not a stylistic preference.

```html
<!-- Color + icon + text — three channels, not one. -->
<span class="status status--error">
  <svg aria-hidden="true">…✕…</svg> Failed
</span>
```

### Fewer borders

Borders are the reflex tool for separation and almost always the wrong one. Every border adds a hard line that fights the content for attention; a UI dense with `1px` rules looks like a spreadsheet. Before drawing a border, reach for a cheaper separator:

1. **Spacing** — a gap already groups and divides (see *Spacing signals grouping* above). Often no separator is needed at all.
2. **Background color** — a subtly different surface tint (a `--neutral-2` panel on a `--neutral-1` page) separates regions without a line.
3. **Shadow** — elevation implies a boundary. Shadow vs. border, layering, and tinting are covered in [surfaces.md](surfaces.md).

**In tables specifically: zebra-striping or whitespace beats gridlines.** Full gridlines (a border on every cell) create visual noise that buries the data. Alternating row backgrounds, or simply generous cell padding with a single rule under the header, guide the eye along rows far better.

```css
/* Quiet table — one header rule + zebra rows, no cell grid. */
.table th       { border-bottom: 1px solid var(--neutral-6); }
.table td       { padding: 12px 16px; }
.table tbody tr:nth-child(even) { background: var(--neutral-2); }
```

**When you *do* use a border, make it earn structure as an accent.** A colored border on **one edge** carries meaning cheaply and looks intentional rather than boxy:

- **Top** border on a card — a category color or status.
- **Left** border on an alert / blockquote — severity (red danger, amber warning).
- **Bottom** border on a tab — the active selection.

```css
.alert--warning { border-left: 3px solid var(--amber-7); }
.tab[aria-selected="true"] { border-bottom: 2px solid var(--blue-6); }
.card--featured { border-top: 3px solid var(--primary-6); }
```

```html
<!-- Tailwind: accent one edge, not all four -->
<div class="border-l-4 border-amber-500 pl-4">Warning…</div>
<div class="border-b-2 border-blue-600">Active tab</div>
```

A single accent edge adds hierarchy for almost nothing. A full four-sided `1px solid` border around everything adds noise for almost nothing. Know the difference.
