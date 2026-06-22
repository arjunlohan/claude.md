# Typography

Type is most of the UI. Get these defaults right and prose reads effortlessly, numbers stop twitching, and hierarchy reads at a glance without a single decorative flourish. Everything here is a committed default — set it, then trust your eyes. Framework-agnostic CSS first, Tailwind variants after. See [SKILL.md](SKILL.md) items 16–17 for the one-line versions; this file is the depth.

Cross-references: text color hierarchy is shared with [layout-and-color.md](layout-and-color.md); contrast ratios and the ≥16px floor are enforced in [accessibility.md](accessibility.md); type sitting on cards/elevated surfaces interacts with [surfaces.md](surfaces.md).

## Text wrapping

Two properties, two jobs. Ragged line lengths and orphaned last words are an instant amateur tell; these fix both for free, with no JS and no manual `<br>`.

- **Headings → `text-wrap: balance`.** Equalizes line lengths across a multi-line heading and pulls up lone trailing words (orphans), so a two-line title splits ~50/50 instead of nine words on line one and one word on line two.
- **Body → `text-wrap: pretty`.** Leaves normal greedy wrapping intact but reworks the *last few lines* to prevent a stubby single-word final line. Cheap enough to apply to all running prose.

```css
h1, h2, h3 {
  text-wrap: balance;
}

p, li, figcaption, blockquote {
  text-wrap: pretty;
}
```

```html
<!-- Tailwind -->
<h1 class="text-balance">A headline that splits evenly across its lines</h1>
<p class="text-pretty">Body copy whose last line will never be a single orphaned word.</p>
```

**GOTCHA — `balance` silently dies on long text.** The balancing algorithm is expensive (the browser re-flows the block searching for an even split), so browsers cap it by line count: **≤6 wrapped lines in Chromium, ≤10 in Firefox.** Past the cap the declaration is *silently ignored* — no warning, no partial effect, it just wraps greedily. So `balance` is a heading tool, not a paragraph tool. For any block that runs 10+ lines, skip both: `balance` won't fire, and `pretty` buys little on a long block. Reserve `pretty` for short-to-medium body paragraphs where a stubby last line is actually visible.

| Element | Property | Tailwind | Why | Skip when |
| --- | --- | --- | --- | --- |
| `h1`–`h3`, short titles, card headers | `text-wrap: balance` | `text-balance` | Even line lengths, no orphan | Heading wraps to >6 lines (won't apply) |
| `p`, `li`, `blockquote`, `figcaption` | `text-wrap: pretty` | `text-pretty` | No stubby last line | Block runs 10+ lines (negligible payoff) |
| Long-form article body, log output, code | *(neither)* | — | Greedy wrapping is fine and cheapest | — |

## Font smoothing

Apply this **once at the root and never again.**

```css
html {
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-rendering: optimizeLegibility;
}
```

```html
<!-- Tailwind: put `antialiased` on the html (or body) element, once -->
<html class="antialiased">
```

**Why.** macOS renders text *heavier* than the designer intended by default (subpixel antialiasing fattens stems). `-webkit-font-smoothing: antialiased` switches it to grayscale antialiasing, which renders crisper and slightly thinner — closer to how the type was drawn. `-moz-osx-font-smoothing: grayscale` is the Firefox-on-macOS equivalent. `text-rendering: optimizeLegibility` turns on kerning and standard ligatures.

**Root only — never per-element.** Setting font-smoothing on individual components makes the *same typeface* render at visibly different apparent weights depending on which rule won, so a button label looks thinner than the heading above it. Declare it once at `:root`/`html` and let it inherit. Non-macOS platforms ignore these properties entirely, so applying them universally is safe — there's no downside on Windows, Linux, iOS, or Android, and the macOS win is real.

## Tabular numbers

`font-variant-numeric: tabular-nums` forces every digit to occupy the **same width**, so a number that changes in place no longer shifts the layout around it. By default most fonts ship *proportional* digits (a `1` is narrower than a `0`), which is fine for prose but causes visible jitter when the value updates.

```css
.timer, .price, .stat-value, .counter {
  font-variant-numeric: tabular-nums;
}
```

```html
<!-- Tailwind -->
<span class="tabular-nums">12:04</span>
<td class="tabular-nums text-right">$1,240.00</td>
```

**Use it for any number that CHANGES in place or sits in a column:**

| Use tabular-nums | Keep proportional (default) |
| --- | --- |
| Timers, countdowns, stopwatches | Static numbers in prose ("we shipped 3 features") |
| Live counters, view/like counts ticking up | Decorative or display numerals in a hero |
| Prices that update (cart totals, tickers) | Phone numbers |
| Stat columns, dashboards, leaderboards, scoreboards | Zip / postal codes |
| Any table column of figures | Version numbers (`v2.1.0`) |

The rule: **does this number mutate while on screen, or align vertically against other numbers?** If yes, tabular. If it's set once and just sits there as part of a sentence, leave it proportional — tabular digits in running prose look slightly mechanical.

**GOTCHA — Inter's `1`.** In Inter, enabling `tabular-nums` widens and re-centers the digit `1` (it grows serif-like flat feet to fill the now-wider slot). This is *expected* behavior, not a bug — but glance at the result, because in a short fixed string like a version badge or a single price the new `1` can look subtly off. Verify it reads right in context before shipping.

**Two alignment rules that travel with numbers:**
- **Right-align columns of numbers** (`text-align: right` / `text-right`). The ones, tens, hundreds line up vertically and become scannable; combined with tabular-nums the column is a clean grid. Left-aligned number columns are nearly unreadable.
- **Baseline-align mixed-size numerals.** When a big figure sits next to a smaller unit or cents (`$<big>24</big><small>.99</small>`), align them on the baseline, not the center, so they sit on a common line like real typography.

## Hierarchy via weight and color, not size alone

Amateur hierarchy cranks font-size for every level until the page is a ransom note. Strong hierarchy leans on **weight and color** and changes size sparingly. (Refactoring UI; Rauno Freiberg.)

**Weight scale:**

| Role | Weight | Notes |
| --- | --- | --- |
| Body / default UI text | 400–500 | 500 reads slightly crisper for dense UI |
| Emphasis, labels, buttons, active nav | 600–700 | The jump that signals "this matters" |
| Headings | 500–600 | Medium weights read best for most headings; reserve 700+ for true display |
| **Never** | <400 | Thin/light weights are illegible for UI at body sizes — banned |

**Three text colors — and never pure black.** Establish exactly three foreground colors and assign by importance (this hierarchy is shared with [layout-and-color.md](layout-and-color.md)):

| Tier | Use | Color |
| --- | --- | --- |
| Primary | Headings, body, the thing you read | Near-black (e.g. `#18181b`), **not** `#000` |
| Secondary | Supporting text, labels, captions | Medium grey |
| Tertiary | Metadata, placeholders, disabled, timestamps | Lighter grey |

Pure `#000` on white is harsher than anything in the physical world and vibrates against the background; a near-black reads softer and more intentional. Confirm each tier still clears the contrast floor in [accessibility.md](accessibility.md) — tertiary grey is where contrast quietly fails.

**De-emphasize as much as you emphasize.** Hierarchy is relative. Rather than only making the important thing louder (bigger, bolder, darker), make the *unimportant* thing quieter (smaller, lighter, lower-contrast). Pushing secondary content down is usually cleaner than pushing primary content up, and it keeps the overall size scale tight.

**NEVER change `font-weight` on hover/active/selected.** Bolder text is wider text, so swapping weight on interaction nudges everything after it — the row reflows and the layout jumps every time the pointer moves. (Rauno Freiberg.) Signal state with color, background, or a weight-stable indicator instead.

```css
/* WRONG — text gets wider on hover, layout shifts */
.nav-link:hover { font-weight: 700; }

/* RIGHT — color change, zero reflow */
.nav-link { color: var(--text-secondary); }
.nav-link:hover { color: var(--text-primary); }

/* If bold-on-active is truly required, reserve the space so it can't shift:
   render an invisible bold copy to fix the width. */
.tab::after {
  content: attr(data-label);
  font-weight: 700;
  height: 0;
  visibility: hidden;
  pointer-events: none;
}
```

## Measure (line length)

The **measure** is the number of characters per line. Comfortable reading lives at **45–75 characters, ~66 ideal** (Anthony Hobday puts the sweet spot around ~70). Too long and the eye loses the start of the next line on the return sweep; too short and the rhythm breaks every few words.

```css
.prose, article p {
  max-width: 65ch; /* ch = width of "0"; tracks the measure as font-size changes */
}
```

```html
<!-- Tailwind: max-w-prose ≈ 65ch, or set it explicitly -->
<article class="max-w-prose">…</article>
<article class="max-w-[65ch]">…</article>
```

`ch` units are the right tool here — `1ch` is the advance width of `0`, so `65ch` stays close to ~65 characters even as the font or size changes, where a fixed `px` width drifts.

**Two prohibitions for long-form text:**
- **Don't center long-form text.** Centered paragraphs give every line a different left edge, so the return sweep has no fixed target and reading slows. Center headings and short callouts only; left-align body.
- **Don't justify on the web.** CSS justification has no hyphenation or fine spacing control by default, so it opens "rivers" of white space through the paragraph. Ragged-right is more even and more readable. (If you must justify, pair it with `hyphens: auto`.)

## Line height

Line height (leading) is **inversely proportional to font size.** Small text needs more leading to separate the lines; large text needs less or the lines drift apart and stop reading as a unit.

| Text size | `line-height` | Roughly |
| --- | --- | --- |
| Body, small UI text | 1.5 | 130–150% |
| Subheads / mid-size | 1.3–1.4 | — |
| Large headings, display | 1.1–1.25 | Tighter as it grows |

```css
body { font-size: 1rem; line-height: 1.5; }
h1   { font-size: clamp(2rem, 5vw, 4.5rem); line-height: 1.1; }
```

**Lower BOTH letter-spacing and line-height as text grows; raise both as text shrinks.** (Anthony Hobday.) Big type set at default tracking and leading looks loose and unfinished; tightening both pulls a headline into a solid shape. Small type set tight gets cramped and illegible; loosening both opens it up.

**Leave letter-spacing alone otherwise.** At body sizes the typeface's designed spacing is already correct — don't touch `letter-spacing` for ordinary text. The only routine exceptions:
- **Large headlines** — a slightly negative tracking (e.g. `-0.02em`) tightens display type.
- **All-caps / small eyebrow labels** — uppercase runs need *positive* tracking (e.g. `0.05em`) to breathe, since caps were never spaced for setting in runs.

```css
h1            { letter-spacing: -0.02em; }
.eyebrow      { text-transform: uppercase; letter-spacing: 0.05em; font-size: 0.75rem; }
```

## Sizing

**Body text ≥16px. Form inputs ≥16px — this one is non-negotiable.** Any `font-size` below 16px on a focusable `<input>`, `<select>`, or `<textarea>` makes **iOS Safari auto-zoom** the page on focus, yanking the layout around the field. (Rauno Freiberg.) The fix is simply never to go under 16px on inputs.

```css
body { font-size: 16px; }          /* floor for readable body text */
input, select, textarea {
  font-size: 16px;                 /* below this, iOS zooms on focus */
}
```

```html
<!-- Tailwind: text-base is 16px; never drop inputs below it -->
<input class="text-base" />
```

The 16px floor is also an accessibility baseline — see [accessibility.md](accessibility.md). Smaller is acceptable only for genuinely secondary metadata (captions, legal), never for primary reading or any input.

**Fluid sizing with `clamp()`** lets large type scale with the viewport between a floor and a ceiling, with no breakpoints (Rauno Freiberg):

```css
/* clamp(MIN, PREFERRED, MAX): never smaller than 2rem, never larger than 4.5rem,
   tracks 5vw in between */
.hero-title { font-size: clamp(2rem, 5vw, 4.5rem); }
```

```html
<!-- Tailwind arbitrary value -->
<h1 class="text-[clamp(2rem,5vw,4.5rem)]">…</h1>
```

Reserve `clamp()` for headings and hero/display type where the size genuinely should respond to viewport width. Body text wants a *fixed*, predictable size (≥16px) — fluid body text fights the reader and can dip under the floor on small screens.

## Font choices

- **At most two typefaces.** One is often enough — separate roles with weight, size, and color before reaching for a second family. A third typeface almost always reads as noise. (Refactoring UI; Anthony Hobday.)
- **Pick families with 5+ weights.** Hierarchy is built primarily on weight (see above), so a typeface needs room — at minimum a regular (400), a medium (500), and a bold (600/700), with more headroom welcome. A two-weight family boxes you in and forces you back onto size for every distinction. Superfamilies (e.g. Inter, with a paired mono) also let the two-typeface budget cover body, display, and code coherently.
- **Pair by contrast, not similarity.** If you do use two, make them clearly different (e.g. a serif display over a sans body) so the pairing reads as intentional rather than a near-miss.
