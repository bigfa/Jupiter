# Home Feed Editorial Refresh Design

## Goal

让首页瀑布流与 about、paywall、相册列表进入同一套暖白 cinematic 设计系统，同时保持首页“以照片为主、快速浏览”的核心节奏。

## Approved Direction

- 选择 `杂志编排版`
- 不改变首页的瀑布流结构和点击进入详情的路径
- 通过更安静的 editorial section header、统一的卡片边缘语言，以及更一致的空状态和骨架屏来完成风格对齐

## Product Intent

首页不是相册页的复制品。它仍然是发现墙，第一优先级是让照片本身足够有吸引力。新的风格不应该给每张图片都加沉重信息层，而应该像一本摄影期刊：

- 图片仍然是主角
- 分组像章节而不是列表标题
- 控件和状态统一，但不喧宾夺主

## Visual Decisions

### Section Headers

日期分组标题升级为 editorial header：

- 小号 eyebrow 文案，提示“档案”或排序状态
- 大号 serif 日期标题
- 一条更轻的 caption，显示当组图片数量
- 标题和内容之间加入更克制的留白与细分隔线

热度排序模式不再直接从顶部进入裸瀑布流，而是在列表开始位置给一个轻量 header，提示用户当前看到的是热门作品视图。

### Photo Cards

照片卡片只做轻量包装：

- 更统一的圆角
- 很薄的奶油描边
- 低而软的阴影
- 暖白 likes 胶囊

不引入底部信息条，避免削弱照片的主视觉地位。

### Surrounding Surfaces

首页背景、分类栏、空状态、错误态、骨架屏一起统一到暖白 palette。目标不是做更多装饰，而是把“旧系统灰”和“新 cinematic 暖白”之间的割裂感消掉。

## Testing Strategy

- 抽出 feed presentation helper，先用测试锁定 header 和空状态 copy
- 然后再修改 `MediaFeedView` 和 `MediaMasonryCard`
- 最后跑定向测试和整包 build
