# Premium Cinematic Polish Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refine Jupiter into a cohesive light-cinematic photo product led by a rebuilt media detail viewer and followed by aligned home, album, settings, and paywall surfaces.

**Architecture:** Keep the current SwiftUI app structure, but extract the most fragile presentation rules into small testable helpers before changing view layouts. Rebuild the media viewer as the source of truth for motion and chrome, then apply the same tokens and surface rules to feed, albums, and utility screens.

**Tech Stack:** SwiftUI, Swift 5, XCTest, Kingfisher, StoreKit, existing MVVM view models

---

### Task 1: Establish shared cinematic presentation tokens

**Files:**
- Create: `Jupiter/Components/CinematicSurfaceStyle.swift`
- Create: `JupiterTests/CinematicSurfaceStyleTests.swift`
- Modify: `Jupiter/Components/FloatingCapsuleButton.swift`
- Modify: `Jupiter/Views/MediaFeedView.swift`
- Modify: `Jupiter/Views/AlbumListView.swift`

**Step 1: Write the failing test**

Create `JupiterTests/CinematicSurfaceStyleTests.swift` with focused assertions around shared token values and state styling:

```swift
import XCTest
@testable import Jupiter

final class CinematicSurfaceStyleTests: XCTestCase {
    func testFloatingControlUsesExpectedCornerRadiusAndShadow() {
        let style = CinematicSurfaceStyle.floatingControl
        XCTAssertEqual(style.cornerRadius, 22)
        XCTAssertEqual(style.horizontalPadding, 14)
        XCTAssertEqual(style.verticalPadding, 10)
        XCTAssertEqual(style.shadowRadius, 10)
    }

    func testSelectedTabHasStrongerForegroundAndFill() {
        let style = CinematicSurfaceStyle.tab(selected: true)
        XCTAssertGreaterThan(style.foregroundOpacity, 0.85)
        XCTAssertGreaterThan(style.fillOpacity, 0.75)
    }
}
```

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:JupiterTests/CinematicSurfaceStyleTests
```

Expected: FAIL because `CinematicSurfaceStyle` and the new test file references do not exist yet.

**Step 3: Write minimal implementation**

Create `Jupiter/Components/CinematicSurfaceStyle.swift` with small, pure style containers:

```swift
import CoreGraphics

struct CinematicSurfaceStyle: Equatable {
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let shadowRadius: CGFloat
    let foregroundOpacity: Double
    let fillOpacity: Double

    static let floatingControl = CinematicSurfaceStyle(
        cornerRadius: 22,
        horizontalPadding: 14,
        verticalPadding: 10,
        shadowRadius: 10,
        foregroundOpacity: 0.88,
        fillOpacity: 0.82
    )

    static func tab(selected: Bool) -> CinematicSurfaceStyle {
        CinematicSurfaceStyle(
            cornerRadius: 20,
            horizontalPadding: 14,
            verticalPadding: 8,
            shadowRadius: 8,
            foregroundOpacity: selected ? 0.9 : 0.52,
            fillOpacity: selected ? 0.88 : 0
        )
    }
}
```

Then update `Jupiter/Components/FloatingCapsuleButton.swift`, `Jupiter/Views/MediaFeedView.swift`, and `Jupiter/Views/AlbumListView.swift` to consume these tokens instead of embedding one-off paddings, fills, and opacity values.

**Step 4: Run test to verify it passes**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:JupiterTests/CinematicSurfaceStyleTests
```

Expected: PASS.

**Step 5: Commit**

```bash
git add Jupiter/Components/CinematicSurfaceStyle.swift Jupiter/Components/FloatingCapsuleButton.swift Jupiter/Views/MediaFeedView.swift Jupiter/Views/AlbumListView.swift JupiterTests/CinematicSurfaceStyleTests.swift
git commit -m "feat: add shared cinematic surface tokens"
```

---

### Task 2: Extract viewer presentation rules and lock them with tests

