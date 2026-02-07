# Changelog

本项目的变更记录维护在此文件中。
格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本遵循语义化版本。

## [Unreleased]

### Added
- 新增 `JupiterTests` 单元测试 target。
- 新增 `APIClientTests`，覆盖：
  - `GET` 请求 query/header 组装与解码。
  - `POST` 请求 JSON body 与 `Content-Type`。
  - 非 2xx 响应的 `APIError` 解析。

## [0.0.1] - 2026-02-07

### Added
- 首个开源版本发布。
- SwiftUI 客户端基础架构：照片流与相册流双入口。
- 首页能力：分类筛选、排序、日期分组、瀑布流排版、下拉刷新与分页加载。
- 相册能力：列表分类、详情瀑布流、点赞、评论、受保护相册解锁。
- 媒体详情能力：全屏查看、缩放、抽屉元数据、下载与分享。
- 远程图片加载使用 `Kingfisher`（SPM）。
- 开源仓库基础文件：`README.md`、`LICENSE`、`.gitignore`。

### Changed
- 照片/相册切换交互升级为轻量转场（淡入淡出 + 小幅水平位移）。
- 底部入口切换改为显式动画触发，非选中页面禁止命中，避免误触。

### Removed
- 移除历史误提交的构建产物与本地用户态文件（如 `.derivedData`、`xcuserdata`）。
