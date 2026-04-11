# Media Metadata Card Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild the photo metadata presentation into a fixed bottom white card with refined layout, no drawer jitter, and smoother content loading.

**Architecture:** Keep `MediaZoomPagerView` as the viewer container, but simplify metadata from a pseudo-drawer into a fixed presentation card controlled by a single open/closed state. Move metadata display rules into small pure helpers and keep card content reusable in `MediaQuickDetailOverlay.swift`.

**Tech Stack:** SwiftUI, Swift 5, XCTest, Kingfisher

---

### Task 1: Lock metadata content-state and geometry rules with tests

**Files:**
- Modify: `Jupiter/Views/MediaMetadataPresentation.swift`
- Modify: `JupiterTests/MediaMetadataPresentationTests.swift`

**Step 1: Write the failing test**

Add a geometry rule assertion:

```swift
func testCardHeightUsesCompactPresentationRatio() {
    XCTAssertEqual(
        MediaMetadataPresentation.cardHeight(for: 900),
        252,
        accuracy: 1
    )
}
```

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/MediaMetadataPresentationTests/testCardHeightUsesCompactPresentationRatio
```

Expected: FAIL because `cardHeight(for:)` does not exist yet.

**Step 3: Write minimal implementation**

Add:

```swift
static func cardHeight(for viewportHeight: CGFloat) -> CGFloat { ... }
```

Rule:
- returns about `28%` of viewport height with sane min/max clamps.

**Step 4: Run test to verify it passes**

Run the same command.

Expected: PASS.

**Step 5: Commit**

```bash
git add Jupiter/Views/MediaMetadataPresentation.swift JupiterTests/MediaMetadataPresentationTests.swift
git commit -m "test: lock metadata card presentation rules"
```

---

### Task 2: Rebuild the metadata card shell as a fixed bottom white card

**Files:**
- Modify: `Jupiter/Views/MediaQuickDetailOverlay.swift`
- Modify: `Jupiter/Components/CinematicSurfaceStyle.swift`
- Modify: `Jupiter/Views/MediaZoomPagerView.swift`

**Step 1: Write the failing test**

Add a new content-state assertion to keep empty/loading behavior stable:

```swift
func testContentStateRemainsContentWhileDetailLoadsIfPreviewHasMetadata() {
    let item = MediaItem(... cameraModel: "X100VI", ...)
    XCTAssertEqual(
        MediaMetadataPresentation.contentState(item: item, isDetailLoading: true),
        .content
    )
}
```

**Step 2: Run test to verify it fails if needed**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/MediaMetadataPresentationTests
```

Expected: If already green, keep it as regression evidence and proceed.

**Step 3: Write minimal implementation**

Refactor the card shell:

- fixed bottom alignment
- use `MediaMetadataPresentation.cardHeight(for:)`
- pure white solid outer card
- narrow horizontal margins
- remove large `Metadata` title
- keep only a slim top handle and trailing accessory area
- internal grid remains two-column with equal-height cells
- no draggable drawer behavior on the card itself

**Step 4: Run tests and build**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/MediaMetadataPresentationTests -only-testing:JupiterTests/MediaViewerPresentationTests
xcodebuild -project Jupiter.xcodeproj -scheme Jupiter -destination 'generic/platform=iOS Simulator' build
```

Expected:
- tests PASS
- build SUCCEEDS

**Step 5: Commit**

```bash
git add Jupiter/Views/MediaQuickDetailOverlay.swift Jupiter/Components/CinematicSurfaceStyle.swift Jupiter/Views/MediaZoomPagerView.swift Jupiter/Views/MediaMetadataPresentation.swift JupiterTests/MediaMetadataPresentationTests.swift
git commit -m "feat: rebuild metadata as a fixed bottom presentation card"
```

---

### Task 3: Tune the open/close motion and collapse priority

**Files:**
- Modify: `Jupiter/Views/MediaViewerPresentation.swift`
- Modify: `Jupiter/Views/MediaZoomPagerView.swift`
- Modify: `JupiterTests/MediaViewerPresentationTests.swift`

**Step 1: Write the failing test**

Add one more rule:

```swift
func testMetadataCollapseTakesPriorityBeforeDismiss() {
    XCTAssertTrue(
        MediaViewerPresentation.photoDragShouldCollapseMetadata(
            translationY: 120,
            metadataState: .medium
        )
    )
}
```

**Step 2: Run test to verify it fails if needed**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/MediaViewerPresentationTests
```

Expected: If already green, treat it as regression verification.

**Step 3: Write minimal implementation**

Refine motion only:

- info button opens/closes the fixed card
- hero image shifts slightly when card opens
- card opens with a short calm spring
- closing the card restores hero resting state smoothly
- downward photo drag collapses metadata first
- no card drag interactions remain

**Step 4: Run tests and build**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/MediaViewerPresentationTests -only-testing:JupiterTests/MediaMetadataPresentationTests -only-testing:JupiterTests/MediaItemDetailMergeTests
xcodebuild -project Jupiter.xcodeproj -scheme Jupiter -destination 'generic/platform=iOS Simulator' build
```

Expected:
- tests PASS
- build SUCCEEDS

**Step 5: Commit**

```bash
git add Jupiter/Views/MediaViewerPresentation.swift Jupiter/Views/MediaZoomPagerView.swift JupiterTests/MediaViewerPresentationTests.swift JupiterTests/MediaMetadataPresentationTests.swift JupiterTests/MediaItemDetailMergeTests.swift
git commit -m "refactor: tune metadata card motion and loading transitions"
```

