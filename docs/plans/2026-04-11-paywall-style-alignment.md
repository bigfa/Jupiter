# Paywall Style Alignment Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 让下载权益 paywall 的视觉风格和 about 页统一，同时保持现有购买与恢复逻辑不变。

**Architecture:** 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/DownloadPaywallView.swift` 内新增轻量 `DownloadPaywallPresentation` 展示层，用它驱动 hero、权益点和说明文案；SwiftUI 视图改为暖白 cinematic 卡片布局，但继续复用 `DownloadAccessViewModel` 的状态与行为。

**Tech Stack:** Swift 5、SwiftUI、XCTest。

---

### Task 1: 为 paywall 展示层补失败测试

**Files:**
- Create: `/Users/rich/Projects/Jupiter/JupiterTests/DownloadPaywallPresentationTests.swift`
- Modify: `/Users/rich/Projects/Jupiter/Jupiter/Views/DownloadPaywallView.swift`

**Step 1: Write the failing test**

- 校验权益卡顺序
- 校验说明项顺序
- 校验状态 badge 文案

**Step 2: Run test to verify it fails**

Run:
```bash
xcodebuild test -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/DownloadPaywallPresentationTests
```

Expected: FAIL，提示 `DownloadPaywallPresentation` 尚不存在。

**Step 3: Write minimal implementation**

- 新增 `DownloadPaywallPresentation`
- 提供 feature / note / badge 数据

**Step 4: Run test to verify it passes**

Run 同上。

### Task 2: 重写 paywall 视觉层

**Files:**
- Modify: `/Users/rich/Projects/Jupiter/Jupiter/Views/DownloadPaywallView.swift`

**Step 1: Write minimal implementation**

- 改背景为暖白 cinematic
- 改 hero、feature 卡和 notes 卡
- 改底部 CTA 区配色和层次

**Step 2: Run build**

```bash
xcodebuild build -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj -scheme Jupiter -destination 'generic/platform=iOS Simulator'
```

Expected: BUILD SUCCEEDED

### Task 3: 验证

**Files:**
- Verify only

**Step 1: Run targeted tests**

```bash
xcodebuild test -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' -only-testing:JupiterTests/DownloadPaywallPresentationTests -only-testing:JupiterTests/DownloadAccessViewModelTests
```

**Step 2: Run build**

```bash
xcodebuild build -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj -scheme Jupiter -destination 'generic/platform=iOS Simulator'
```

**Step 3: Review result**

- paywall 与 about 页风格一致
- CTA 状态正确
- build 和定向测试都通过
