# About Sheet Redesign Design

**Date:** 2026-04-11
**Project:** Jupiter / Tinyglim
**Status:** Approved for implementation

---

## Goal

把当前功能型 `List` 风格的 about 页，重做为更现代、更安静的产品信息页，同时保留现有入口能力：

- 查看版本号
- 联系作者
- 查看下载权益 / 进入付费页
- 查看隐私政策和服务条款

## Direction

采用轻量的 `light cinematic` 语言，而不是继续堆默认表单样式：

- 暖白背景和柔和渐变
- 顶部产品信息 hero 区
- 分组信息卡片替代 `List`
- 下载权益作为单独强调卡片
- 法务和联系信息保持轻、清晰、可点

## Structure

### Hero

- 显示产品名 `Tinyglim`
- 一句简短中文描述
- 一个版本徽标

### Access Card

- 显示下载权益当前状态
- 已解锁和未解锁有不同文案
- 点击后仍进入既有 `DownloadPaywallView`

### Info Cards

- 联系作者
- 隐私政策
- 服务条款

### Interaction

- 仍使用 sheet 内 `NavigationStack`
- 保留右上角关闭按钮
- 链接依旧通过 `SFSafariViewController`

## Constraints

- 不改业务逻辑
- 不引入新的支付或设置能力
- 不依赖新的资源文件
- 优先复用现有 `CinematicSurfaceStyle` / `CinematicPalette`

## Testing

- 为 about 页增加纯展示规则测试
- 验证权益状态文案与卡片顺序
- 最后跑定向测试和项目 build
