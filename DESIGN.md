---
name: SmartGrow
description: Calm, precise plant monitoring with a warm accent and confident controls.
colors:
  accent: "#E2491A"
  canvas: "#F6F6F5"
  surface: "#FFFFFF"
  text-primary: "#1B1B1B"
  text-secondary: "#5F5E5F"
  divider: "#E8E8E6"
typography:
  display:
    fontFamily: "Inter, sans-serif"
    fontSize: "26px"
    fontWeight: 600
    lineHeight: 1.2
  section:
    fontFamily: "Inter, sans-serif"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: 1.3
  screen:
    fontFamily: "Inter, sans-serif"
    fontSize: "16px"
    fontWeight: 500
    lineHeight: 1.4
  card:
    fontFamily: "Inter, sans-serif"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: 1.4
  body:
    fontFamily: "Inter, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.5
  caption:
    fontFamily: "Inter, sans-serif"
    fontSize: "10px"
    fontWeight: 400
    lineHeight: 1.4
  metric:
    fontFamily: "Inter, sans-serif"
    fontSize: "26px"
    fontWeight: 600
    lineHeight: 1
rounded:
  card: "16px"
  pill: "999px"
  icon-container: "50%"
  compact: "8px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  base: "16px"
  lg: "24px"
  xl: "32px"
components:
  tab-selected:
    backgroundColor: "{colors.accent}"
    textColor: "#FFFFFF"
    rounded: "{rounded.pill}"
    padding: "8px 20px"
  tab-unselected:
    backgroundColor: "#EDEDE9"
    textColor: "{colors.text-secondary}"
    rounded: "{rounded.pill}"
    padding: "8px 20px"
  nav-bar:
    backgroundColor: "#1B1B1B"
    textColor: "#FFFFFF"
    height: "64px"
  nav-active:
    backgroundColor: "{colors.accent}"
    textColor: "#FFFFFF"
    rounded: "{rounded.icon-container}"
    size: "44px"
  card-device:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.card}"
    padding: "16px"
  toggle-on:
    backgroundColor: "{colors.accent}"
    rounded: "{rounded.pill}"
    size: "52px"
  toggle-off:
    backgroundColor: "#EDEDE9"
    rounded: "{rounded.pill}"
    size: "52px"
---

# Design System: SmartGrow

## Overview

**Creative North Star: "The Calm Control Room"**

SmartGrow is a home interface for living things — plants that need daily attention but not constant anxiety. The visual language carries the same quality: confident without being loud, warm without being soft. The orange accent signals exactly one thing — something you can act on right now — and it appears only when that's true. Everything else steps back into warm white and a cream canvas.

The reference screens establish a clear hierarchy: a warm-gray canvas (`#F6F6F5`) grounds all pages, clean white cards float on top of it, and a single burnt-orange accent (`#E2491A`) marks the selected, the active, and the primary action. Navigation is anchored dark at the bottom — almost black (`#1B1B1B`) with the active destination lit in orange. The result feels like a focused dashboard, not a marketing page.

Density is relaxed. Cards have generous 16px internal padding, groups are separated by consistent gaps, and labels are short and direct. The tone of copy is calm and functional — "Turn Off", "Connected to Living Room", never "Device is now activated successfully!".

**Key Characteristics:**
- Warm cream canvas with floating white surfaces — depth through layering, not shadow
- Single confident accent (burnt orange) reserved for selection, active state, and primary actions only
- Dark-anchored bottom navigation with one lit destination
- Pill-shaped tabs and compact actions; rounded-16 cards
- Inter typeface throughout; weight and size establish hierarchy before color does
- Short, direct labels; status always paired with a text label, not color alone

## Colors

One warm accent, one neutral system. The accent earns every appearance.

### Primary
- **Burnt Orange** (`#E2491A`): Selected tabs, active navigation destination, ON-state toggles, primary action buttons, and gauge needles. This color must not appear as a background area, decorative border, or passive element. Its rarity is what makes it feel like confirmation.