**Files:**
- Create: `Jupiter/Views/MediaViewerPresentation.swift`
- Create: `JupiterTests/MediaViewerPresentationTests.swift`
- Modify: `Jupiter/Views/MediaZoomPagerView.swift`

**Step 1: Write the failing test**

Create `JupiterTests/MediaViewerPresentationTests.swift` to cover the logic that currently lives inline in the view:

```swift
import XCTest
@testable import Jupiter

final class MediaViewerPresentationTests: XCTestCase {
    func testAspectFitRectCentersPortraitImage() {
        let rect = MediaViewerPresentation.aspectFitRect(
            imageSize: CGSize(width: 724, height: 1086),
            containerSize: CGSize(width: 393, height: 852)
        )

        XCTAssertEqual(rect.midX, 196.5, accuracy: 0.5)
        XCTAssertEqual(rect.midY, 426, accuracy: 0.5)
    }

    func testDismissDragRequiresDownwardMotionAndCollapsedMetadata() {
        XCTAssertTrue(MediaViewerPresentation.shouldDismissPhoto(
            translationY: 130,
            predictedTranslationY: 260,
            zoomScale: 1,
            metadataState: .collapsed
        ))

        XCTAssertFalse(MediaViewerPresentation.shouldDismissPhoto(
            translationY: 130,
            predictedTranslationY: 260,
            zoomScale: 1,
            metadataState: .medium
        ))
    }
}
```

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:JupiterTests/MediaViewerPresentationTests
```

Expected: FAIL because `MediaViewerPresentation` does not exist yet.

**Step 3: Write minimal implementation**

Create `Jupiter/Views/MediaViewerPresentation.swift` with pure helpers:

```swift
import CoreGraphics

enum ViewerMetadataState {
    case collapsed
    case medium
    case expanded
}

enum MediaViewerPresentation {
    static func aspectFitRect(imageSize: CGSize, containerSize: CGSize) -> CGRect { ... }

    static func shouldDismissPhoto(
        translationY: CGFloat,
        predictedTranslationY: CGFloat,
        zoomScale: CGFloat,
        metadataState: ViewerMetadataState
    ) -> Bool { ... }

    static func chromeTopPadding(safeTopInset: CGFloat) -> CGFloat { ... }
}
```

Update `Jupiter/Views/MediaZoomPagerView.swift` to use these helpers rather than duplicating layout and dismiss logic inline.

**Step 4: Run test to verify it passes**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:JupiterTests/MediaViewerPresentationTests
```

Expected: PASS.

**Step 5: Commit**

```bash
git add Jupiter/Views/MediaViewerPresentation.swift Jupiter/Views/MediaZoomPagerView.swift JupiterTests/MediaViewerPresentationTests.swift
git commit -m "test: lock media viewer presentation rules"
```

---

### Task 3: Rebuild the media detail viewer around the new cinematic rules

**Files:**
- Modify: `Jupiter/Views/MediaZoomPagerView.swift`
- Modify: `Jupiter/Components/ZoomableImageView.swift`
- Modify: `Jupiter/Components/RemoteImage.swift`
- Modify: `Jupiter/Views/MediaQuickDetailOverlay.swift`

**Step 1: Write the failing test**

Add one more assertion to `JupiterTests/MediaViewerPresentationTests.swift` for paging and metadata interaction:

