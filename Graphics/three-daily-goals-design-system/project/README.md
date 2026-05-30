# Three Daily Goals — Design System

> "The task manager that helps you let go"

## Company & Product Overview

**Vithanco** is a one-person software company by Klaus Kneupner. The flagship product is **Three Daily Goals** — a productivity app for iPhone, iPad, and Mac (iOS 18+, macOS 15+) sold as a $19.99 one-time purchase on the App Store.

The core philosophy: instead of emptying an infinite "bucket" of tasks, treat your task list as a **river** — always flowing, with stale items naturally falling away. Tasks untouched for 30 days are automatically moved to the **Graveyard**. About 30% of tasks end there — and users never miss them.

### Key Concepts
- **Three Daily Goals**: Pick 3 priority tasks each day
- **Compass Check**: A customizable 5-step daily review ritual (noon-to-noon planning)
- **Graveyard**: Tasks auto-archived after 30 days of inactivity
- **Energy-Effort Matrix**: Categorize tasks by energy and effort (instead of Eisenhower urgency/importance)
- **Streak**: Gamified daily check-in counter
- **CloudKit Sync**: Seamless iPhone/iPad/Mac sync

### Task States
| State | Color | Icon (SF Symbol) |
|-------|-------|---------|
| Priority | Orange | `star.fill` |
| Open | Blue | `circle` |
| Pending Response | Yellow | `clock` |
| Closed | Green | `checkmark.circle.fill` |
| Graveyard (dead) | Brown | `archivebox` |

### Energy-Effort Matrix Quadrants
| Quadrant | Label | Color |
|----------|-------|-------|
| High Energy + Big Task | Deep Work | Soft lavender `#B4A5D5` |
| Low Energy + Big Task | Steady Progress | Soft teal `#7BB8BA` |
| High Energy + Small Task | Sprint Tasks | Soft coral `#F4A89A` |
| Low Energy + Small Task | Easy Wins | Soft mint `#A8D5BA` |

---

## Sources

- **App codebase**: https://github.com/Vithanco/ThreeDailyGoals (MIT licensed, Swift/SwiftUI/SwiftData)
- **Website**: https://github.com/Vithanco/www.threedailygoals.com
- **App Store**: https://apps.apple.com/us/app/three-daily-goals/id6474504409

---

## CONTENT FUNDAMENTALS

### Voice & Tone
- **First-person "I"** in founder/blog copy; **second-person "you"** in marketing + UI
- **Warm, honest, slightly philosophical** — not hustle-culture productivity speak
- **Conversational** — Klaus writes like he's talking to a friend who also struggles with task overload
- No em-dashes overdone; short punchy sentences mixed with longer reflective ones
- Occasional rhetorical questions: "How do others cope with runaway task lists?"

### Casing
- **Title case** for feature names: Compass Check, Three Daily Goals, Graveyard, Energy-Effort Matrix
- **Sentence case** for UI labels and nav items
- Nav items on website are **UPPERCASE** (CSS `text-transform: uppercase`)

### Emoji
- **No emoji** in UI, marketing copy, or branding — completely clean
- No decorative unicode either

### Key Phrases / Copy Patterns
- "Don't drown in your own to-dos" (hero headline)
- "The task manager that helps you let go"
- "The process-driven Task Manager"
- "A calmer way to get things done — without the guilt."
- "Rivers, not buckets" (philosophical metaphor from Oliver Burkeman)
- "30% of my tasks quietly move to the graveyard — and I've never missed one."
- Blockquotes used for social proof: short 1-sentence user quotes, attribution as **Name, role**

### Vibe
Calm, grounded, anti-anxiety. Productivity without pressure. Philosophical but practical. The writing acknowledges failure/frustration before offering a solution. Not slick SaaS copy — genuine indie-founder voice.

---

## VISUAL FOUNDATIONS

### Colors
- **Accent / Brand**: `#EA580C` — deep orange (Tailwind orange-600)
- **Foreground**: `#000000` black
- **Background**: `#FFFFFF` white
- **Neutral scale**: #FAFAFA → #424242 (9-step Material-inspired scale)

### Task State Colors (semantic)
- Priority: `Color.orange` (system orange)
- Open: `Color.blue` (system blue)  
- Pending: `Color.yellow` (system yellow)
- Closed: `Color.green` at 70% opacity
- Dead/Graveyard: `Color.brown` (system brown)
- Due Soon: `Color.red`

### Energy-Effort Matrix Colors (muted pastels)
- Deep Work: `#B4A5D5` (soft lavender)
- Steady Progress: `#7BB8BA` (soft teal)
- Sprint Tasks: `#F4A89A` (soft coral/peach)
- Easy Wins: `#A8D5BA` (soft mint)

### Typography
- **Website**: `ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto` — pure system stack, no custom fonts
- **App**: SwiftUI Dynamic Type — `.body`, `.headline`, `.callout`, `.caption`, `.subheadline` — no fixed px sizes
- **H1**: 40px / 45px line-height on web
- No display or serif fonts used anywhere

