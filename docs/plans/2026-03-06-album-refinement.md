# Album Refinement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refine album detail and album list presentation so the detail page uses the album title in the navigation bar and the list feels more editorial.

**Architecture:** Keep the existing data flow and navigation intact. Limit the work to SwiftUI view composition in the album detail view, album card component, and album list skeleton/layout so the behavior stays stable while presentation is upgraded.

**Tech Stack:** SwiftUI, MVVM, Kingfisher-backed `RemoteImage`, XCTest-free build verification

---

### Task 1: Simplify Album Detail Header

**Files:**
- Modify: `/Users/rich/Projects/Jupiter/Jupiter/Views/AlbumDetailView.swift`

**Step 1: Remove redundant header metadata**

Delete the header row that renders photo count and likes.

**Step 2: Promote album title to the navigation bar**

Use `viewModel.album?.title ?? preview?.title ?? "Album"` as the navigation title.

**Step 3: Keep the body header focused**

Retain only title and description in the inline header block.

**Step 4: Verify**

Run:

```bash
xcodebuild -project Jupiter.xcodeproj -scheme Jupiter -destination 'generic/platform=iOS Simulator' build
```

Expected: `BUILD SUCCEEDED`

### Task 2: Redesign Album List Cards

**Files:**
- Modify: `/Users/rich/Projects/Jupiter/Jupiter/Components/AlbumCard.swift`

**Step 1: Increase cover presence**

Raise the visual height of the cover and tune crop/overlay to feel more editorial.

**Step 2: Reduce metadata noise**

Remove the bottom count/likes line and keep title + optional description only.

**Step 3: Refine typography and chrome**

Use more expressive title typography, softer description styling, lighter locked badge, and a more subtle border/shadow stack.

**Step 4: Verify**

Run the simulator build command and confirm it passes.

### Task 3: Align Album List Layout and Skeletons

**Files:**
- Modify: `/Users/rich/Projects/Jupiter/Jupiter/Views/AlbumListView.swift`

**Step 1: Match spacing to the new card treatment**

Tune card spacing and horizontal padding so the single-column list breathes correctly.

**Step 2: Update skeleton proportions**

Raise skeleton height and roundness to match the new card geometry.

**Step 3: Verify**

Run the simulator build command and confirm it passes.
