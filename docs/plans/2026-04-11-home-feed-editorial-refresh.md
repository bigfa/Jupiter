# Home Feed Editorial Refresh Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 用更轻的 editorial 编排和统一的暖白 cinematic 表面语言重构首页瀑布流，让它和 about、paywall、相册列表属于同一设计系统。

**Architecture:** 先把首页分组 header 和空状态文案抽到 `MediaFeedPresentation` 中做成可测试 helper，再分别修改 `MediaFeedView` 的 section shell 和 `MediaMasonryCard` 的照片卡片外观。数据流、分页和全屏查看逻辑保持不变。

**Tech Stack:** SwiftUI, XCTest, Kingfisher-backed `LazyRemoteImage`

---

### Task 1: 锁定首页展示层规则

**Files:**
- Create: `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaFeedPresentation.swift`
- Create: `/Users/rich/Projects/Jupiter/JupiterTests/MediaFeedPresentationTests.swift`

**Step 1: Write the failing test**

为首页 section header 和空状态写失败测试：

- 日期分组 header 返回 `档案 + 大标题 + 张数 caption`
- 热门排序 header 返回 `热度排序 + 热门照片`
- 空状态在全部分类和单个分类下返回一致的暖白文案

**Step 2: Run test to verify it fails**

```bash
xcodebuild test -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj \
  -scheme Jupiter \
  -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' \
  -only-testing:JupiterTests/MediaFeedPresentationTests
```

Expected: FAIL because the helper does not exist yet.

**Step 3: Write minimal implementation**

在 `MediaFeedPresentation.swift` 中补最小展示模型和 helper，让测试先变绿。

**Step 4: Run test to verify it passes**

重复上面的测试命令，预期 `TEST SUCCEEDED`。

### Task 2: 改首页 section shell 和 surrounding surfaces

**Files:**
- Modify: `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaFeedView.swift`

**Step 1: Add editorial section header**

- 日期排序时使用新的 editorial header
- 热门排序时给瀑布流补一个单独的 header

**Step 2: Align surrounding surfaces**

- 添加暖白背景
- 分类栏改成奶油胶囊风格
- 空状态、错误态、骨架屏、到底文案统一视觉和语气

**Step 3: Preserve behaviors**

确认刷新、筛选、分页、全屏打开、sort 切换滚回顶部等行为不变。

### Task 3: 改首页真实照片卡片路径

**Files:**
- Modify: `/Users/rich/Projects/Jupiter/Jupiter/Components/MediaMasonryCard.swift`
- Modify: `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaFeedView.swift`

**Step 1: Introduce feed-only card chrome**

- 给首页瀑布流卡片增加轻量 editorial 外观
- 保持 album detail 使用原有更轻的 plain 卡片样式，避免意外联动

**Step 2: Add likes badge polish**

- 将 likes 改成暖白胶囊
- 保证小尺寸卡片上仍然可读

### Task 4: 验证

**Files:**
- Verify only

**Step 1: Run focused tests**

```bash
xcodebuild test -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj \
  -scheme Jupiter \
  -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' \
  -only-testing:JupiterTests/MediaFeedPresentationTests
```

**Step 2: Run full build**

```bash
xcodebuild build -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj \
  -scheme Jupiter \
  -destination 'generic/platform=iOS Simulator'
```

Expected: both commands succeed.
