# Implementation Plan: 媒体详情交互收尾优化

**Branch**: `[001-media-detail-interaction-polish]` | **Date**: 2026-02-08 | **Spec**: `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/spec.md`  
**Input**: Feature specification from `/Users/rich/Projects/Jupiter/specs/001-media-detail-interaction-polish/spec.md`

## Summary

本次实现目标是将媒体详情页交互收敛到可稳定交付状态，聚焦三个问题域：
1) Metadata 抽屉底部贴边与安全区一致；
2) 顶部关闭按钮避让状态栏且层级稳定；
3) 点赞交互具备明确 loading/error 反馈并支持可回归测试。

核心做法是在 `MediaZoomPagerView` 统一管理安全区和抽屉容器高度，在 `MediaLikeViewModel` 增加可观测错误状态与请求上下文保护，同时补齐单测与验收清单。

### Current Progress

基础实现（Phase 0~4）已完成，Code Review 发现一个 Bug 和若干改进项，已追加为 Phase 6。详见 `tasks.md` 的 Remaining Work Summary。

## Technical Context

**Language/Version**: Swift 5  
**Primary Dependencies**: SwiftUI, Kingfisher (`7.12.0`)  
**Storage**: N/A（客户端不新增本地持久化）  
**Testing**: XCTest + `xcodebuild test` + 手工交互验证  
**Target Platform**: iOS 18.6+（当前工程配置）  
**Project Type**: Mobile (single iOS app)  
**Performance Goals**: 详情页拖拽/抽屉动画保持流畅（目标接近 60fps，通过 Xcode Instruments Core Animation 工具测量），点赞点击反馈在 120ms 内出现（通过 `ProgressView` 即时展示 loading 态实现，无需额外度量）
**Constraints**: 不改后端 API；不破坏左右翻页和下拉关闭交互；不引入新图片库  
**Scale/Scope**: 1 个功能 spec，约 3~5 个源码文件 + 1~2 个测试文件

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*
*✅ Re-checked: Phase 1 已完成，所有原则仍通过。*

- **I. User Experience Consistency First**: 通过。实现以安全区、层级和手势冲突为主线，不做额外视觉重构。
- **II. API Contract Driven Development**: 通过。点赞接口沿用现有 `/api/media/{id}/like`，仅补客户端错误可见性。
- **III. Testable by Default**: 通过。新增/扩展 `MediaLikeViewModel` 相关单测覆盖成功、失败和请求竞态。
- **IV. Incremental and Reversible Delivery**: 通过。按 US1/US2/US3 分段实施，每段可单独验证。
- **V. Simplicity and Observability**: 通过。采用最小改动路径，异常通过 `errorMessage` 直达 UI。

## Project Structure

### Documentation (this feature)

```text
specs/001-media-detail-interaction-polish/
├── plan.md
├── spec.md
└── tasks.md
```

### Source Code (repository root)

```text
Jupiter/
├── Views/
│   ├── MediaZoomPagerView.swift
│   └── MediaLikeViewModel.swift
├── Services/
│   └── MediaService.swift
└── Networking/
    └── APIClient.swift

JupiterTests/
├── MediaLikeViewModelTests.swift
└── APIClientTests.swift
```

**Structure Decision**: 保持现有单 iOS 工程结构，仅在现有视图、ViewModel、服务层和测试目录增量修改。

## Implementation Phases

> Phase 编号与 `tasks.md` 对齐（Phase 0~5）。

### Phase 0 - Setup *(对应 tasks.md Phase 0)*

- 建立验收清单骨架（`quickstart.md`）。
- 固化当前问题基线（底部白边、关闭按钮遮挡、点赞无反馈）。
- 确认可复现设备矩阵：iPhone 16 模拟器 + 1 台真机。

### Phase 1 - Foundational *(对应 tasks.md Phase 1)* ✅ 已完成

- 在 `MediaZoomPagerView` 统一注入顶部/底部安全区。
- `MetadataDrawer` 改为"内容高度 + 底部 inset"容器，确保贴底。
- 规范抽屉、图片、关闭按钮的层级与命中策略。

### Phase 2 - US1: Drawer Layout *(对应 tasks.md Phase 2)* 🔶 大部分完成

- 抽屉外观使用顶部圆角，底部零圆角，消除底部缝隙。✅
- 三段锚点计算基于内容高度，`bottomInset` 在容器层独立叠加。✅
- **待办**: 覆盖 `bottomInset == 0` 设备的兜底行为（T014）。

### Phase 3 - US2: Close Button *(对应 tasks.md Phase 3)* ✅ 已完成

