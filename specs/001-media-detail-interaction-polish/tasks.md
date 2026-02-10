---

description: "Task list for 媒体详情交互收尾优化"
---

# Tasks: 媒体详情交互收尾优化

**Input**: Design documents from `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/`
**Prerequisites**: `spec.md`, `plan.md`

**Tests**: 本特性要求包含测试任务（`xcodebuild test` + ViewModel 单测）。

**Organization**: 任务按用户故事分组，保证每个故事可独立实现与验收。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 可并行执行（不同文件、无直接依赖）
- **[Story]**: 所属用户故事（US1/US2/US3）
- **[manual]**: 需要人工操作（截图、真机验证等），AI agent 无法独立完成
- 每条任务包含明确文件路径

## Phase 0: Setup (Shared Infrastructure)

**Purpose**: 对齐实现边界与验收基线

- [x] T001 建立手工验收清单文件骨架与全局条目到 `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/quickstart.md`（包含 US1~US3 章节标题与通用前置条件，各故事细节由 T010/T020/T025 填充）
- [ ] T002 [manual] 记录基线问题截图与复现条件（模拟器 + 真机）到 `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/quickstart.md`

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: 完成所有用户故事共享的基础改造

**⚠️ CRITICAL**: 本阶段完成前不进入故事级交付

- [x] T003 统一在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 中向子视图传递 `safeTopInset/safeBottomInset`
- [x] T004 [P] 规范抽屉高度模型（内容高度 vs 容器高度）于 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift`
- [x] T005 [P] 规范抽屉层级与命中策略（抽屉、图片、关闭按钮）于 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift`

**Checkpoint**: 安全区与层级模型稳定，可进入 US1/US2/US3

---

## Phase 2: User Story 1 - 抽屉贴底与安全区一致 (Priority: P1) 🎯 MVP

**Goal**: 抽屉三态都与屏幕底边连续贴合，无白边/缝隙
**Independent Test**: 打开详情页并拖拽抽屉至折叠、中间、全开，底部连续无断层

### Tests for User Story 1

- [x] T010 [US1] 在 `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/quickstart.md` 的 US1 章节填写 Given/When/Then 手工验收步骤

### Implementation for User Story 1

- [x] T011 [US1] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 为 `MetadataDrawer` 增加底部 inset 补偿并贴底渲染
  > 已实现：`.padding(.bottom, bottomInset)` + `.frame(height: currentHeight + bottomInset)` + `.ignoresSafeArea(edges: .bottom)`
- [x] T012 [US1] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 使用顶部圆角、底部零圆角裁剪抽屉外观
  > 已实现：`UnevenRoundedRectangle(cornerRadii: .init(topLeading: 22, bottomLeading: 0, bottomTrailing: 0, topTrailing: 22))`
- [x] T013 [US1] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 校正三段锚点计算，避免因 inset 叠加产生视觉错位
  > 已实现：锚点基于内容高度（`collapsedHeight/mediumHeight/expandedHeight`），`bottomInset` 在容器层独立叠加
- [x] T014 [US1] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 覆盖 `bottomInset == 0` 设备的兜底行为

**Checkpoint**: US1 可独立验收通过

---

## Phase 3: User Story 2 - 顶部关闭按钮可见且不遮挡 (Priority: P2)

**Goal**: 关闭按钮在不同安全区机型都完整可见、可点击、不卡层
**Independent Test**: 在有/无灵动岛设备验证按钮位置、层级与点击

### Tests for User Story 2

- [x] T020 [US2] 在 `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/quickstart.md` 的 US2 章节填写机型与场景验收步骤

### Implementation for User Story 2

- [x] T021 [US2] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 将关闭按钮位置改为父级安全区驱动并下移
  > 已实现：`.padding(.top, max(safeTopInset, 24) + 20)`，`safeTopInset` 由父容器 `GeometryReader` 传入
- [x] T022 [US2] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 提升关闭按钮层级，确保动画过程中不被遮挡
  > 已实现：`.zIndex(10)`
- [x] T023 [US2] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 复核拖拽期间 `allowsHitTesting` 对关闭按钮的影响
  > 已实现：关闭按钮 `.allowsHitTesting(!isDragging)`，仅在垂直拖拽进行中禁用

**Checkpoint**: US2 可独立验收通过

---

## Phase 4: User Story 3 - 点赞操作有反馈且可诊断 (Priority: P3)

**Goal**: 点赞成功/失败都有明确反馈，切图后状态不串
**Independent Test**: 成功与失败网络场景下连续点击心形，验证状态变化与错误提示

### Tests for User Story 3

- [x] T025 [US3] 在 `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/quickstart.md` 的 US3 章节填写成功/失败场景手工验收步骤
- [x] T030 [P] [US3] 在 `/Users/rich/Projects/Jupiter/JupiterTests/MediaLikeViewModelTests.swift` 覆盖 toggle 成功、失败与 load 失败场景
- [x] T031 [P] [US3] 在 `/Users/rich/Projects/Jupiter/JupiterTests/APIClientTests.swift` 保持点赞请求 body/header 断言稳定

