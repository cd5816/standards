#git diff --stat Design Guide — "Geist-flavored" Aesthetic

Instructions for building clean, beautiful, Vercel/Geist-inspired web UIs. Follow
these rules exactly. They are distilled from a real interface that the client
loved. When in doubt, prefer restraint: remove, don't add.

---

## 1. Core philosophy (read this first)

Five principles drive every decision below. If a choice conflicts with one of
these, the principle wins.

1. **Near-monochrome.** The UI is black, white, and grays. Color is reserved
   *strictly for meaning* (success, error, a single interactive accent). Never
   use color for decoration.
2. **Whitespace is the primary structure.** Space groups and separates content —
   not boxes, not background fills. Give elements room to breathe.
3. **Hairline dividers, not boxes.** When you must show structure, use a 1px
   ~8%-gray line, not a heavy border or a shadowed card. Related rows share a
   single container with internal hairlines rather than becoming separate cards.
4. **Tight, confident display type.** Headings are large, semibold (600, not
   800), with negative letter-spacing. Body text is calm and readable.
5. **Signal, not chrome.** Every visual element should communicate state or
   hierarchy. If it doesn't mean something, delete it.

---

## 2. Design tokens (copy these verbatim)

Define everything as CSS custom properties on `:root`. Never hardcode a color or
radius inline.

```css
:root {
  color-scheme: light;

  /* Neutrals — the entire palette is basically this */
  --bg: #fff;
  --fg: #171717;            /* near-black body text (NOT pure #000) */
  --fg-secondary: #666;     /* labels, help text, muted copy */
  --fg-tertiary: #8f8f8f;   /* placeholders, faint meta */
  --border: #ebebeb;        /* hairline — ~8% off white, the default divider */
  --border-strong: #d4d4d4; /* hover / emphasis hairline */
  --surface-subtle: #fafafa;/* the ONLY fill, for table headers etc. */

  /* Meaning-only color */
  --accent: #0072f5;        /* single interactive accent (focus, links) */
  --accent-hover: #0060df;
  --accent-wash: #f0f7ff;   /* focus ring background */
  --ok: #16a34a;            /* success only */
  --alert: #e5484d;         /* error/danger only */

  /* Geometry */
  --radius: 6px;            /* inputs, buttons */
  --radius-lg: 10px;        /* containers, cards */
  --page-width: 960px;      /* content column max width */

  /* Type */
  --font-sans: "Geist", Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  --font-mono: "Geist Mono", ui-monospace, SFMono-Regular, Menlo, monospace;
}
```

