# Album List Cinematic Refresh Design

## Goal

让相册列表和新的 about / paywall 保持同一套暖白、奶油卡片、暖橙红点缀的视觉语言，同时保留当前单列大封面的作品感和既有导航行为。

## Approved Direction

- 结构保持为单列大图卡片，不改成密集列表或多列。
- 相册标题信息不再直接压在封面图上，改成贴底的一条奶油色信息条。
- 页面背景、分类栏、骨架屏、空状态统一到 cinematic palette。

## UX Decisions

### Card Structure

每张相册卡片拆成两层：

- 上半部分仍然是大图封面，承担作品感和浏览吸引力。
- 下半部分是固定贴底的信息条，使用暖白表面、轻描边和柔和阴影。

信息条中展示：

- 相册标题
- 描述文案，若为空则回退到分类名称，再回退到通用文案
- 关键元信息胶囊，例如照片数量、喜欢数量、受保护状态

### Page Shell

列表页本身换成暖白渐变背景，并保持现有顶部分类栏与底部浮动切换器。分类栏改成更明显的暖白胶囊选中态，加载骨架与错误/空状态也改成奶油卡片风格。

## Implementation Notes

- 使用 presentation helper 生成卡片副标题和元信息，避免把格式化逻辑散落在 SwiftUI 视图里。
- 仅调整视觉层，不修改 `AlbumListViewModel` 的分页与筛选逻辑。
- 继续复用 `RemoteImage`，不引入新的图片加载路径。

## Testing Strategy

- 先为 presentation helper 写失败测试，锁定副标题回退和元信息顺序。
- 完成后跑定向测试和整包 build，确认视觉重构未破坏编译链路。
