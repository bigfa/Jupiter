# Album List Cinematic Refresh Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将相册列表改成与 about / paywall 一致的暖白 cinematic 风格，并把卡片信息改为贴底奶油信息条。

**Architecture:** 在 `AlbumCard` 内新增轻量 presentation helper，先用单元测试锁定展示规则，再重构 `AlbumCard` 和 `AlbumListView` 的视觉层。业务数据和导航逻辑保持不变，只调整展示与容器样式。

**Tech Stack:** SwiftUI, XCTest, Kingfisher-backed `RemoteImage`

---

### Task 1: 锁定相册卡片展示规则

**Files:**
- Modify: `/Users/rich/Projects/Jupiter/Jupiter/Components/AlbumCard.swift`
- Create: `/Users/rich/Projects/Jupiter/JupiterTests/AlbumCardPresentationTests.swift`

**Step 1: Write the failing test**

为副标题回退和元信息顺序写展示层测试：

- 描述为空时回退到分类名称
- 没有描述和分类时回退到默认文案
- 元信息按照片数、喜欢数、保护状态顺序输出

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj \
  -scheme Jupiter \
  -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' \
  -only-testing:JupiterTests/AlbumCardPresentationTests
```

Expected: FAIL because the presentation helper does not exist yet.

**Step 3: Write minimal implementation**

在 `AlbumCard.swift` 中添加 presentation helper 和需要的展示模型，先满足测试。

**Step 4: Run test to verify it passes**

重复上面的 `xcodebuild test` 命令，预期 `TEST SUCCEEDED`。

### Task 2: 重构相册卡片和列表容器

**Files:**
- Modify: `/Users/rich/Projects/Jupiter/Jupiter/Components/AlbumCard.swift`
- Modify: `/Users/rich/Projects/Jupiter/Jupiter/Views/AlbumListView.swift`

**Step 1: Update card shell**

- 将卡片改成“封面图 + 贴底信息条”的上下结构
- 统一圆角、描边、阴影、胶囊信息样式
- 保留受保护标记，但改成暖白体系里的胶囊标签

**Step 2: Update page shell**

- 给列表页加暖白渐变背景
- 优化分类栏的选中态
- 调整骨架屏、空状态、错误态为奶油卡片风格

**Step 3: Sanity-check pagination hooks**

确认 `.task { await viewModel.loadMoreIfNeeded(current: album) }` 等现有分页逻辑不受影响。

### Task 3: 验证

**Files:**
- Verify only

**Step 1: Run focused tests**

```bash
xcodebuild test -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj \
  -scheme Jupiter \
  -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' \
  -only-testing:JupiterTests/AlbumCardPresentationTests
```

**Step 2: Run full build**

```bash
xcodebuild build -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj \
  -scheme Jupiter \
  -destination 'generic/platform=iOS Simulator'
```

Expected: both commands succeed.
