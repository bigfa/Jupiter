# 媒体详情交互收尾优化 - 手工验收清单

## 0. 通用前置条件

- 分支：`001-media-detail-interaction-polish`
- 设备矩阵：
  - iPhone 16 模拟器（iOS 18.6）
  - 1 台真机（建议灵动岛机型）
- 构建命令：
  - `xcodebuild -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' build`
- 测试命令：
  - `xcodebuild -project Jupiter.xcodeproj -scheme Jupiter -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' test`
- 后端连通：确保 `AppConfig.baseURL` 可访问并有媒体数据。

## 1. 基线问题记录（T002，manual）

在修复前记录以下截图（模拟器 + 真机各 1 组）：

1. 抽屉底部白边/缝隙。
2. 关闭按钮与状态栏重叠或被遮挡。
3. 点赞点击无反馈（成功与失败场景）。

建议截图命名：

- `baseline-us1-simulator.png`
- `baseline-us1-device.png`
- `baseline-us2-simulator.png`
- `baseline-us2-device.png`
- `baseline-us3-like-no-feedback.png`

## 2. US1 验收：抽屉贴底与安全区一致（T010）

### Given

- 已进入任意图片详情页，底部 Metadata 抽屉可拖拽。

### When

1. 抽屉处于折叠态。
2. 上拉到中间态。
3. 上拉到全开态。
4. 在三态之间反复拖拽切换。

### Then

1. 抽屉始终紧贴屏幕底边，无白边或断层。
2. 圆角只出现在抽屉顶部，底部保持连续贴边。
3. 在安全区为 0 的设备（或场景）下，视觉连续性仍成立。

## 3. US2 验收：关闭按钮可见且不遮挡（T020）

### Given

- 已进入任意图片详情页。

### When

1. 静止观察关闭按钮位置。
2. 执行图片下拉手势。
3. 展开/收起 Metadata 抽屉。
4. 左右滑动切换上一张/下一张。

### Then

1. 关闭按钮位于状态栏下方，不与时间/灵动岛重叠。
2. 关闭按钮全程可见、可点击，不被抽屉或图片遮挡。
3. 拖拽过程不存在按钮层级闪烁或命中异常。

## 4. US3 验收：点赞反馈清晰且可诊断（T025）

### Given

- 已进入任意图片详情页并展开 Metadata 抽屉。

### When

1. 正常网络下点击点赞按钮。
2. 连续快速点击点赞按钮。
3. 模拟后端失败（401/500）后点击点赞按钮。
4. 左右切图后再次点击点赞按钮。

### Then

1. 请求中显示 loading（按钮内 `ProgressView`）并禁用重复点击。
2. 成功后点赞状态与数量立即更新。
3. 失败后显示错误文案，且可再次重试。
4. 切图后点赞状态与当前图片匹配，不串状态。

## 5. 全量回归清单（T042，manual）

- [ ] US1 全部通过（抽屉贴底连续）
- [ ] US2 全部通过（关闭按钮位置/层级正确）
- [ ] US3 全部通过（点赞反馈与错误可见）
- [ ] 图片左右切换仍可用
- [ ] 图片下拉关闭与抽屉收起逻辑符合预期
- [ ] 模拟器与真机结论一致