- 关闭按钮位置由父容器安全区驱动，不再依赖局部状态推断。
- 按钮提升层级（`.zIndex(10)`），确保不被抽屉或图片层遮挡。
- 拖拽中 `.allowsHitTesting(!isDragging)` 不误禁用关闭按钮。

### Phase 4 - US3: Like Feedback *(对应 tasks.md Phase 4)* ✅ 已完成

- `MediaLikeViewModel` 输出 `errorMessage`，并保留 `isLoading` 可观测状态。✅
- `latestRequestID` 请求上下文保护，避免旧请求回写新图片状态。✅
- 抽屉心形按钮展示 loading、失败文案并禁止重复点击。✅
- `MediaLikeViewModelTests` 单元测试 + API 请求断言。✅

### Phase 5 - Verification and Regression Gate *(对应 tasks.md Phase 5)*

- 运行 `xcodebuild build` 与 `xcodebuild test`。✅
- 按 US1~US3 场景进行手工验收。
- 回归检查：左右翻页、抽屉三段拖拽、下拉关闭。
- 更新 CHANGELOG.md。✅

### Phase 6 - Code Review Fixes *(对应 tasks.md Phase 6)*

Code Review 发现的 Bug 与改进项：

- **[Bug]** `MetadataDrawer` 使用 `@State` 持有 `MediaLikeViewModel`（ObservableObject），`@Published` 属性变化不会触发视图重绘。需迁移至 `@Observable` 宏。
- **[改进]** 提取 `URLProtocolStub` 为共享测试辅助，消除 `APIClientTests` 与 `MediaLikeViewModelTests` 之间的重复代码。
- **[改进]** 补充 `latestRequestID` 并发竞态的单元测试。
- **[改进]** 移除 `MetadataDrawer` 中 `.task(id:)` 内多余的 `vm.clearError()` 调用。

### Phase 7 - Drag Dismiss & Drawer Scaling Fix *(对应 tasks.md Phase 7)*

交互测试发现两个视觉问题，均在 `MediaZoomPagerView.swift` 中修复：

- **[Bug] 背景层随图片一起位移**：`.navigationTransition(.zoom(sourceID:in:))` 是 `NavigationStack` push 转场 API，当前页面已改用 `fullScreenCover` 呈现，但该修饰符仍残留。它在 fullScreenCover 上安装了系统级交互关闭手势，下拉时系统把整个视图（背景+图片+按钮+抽屉）一起拖动；同时自定义 `DragGesture` 给图片额外叠加 `dragOffset`，导致背景和图片以不同 offset 分离移动。修复：删除 `.navigationTransition(.zoom(...))`，由自定义手势调用 `dismiss()` 完成关闭。
- **[Bug] 抽屉展开时图片向右侧偏移缩放**：`sheetScale`（`1.0 - sheetProgress * 0.08`）通过 `.scaleEffect()` 缩放图片，但 `.position()` 后的视图中心与布局中心不一致，导致缩放后图片视觉右偏且两侧不再贴边。修复：删除 `sheetScale`，`imageScale` 仅保留拖拽关闭缩放（`1.0 - dragProgress * 0.08`）；抽屉展开时图片保持原始尺寸，通过 `imageOffsetY` 上移后用 `.clipped()` 裁切溢出部分实现视觉缩放效果。将 `imageOffsetY`（抽屉推动）和 `dragOffset`（下拉关闭）分层：前者在 `.clipped()` 之前应用，后者在之后应用。

## Risk and Mitigation

- **风险**: 抽屉高度与安全区叠加后导致拖拽锚点错位。
  **缓解**: 将锚点定义为"内容高度"，容器额外叠加 `bottomInset`。
- **风险**: 按钮层级上调后影响图片手势区域。
  **缓解**: 按钮区域最小化并只在顶部左侧生效。
- **风险**: 点赞请求并发造成 UI 状态闪回。
  **缓解**: 使用 `latestRequestID` 仅允许最新请求落状态。
- **风险**: `@State` 持有 ObservableObject 导致 `@Published` 变化不触发 UI 更新。
  **缓解**: 迁移 `MediaLikeViewModel` 至 `@Observable` 宏，SwiftUI 自动追踪属性访问（T050）。
- **风险**: 删除 `.navigationTransition(.zoom(...))` 后失去 zoom 入场动画。
  **缓解**: 当前已使用 `fullScreenCover` 呈现，`.navigationTransition` 本身不提供 fullScreenCover 的 zoom 入场效果，仅安装了不需要的交互关闭手势，删除无副作用。
- **风险**: 移除 `sheetScale` 后抽屉展开时图片无视觉退让。
  **缓解**: 图片通过 `imageOffsetY` 上移 + `.clipped()` 裁切实现等效退让效果，且保持两侧贴边。

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |

