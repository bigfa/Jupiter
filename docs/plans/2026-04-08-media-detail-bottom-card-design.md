# Media Detail Bottom Card Refinement Design

## Goal
在保持当前稳定图片预览链路不回退的前提下，把照片详情页的 metadata 展示从系统 sheet 收成高端摄影 App 风格的底部白色说明卡：照片仍为主角，白卡贴底但不压图，版式更从容。

## Constraints
- 保留当前 `MediaZoomPagerView` 的稳定预览与左右切图逻辑。
- 不再使用 full-screen sheet 展示 metadata。
- 底部卡片风格：纯白实体、左右窄边距、底部贴屏、顶部轻 handle。
- 照片与白卡之间保留明确呼吸区，优先视觉构图，不追求数学居中。
- metadata 继续通过 `/api/media/{id}` 补齐完整 EXIF。

## Layout
- 顶部：保留关闭按钮和 info 按钮。
- 中部：照片按 `aspect fit` 展示，但展示画布需为底部白卡预留空间。
- 底部：点击 info 后显示底部白卡。
  - 左右边距约 `12pt`
  - 与照片底边距离约 `18pt`
  - 默认视觉高度约 `28%` 屏高
  - 卡片顶部仅保留 handle 和轻量操作区
  - 信息区使用两列等高参数卡

## Data Flow
- 详情页维持列表 `MediaItem` 作为初始数据。
- 打开 metadata 后异步加载 `/api/media/{id}` 详情。
- 卡片先展示预览里已有字段；若字段不足且请求中，则显示 skeleton；详情回包后补齐。

## Interaction
- 点击右上角 info：底部白卡淡入并从底部轻推上来。
- 卡片显示时，照片仅做轻微上移，不做大幅缩放。
- 下拉照片时：若白卡显示，优先收起白卡；白卡收起后才允许关闭详情。
- 左右滑动切图继续使用当前稳定逻辑。

## Testing
- `MediaViewerPresentationTests`
  - 验证为 metadata 卡片预留的照片画布与间距规则
- `MediaMetadataPresentationTests`
  - 验证 viewer 底部卡默认高度策略
- 构建验证
  - `xcodebuild -project Jupiter.xcodeproj -scheme Jupiter -destination 'generic/platform=iOS Simulator' build`
