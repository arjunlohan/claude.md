# Sources & credits

The defaults in this skill are distilled from the people and teams who set the bar for interface craft. Where this skill commits to a number, it's an opinionated synthesis of the sources below — not a quote from any one of them. **Finesse is not affiliated with or endorsed by anyone listed here.** Go read the primaries; they're better than any summary.

## Interaction & motion craft

- **Rauno Freiberg** — *Web Interface Guidelines*, the code-level interaction playbook (animation ≤200ms feels immediate, hover only on `@media (hover: hover)`, open menus on `mousedown`, focus rings via `box-shadow` not `outline`, optimistic-update-and-rollback, inline feedback over toasts, inputs ≥16px). Staff Design Engineer at Vercel; author of **cmdk**.
  - https://interfaces.rauno.me/ · https://github.com/raunofreiberg/interfaces · https://rauno.me/craft/interaction-design
- **Emil Kowalski** — essays + courses on web animation; author of **Sonner** (toast) and **Vaul** (drawer). Keep UI animation <300ms; `ease-out` to enter; custom curves over weak keywords; make animations interruptible (transitions, not keyframes); never animate from `scale(0)`; "the best animation is no animation"; respect reduced motion. Vaul's iOS curve `cubic-bezier(0.32, 0.72, 0, 1)`.
  - https://emilkowal.ski/ui/great-animations · https://animations.dev/ · https://github.com/emilkowalski/sonner · https://github.com/emilkowalski/vaul
- **Apple — Human Interface Guidelines: Motion** + *Designing Fluid Interfaces* (WWDC 2018). Motion must be purposeful, quick, physically plausible, and spatially continuous; fluid motion is responsive, interruptible, and redirectable; drive it with springs (damping + response), not fixed durations; respect Reduce Motion by substituting crossfades.
  - https://developer.apple.com/design/human-interface-guidelines/motion · https://developer.apple.com/videos/play/wwdc2018/803/
- **Material Design — Motion** (Google). The duration/easing token system this skill's scale echoes: entering elements decelerate, exiting elements accelerate; durations scale with distance and surface size; ~300ms canonical default; pair emphasized easing with longer durations.
  - https://m3.material.io/styles/motion/easing-and-duration · https://github.com/material-components/material-components-android/blob/master/docs/theming/Motion.md
- **Josh Comeau** — interactive articles on CSS transitions, keyframes, spring physics, and reduced motion. Animate on actions not states; `ease-out` in / `ease-in` out; design shadows with one light source, layered and tinted; opt motion in via `no-preference` and substitute rather than delete.
  - https://www.joshwcomeau.com/animation/css-transitions/ · https://www.joshwcomeau.com/css/designing-shadows/ · https://www.joshwcomeau.com/react/prefers-reduced-motion/
- **Pasquale D'Silva** — *Transitional Interfaces*. Animation is functional, not decorative; hard cuts are unnatural; use time to stitch space together and preserve the user's mental map.
  - https://medium.com/@pasql/transitional-interfaces-926eb80d64e3
- **Val Head** — *Designing Interface Animation* (Rosenfeld). UI durations ~200–500ms scaled to motion size; the Disney principles that matter for UI (timing, follow-through, anticipation); "getting it to feel right matters more than the exact numbers."
  - https://valhead.com/ · https://rosenfeldmedia.com/books/designing-interface-animation/
