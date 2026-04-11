# About Sheet Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 About 页从默认列表样式重构为现代化产品信息页，同时保留现有入口和行为。

**Architecture:** 在现有 `MediaFeedView.swift` 中新增一个轻量的 `AppInfoPresentation` 纯展示层，用于生成 hero、权益卡和辅助链接的文案及结构；SwiftUI about 页改为 `ScrollView + card sections`，继续复用既有 `DownloadAccessViewModel`、Safari sheet 和 paywall。

**Tech Stack:** Swift 5、SwiftUI、XCTest。

---

### Task 1: 为 About 展示规则补失败测试

**Files:**
- Create: `/Users/rich/Projects/Jupiter/JupiterTests/AppInfoPresentationTests.swift`
- Modify: `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaFeedView.swift`

**Step 1: Write the failing test**

- 校验未解锁状态的文案
- 校验已解锁状态的文案
- 校验主要信息卡片顺序

**Step 2: Run test to verify it fails**

Run:
```bash
xcodebuild test -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/AppInfoPresentationTests
```

Expected: FAIL，提示类型或方法缺失。

**Step 3: Write minimal implementation**

- 新增 `AppInfoPresentation`
- 提供权益文案和 about 卡片配置

**Step 4: Run test to verify it passes**

Run 同上。

**Step 5: Commit**

按当前工作树状态决定是否单独提交；若不适合提交，则至少保留清晰 diff。

### Task 2: 重写 About 页布局

**Files:**
- Modify: `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaFeedView.swift`

**Step 1: Write the failing test**

- 通过展示层测试锁定结构后，视图层不再额外补 UI 测试

**Step 2: Write minimal implementation**

- 把 `AppInfoSheet` 从 `List` 改成卡片式 `ScrollView`
- 增加 hero、权益卡、链接卡和底部说明
- 保留 `DownloadPaywallView`、Safari、dismiss 行为

**Step 3: Run build**

Run:
```bash
xcodebuild build -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj -scheme Jupiter -destination 'generic/platform=iOS Simulator'
```

Expected: BUILD SUCCEEDED

### Task 3: 验证

**Files:**
- Verify only

**Step 1: Run targeted tests**

```bash
xcodebuild test -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/AppInfoPresentationTests
```

**Step 2: Run build**

```bash
xcodebuild build -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj -scheme Jupiter -destination 'generic/platform=iOS Simulator'
```

**Step 3: Review result**

- 检查文案状态是否正确
- 检查 about 页是否脱离默认列表观感
