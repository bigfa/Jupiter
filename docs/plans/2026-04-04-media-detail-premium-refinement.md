# Media Detail Premium Refinement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refine Jupiter’s media detail viewer into a premium photography presentation surface with precise hero-image centering, matched chrome controls, fixed atmosphere background, and a minimal floating metadata card.

**Architecture:** Build on the existing `MediaViewerPresentation` helper and `MediaZoomPagerView`, but move more composition and interaction rules into small pure helpers before tightening the SwiftUI layout. Keep the viewer photo-first: the background remains fixed, the hero image is the primary moving layer, and metadata is promoted to an explicit floating card rather than a default drawer.

**Tech Stack:** SwiftUI, Swift 5, XCTest, Kingfisher, existing MVVM view models

---

### Task 1: Lock the refined viewer composition rules with tests

**Files:**
- Modify: `Jupiter/Views/MediaViewerPresentation.swift`
- Modify: `JupiterTests/MediaViewerPresentationTests.swift`

**Step 1: Write the failing test**

Extend `JupiterTests/MediaViewerPresentationTests.swift` with assertions for the new composition rules:

```swift
func testHeroRestingFrameUsesFullCanvasCentering() {
    let frame = MediaViewerPresentation.heroRestingFrame(
        imageSize: CGSize(width: 724, height: 1086),
        viewportSize: CGSize(width: 393, height: 852),
        safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
    )

    XCTAssertEqual(frame.midY, 472.5, accuracy: 0.5)
}

func testChromeButtonsRespectSafeAreaAndOuterMargin() {
    XCTAssertEqual(
        MediaViewerPresentation.chromeButtonTopInset(safeTopInset: 59),
        71,
        accuracy: 0.5
    )
}

func testMetadataOpenPreventsPhotoDismiss() {
    XCTAssertFalse(
        MediaViewerPresentation.shouldDismissPhoto(
            translationY: 140,
            predictedTranslationY: 300,
            zoomScale: 1,
            metadataState: .medium
        )
    )
}
```

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/MediaViewerPresentationTests
```

Expected: FAIL because `heroRestingFrame` and `chromeButtonTopInset` do not exist yet.

**Step 3: Write minimal implementation**

Update `Jupiter/Views/MediaViewerPresentation.swift` with new pure helpers:

```swift
static func heroRestingFrame(
    imageSize: CGSize,
    viewportSize: CGSize,
    safeAreaInsets: EdgeInsets
) -> CGRect { ... }

static func chromeButtonTopInset(safeTopInset: CGFloat) -> CGFloat { ... }
```

Rules:

- `heroRestingFrame` centers against full visual canvas, not safe-area-reduced height
- chrome top inset uses safe top inset plus a fixed outer margin
- existing dismiss logic continues to depend on metadata state and zoom scale

**Step 4: Run test to verify it passes**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/MediaViewerPresentationTests
```

Expected: PASS.

**Step 5: Commit**

```bash
git add Jupiter/Views/MediaViewerPresentation.swift JupiterTests/MediaViewerPresentationTests.swift
git commit -m "test: lock premium media viewer composition rules"
```

---

### Task 2: Re-center the hero image and stabilize chrome layout

**Files:**
- Modify: `Jupiter/Views/MediaZoomPagerView.swift`
- Modify: `Jupiter/Views/MediaViewerPresentation.swift`

**Step 1: Write the failing test**

Add a focused regression assertion to `JupiterTests/MediaViewerPresentationTests.swift` for landscape composition:

```swift
func testLandscapeHeroFrameStillCentersOnFullCanvas() {
    let frame = MediaViewerPresentation.heroRestingFrame(
        imageSize: CGSize(width: 1600, height: 900),
        viewportSize: CGSize(width: 393, height: 852),
        safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
    )

    XCTAssertEqual(frame.midX, 196.5, accuracy: 0.5)
}
```

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/MediaViewerPresentationTests/testLandscapeHeroFrameStillCentersOnFullCanvas
```

Expected: FAIL until the new helper is used consistently.

**Step 3: Write minimal implementation**

Refactor `Jupiter/Views/MediaZoomPagerView.swift` to use the new composition helpers end-to-end:

- compute the hero resting frame through `MediaViewerPresentation.heroRestingFrame`
- place the hero image by absolute frame/position relative to the full screen canvas
- move the close and info buttons to symmetrical top positions using `chromeButtonTopInset`
- ensure chrome hides/fades without altering hero layout
- keep background atmosphere fixed and independent from drag offsets

Do not redesign metadata yet. This task is strictly about hero centering, chrome placement, and stable layering.

**Step 4: Run tests and build**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/MediaViewerPresentationTests
xcodebuild -project Jupiter.xcodeproj -scheme Jupiter -destination 'generic/platform=iOS Simulator' build
```

Expected:

- tests PASS
- build SUCCEEDS

**Step 5: Commit**

```bash
git add Jupiter/Views/MediaZoomPagerView.swift Jupiter/Views/MediaViewerPresentation.swift JupiterTests/MediaViewerPresentationTests.swift
git commit -m "fix: re-center media hero and stabilize viewer chrome"
```

---

### Task 3: Replace the heavy metadata drawer with a minimal floating info card

**Files:**
- Modify: `Jupiter/Views/MediaZoomPagerView.swift`
- Modify: `Jupiter/Views/MediaQuickDetailOverlay.swift`
- Modify: `Jupiter/Components/CinematicSurfaceStyle.swift`

**Step 1: Write the failing test**