Rules:
- **Text is `--fg` (#171717), never pure black.** Pure black looks harsh.
- **Borders default to `--border` (#ebebeb).** They should be barely visible —
  felt, not seen. Only strengthen to `--border-strong` on hover.
- **`--surface-subtle` is the only background fill you're allowed.** Use it
  sparingly (e.g. table header rows). Everything else is `--bg` white.
- Content column caps at **960px**, centered with `margin-inline: auto`. This
  leaves natural room for a ~260px left nav later (960 + 260 ≈ 1220).

---

## 3. Typography

```css
html {
  font-family: var(--font-sans);
  font-size: 16px;
  line-height: 1.5;
  -webkit-font-smoothing: antialiased;
  text-rendering: optimizeLegibility;
}

h1 {
  font-size: clamp(1.9rem, 3.4vw, 2.5rem);
  font-weight: 600;                 /* semibold, never 700+ */
  letter-spacing: -0.04em;          /* signature tight display tracking */
  line-height: 1.1;
}
h2 { font-size: 1.25rem; font-weight: 600; letter-spacing: -0.02em; }

/* Wrapping polish */
h1, h2, h3 { text-wrap: balance; }
p, .help-text { text-wrap: pretty; }
```

Rules:
- **Display headings: weight 600, negative letter-spacing** (`-0.04em` for h1,
  `-0.02em` for h2). This tight tracking is the single most recognizable part of
  the look. Do not skip it.
- **Body 16px / line-height 1.5.** Secondary/help text drops to ~0.9rem in
  `--fg-secondary`.
- **Eyebrows / labels / meta: uppercase, ~0.72rem, weight 500, letter-spacing
  0.04em, in `--fg-secondary`.** Use these small caps for section kickers and
  table headers.
- **Use the mono font for machine-ish meta** (section numbers like `AUTO / 04`,
  codes). It adds a developer-tool texture without color.
- Always enable `-webkit-font-smoothing: antialiased` and `text-wrap: balance`
  on headings / `pretty` on paragraphs.

---

## 4. Layout & spacing

- Center all top-level regions in a shared column:
  ```css
  .site-header, .tabs, main, footer {
    width: min(100% - 48px, var(--page-width));
    margin-inline: auto;
  }
  ```
- **Separate sections with generous vertical space** (`margin-bottom: 48px`),
  not borders. Let whitespace do the grouping.
- Header: flex row, `align-items: flex-end`, title on the left, actions on the
  right, separated from body by ONE hairline bottom border.
- Section pattern: a mono eyebrow (`AUTO / 04`), then an `<h2>`, then optional
  secondary help text, then the content. No box around the whole section.

---

## 5. Structure: hairlines over boxes

This is the rule people get wrong most. **Do not turn every group into a
bordered/shadowed card.** Instead:

- When several rows belong together (a table, a repeatable list), wrap them in
  ONE container with `1px solid var(--border)` + `--radius-lg` + `overflow:
  hidden`, and divide the rows with internal `border-bottom: 1px solid
  var(--border)` (remove it on `:last-child`).
- Two related panels side by side share a single divider between them
  (`border-right: 1px solid var(--border)` on the first), inside one rounded
  container — **not** two separate cards with a gap.
- **No drop shadows.** Elevation is expressed with hairlines and whitespace, not
  shadow.
- Table/list header row: `--surface-subtle` background, uppercase 0.72rem labels
  in `--fg-secondary`.

---

## 6. Buttons (clear hierarchy, minimal color)

```css
.button {
  min-height: 36px; padding: 0 14px;
  border: 1px solid var(--fg);
  border-radius: var(--radius);
  font-size: 0.875rem; font-weight: 500;
  transition: background 120ms ease, border-color 120ms ease, color 120ms ease;
}
```

- **Primary = solid near-black** (`background: var(--fg)`, white text). Hover
  lightens to `#333`. This is the single loudest element on the page — use one
  per view.
- **Secondary / add / small = quiet outline** (white bg, `--border`, `--fg`
  text). Hover fills `--surface-subtle` and strengthens the border.
- **Danger = quiet by default.** Neutral outline + `--fg-secondary` text;
  ONLY reveals `--alert` color on hover. Destructive actions should whisper
  until intended, never shout in red.
- Note: the accent blue is for **focus and links**, not for primary buttons.
  Primary is black. This keeps the palette monochrome.

---

## 7. Form controls

```css
input, select, textarea {
  width: 100%;
  border: 1px solid var(--border);
  border-radius: var(--radius);
  background: var(--bg);
  transition: border-color 120ms ease, box-shadow 120ms ease;
}
input, select { min-height: 38px; padding: 8px 10px; }

input:hover, select:hover, textarea:hover { border-color: var(--border-strong); }
input:focus, select:focus, textarea:focus {
  outline: none;
  border-color: var(--accent);
  box-shadow: 0 0 0 3px var(--accent-wash);   /* soft accent focus ring */
}
input::placeholder { color: var(--fg-tertiary); }
```

- Field labels sit above inputs: block, `margin-bottom: 6px`, ~0.8rem, weight
  500, `--fg-secondary`. Sentence case for field labels (reserve UPPERCASE for
  eyebrows/table headers).
- **Focus = accent border + 3px accent-wash ring.** This is the one place accent
  color appears on inputs. Never remove focus visibility for a11y.
- **Always normalize `input[type="date"]`** (see gotchas section 10) — iOS Safari
  center-aligns and restyles it otherwise.

---

## 8. Navigation / tabs (underline style)

```css
.tabs { display: flex; align-items: center; gap: 4px;
        border-bottom: 1px solid var(--border); }
.tab  { min-height: 44px; padding: 0 14px; border: 0;
        border-bottom: 2px solid transparent;
        color: var(--fg-secondary); font-weight: 500; }
.tab.is-active { color: var(--fg); border-bottom-color: var(--fg); }
```

- Tabs are **underline-style**, not pills or filled backgrounds. Inactive =
  gray text; active = near-black text with a 2px near-black underline.
- The tab bar (and any persistent bar) is a good home for **status indicators**
  because it stays visible. Dock status to the right end with `margin-left: auto`.

---

## 9. State & status (the "signal, not chrome" rule in action)

- Represent save/sync state as a small **colored dot + short label**, driven by a
  `data-state` attribute — not a big banner:
  ```css
  .save-status[data-state="ok"]      { color: var(--ok); }
  .save-status[data-state="pending"] { color: var(--fg-secondary); }
  .save-status[data-state="alert"]   { color: var(--alert); }
  ```
- Success is green, error is red, idle/pending is gray. **These three colors are
  the ONLY non-accent colors in the whole UI**, and they only appear to convey
  state.
- Empty states: quiet `--fg-secondary` text, no loud illustration.
- Error banner: the one place a light color fill (`#fef2f2`) + `--alert` border
  is allowed, and only when there's an actual error.

---

## 10. Responsive & platform gotchas (hard-won — don't skip)

- **Mobile breakpoint ~860px:** stack the header vertically; collapse
  multi-column grids to `1fr` or `1fr 1fr`. Below ~520px go single column and
  make the tab/nav bar `position: sticky; top: 0`.
- **CSS Grid `1fr` = `minmax(auto, 1fr)`.** The `auto` minimum means a track
  can't shrink below its content's intrinsic width. If grid *items* are wrapper
  elements (e.g. a `<label>` around an input), set **`min-width: 0` on the grid
  ITEM**, not just the input — otherwise wide intrinsic controls (like
  `input[type=date]`) force the track wide and overflow/clip the container:
  ```css
  .row > * { min-width: 0; }
  ```
- **`input[type="date"]` on iOS Safari** applies its own user-agent styling:
  it center-aligns the value and ignores your padding/alignment. Normalize it:
  ```css
  input[type="date"] { -webkit-appearance: none; appearance: none; text-align: left; }
  ```
- **Chrome DevTools device mode != real iOS.** It uses Chrome's engine, so
  Safari/WebKit-specific bugs (date inputs, form control chrome) won't reproduce
  there. Verify anything WebKit-specific on a real iPhone.
- On mobile, hide table header rows and show per-field inline captions instead.

---

## 11. Motion

- Transitions are **short and subtle**: `120ms ease` on color/border/background.
- No bouncy, long, or attention-grabbing animation. Movement should feel instant
  and mechanical, not playful.

---

## 12. Print

- Provide a `@media print` block: hide interactive chrome (nav, buttons, status,
  banners), drop to ~11px, remove the max-width constraint, and show only the
  content worth putting on paper.

---

## Quick checklist before you ship

- [ ] Palette is grayscale + at most one accent; color only means something.
- [ ] Text is `--fg` (#171717), not pure black.
- [ ] Headings are weight 600 with negative letter-spacing.
- [ ] Structure comes from whitespace and hairlines — no drop shadows, no box-per-group.
- [ ] Exactly one solid (black) primary button per view; everything else outlined.
- [ ] Inputs have the accent focus ring; focus is never removed.
- [ ] `min-width: 0` on grid items; `input[type=date]` normalized.
- [ ] Verified on a real iPhone, not just DevTools.
- [ ] Transitions are 120ms and quiet.
