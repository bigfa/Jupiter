# Feature Specification: 媒体详情交互收尾优化

**Feature Branch**: `[001-media-detail-interaction-polish]`  
**Created**: 2026-02-08  
**Status**: Draft  
**Input**: User description: "统一修复图片详情页中抽屉贴边、按钮避让、拖拽与点赞反馈问题，达到可稳定交付状态"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 抽屉贴底与安全区一致 (Priority: P1)

作为用户，我希望详情页底部 Metadata 抽屉始终紧贴屏幕底边，没有白缝或不连续材质，保证视觉完整。

**Why this priority**: 这是最明显的视觉缺陷，直接影响主路径体验和发布质量。  
**Independent Test**: 打开任意媒体详情页，观察抽屉折叠/中间/全开三态，底部应始终贴边无白边。

**Acceptance Scenarios**:

1. **Given** 详情页打开且抽屉折叠，**When** 用户不操作，**Then** 抽屉底部与屏幕底边连续贴合。
2. **Given** 抽屉被拖动到中间或全开，**When** 抽屉停住，**Then** 底部材质连续且无白缝。

---

### User Story 2 - 顶部关闭按钮可见且不遮挡 (Priority: P2)

作为用户，我希望关闭按钮始终在状态栏下方可点击位置，不与灵动岛/状态栏重叠，不被内容遮挡。

**Why this priority**: 关闭是主退出路径，误触或遮挡会导致严重可用性问题。  
**Independent Test**: 在不同机型安全区（刘海/灵动岛）打开详情页，确认按钮始终可见可点。

**Acceptance Scenarios**:

1. **Given** iPhone 16 模拟器打开详情页，**When** 页面加载完成，**Then** 关闭按钮位于安全区下方且完整可见。
2. **Given** 用户拖动图片或展开抽屉，**When** 动画过程中，**Then** 关闭按钮不会被抽屉或图片层级遮挡。

---

### User Story 3 - 点赞操作有反馈且可诊断 (Priority: P3)

作为用户，我希望点击点赞后立即看到状态反馈；失败时看到可读错误，而不是“点了没反应”。

**Why this priority**: 属于高频交互，反馈缺失会让用户误判系统失效。  
**Independent Test**: 在正常与失败网络场景分别点击点赞，验证 loading、状态变化、错误提示。

**Acceptance Scenarios**:

1. **Given** 点赞请求成功，**When** 点击心形按钮，**Then** 出现请求中反馈且最终状态更新为已赞/未赞。
2. **Given** 点赞请求失败，**When** 点击心形按钮，**Then** 显示错误提示并允许再次重试。

---

### Edge Cases

- 当媒体尺寸字段缺失或为 0 时，详情页仍应正常展示且抽屉贴边逻辑不失效。
- 当用户快速切换上一张/下一张时，旧请求返回不得覆盖新图片的点赞状态。
- 当抽屉拖拽与点赞点击接近同时发生时，按钮点击应优先命中，避免被父手势吞掉。

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: 系统 MUST 在媒体详情页中保证 Metadata 抽屉底边与屏幕底边连续贴合，不出现白边。
- **FR-002**: 系统 MUST 根据安全区动态计算关闭按钮位置，避免与状态栏/灵动岛重叠。
- **FR-003**: 用户 MUST 能在详情页稳定点击点赞按钮，不受抽屉点击手势误拦截。
- **FR-004**: 系统 MUST 在点赞请求期间展示明确 loading 状态并防止重复提交。
- **FR-005**: 系统 MUST 在点赞请求失败时显示可读错误信息并允许重试。
- **FR-006**: 系统 MUST 在切换图片时确保点赞状态与当前媒体 ID 一致，避免旧请求回写。

### Key Entities *(include if feature involves data)*

- **MediaLikeState**: 当前媒体的点赞状态，包含 `mediaId`、`liked`、`likes`、`isLoading`、`errorMessage`。
- **MetadataDrawerState**: 抽屉状态，包含 `collapsed/medium/expanded` 高度锚点与当前高度。
- **MediaZoomLayoutState**: 详情页布局状态，包含安全区、按钮位置与图片偏移/缩放参数。

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 在目标机型（iPhone 16 模拟器 + 一台真机）下，详情页抽屉三态均无可见底部白边。
- **SC-002**: 关闭按钮在上述机型 100% 可见且可点击，不与状态栏元素重叠。
- **SC-003**: 点赞交互在成功和失败场景均有可见反馈，失败场景不再出现“无反馈”问题。
- **SC-004**: 对应单元测试通过（点赞成功/失败/加载场景），且 `xcodebuild test` 全量通过。