- **Cassie Evans** — accessible SVG/GSAP motion. Reduced motion ≠ no motion (tailor it, don't use a sledgehammer); animation must serve a purpose and respect focus; use FLIP for performant layout animation.
  - https://css-tricks.com/empathetic-animation/

## Performance

- **web.dev / Chrome** — the rendering pipeline (Style → Layout → Paint → Composite), why only `transform`/`opacity` are cheap (compositor thread runs independently of main), the `top/left` ~50%-dropped-frames vs `transform` ~1% stat, `will-change` only within ~200ms, and the **RAIL** budget (Response ≤100ms, Animation 10ms/frame).
  - https://web.dev/articles/animations-guide · https://web.dev/articles/animations-and-performance · https://web.dev/articles/rail
- **Paul Lewis** — the **FLIP** technique (First, Last, Invert, Play): front-load measurement into the ~100ms window, then animate only `transform`.
  - https://aerotwist.com/blog/flip-your-animations/
- **Stripe (Benjamin De Cock)** — animate only cheap properties; climb the tool ladder CSS → CSS animations → WAAPI → `requestAnimationFrame`; anticipatory, "invisible" field transitions.
  - https://stripe.com/blog/connect-front-end-experience
- **Simon Hearne** — optimistic-UI patterns (render the expected result immediately, reconcile/roll back).
  - https://simonhearne.com/2021/optimistic-ui-patterns/

## Systems, type, color & visual rules

- **Vercel — Geist** + *Web Interface Guidelines*. Functional 10-step color scales mapped to role; semantic type scale; radius + shadow-elevation tokens; "only animate when it clarifies cause & effect," cancelable by input; loading show-delay (~150–300ms) + minimum visible time (~300–500ms).
  - https://vercel.com/geist/introduction · https://vercel.com/design/guidelines
- **Refactoring UI (Adam Wathan & Steve Schoger)** — hierarchy via weight & color, spacing signals grouping, near-black/near-white, saturate neutrals, many shades, two-part tinted shadows, design empty states, fewer borders, measure 45–75ch.
  - https://www.refactoringui.com/
- **Anthony Hobday** — *Visual design rules you can safely follow every time* (optical over mathematical alignment, drop-shadow blur ≈ 2× distance, body text ≥16px, line length ~70, button horizontal padding ≈ 2× vertical, don't use shadows in dark UI, don't mix depth techniques).
  - https://anthonyhobday.com/sideprojects/saferules/

## Lineage — the skill that started the conversation

- **Jakub Krehel — *make-interfaces-feel-better*** and the article *Details that make interfaces feel better*. Finesse is an independent, original work — not a fork — but it owes the framing (and the progressive-disclosure skill packaging) to this prototype, which it deliberately extends with a motion-token system, accessibility, interaction states, performance, and modern platform primitives.
  - https://github.com/jakubkrehel/make-interfaces-feel-better · https://jakub.kr/writing/details-that-make-interfaces-feel-better

## Worth studying for "feel" (people & products)

Interface feel is best learned by using meticulously crafted software and reading its makers. A non-exhaustive, fact-checked list:

- **Linear** — the modern bar for B2B craft: local-first sync engine, optimistic/instant UI, keyboard-first, "craft and taste" as an explicit value. Karri Saarinen (co-founder/designer, co-created Airbnb's DLS), Tuomas Artman (sync engine), Nan Yu ("speed and quality are positively correlated"). https://linear.app/method
- **Family** (crypto wallet) — **Benji Taylor**'s essay *Family Values*: the "tray" system, shared-letter text morphing, directional tab transitions, and the Delight–Impact curve (put the showiest delight in rarely-used surfaces). https://benji.org/family-values
- **The Browser Company / Arc** — making software "feel alive"; kinematics and an "imperceptible bounce" as tactile confirmation; inspiration drawn from film and games, not other software.
- **Loren Brichter** — invented pull-to-refresh and swipe-to-action on table cells (Tweetie); obsessive scroll smoothness.
- **Flighty** — Apple-cited "astonishing animations and delightfully deployed haptics"; best-in-class Live Activities / Dynamic Island.
- **Halide** (Sebastiaan de With) — "we made a camera, not an app": gesture/dial controls tuned for muscle memory, a single sparing highlight color.
- **Apollo** (Christian Selig) — customizable swipe gestures + Taptic-Engine haptics; a faithfully native feel.
- **Things** (Cultured Code) — the "Magic Plus" button with its liquid, drag-to-place interaction; an Apple Design Award benchmark for transition craft.
- **Airbnb — Lottie** — open-sourced designer-authored animation (After Effects → JSON) rendered natively across platforms; the reason high-fidelity motion got cheap to ship.

*Attribution notes (verified during research): `vaul`/`sonner` are Emil Kowalski's, not Rauno's (Rauno's is `cmdk`); Family is Benji Taylor's; these corrections matter — cite accurately.*
