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
- 每条任务包含明确文件路径

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: 对齐实现边界与验收基线

- [ ] T001 建立手工验收清单草案到 `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/quickstart.md`（覆盖 US1~US3）
- [ ] T002 记录基线问题截图与复现条件（模拟器 + 真机）到 `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/quickstart.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: 完成所有用户故事共享的基础改造

**⚠️ CRITICAL**: 本阶段完成前不进入故事级交付

- [ ] T003 统一在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 中向子视图传递 `safeTopInset/safeBottomInset`
- [ ] T004 [P] 规范抽屉高度模型（内容高度 vs 容器高度）于 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift`
- [ ] T005 [P] 规范抽屉层级与命中策略（抽屉、图片、关闭按钮）于 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift`

**Checkpoint**: 安全区与层级模型稳定，可进入 US1/US2/US3

---

## Phase 3: User Story 1 - 抽屉贴底与安全区一致 (Priority: P1) 🎯 MVP

**Goal**: 抽屉三态都与屏幕底边连续贴合，无白边/缝隙  
**Independent Test**: 打开详情页并拖拽抽屉至折叠、中间、全开，底部连续无断层

### Tests for User Story 1

- [ ] T010 [US1] 在 `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/quickstart.md` 写入 US1 的 Given/When/Then 手工验收步骤

### Implementation for User Story 1

- [ ] T011 [US1] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 为 `MetadataDrawer` 增加底部 inset 补偿并贴底渲染
- [ ] T012 [US1] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 使用顶部圆角、底部零圆角裁剪抽屉外观
- [ ] T013 [US1] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 校正三段锚点计算，避免因 inset 叠加产生视觉错位
- [ ] T014 [US1] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 覆盖 `bottomInset == 0` 设备的兜底行为

**Checkpoint**: US1 可独立验收通过

---

## Phase 4: User Story 2 - 顶部关闭按钮可见且不遮挡 (Priority: P2)

**Goal**: 关闭按钮在不同安全区机型都完整可见、可点击、不卡层  
**Independent Test**: 在有/无灵动岛设备验证按钮位置、层级与点击

### Tests for User Story 2

- [ ] T020 [US2] 在 `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/quickstart.md` 写入 US2 的机型与场景验收步骤

### Implementation for User Story 2

- [ ] T021 [US2] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 将关闭按钮位置改为父级安全区驱动并下移
- [ ] T022 [US2] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 提升关闭按钮层级，确保动画过程中不被遮挡
- [ ] T023 [US2] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 复核拖拽期间 `allowsHitTesting` 对关闭按钮的影响

**Checkpoint**: US2 可独立验收通过

---

## Phase 5: User Story 3 - 点赞操作有反馈且可诊断 (Priority: P3)

**Goal**: 点赞成功/失败都有明确反馈，切图后状态不串  
**Independent Test**: 成功与失败网络场景下连续点击心形，验证状态变化与错误提示

### Tests for User Story 3

- [ ] T030 [P] [US3] 在 `/Users/rich/Projects/Jupiter/JupiterTests/MediaLikeViewModelTests.swift` 覆盖 toggle 成功、失败与 load 失败场景
- [ ] T031 [P] [US3] 在 `/Users/rich/Projects/Jupiter/JupiterTests/APIClientTests.swift` 保持点赞请求 body/header 断言稳定

### Implementation for User Story 3

- [ ] T032 [US3] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaLikeViewModel.swift` 维护 `errorMessage` 与 `latestRequestID` 回写保护
- [ ] T033 [US3] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 为点赞按钮增加 loading、disable 与错误文案展示
- [ ] T034 [US3] 在 `/Users/rich/Projects/Jupiter/Jupiter/Views/MediaZoomPagerView.swift` 在 `item.id` 切换时重置点赞错误态并重新加载
- [ ] T035 [US3] 在 `/Users/rich/Projects/Jupiter/Jupiter/Services/MediaService.swift` 保持可注入 `APIClient` 以支持测试替身

**Checkpoint**: US3 可独立验收通过

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: 统一回归验证并收敛交付风险

- [ ] T040 执行 `xcodebuild -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj -scheme Jupiter -destination 'id=B3B28A6B-B593-419C-A688-921A025A7BF8' build`
- [ ] T041 执行 `xcodebuild -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj -scheme Jupiter -destination 'id=B3B28A6B-B593-419C-A688-921A025A7BF8' test`
- [ ] T042 按 `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/quickstart.md` 完成 US1~US3 手工回归
- [ ] T043 更新 `/Users/rich/Projects/Jupiter/CHANGELOG.md` 记录本特性交付条目

---

## Dependencies & Execution Order

### Phase Dependencies

- Setup (Phase 1) 无依赖，可立即开始
- Foundational (Phase 2) 依赖 Setup，且阻塞所有用户故事
- User Stories (Phase 3~5) 依赖 Foundational 完成
- Polish (Phase 6) 依赖目标用户故事完成

### User Story Dependencies

- US1 (P1): 可在 Phase 2 后立即开始
- US2 (P2): 依赖 Phase 2，可与 US1 并行，但建议在 US1 稳定后落地
- US3 (P3): 依赖 Phase 2，可与 US1/US2 并行

### Within Each User Story

- 测试任务优先于实现任务
- 布局/状态结构调整优先于样式微调
- 故事级验收通过后再进入下一故事收尾

### Parallel Opportunities

- T004 与 T005 可并行（同文件不同关注点，合并前统一回归）
- T030 与 T031 可并行（不同测试文件）
- T033 与 T035 可并行（视图层与服务层）

---

## Parallel Example: User Story 3

```bash
# 并行执行测试任务
Task: "T030 在 JupiterTests/MediaLikeViewModelTests.swift 扩展点赞场景测试"
Task: "T031 在 JupiterTests/APIClientTests.swift 维持请求断言回归"

# 并行执行实现任务
Task: "T033 在 Jupiter/Views/MediaZoomPagerView.swift 增加点赞反馈 UI"
Task: "T035 在 Jupiter/Services/MediaService.swift 维持可注入 client"
```

---

## Implementation Strategy

### MVP First (US1)

1. 完成 Phase 1 与 Phase 2  
2. 完成 US1 并验收“贴底无白边”  
3. 先交付可视化主问题修复

### Incremental Delivery

1. US1 解决视觉一致性  
2. US2 解决关闭路径可用性  
3. US3 解决点赞交互可靠性与可诊断性  
4. 最后统一回归与测试

### Rollback Strategy

- 每个故事保持单独提交与可回退点
- 发生回归时优先回退对应故事提交，不影响其他故事验证