### Implementation for User Story 3

- [x] T032 [US3] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaLikeViewModel.swift` 维护 `errorMessage` 与 `latestRequestID` 回写保护
  > 已实现：`@Published private(set) var errorMessage: String?` + `private var latestRequestID = UUID()`，`load()`/`toggle()` 均校验 requestID
- [x] T033 [US3] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 为点赞按钮增加 loading、disable 与错误文案展示
  > 已实现：`ProgressView` loading 态 + `.disabled(isLoading)` + `Text(message).foregroundStyle(.red)` 错误展示
- [x] T034 [US3] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 在 `item.id` 切换时重置点赞错误态并重新加载
  > 已实现：`.task(id: item?.id)` 触发重建 ViewModel + `vm.clearError()` + `await vm.load()`
- [x] T035 [US3] 在 `/Users/rich/Projects/Jupiter/Jupiter/Services/MediaService.swift` 保持可注入 `APIClient` 以支持测试替身
  > 已实现：`MediaService(client: APIClient = .shared)` + `MediaLikeViewModel(mediaId:service:)` 便利构造器

**Checkpoint**: US3 可独立验收通过

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: 统一回归验证并收敛交付风险

- [x] T040 执行 `xcodebuild -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,name=iPhone 16' build`
- [x] T041 执行 `xcodebuild -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,name=iPhone 16' test`
- [ ] T042 [manual] 按 `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/quickstart.md` 完成 US1~US3 手工回归
- [x] T043 更新 `/Users/rich/Projects/Jupiter/CHANGELOG.md` 记录本特性交付条目

---

## Phase 6: Code Review Fixes

**Purpose**: 修复 Code Review 发现的 Bug 与改进项

**⚠️ BUG**: T050 为阻塞性问题，点赞按钮 UI 可能不会实时更新

### Bug Fix

