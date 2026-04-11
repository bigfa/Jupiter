# Paywall Style Alignment Design

**Date:** 2026-04-11
**Project:** Jupiter / Tinyglim
**Status:** Approved for implementation

---

## Goal

把下载权益 paywall 的视觉语言统一到刚刚重做的 about 页风格上，让它看起来像同一个产品里的页面，而不是一张独立的促销页。

## Direction

- 去掉蓝紫色 mesh 背景
- 改为暖白、奶油色、淡暖橙的 light cinematic 体系
- 保留现有购买、恢复、解锁逻辑
- 强调“下载权益”而不是单纯营销文案

## Layout

### Hero

- 暖色圆形图标
- 简洁标题与副标题
- 显示当前权益状态

### Feature Card

- 一张主卡片承载 4 个权益点
- 图标统一为暖底小方块
- 字级和行距与 about 页卡片接近

### Note Card

- 用独立浅色卡片承载 App Store / 恢复 / 隐私类说明

### Sticky Action Area

- 底部固定 CTA 区继续保留
- CTA 改成暖色主按钮
- 恢复购买保留为轻次级按钮

## Constraints

- 不修改 `DownloadAccessViewModel` 的购买流程
- 不改变 paywall 入口
- 不引入新的图片资源
- 尽量复用 `CinematicPalette`

## Testing

- 给 paywall 新增一个展示层测试
- 校验 feature 顺序和 note 顺序
- 最后跑定向测试与 build
