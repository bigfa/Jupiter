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

- [ ] T001 建立手工验收清单文件骨架与全局条目到 `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/quickstart.md`（包含 US1~US3 章节标题与通用前置条件，各故事细节由 T010/T020/T025 填充）
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

- [ ] T010 [US1] 在 `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/quickstart.md` 的 US1 章节填写 Given/When/Then 手工验收步骤

### Implementation for User Story 1

- [x] T011 [US1] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 为 `MetadataDrawer` 增加底部 inset 补偿并贴底渲染
  > 已实现：`.padding(.bottom, bottomInset)` + `.frame(height: currentHeight + bottomInset)` + `.ignoresSafeArea(edges: .bottom)`
- [x] T012 [US1] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 使用顶部圆角、底部零圆角裁剪抽屉外观
  > 已实现：`UnevenRoundedRectangle(cornerRadii: .init(topLeading: 22, bottomLeading: 0, bottomTrailing: 0, topTrailing: 22))`
- [x] T013 [US1] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 校正三段锚点计算，避免因 inset 叠加产生视觉错位
  > 已实现：锚点基于内容高度（`collapsedHeight/mediumHeight/expandedHeight`），`bottomInset` 在容器层独立叠加
- [ ] T014 [US1] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 覆盖 `bottomInset == 0` 设备的兜底行为

**Checkpoint**: US1 可独立验收通过

---

## Phase 3: User Story 2 - 顶部关闭按钮可见且不遮挡 (Priority: P2)

**Goal**: 关闭按钮在不同安全区机型都完整可见、可点击、不卡层
**Independent Test**: 在有/无灵动岛设备验证按钮位置、层级与点击

### Tests for User Story 2

- [ ] T020 [US2] 在 `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/quickstart.md` 的 US2 章节填写机型与场景验收步骤

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

- [ ] T025 [US3] 在 `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/quickstart.md` 的 US3 章节填写成功/失败场景手工验收步骤
- [ ] T030 [P] [US3] 在 `/Users/rich/Projects/Jupiter/JupiterTests/MediaLikeViewModelTests.swift` 覆盖 toggle 成功、失败与 load 失败场景
- [ ] T031 [P] [US3] 在 `/Users/rich/Projects/Jupiter/JupiterTests/APIClientTests.swift` 保持点赞请求 body/header 断言稳定

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

- [ ] T040 执行 `xcodebuild -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,name=iPhone 16' build`
- [ ] T041 执行 `xcodebuild -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,name=iPhone 16' test`
- [ ] T042 [manual] 按 `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/quickstart.md` 完成 US1~US3 手工回归
- [ ] T043 更新 `/Users/rich/Projects/Jupiter/CHANGELOG.md` 记录本特性交付条目

---

## Dependencies & Execution Order

### Phase Dependencies

- Setup (Phase 0) 无依赖，可立即开始
- Foundational (Phase 1) 依赖 Setup，且阻塞所有用户故事 ✅ 已完成
- User Stories (Phase 2~4) 依赖 Foundational 完成
- Polish (Phase 5) 依赖目标用户故事完成

### User Story Dependencies

- US1 (P1): 可在 Phase 1 后立即开始
- US2 (P2): 依赖 Phase 1，可与 US1 并行，但建议在 US1 稳定后落地
- US3 (P3): 依赖 Phase 1，可与 US1/US2 并行

### Within Each User Story

- 测试任务优先于实现任务
- 布局/状态结构调整优先于样式微调
- 故事级验收通过后再进入下一故事收尾

### Parallel Opportunities

- T030 与 T031 可并行（不同测试文件）

---

## Remaining Work Summary

已完成实现任务：T003-T005, T011-T013, T021-T023, T032-T035（共 12 项）

待办任务（共 11 项）：

| 任务 | 类型 | 说明 |
|------|------|------|
| T001 | 文档 | 验收清单骨架 |
| T002 | manual | 基线截图 |
| T010 | 文档 | US1 验收步骤 |
| T014 | 代码 | bottomInset == 0 兜底 |
| T020 | 文档 | US2 验收步骤 |
| T025 | 文档 | US3 验收步骤 |
| T030 | 测试 | ViewModel 单测 |
| T031 | 测试 | API 请求断言 |
| T040 | 验证 | 构建 |
| T041 | 验证 | 测试 |
| T042 | manual | 手工回归 |
| T043 | 文档 | CHANGELOG |
