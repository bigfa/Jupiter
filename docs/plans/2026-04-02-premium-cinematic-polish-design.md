# Premium Cinematic Polish Design

**Date:** 2026-04-02  
**Project:** Jupiter / Tinyglim / 微光图志  
**Status:** Approved for planning

---

## Goal

Run a product-wide polish pass centered on the media detail experience, using a light cinematic visual language that feels warmer, more premium, and more cohesive without expanding backend scope or changing core business flows.

This pass is not about adding major new features. It is about making the existing app feel intentionally designed end-to-end.

---

## Product Direction

### Selected Direction

- Polish level: `Aggressive`
- Visual mood: `Light cinematic`
- Master screen: `Media detail`
- Balance: `Photo-first, but with refined metadata and utility surfaces`

### Design Intent

The app should feel like a quiet premium photography product rather than a collection of functional screens. Photos remain the strongest visual element, while UI components become softer, calmer, and more consistent.

The intended emotional tone is:

- Warm white gallery space instead of flat system white
- Subtle depth instead of loud decoration
- Calm motion instead of flashy motion
- Strong hierarchy where the photo is always the hero

---

## Core Visual Language

### Background System

- Replace hard white backgrounds with a warm neutral base:
  - soft ivory
  - pale stone
  - faint warm gray gradients
- Fullscreen media surfaces should cover status bar and home indicator areas cleanly.
- Blurred photo backdrops may be used only in immersive screens, not everywhere.

### Material Usage

- Material should be limited to control chrome and lightweight floating surfaces.
- Large information surfaces should avoid overusing blur when a solid warm white card communicates better.
- The app should stop mixing heavy blur, plain white sheets, and dark overlays without a clear rule.

### Typography

- Editorial serif remains the accent typeface for titles, section headings, and selected tabs.
- Functional UI such as metadata, settings, action labels, and purchase details uses a clean sans serif system style.
- The contrast between serif and sans should feel deliberate and consistent.

### Shape and Depth

- Standardize to a small set of corner radii across the product.
- Reduce random shadow behavior and use only low, soft depth.
- Floating controls should share the same size, stroke treatment, fill logic, and pressed feedback.

### Motion

- Motion should feel calm and expensive:
  - short fades
  - soft springs
  - controlled offset distances
- Avoid competing motion systems between pages.
- Every transition should reinforce hierarchy instead of calling attention to itself.

---

## Master Screen: Media Detail

The media detail screen defines the visual and interaction language for the rest of the app.

### Layer Model

The screen should be treated as four coordinated layers:

1. Atmosphere background layer  
   A blurred and desaturated version of the active photo fills the entire screen, including status bar and home indicator regions. It provides mood only and does not move with photo drag.

2. Photo hero layer  
   The active image is the only moving primary layer. It must remain truly centered by default and respond independently to paging, zoom, and drag-to-dismiss interactions.

3. Chrome control layer  
   Close and metadata buttons share identical size, material, placement logic, and opacity behavior. They fade when the user actively drags the photo.

4. Info card layer  
   Metadata is presented as a bottom floating card, not a heavy drawer that dominates the screen. It supports collapsed, medium, and near-full states while preserving photo visibility.

### Interaction Principles

- A single tap toggles chrome visibility.
- Horizontal swipe moves between previous and next photos with a lighter, more native-feeling transition.
- Vertical drag dismisses only when the metadata card is collapsed.
- When the metadata card is open, downward drag on the photo should first collapse the card instead of closing the viewer.
- Pinch and double-tap zoom remain supported.
- Drag-to-dismiss is disabled while the image is zoomed in.

### Metadata Behavior

- The info surface should feel like a floating explanation card, not a utility drawer.
- Collapsed state shows only a minimal affordance.
- Medium state shows the primary metadata card grid.
- Expanded state shows the full metadata set and utility actions.
- The photo may shift slightly upward and scale subtly as the metadata surface expands, but the surface should not aggressively cover the image.

### Information Design

- Metadata is shown as compact, consistent cards with icon-led labels.
- Cards should maintain aligned row heights to avoid visual mess.
- Only meaningful photography details remain visible.
- Utility actions such as like and download belong inside this information system rather than cluttering the main chrome.

### Quality Bar

The media detail screen should feel:

- centered
- stable
- edge-to-edge
- calm
- continuous during page changes

It should never feel like a draggable modal card.

---

## Home Feed Strategy