### Neutral
- **Warm Canvas** (`#F6F6F5`): Page background across all screens. Gives the interface warmth without competing with content.
- **Surface White** (`#FFFFFF`): Cards, panels, and modal sheets. Floats above the canvas.
- **Primary Ink** (`#1B1B1B`): Main text, screen titles, metric values, and the navigation bar background.
- **Secondary Text** (`#5F5E5F`): Supporting labels, subtitles, device subtypes, and secondary metadata.
- **Divider Gray** (`#E8E8E6`): Card borders (thin, low contrast), separators, and inactive tab backgrounds.

### Named Rules
**The One Voice Rule.** The burnt-orange accent appears on at most 10% of any screen's visible area. It signals one thing — this is selected, active, or the primary action — and that signal works only while it stays rare.

**The Canvas–Surface–Ink Rule.** Every screen uses exactly three levels: canvas behind, surface on top, ink inside. Never put text directly on the canvas without a surface card.

## Typography

**Primary Font:** Inter (sans-serif fallback)

Geometric, clean, and legible at small sizes. Inter's optical sizing and tabular figures make it a natural fit for data-dense cards and sensor metrics. No display-vs-body pairing — Inter does both, shifted only by weight and size.

### Hierarchy
- **Display** (Semibold 600, 26px, 1.2): Page-level headings ("Your Smart Home Overview", greeting lines). Used once per screen.
- **Section** (Semibold 600, 20px, 1.3): Section headings ("My Devices", "Schedule") and screen titles in navigation headers.
- **Screen** (Medium 500, 16px, 1.4): Card primary labels ("Living Room Light", "Air Conditioner") and list item titles.
- **Card** (Medium 500, 14px, 1.4): Secondary card content, device subtypes, room names, mode labels.
- **Body** (Regular 400, 12px, 1.5): Connected-state descriptions, helper text, general body content. Minimum size for readable text.
- **Caption** (Regular 400, 10px, 1.4): Brand names, secondary metadata, timestamps. Use sparingly.
- **Metric** (Semibold 600, 26px, 1.0): Gauge center values (temperature, moisture %), standalone numeric readings. Tabular figures.

### Named Rules
**The Weight-Before-Color Rule.** Establish hierarchy through size and weight first. Add color only when weight alone is insufficient — for example, the accent on a selected tab. Never use color to substitute for a missing type scale step.

## Layout

Screens follow a consistent vertical rhythm: status bar → page header (greeting or back-nav + title) → primary content area → persistent bottom navigation. The page header sits 16px from safe-area top. The bottom nav sits flush with the safe-area bottom.

Card grids use 16px horizontal margin and 12px vertical gaps. Inside cards: 16px padding on all sides. Grouped controls within a card maintain 8px internal spacing.

The spacing scale is `4 / 8 / 12 / 16 / 24 / 32px`. Use multiples of 4 for all spacing decisions. The 16px base unit governs card padding, section margins, and primary horizontal rhythm.

Suggested visual balance per screen: 68% canvas, 22% white surfaces, 10% accent. This is a tone target, not a measured constraint.

## Elevation & Depth

This system is **tonal, not shadow-based**. Depth comes from the canvas–surface contrast (cream vs. white), not from drop shadows. Cards sit on the canvas with a thin, low-contrast border (`#E8E8E6`, ~1px) rather than a shadow.

The navigation bar achieves its visual anchoring through its dark background (`#1B1B1B`), not elevation. No `box-shadow` appears on the navigation bar.

The gauge arc and sensor metric cards may use a very subtle inset appearance (achieved via background contrast only) to suggest a contained reading space — never a cast shadow.

### Named Rules
**The Flat-By-Default Rule.** Surfaces are flat at rest. Borders, not shadows, distinguish card from canvas. Motion and color distinguish state; shadows do not.

## Shapes

Rounded geometry throughout. Two primary radii:

- **Card radius (16px):** All device cards, info panels, and modal sheets. Consistent; never mix with sharper corners.
- **Pill (999px):** Tab selectors, compact action buttons, toggle controls ("+ Add device", "View all", mode tabs "Cool / Dry / Fan"). Signals selectability and interactivity.
- **Icon containers (circular, ~44px):** Navigation destination icons. The active one fills with the accent; inactive ones are transparent.
- **Compact (8px):** Secondary UI elements: input fields, small badges, tooltip containers.