```swift
func testHorizontalPagingProducesDirectionalOffsets() {
    XCTAssertEqual(MediaViewerPresentation.pageOffsets(direction: .next, width: 393).outbound, -393, accuracy: 0.1)
    XCTAssertEqual(MediaViewerPresentation.pageOffsets(direction: .previous, width: 393).outbound, 393, accuracy: 0.1)
}
```

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:JupiterTests/MediaViewerPresentationTests/testHorizontalPagingProducesDirectionalOffsets
```

Expected: FAIL because `pageOffsets` is not implemented yet.

**Step 3: Write minimal implementation**

Refactor `Jupiter/Views/MediaZoomPagerView.swift` to match the approved design:

- move the photo only, never the entire fullscreen surface
- keep the blurred photo atmosphere fixed behind the hero image
- unify close and metadata buttons to identical size and placement rules
- allow `single tap -> toggle chrome`
- make `metadata collapsed -> drag closes viewer`
- make `metadata open -> drag collapses metadata first`
- replace the current hard page slide with a softer slide-plus-fade transition
- ensure the photo remains truly centered independent of safe area chrome

Use the helper APIs from `MediaViewerPresentation.swift` instead of spreading layout math through the view body.

**Step 4: Run tests and build**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:JupiterTests/MediaViewerPresentationTests
xcodebuild -project Jupiter.xcodeproj -scheme Jupiter -destination 'generic/platform=iOS Simulator' build
```

Expected:

- tests PASS
- app build SUCCEEDS

**Step 5: Commit**

```bash
git add Jupiter/Views/MediaZoomPagerView.swift Jupiter/Components/ZoomableImageView.swift Jupiter/Components/RemoteImage.swift Jupiter/Views/MediaQuickDetailOverlay.swift Jupiter/Views/MediaViewerPresentation.swift JupiterTests/MediaViewerPresentationTests.swift
git commit -m "feat: rebuild media viewer with cinematic motion"
```

---

### Task 4: Bring home and album surfaces into the same design system

**Files:**
- Modify: `Jupiter/Views/MediaFeedView.swift`
- Modify: `Jupiter/Views/AlbumListView.swift`
- Modify: `Jupiter/Components/AlbumCard.swift`
- Modify: `Jupiter/Views/AlbumDetailView.swift`
- Modify: `Jupiter/Views/RootTabView.swift`

**Step 1: Write the failing test**

Create a small regression test for date-title and category presentation decisions in `JupiterTests/FeedPresentationTests.swift`:

```swift
import XCTest
@testable import Jupiter

final class FeedPresentationTests: XCTestCase {
    func testCurrentYearUsesShortDateTitle() {
        let title = FeedPresentation.formattedSectionTitle(
            from: "2026-04-02T11:22:33.000Z",
            now: ISO8601DateFormatter().date(from: "2026-04-10T00:00:00Z")!
        )
        XCTAssertEqual(title, "Apr 02")
    }
}
```

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:JupiterTests/FeedPresentationTests
```

Expected: FAIL because `FeedPresentation` does not exist yet.

**Step 3: Write minimal implementation**

Extract simple feed presentation helpers and update the screens to use shared cinematic rules:

- tighten the sticky category strip and floating controls into one coherent visual family
- make album cards feel more like collection covers than generic content cards
- keep the home feed denser, while album screens keep slightly more breathing room
- refine empty, error, skeleton, and no-more states to match the approved tone
- keep the root section transition subtle and consistent with the viewer motion language

If needed, add `Jupiter/Views/FeedPresentation.swift` to host date-title formatting and state-copy helpers.

**Step 4: Run tests and build**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:JupiterTests/FeedPresentationTests
xcodebuild -project Jupiter.xcodeproj -scheme Jupiter -destination 'generic/platform=iOS Simulator' build
```

Expected:

- tests PASS
- app build SUCCEEDS

**Step 5: Commit**

```bash
git add Jupiter/Views/MediaFeedView.swift Jupiter/Views/AlbumListView.swift Jupiter/Components/AlbumCard.swift Jupiter/Views/AlbumDetailView.swift Jupiter/Views/RootTabView.swift Jupiter/Views/FeedPresentation.swift JupiterTests/FeedPresentationTests.swift
git commit -m "feat: unify feed and album presentation"
```

---

### Task 5: Polish settings, about sheet, paywall, and product copy