Add a state-transition test to `JupiterTests/MediaViewerPresentationTests.swift`:

```swift
func testMetadataOpenStateUsesPhotoFirstDismissBehavior() {
    XCTAssertTrue(
        MediaViewerPresentation.photoDragShouldCollapseMetadata(
            translationY: 120,
            metadataState: .medium
        )
    )

    XCTAssertFalse(
        MediaViewerPresentation.photoDragShouldCollapseMetadata(
            translationY: 120,
            metadataState: .collapsed
        )
    )
}
```

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/MediaViewerPresentationTests/testMetadataOpenStateUsesPhotoFirstDismissBehavior
```

Expected: FAIL because the helper does not exist yet.

**Step 3: Write minimal implementation**

Add the smallest pure helper to `Jupiter/Views/MediaViewerPresentation.swift`:

```swift
static func photoDragShouldCollapseMetadata(
    translationY: CGFloat,
    metadataState: ViewerMetadataState
) -> Bool { ... }
```

Then refactor `Jupiter/Views/MediaZoomPagerView.swift` so that:

- metadata is shown only when the user taps the info button
- metadata appears as a floating bottom card, not a default persistent drawer
- the floating card uses solid warm-white material and matched corner/shadow tokens
- the hero image shifts only slightly when metadata is open
- downward photo drag collapses metadata before closing the whole viewer
- close and info buttons remain visible and visually matched

Use `Jupiter/Views/MediaQuickDetailOverlay.swift` only if shared metadata card content should be extracted there. Avoid unnecessary new abstractions.

**Step 4: Run tests and build**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/MediaViewerPresentationTests
xcodebuild -project Jupiter.xcodeproj -scheme Jupiter -destination 'generic/platform=iOS Simulator' build
```

Expected:

- tests PASS
- build SUCCEEDS

**Step 5: Commit**

```bash
git add Jupiter/Views/MediaZoomPagerView.swift Jupiter/Views/MediaQuickDetailOverlay.swift Jupiter/Components/CinematicSurfaceStyle.swift Jupiter/Views/MediaViewerPresentation.swift JupiterTests/MediaViewerPresentationTests.swift
git commit -m "feat: add minimal floating metadata card to viewer"
```

---

### Task 4: Refine viewer motion so it feels photo-first and premium

**Files:**
- Modify: `Jupiter/Views/MediaZoomPagerView.swift`
- Modify: `Jupiter/Views/MediaViewerPresentation.swift`

**Step 1: Write the failing test**

Add one more motion rule assertion:

```swift
func testDragProgressNeverMovesAtmosphereLayer() {
    XCTAssertEqual(
        MediaViewerPresentation.atmosphereOffset(for: CGSize(width: 0, height: 180)),
        .zero
    )
}
```

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/MediaViewerPresentationTests/testDragProgressNeverMovesAtmosphereLayer
```

Expected: FAIL because `atmosphereOffset` does not exist yet.

**Step 3: Write minimal implementation**

Update `Jupiter/Views/MediaViewerPresentation.swift` with motion helpers:

```swift
static func atmosphereOffset(for dragOffset: CGSize) -> CGSize {
    .zero
}
```

Then refine `Jupiter/Views/MediaZoomPagerView.swift`:

- opening transition: hero settles first, chrome fades in slightly after
- closing transition: chrome fades before hero returns
- paging uses the existing soft slide + fade but with shorter travel distance
- vertical drag changes only hero position/scale and chrome opacity
- atmosphere responds only via blur/opacity, never position
- metadata card entrance/exit uses a short, calm spring

This task is about motion tuning, not structure changes.

**Step 4: Run tests and build**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/MediaViewerPresentationTests
xcodebuild -project Jupiter.xcodeproj -scheme Jupiter -destination 'generic/platform=iOS Simulator' build
```

Expected:

- tests PASS
- build SUCCEEDS

**Step 5: Commit**

```bash
git add Jupiter/Views/MediaZoomPagerView.swift Jupiter/Views/MediaViewerPresentation.swift JupiterTests/MediaViewerPresentationTests.swift
git commit -m "refactor: tune premium media viewer motion"
```

---

### Task 5: Capture manual regression checkpoints for the refined viewer

**Files:**
- Modify: `specs/001-media-detail-interaction-polish/manual-regression-template.md`
- Modify: `CHANGELOG.md`

**Step 1: Write the failing checklist**

Add explicit pass/fail rows for:

- hero visual centering
- symmetric close/info button placement
- fixed atmosphere backdrop
- metadata open/close priority
- continuous next/previous paging
- premium motion feel on open and close

Treat missing checklist rows as failure.

**Step 2: Run documentation review**

Read the updated checklist and changelog to confirm the new viewer standard is represented.

Expected: both files mention the refined viewer goals and manual verification points.

**Step 3: Write minimal implementation**

Update:

- `specs/001-media-detail-interaction-polish/manual-regression-template.md`
- `CHANGELOG.md`

Add only the rows needed to cover the refined viewer quality bar.

**Step 4: Sanity-check build and tests**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/MediaViewerPresentationTests -only-testing:JupiterTests/DownloadAccessViewModelTests -only-testing:JupiterTests/FeedPresentationTests
xcodebuild -project Jupiter.xcodeproj -scheme Jupiter -destination 'generic/platform=iOS Simulator' build
```

Expected:

- tests PASS
- build SUCCEEDS

**Step 5: Commit**

```bash
git add specs/001-media-detail-interaction-polish/manual-regression-template.md CHANGELOG.md
git commit -m "docs: capture premium viewer regression checks"
```
