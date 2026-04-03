# Media Detail Premium Refinement Design

**Date:** 2026-04-04  
**Project:** Jupiter / Tinyglim / 微光图志  
**Status:** Approved for planning

---

## Goal

Take the media detail viewer from “working cinematic prototype” to a truly refined premium photography experience.

This refinement is intentionally narrow. We are not redesigning the whole app again. We are using the media detail viewer as the quality bar and raising its precision in three areas:

- layout hierarchy
- material quality
- motion quality

---

## Approved Direction

### Product Mood

- Reference class: `High-end photography app`
- Tone: `Light cinematic`
- Primary priority: `Photo-first`
- Information model: `Minimal floating metadata`
- Photo treatment: `Absolute hero`
- Background treatment: `Soft atmospheric backdrop`

### What This Means

The viewer should feel closer to a premium photography product than to a generic full-screen modal.

The image should own the screen. Controls and metadata should feel like carefully designed instruments around the image rather than UI layered on top of it.

---

## Experience Intent

The desired emotional impression is:

- calm
- expensive
- precise
- quiet
- photo-led

When the viewer opens, the user should feel that the image has been elevated into a presentation space.

When the viewer closes, it should feel like the image gently returns to the gallery rather than the screen abruptly dismissing a modal.

---

## Composition System

### Photo as Absolute Hero

- The active photo remains the strongest contrast element on screen.
- The photo uses `aspectFit`, but its position must be based on the full visual canvas, not safe-area-constrained layout.
- Status bar and home indicator regions must not push the image off visual center.
- The photo should occupy as much space as possible while still preserving a small breathing margin around it.

### Centering Rule

The viewer uses **visual centering**, not “safe area centering.”

That means:

- the active image is centered against the full display canvas
- top chrome is positioned relative to safe area
- bottom metadata card is positioned relative to safe area
- neither of those should affect the hero image’s resting center

This is the most important precision rule in the redesign.

---

## Layer Model

The screen should be understood as four coordinated layers.

### 1. Atmosphere Layer

- A very soft backdrop derived from the active image
- Warm, blurred, desaturated, and low contrast
- Covers the entire display including status bar and home indicator
- Never moves with drag-to-dismiss
- Exists to support the image, never to attract attention

### 2. Hero Image Layer

- The only large moving layer
- Handles paging, zooming, and drag-to-dismiss
- Always returns to the same centered resting position
- Should never feel attached to a moving card or sheet

### 3. Chrome Layer

- Close button and info button share identical shape, size, material, and shadow
- Both sit outside the photo’s strongest content zone
- Both fade with the same opacity rules during drag or chrome hide
- Their layout is symmetrical and deliberate, not incidental

### 4. Info Layer

- Metadata appears only when explicitly requested
- It is a floating explanation card, not a permanent drawer
- It rises from the bottom edge but stops before dominating the image
- It behaves like a secondary layer, never the main subject

---

## Metadata Strategy

### Selected Pattern: Minimal Floating Metadata

Default state should be:

- photo
- close button
- info button

No persistent drawer. No always-visible metadata strip. No permanent bottom chrome.

### Info Card Behavior

- Tap the info button to reveal metadata
- The metadata surface appears as a refined white card from the bottom
- The card should feel light and intentional, not like a default system sheet
- It should avoid covering the photo subject whenever possible
- Dismissing the card should feel like sliding a caption card away, not collapsing a utility panel

### Information Structure

Metadata remains card-based, but the presentation becomes more editorial:

- icon
- compact label
- strong value

Rules:

- two-column layout
- matching row heights
- consistent icon scale
- fewer visible fields
- no noisy engineering metadata by default

---

## Motion Design

### Opening / Closing

- Opening should feel like the image expands into a presentation stage
- Atmosphere fades in first or alongside the image
- Chrome appears slightly after the hero settles
- Closing runs in reverse: chrome fades first, then image returns

### Horizontal Paging

- Use soft slide + fade
- Motion distance should be shorter than a full hard swipe illusion
- The incoming image should feel continuous, not stacked as a new screen
- Continuous swiping must remain stable and never snap back unexpectedly

### Vertical Drag to Dismiss

- Only the hero image moves
- Background remains fixed
- Atmosphere blur/opacity shifts with progress
- Buttons fade with progress
- If the info card is open, downward drag should dismiss the info card first
- Only when the info card is closed should downward drag dismiss the viewer

### Metadata Motion

- The card should rise with a subtle spring and short fade
- The hero image may shift slightly upward and scale subtly to preserve breathing room
- This response should be smooth throughout the gesture, not only at state boundaries

---

## Material System

### Background

- Replace plain white full-screen emptiness with warm white plus soft atmospheric image tint
- The backdrop must remain restrained and almost invisible when the image is strong

### Controls

- White translucent solid fills, not heavy blur
- Low-contrast outline
- Very soft depth
- Same diameter and same visual weight for close and info

### Metadata Card

- Solid warm white surface
- Clean edge definition
- Low shadow radius
- Interior cards slightly lifted from the card surface, but only subtly

The viewer should stop mixing multiple material languages in one screen.

---

## Precision Problems This Design Must Fix

The current viewer still suffers from “almost right” problems that prevent it from feeling premium:

- image appears vertically off-center
- controls can feel too close to the status bar
- metadata competes with the hero image
- transitions feel functional rather than luxurious
- layout still occasionally reads like a card/modal instead of a presentation surface

This refinement specifically exists to remove those rough edges.

---

## Success Criteria

The redesign is successful when:

- the photo feels perfectly centered at rest
- the background fills the entire device without white seams
- close and info buttons feel like a matched pair of premium controls
- metadata feels optional and elegant, never heavy
- paging and drag-to-dismiss both feel continuous and stable
- the whole screen reads as a premium photo presentation, not a utility view

---

## Out of Scope

This refinement does not introduce:

- new backend data
- new metadata fields
- a broader app-wide redesign beyond what is needed to support the detail viewer standard
- a new navigation model
- unrelated feed or album architecture changes

The scope is precision, not expansion.