**Files:**
- Modify: `Jupiter/Views/MediaFeedView.swift`
- Modify: `Jupiter/Views/DownloadPaywallView.swift`
- Modify: `Jupiter/Localizable.xcstrings`
- Modify: `Jupiter/ja.lproj/InfoPlist.strings`
- Modify: `Jupiter/zh-Hans.lproj/InfoPlist.strings`

**Step 1: Write the failing test**

Add a unit test for paywall CTA title formatting to `JupiterTests/DownloadAccessViewModelTests.swift`:

```swift
import XCTest
@testable import Jupiter

final class DownloadAccessViewModelTests: XCTestCase {
    @MainActor
    func testPurchaseButtonTitleFallsBackToOneTimePurchase() {
        let viewModel = DownloadAccessViewModel(productId: "test.product")
        XCTAssertEqual(viewModel.purchaseButtonTitle, "One-time purchase")
    }
}
```

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:JupiterTests/DownloadAccessViewModelTests
```

Expected: FAIL because the test file does not exist yet.

**Step 3: Write minimal implementation**

Refine `Jupiter/Views/MediaFeedView.swift` and `Jupiter/Views/DownloadPaywallView.swift` so the support and purchase surfaces match the cinematic system:

- make the about sheet feel like product information, not a default utility list
- align paywall feature cards, CTA area, and background treatment with the new light-cinematic palette
- ensure copy and localization keys are consistent across English, Simplified Chinese, and Japanese
- keep entitlement messaging short, clear, and tonally aligned

Add `JupiterTests/DownloadAccessViewModelTests.swift` for the fallback CTA title and any other pure display logic worth locking.

**Step 4: Run tests and build**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:JupiterTests/DownloadAccessViewModelTests
xcodebuild -project Jupiter.xcodeproj -scheme Jupiter -destination 'generic/platform=iOS Simulator' build
```

Expected:

- tests PASS
- app build SUCCEEDS

**Step 5: Commit**

```bash
git add Jupiter/Views/MediaFeedView.swift Jupiter/Views/DownloadPaywallView.swift Jupiter/Localizable.xcstrings Jupiter/ja.lproj/InfoPlist.strings Jupiter/zh-Hans.lproj/InfoPlist.strings JupiterTests/DownloadAccessViewModelTests.swift
git commit -m "feat: polish settings and paywall surfaces"
```

---

### Task 6: Verify the full polish pass and capture regression coverage

**Files:**
- Modify: `specs/001-media-detail-interaction-polish/manual-regression-template.md`
- Modify: `CHANGELOG.md`

**Step 1: Write the failing checklist**

Update `specs/001-media-detail-interaction-polish/manual-regression-template.md` with concrete pass/fail checkpoints for:

- media viewer centering
- metadata card states
- paging continuity
- home feed sticky controls
- album list tap-through and refresh
- paywall and settings flow

Treat missing checklist rows as the failure condition.

**Step 2: Run verification to show current gaps**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: PASS on unit tests, with manual regression items still requiring completion in simulator and on device.

**Step 3: Write minimal implementation**

- add a concise changelog entry summarizing the polish pass
- update the regression template so the release check has a stable checklist

**Step 4: Run final verification**

Run:

```bash
xcodebuild test -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild -project Jupiter.xcodeproj -scheme Jupiter -destination 'generic/platform=iOS Simulator' build
```

Expected:

- all automated tests PASS
- final build SUCCEEDS

Then complete manual checks using:

`specs/001-media-detail-interaction-polish/manual-regression-template.md`

**Step 5: Commit**

```bash
git add specs/001-media-detail-interaction-polish/manual-regression-template.md CHANGELOG.md
git commit -m "docs: add premium polish regression checklist"
```

---

## Notes for Execution

- Keep the photo as the strongest visual element in every task.
- Do not introduce additional backend dependencies.
- Do not let page-level styling regress safe-area coverage or paging stability.
- Prefer extracting pure helpers when a layout rule needs to be tested.
- Re-run the media viewer regression flow after every task that touches fullscreen presentation.