- [x] T050 [US3] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaLikeViewModel.swift` 将 `MediaLikeViewModel` 从 `ObservableObject` 迁移至 `@Observable` 宏，并移除 `@Published` 属性包装器和 `ObservableObject` 协议。同步更新 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 中 `MetadataDrawer` 的 `@State private var likeViewModel` 声明（无需改为 `@StateObject`，`@Observable` + `@State` 即可正确工作）
  > 原因：当前 `@State` 持有 `ObservableObject` 不会订阅 `objectWillChange`，`@Published` 属性变化不触发视图重绘

### Improvements

- [x] T051 [P] 提取 `/Users/rich/Projects/Jupiter/JupiterTests/Helpers/URLProtocolStub.swift` 共享测试辅助类，替换 `APIClientTests.swift` 和 `MediaLikeViewModelTests.swift` 中的重复 `URLProtocolStub` / `MediaLikeURLProtocolStub`
- [x] T052 [P] [US3] 在 `/Users/rich/Projects/Jupiter/JupiterTests/MediaLikeViewModelTests.swift` 补充 `latestRequestID` 并发竞态测试：连续调用两次 `load()`，验证慢返回的第一次结果被丢弃
- [x] T053 [US3] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 的 `.task(id: item?.id)` 中移除多余的 `vm.clearError()` 调用（`load()` 已内置 `errorMessage = nil`）

**Checkpoint**: 所有 Code Review 问题已修复，`xcodebuild test` 通过

---

## Phase 7: Drag Dismiss & Drawer Scaling Fix

**Purpose**: 修复下拉关闭时背景跟随移动，以及抽屉展开时图片右偏缩放的视觉问题

**⚠️ BUG**: T060 为阻塞性问题，下拉关闭时背景层与图片以不同 offset 分离移动

### Bug Fix

- [x] T060 [US1/US2] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 删除 `.navigationTransition(.zoom(sourceID: transitionId, in: namespace))`（第 87 行）
  > 原因：该 API 为 NavigationStack push 转场设计，当前页面已改用 `fullScreenCover`，但残留的修饰符安装了系统级交互关闭手势，导致整个视图（背景+图片+抽屉）被系统拖动，与自定义 `DragGesture` 的 `dragOffset` 叠加后背景和图片以不同 offset 分离移动

- [x] T061 [US1] ~~在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 将抽屉展开时的图片缩放改为裁切方案~~
  > **已废弃**：`.frame(proxy.size) + .clipped()` 方案导致图片定位完全错误（T065），已回退。仅保留删除 `sheetScale` 和简化 `imageScale` 的部分。

- [x] T065 [US1] **[回归 Bug]** 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 回退 T061 的 `.frame() + .clipped()` 方案，恢复原始定位链：
  ```
  .frame(width: imageRect.width, height: imageRect.height)
  .position(x: imageRect.midX, y: imageRect.midY)
  .offset(x: dragOffset.width, y: dragOffset.height + imageOffsetY)
  .scaleEffect(imageScale)  // 仅 1.0 - dragProgress * 0.08
  ```
  > 原因：`.frame(proxy.size)` 插入在 `.position()` 和 ZStack 之间，将 `.position()` 的坐标空间从 ZStack 全屏尺寸（852pt，含 `.ignoresSafeArea()`）改为 GeometryReader 安全区内尺寸（759pt）。`imageRect.midY` 基于 `proxy.size` 计算，在缩小的坐标系中被 `.bottom` 对齐额外下移 93px；`fullScreenCover` 呈现动画期间 `proxy.size` 从 0 过渡到最终值时，`.frame(0, 0)` 把图片约束在零尺寸区域，导致部分图片只能看到一角、部分完全不可见

### Verification

- [x] T062 执行 `xcodebuild build` 确认编译通过（T065 回退后需重新验证）
- [ ] T063 [manual] 验证：下拉图片时仅图片移动，背景层静止不动
- [ ] T064 [manual] 验证：抽屉三态展开时图片两侧始终贴边，无右偏
- [ ] T066 [manual] 验证：点击查看大图时所有图片定位正确，无错位或不可见

**Checkpoint**: 下拉关闭与抽屉展开视觉问题修复

---

## Phase 8: Swipe Paging & Metadata Decode Fix

**Purpose**: 修复左右翻页手势冲突与 Metadata EXIF 字段解码失败

**⚠️ BUG**: T070 为阻塞性问题，左右滑动翻页完全失效

### Bug Fix

- [x] T070 [P] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 删除自定义手势中的水平滑动处理：
  1. 删除 `MediaZoomDetailPage` 的 `onHorizontalSwipe` 回调参数
  2. 删除 DragGesture `.onEnded` 中 `axis == .horizontal` 分支（调用 `onHorizontalSwipe` 的代码）
  3. 删除 `MediaZoomPagerView` 的 `handleHorizontalSwipe` 方法
  4. 删除 `SwipeDirection` 枚举
  > 原因：TabView `.page` 原生手势与自定义 `DragGesture` 的 `onHorizontalSwipe` 同时更新 `selection`，导致翻页动画冲突、页面不跟随出现、连续滑动后加载顺序错乱

- [x] T071 [P] 在 `/Users/rich/Projects/Jupiter/Jupiter/Models/Media.swift` 移除 `MediaItem` 所有属性的 `= nil` 默认值：
  将 `let filename: String? = nil` 等声明改为 `let filename: String?`（影响 `filename`~`categories` 共 14 个属性）
  > 原因：`let ... = nil` 导致 Swift Codable 自动合成的 `init(from:)` 跳过解码，API 返回的 EXIF 字段全部丢失，抽屉只能显示尺寸和时间

- [x] T072 [P] 更新所有手动创建 `MediaItem` 的调用点（Preview、测试等），补齐移除默认值后的缺省参数

### Verification

- [x] T073 执行 `xcodebuild build` 确认编译通过
- [ ] T074 [manual] 验证：左右滑动翻页流畅，页面跟随出现，连续滑动顺序正确
- [ ] T075 [manual] 验证：抽屉展开后显示相机、光圈、ISO、快门等 EXIF 信息

**Checkpoint**: 翻页手势与 Metadata 解码修复

---

## Dependencies & Execution Order

### Phase Dependencies

- Setup (Phase 0) 无依赖，可立即开始
- Foundational (Phase 1) 依赖 Setup，且阻塞所有用户故事 ✅ 已完成
- User Stories (Phase 2~4) 依赖 Foundational 完成 ✅ 已完成
- Polish (Phase 5) 依赖目标用户故事完成
- Code Review Fixes (Phase 6) 可独立开始，T050 优先级最高
- Drag Dismiss & Scaling Fix (Phase 7) 依赖 Phase 6 完成，T060 优先级最高
- Swipe Paging & Metadata Fix (Phase 8) 可独立开始，T070/T071 可并行（不同文件）

### User Story Dependencies

- US1 (P1): 可在 Phase 1 后立即开始
- US2 (P2): 依赖 Phase 1，可与 US1 并行，但建议在 US1 稳定后落地
- US3 (P3): 依赖 Phase 1，可与 US1/US2 并行

### Within Each User Story

- 测试任务优先于实现任务
- 布局/状态结构调整优先于样式微调
- 故事级验收通过后再进入下一故事收尾

### Parallel Opportunities

- T051 与 T052 可并行（不同文件、不同关注点）
- T050 完成后方可运行 T052 的测试验证

---

## Remaining Work Summary

已完成任务：T001, T003-T005, T010-T014, T020-T023, T025, T030-T035, T040-T041, T043, T050-T053, T060, T062, T065, T070-T073

待办任务（共 7 项）：

| 任务 | 类型 | 优先级 | 说明 |
|------|------|--------|------|
| T074 | manual | P1 | 验证左右翻页流畅 |
| T075 | manual | P1 | 验证抽屉显示 EXIF 信息 |
| T063 | manual | P1 | 验证背景不随图片移动 |
| T064 | manual | P1 | 验证图片两侧贴边无右偏 |
| T066 | manual | P1 | 验证图片定位正确无错位 |
| T002 | manual | P3 | 基线截图 |
| T042 | manual | P1 | 手工回归 |