The home feed should inherit the media detail visual language without becoming overly decorative.

### Role

The home screen is the discovery wall. Its job is to get users into images quickly.

### Direction

- Keep the photo grid visually dominant.
- Preserve grouped-by-date layout for date sorting and free-flow layout for hot sorting.
- Treat the date headings as quiet editorial chapter markers.
- Keep the sticky category bar, but make it feel like a lightweight gallery control strip rather than a standard app toolbar.
- Ensure skeletons, empty states, retry states, and no-more states match the same product voice as the rest of the app.

### Desired Feel

The home feed should feel calm and spacious, but dense enough to support browsing momentum.

---

## Album List Strategy

The album list should read like a catalogue of curated collections.

### Role

The album screen is the library index, not another generic card feed.

### Direction

- Album cards should feel closer to photo-book covers than content cards.
- Increase nuance in type hierarchy and cover presentation.
- Reduce the sense that overlays are pasted on top of the image.
- Preserve slightly more breathing room than the home feed so the two sections feel related but distinct.
- Maintain the same category control language as the home feed.

### Desired Feel

The album list should feel like browsing named bodies of work.

---

## Album Detail Strategy

Album detail should feel like entering a chapter inside the same gallery system.

### Direction

- The navigation bar title is enough; repeated page titles should be removed when redundant.
- Introductory description content should feel like a curator note, not a generic text box.
- The media layout should inherit the home feed rhythm while allowing slightly softer edges and more breathing room.
- Tapping a photo should open exactly the same immersive viewer used from the home feed.

### Desired Feel

Users should feel that they are still in the same product world, just one level deeper.

---

## Settings and Paywall Strategy

These screens must no longer feel like utility leftovers.

### Settings / About

- Present product information in a quieter, more intentional information layout.
- Keep the surface light, compact, and aligned with the app's overall visual system.
- Use the same component language for version, author contact, and entitlement state.

### Paywall

- Keep the premium feel, but tie it closer to the main app visual language.
- The paywall should feel like a natural extension of the product, not a separate promotional microsite.
- CTA area, feature cards, copy rhythm, and background treatment should align with the same cinematic system.

---

## Copy and UX Consistency Rules

This polish pass should also standardize product voice.

### Rules

- Empty states should feel calm and helpful, never abrupt.
- Error states should be concise and readable.
- Purchase, restore, unlock, and retry messages should share one tone.
- Button labels should be short and consistent.
- Localization quality should be treated as part of the polish pass, not a separate concern.

---

## Implementation Boundaries

### In Scope

- Media detail visual hierarchy and motion refinement
- Unified visual language across home, albums, settings, and paywall
- Control styling, spacing, cards, safe area handling, and surface treatment
- Copy, loading states, empty states, and error-state polish
- Interaction tuning for paging, drag dismissal, metadata presentation, and feedback

### Out of Scope

- New backend endpoints
- New business models beyond the existing one-time purchase flow
- Major data-model redesign
- Large UIKit-only custom transition rewrites unless absolutely required

---

## Priority Order

### P1

- Media detail viewer
- Photo centering
- Metadata card behavior
- Paging motion
- Dismiss and chrome interaction quality

### P2

- Home feed control strip and state polish
- Album list refinement
- Album detail visual consistency

### P3

- Settings and about sheet cleanup
- Paywall cohesion and copy polish

### P4

- Micro-interactions
- Press states
- Fade timing
- Entrance timing
- Completion messaging

---

## Success Criteria

This polish pass is successful when:

- The app feels like one product, not several modules with different tastes.
- The media detail screen is stable, centered, immersive, and visually calm.
- The home feed, album list, and album detail screens clearly belong to the same design system.
- Settings and paywall no longer feel visually secondary.
- Users can sense a higher-quality product even before noticing individual feature changes.

---

## Risks to Watch

- Over-styling the app until the photo is no longer the hero
- Mixing too many material effects and reintroducing inconsistency
- Regressing media paging or dismissal while improving appearance
- Creating a premium feel in one screen while leaving adjacent screens behind
- Letting localization drift while visual polish improves

---

## Final Recommendation

Proceed with a product-wide polish pass led by the media detail screen.

Use the media detail viewer as the design source of truth, then cascade that language outward to the home feed, album catalogue, album detail, settings, and paywall. Favor restraint, warmth, continuity, and photo-first hierarchy over adding new controls or more expressive but distracting motion.