### Backgrounds & Surfaces
- Clean white backgrounds; no gradients in the app
- Website uses white background only
- Cards use `neutral50` (#FAFAFA) light / `neutral800` (#424242) dark
- **No full-bleed imagery**, no textures, no patterns
- Screenshot galleries use `border-radius: 12px` + subtle box-shadow

### Cards
- `border-radius: 10–12px` (app: `clipShape(.rect(cornerRadius: 10))`)
- Light border: `neutral200` light mode / `neutral700` dark mode  
- Subtle shadow: `rgba(0,0,0,0.15) 0px 3px` (app) / `rgba(149,157,165,0.2) 0px 8px 24px` (web)
- `.padding(.horizontal, 8).padding(.vertical, 8)` inside cards

### Blockquotes (website)
- Background `#f7f7f7`, 10px orange left-border, 1px orange-tinted right/top/bottom border
- Italic text, centered, `#333` color

### Shadows
- Web sidebar widgets: `rgba(100,100,111,0.2) 0px 7px 29px 0px`
- Web header: `rgba(149,157,165,0.2) 0px 8px 24px`
- App cards: `radius: 3, x:0, y:2`
- App lists: `radius: 2, x:0, y:1`

### Borders
- Radius: 6px (buttons), 8px (streak widget), 10–12px (cards/lists)
- Nav items on website: `border-radius: 2px`
- Tags: `border-radius: 4px`

### Animations
- No custom animations in the app (SwiftUI system animations)
- Website screenshot slider: `transition: transform 0.3s ease, box-shadow 0.3s ease`
- Hover: `translateY(-4px)` on screenshot cards; `scale(105%)` on social icons; `scale(102%)` on tags

### Hover / Press States
- Buttons: opacity shift or slightly darker background (e.g. `rgba(234,88,12,0.95)` on newsletter CTA hover)
- Slider arrows: `scale(1.1)` on hover, `scale(0.95)` on active
- Nav items: orange gradient background + white text when `.selected`

### Iconography
- Exclusively **SF Symbols** in the app (all declared as string constants with `img` prefix in `IconsRelated.swift`)
- Social media: custom SVGs (LinkedIn, Bluesky, RSS)
- No icon fonts in the app; Font Awesome used only on the website (for star ratings)

### Layout Rules
- Website max content width: 700px article + 300px sidebar
- App sidebar: `minWidth: 350, idealWidth: 500, maxWidth: 1000` (macOS)
- Spacing: 8px base grid; common paddings: 8, 12, 16px
- Header: fixed, 100px tall on desktop, responsive on mobile

### Color Vibe of Imagery
- App screenshots: clean iOS/macOS default system UI — white/light mode + system colors
- No grain, filters, or color grading
- Warm-neutral system feel

### Marketing Screenshot Background Palette
- Warm cream: `#FFF9F1` (base background)
- Brand orange: `#EA580C` (geometric fill, lower-left)
- Near black: `#111111` (geometric accent, lower-right)
- Arranged as geometric shapes behind device frames

---

## ICONOGRAPHY

The app exclusively uses **Apple SF Symbols** — no external icon libraries, no SVG icons, no PNG icons. All SF Symbol names are declared as string constants (with the `img` prefix) in `tdgCore/Sources/tdgCoreWidget/Helpers/IconsRelated.swift`.

### Key SF Symbol Assignments

| Constant | SF Symbol | Usage |
|----------|-----------|-------|
| `imgOpen` | `circle` | Open task state |
| `imgClosed` | `checkmark.circle.fill` | Closed task |
| `imgGraveyard` | `archivebox` | Graveyard/dead state |
| `imgPendingResponse` | `clock` | Waiting state |
| `imgPriority` | `star.fill` | Priority/today |
| `imgCompassCheck` | `safari` | Compass Check nav |
| `imgStreak` | `flame` | Streak display |
| `imgStreakActive` | `flame.fill` | Active streak |
| `imgSearch` | `magnifyingglass` | Search |
| `imgPlus` | `plus.circle.fill` | Add task |
| `imgTrash` | `trash` | Delete |
| `imgPreferences` | `gearshape` | Settings |
| `imgStats` | `chart.bar.fill` | Stats |
| `imgEemDeepWork` | `brain.head.profile` | Deep Work quadrant |
| `imgEemSteadyProgress` | `tortoise.fill` | Steady Progress quadrant |
| `imgEemSprintTasks` | `bolt.fill` | Sprint Tasks quadrant |
| `imgEemEasyWins` | `checkmark.circle.fill` | Easy Wins quadrant |

### Web / Social Icons
Located in `assets/icons/`: `linkedin.svg`, `bluesky.svg`, `rss.svg` — used only in website footer.

### Logo Assets
Located in `assets/`:
- `logo.svg` — primary SVG logo
- `logo.png` / `logo1024.png` — PNG variants
- `Wordmark.png` — text wordmark
- `logo-white.png` — white variant (dark bg)
- `logo-black.png` — black variant

---

## File Index

```
README.md                    ← This file
SKILL.md                     ← Claude Code skill descriptor
colors_and_type.css          ← CSS design tokens (colors, type, spacing)

assets/
  logo.svg                   ← Primary logo SVG
  logo.png                   ← Logo PNG
  logo1024.png               ← 1024px logo
  Wordmark.png               ← Text wordmark
  logo-white.png             ← White logo variant
  logo-black.png             ← Black logo variant
  icons/
    linkedin.svg             ← LinkedIn social icon
    bluesky.svg              ← Bluesky social icon
    rss.svg                  ← RSS icon
  screenshots/
    ios-1.png … ios-3.png    ← iPhone app screenshots
    macos-1.png … macos-2.png ← macOS app screenshots

preview/
  colors-brand.html          ← Brand + accent color swatches
  colors-state.html          ← Task state colors
  colors-eem.html            ← Energy-Effort Matrix colors
  colors-neutral.html        ← Neutral scale
  type-scale.html            ← Typography scale
  type-specimens.html        ← Type specimens
  spacing-tokens.html        ← Spacing + radius + shadow tokens
  components-tasks.html      ← Task row components
  components-states.html     ← State badges + indicators
  components-buttons.html    ← Button variants
  components-streak.html     ← Streak & compass check widgets
  logo-usage.html            ← Logo usage guidelines

ui_kits/
  ios_app/
    README.md                ← iOS app kit notes
    index.html               ← Main app prototype (iOS)
    components.jsx           ← Shared UI components
```
