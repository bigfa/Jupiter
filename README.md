# Jupiter

## 中文

### 项目简介
Jupiter 是一个基于 SwiftUI 的 iOS 照片与相册客户端，支持照片流、相册浏览、筛选排序、详情查看、点赞与评论等能力。

### 功能概览
- 照片首页：分类筛选、排序、瀑布流布局、下拉刷新、分页加载
- 相册列表：分类筛选、封面卡片、下拉刷新、分页加载
- 相册详情：媒体瀑布流、点赞、评论、受保护相册解锁
- 媒体详情：全屏查看、缩放、EXIF/地理信息展示、分享/下载

### 技术栈与环境要求
- Xcode 17+
- iOS Deployment Target: 18.6
- Swift 5
- 依赖管理：Swift Package Manager
- 三方依赖：`Kingfisher` (`7.12.0`)

### 项目结构
- `Jupiter/Views`：页面与交互逻辑
- `Jupiter/Components`：可复用 UI 组件
- `Jupiter/Services`：业务服务层（媒体、相册、评论、点赞）
- `Jupiter/Networking`：网络请求与错误处理
- `Jupiter/Models`：数据模型
- `Jupiter/Resources`：运行时配置等资源

### 配置参数
配置文件：`Jupiter/Resources/AppConfig.swift`

| 参数 | 说明 | 必填 | 默认值 |
| --- | --- | --- | --- |
| `baseURL` | 后端 API 根地址 | 是 | `https://w.wpista.com` |
| `defaultLocale` | 默认语言标识 | 否 | `zh` |

示例：

```swift
enum AppConfig {
    static let baseURL = URL(string: "https://your-api-domain.com")!
    static let defaultLocale = "zh"
}
```

### 后端 API 依赖
- `GET /api/media/list`
- `GET /api/media/categories`
- `GET /api/media/{id}`
- `GET /api/albums`
- `GET /api/albums/categories`
- `GET /api/albums/{id}`
- `GET /api/albums/{id}/media`
- `POST /api/albums/{id}/unlock`
- `GET /api/albums/{id}/like`
- `POST /api/albums/{id}/like`
- `DELETE /api/albums/{id}/like`
- `GET /api/albums/{id}/comments`
- `POST /api/albums/{id}/comments`

### 开发步骤
```bash
git clone git@github.com:bigfa/Jupiter.git
cd Jupiter
open /Users/rich/Projects/Jupiter/Jupiter.xcodeproj
```

1. 修改 `Jupiter/Resources/AppConfig.swift` 中的 `baseURL`。
2. 在 Xcode 中选择 `Jupiter` scheme 与模拟器后运行。
3. 命令行构建验证：

```bash
xcodebuild -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj \
  -scheme Jupiter \
  -destination 'generic/platform=iOS Simulator' \
  build
```

### 发布与推送
```bash
# 如果未配置 origin
git remote add origin git@github.com:bigfa/Jupiter.git

# 如果已配置 origin
git remote set-url origin git@github.com:bigfa/Jupiter.git

git push -u origin main
```

### 常见问题
- 构建失败：确认 Xcode 版本与 iOS SDK 是否满足要求，并执行 `Product -> Clean Build Folder` 后重试。
- 请求失败：确认 `baseURL` 可访问，且后端 API 路径与返回结构匹配。
- 相册受保护：需要先调用解锁接口获取 token，客户端会自动缓存到本地。
- 无法下载到相册：确认系统照片权限已授予应用。

---

## English

### Overview
Jupiter is a SwiftUI-based iOS photo and album client. It provides media feed browsing, album browsing, filtering/sorting, media detail viewing, likes, and comments.

### Features
- Media feed: category filters, sorting, masonry layout, pull-to-refresh, pagination
- Album list: category filters, cover cards, pull-to-refresh, pagination
- Album detail: masonry media list, likes, comments, protected album unlock
- Media detail: full-screen preview, zoom, EXIF/location info, share/download

### Tech Stack & Requirements
- Xcode 17+
- iOS Deployment Target: 18.6
- Swift 5
- Dependency manager: Swift Package Manager
- Third-party dependency: `Kingfisher` (`7.12.0`)

### Project Structure
- `Jupiter/Views`: screens and interaction logic
- `Jupiter/Components`: reusable UI components
- `Jupiter/Services`: business services (media, albums, comments, likes)
- `Jupiter/Networking`: API client and error handling
- `Jupiter/Models`: data models
- `Jupiter/Resources`: runtime configuration

### Configuration
File: `Jupiter/Resources/AppConfig.swift`

| Key | Description | Required | Default |
| --- | --- | --- | --- |
| `baseURL` | API server base URL | Yes | `https://w.wpista.com` |
| `defaultLocale` | Default locale | No | `zh` |

```swift
enum AppConfig {
    static let baseURL = URL(string: "https://your-api-domain.com")!
    static let defaultLocale = "zh"
}
```

### Backend API Dependencies
- `GET /api/media/list`
- `GET /api/media/categories`
- `GET /api/media/{id}`
- `GET /api/albums`
- `GET /api/albums/categories`
- `GET /api/albums/{id}`
- `GET /api/albums/{id}/media`
- `POST /api/albums/{id}/unlock`
- `GET /api/albums/{id}/like`
- `POST /api/albums/{id}/like`
- `DELETE /api/albums/{id}/like`
- `GET /api/albums/{id}/comments`
- `POST /api/albums/{id}/comments`

### Development Setup
```bash
git clone git@github.com:bigfa/Jupiter.git
cd Jupiter
open /Users/rich/Projects/Jupiter/Jupiter.xcodeproj
```

1. Update `baseURL` in `Jupiter/Resources/AppConfig.swift`.
2. Run with the `Jupiter` scheme in Xcode.
3. Validate build from CLI:

```bash
xcodebuild -project /Users/rich/Projects/Jupiter/Jupiter.xcodeproj \
  -scheme Jupiter \
  -destination 'generic/platform=iOS Simulator' \
  build
```

### Publish to Remote
```bash
# If origin does not exist
git remote add origin git@github.com:bigfa/Jupiter.git

# If origin already exists
git remote set-url origin git@github.com:bigfa/Jupiter.git

git push -u origin main
```

### Troubleshooting
- Build errors: verify Xcode/SDK version, then clean build folder and retry.
- Request failures: verify `baseURL` reachability and backend response schema.
- Protected albums: unlock endpoint must return a valid token for detail/media APIs.
- Download to Photos failed: ensure Photo Library permission is granted.