Mixed corner radii on the same screen are not permitted. A card is always 16px; a pill is always fully rounded. Never use a 24px radius on a card that neighbours a 16px card.

## Components

### Tabs / Pill Selectors
The primary filtering and mode-selection control. Fully rounded pills in a horizontal scrollable or fixed row.
- **Selected:** Burnt orange background (`#E2491A`), white text, Semibold 500, 8px × 20px padding
- **Unselected:** Pale neutral background (`#EDEDE9`), secondary text color, same padding
- Spacing between pills: 8px. No border on either state.

### Cards
Soft white containers on the warm canvas.
- **Background:** Surface White (`#FFFFFF`)
- **Radius:** 16px
- **Border:** 1px solid `#E8E8E6`
- **Shadow:** None
- **Padding:** 16px
- **Layout:** Card title (Screen weight) top-left; subtitle (Body weight, secondary color) beneath; control/state element right-aligned or bottom.

### Toggle (On/Off Switch)
The primary actuator for pump, device power, and mode.
- **ON state:** Accent orange track (`#E2491A`), white thumb, thumb slightly larger than half the track height
- **OFF state:** Neutral track (`#EDEDE9`), white thumb
- Fully pill-shaped (999px). Minimum touch target 44×44px.
- Always paired with a text label ("ON" / "OFF") visible near the control — never color alone.

### Bottom Navigation Bar
Visually anchored, always present.
- **Background:** Near-black (`#1B1B1B`)
- **Inactive icons:** White, outline stroke, consistent weight
- **Active destination:** Circular orange container (`#E2491A`, ~44px diameter) with white icon inside
- **Height:** 64px + safe area inset
- 4–5 destinations, label visible on active destination only (or consistently on all — do not mix)

### Gauge / Radial Meter
Used for moisture percentage and temperature reading.
- **Arc background:** Light neutral (`#E8E8E6`)
- **Arc fill:** Accent orange (`#E2491A`) from start angle to current value
- **Center metric:** Metric type style (Semibold 600, 26px), centered
- **Range labels:** Caption type (10px) at arc endpoints
- **Needle (optional):** Small orange dot or pointer at current value

### Buttons (Floating / Inline)
- **Primary action (FAB-style):** Circular, accent orange, white icon, 56px diameter
- **Inline text action ("View all", "+ Add device"):** Pill-shaped, neutral background or plain text in accent color; keep labels under 3 words

### Shimmer / Loading State
Skeleton cards during data load: same card geometry, background cycles between `#F6F6F5` and `#EDEDE9`. No spinner visible over content.

## Do's and Don'ts

### Do:
- **Do** use `#E2491A` exclusively for selected/active/primary-action states. One accent, one job.
- **Do** pair every toggle and status indicator with a short text label ("ON", "Connected", "Auto") — never rely on color alone.
- **Do** use 16px card padding and 12px card gap consistently across all list screens.
- **Do** keep the bottom navigation bar dark and physically anchored — it must feel like a fixed chrome element, not a floating tray.
- **Do** use pill shape for all tab and mode selectors; use 16px radius for all container cards.
- **Do** establish hierarchy with Inter weight (400 → 500 → 600) before reaching for color.
- **Do** show shimmer skeleton cards while API data is loading — same geometry as the real card.

### Don't:
- **Don't** use the orange accent as a card background, section background, or decorative element. Its rarity is its value.
- **Don't** mix corner radii — if two cards appear together, both must be 16px.
- **Don't** use shadows. The canvas–surface contrast is the only depth signal.
- **Don't** write verbose status messages. "Connected to Living Room" not "This device is currently connected and operating normally in Living Room."
- **Don't** use orange for more than one destination in the bottom nav at the same time.
- **Don't** place text directly on the warm canvas without a white surface card beneath it.
- **Don't** use captions (10px) for anything a user needs to read quickly — reserve for brand metadata and secondary timestamps only.
