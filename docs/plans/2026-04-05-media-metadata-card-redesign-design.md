# Media Metadata Card Redesign

**Date:** 2026-04-05  
**Project:** Jupiter / 微光图志  
**Status:** Approved for implementation

---

## Goal

Replace the current unstable metadata overlay with a refined bottom-aligned white presentation card that feels like a premium photography companion surface rather than a drawer.

---

## Approved Direction

### Product Mood

- Reference class: `High-end photography app`
- Tone: `Light cinematic`
- Metadata pattern: `Bottom floating info card`
- Material: `Pure white solid surface`
- Width behavior: `Edge-hugging wide card`
- Density: `Two-column compact cards`
- Default height: `About 28% of the screen`

### What This Means

The metadata surface should feel editorial and deliberate.
It should not behave like a utility sheet or a draggable drawer.
The photo remains the hero. Metadata is a supporting explanation layer.

---

## Composition

### Card Placement

- The card sits directly against the bottom edge of the screen.
- Left and right margins are narrow, around `12-14pt`.
- The bottom edge visually merges with the display edge so there is no white seam.
- The top corners are generously rounded.

### Card Height

- Default open state is fixed near `28%` of the screen height.
- The card should not have multi-stage drawer behavior.
- The card can scroll internally if the metadata content exceeds the visible area.

### Relationship to the Hero Image

- Opening the card causes only a very subtle hero response:
  - slight upward shift
  - slight scale reduction
- The image must still read as the primary subject.
- The metadata card should never appear to push the entire screen or drag the atmosphere layer.

---

## Visual System

### Surface Material

- Use a pure warm white solid fill.
- No glass effect.
- No translucent sheet appearance.
- Add only a very subtle top-edge outline and a light shadow for separation.

### Header Treatment

- Remove the large `Metadata` title.
- Keep only a small top handle for affordance.
- The accessory action area (currently like state) remains on the top-right of the card.
- The header should feel nearly invisible.

### Internal Metadata Cards

- Use a stable two-column grid.
- Each row should have equal height between the two cells.
- Internal cards use a soft warm-gray white fill with light outline.
- Icons remain lightweight line icons.
- Values are the visual focus.

---

## Information Architecture

### Primary Fields

First priority block:

- camera model
- lens
- aperture
- shutter
- ISO
- focal length

### Secondary Fields

Second priority block:

- shoot time
- location
- GPS
- format
- tags
- categories

### Explicit Exclusions

Keep these hidden:

- filename
- dimensions
- aspect ratio
- file size
- upload time

---

## Motion

### Opening

- Tap the info button.
- The card rises from the bottom with a short, calm spring.
- Opacity fades in with the same motion.
- Hero image responds slightly after the card begins to settle.

### Closing

- Tap the info button again or drag the photo downward.
- If metadata is open, the card closes first.
- The card should sink cleanly without stagger or drawer-like snapping.

### Drag Behavior

- The metadata surface itself should not be draggable in multiple stages.
- Downward photo drag should collapse metadata first, then allow viewer dismissal on the next drag.
- The atmosphere layer remains fixed.

---

## Loading Behavior

### Metadata Fetch Experience

- Opening the card should always feel immediate.
- If only preview metadata exists, show it immediately.
- If the detail request is still loading and there is no presentable metadata yet, show a skeleton grid that matches the final card geometry.
- When detail data arrives, fade the real content in.
- Only show `No EXIF data` if loading has completed and no presentable metadata exists.

---

## Success Criteria

The redesign is successful when:

- the info button opens a clean bottom card with no visual misalignment
- the card feels like a premium white presentation surface
- the card no longer behaves like a draggable drawer
- the image remains visually dominant
- metadata content feels tidy, dense, and editorial
- loading transitions no longer flash empty state before data arrives

