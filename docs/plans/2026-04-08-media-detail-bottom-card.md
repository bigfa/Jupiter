# Media Detail Bottom Card Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将照片详情 metadata 从 sheet 改成贴底白色说明卡，并重新平衡照片与卡片的版式关系。

**Architecture:** 保留现有 `MediaZoomPagerView` 的稳定图片预览和左右切图逻辑，只在详情页内部引入自定义底部白卡。版式规则放在 presentation helpers 里，用测试锁住照片画布与卡片高度策略；metadata 详情请求仍由 `MediaService` 提供。

**Tech Stack:** SwiftUI, XCTest, async/await, Kingfisher

---

### Task 1: 写入版式规则测试

**Files:**
- Modify: `/Users/rich/Projects/Jupiter/JupiterTests/MediaViewerPresentationTests.swift`
- Modify: `/Users/rich/Projects/Jupiter/JupiterTests/MediaMetadataPresentationTests.swift`

**Step 1: Write the failing test**
- 为 viewer metadata 打开状态补一条“照片底部需要为白卡和呼吸区预留空间”的断言。
- 为 metadata viewer 卡片补一条“默认高度走 28% 屏高策略”的断言。

**Step 2: Run test to verify it fails**
Run: `xcodebuild test -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/MediaViewerPresentationTests -only-testing:JupiterTests/MediaMetadataPresentationTests`
Expected: FAIL on the new assertions.

**Step 3: Write minimal implementation**
- 在 presentation helpers 中加入 viewer card height / photo inset rule。

**Step 4: Run test to verify it passes**
Run the same command and expect PASS.

### Task 2: 接入底部白卡

**Files:**
- Modify: `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift`
- Reuse: `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaQuickDetailOverlay.swift`

**Step 1: Write the failing test**
- 以 helper 测试形式确保 metadata 开启时照片位置不是 full screen 填充。

**Step 2: Run test to verify it fails**
Run targeted viewer tests.

**Step 3: Write minimal implementation**
- 将 `showMetadata` 从 `.sheet` 改为详情页内的底部白卡。
- 让照片使用 helper 计算后的画布位置。
- 打开 metadata 时请求详情并展示卡片内容。
- 卡片右上角保留轻量点赞入口。

**Step 4: Run test to verify it passes**
Run viewer + metadata tests.

### Task 3: 验证与收尾

**Files:**
- Modify only if needed: `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift`

**Step 1: Build**
Run: `xcodebuild -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj -scheme Jupiter -destination 'generic/platform=iOS Simulator' build`
Expected: `BUILD SUCCEEDED`

**Step 2: Final targeted tests**
Run: `xcodebuild test -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/MediaViewerPresentationTests -only-testing:JupiterTests/MediaMetadataPresentationTests -only-testing:JupiterTests/MediaItemDetailMergeTests`
Expected: `TEST SUCCEEDED`
