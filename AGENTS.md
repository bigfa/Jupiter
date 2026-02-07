# AGENTS.md

本文件为 AI 编码助手提供项目上下文与开发规范，确保生成的代码与现有代码库保持一致。

## 项目概述

Jupiter 是一个基于 SwiftUI 的 iOS 照片与相册客户端，采用 MVVM 架构，通过 async/await 与后端 REST API 交互。主要功能包括照片瀑布流浏览、相册管理、点赞、评论及受保护相册解锁。

## 技术栈

- **语言**: Swift 5
- **UI 框架**: SwiftUI
- **最低部署版本**: iOS 18.6
- **IDE**: Xcode 17+
- **包管理**: Swift Package Manager
- **三方依赖**: Kingfisher 7.12.0（远程图片加载与缓存）
- **测试框架**: XCTest

## 项目结构

```
Jupiter/
├── Views/          # 页面视图 + 对应 ViewModel
├── Components/     # 可复用 UI 组件
├── Models/         # Codable 数据模型
├── Services/       # 业务服务层（API 调用封装）
├── Networking/     # 通用网络客户端与错误定义
├── Resources/      # 运行时配置（AppConfig）
└── JupiterApp.swift  # App 入口
JupiterTests/
└── APIClientTests.swift  # 网络层单元测试
```

## 架构规范

### MVVM 分层

- **Model**: 纯数据结构，遵循 `Codable`、`Identifiable`、`Hashable`。使用 `CodingKeys` 映射 snake_case API 字段到 camelCase 属性。
- **ViewModel**: 标注 `@MainActor final class`，使用 `@Published` 暴露状态。所有异步方法使用 `async/await`。
- **View**: SwiftUI `struct`，通过 `@StateObject` 持有 ViewModel，通过 `@Binding` / `@State` 管理局部状态。
- **Service**: 无状态 `struct`，封装具体 API 端点调用，返回类型化结果。
- **Networking**: `APIClient.shared` 单例，提供泛型 `get`/`post`/`delete` 方法。

### 文件命名约定

| 类型 | 命名规则 | 示例 |
| --- | --- | --- |
| 页面视图 | `{Feature}View.swift` | `MediaFeedView.swift` |
| ViewModel | `{Feature}ViewModel.swift` | `MediaFeedViewModel.swift` |
| 组件 | 描述性名称 | `MasonryGrid.swift`, `ZoomableImageView.swift` |
| 数据模型 | 实体名称 | `Media.swift`, `Album.swift` |
| 服务 | `{Domain}Service.swift` | `MediaService.swift`, `AlbumService.swift` |

## 编码规范

### Swift 风格

- 4 空格缩进
- 类型名 PascalCase，属性/方法名 camelCase
- 每个文件一个主要类型，文件名与类型名一致
- ViewModel 属性使用 `@Published private(set)` 限制外部写入
- 优先使用 `struct` 而非 `class`（ViewModel 除外）
- 使用 `enum` 作为命名空间（如 `AppConfig`）

### ViewModel 模板

```swift
@MainActor
final class FeatureViewModel: ObservableObject {
    @Published private(set) var items: [Item] = []
    @Published private(set) var isLoading = false

    private let service = SomeService()
    private var page = 1

    func loadInitial() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await service.fetchItems(page: page)
            items = response.results
        } catch {
            // 静默处理或设置 error 状态
        }
    }
}
```

### Model 模板

```swift
struct SomeItem: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title
        case createdAt = "created_at"
    }
}
```

### Service 模板

```swift
struct SomeService {
    func fetchItems(page: Int) async throws -> SomeListResponse {
        try await APIClient.shared.get(
            path: "/api/some/list",
            queryItems: [URLQueryItem(name: "page", value: "\(page)")]
        )
    }
}
```

### API 响应结构

后端 API 遵循统一格式：

- 单对象: `{ "ok": true, "data": { ... } }`
- 列表: `{ "ok": true, "results": [...], "total": N, "page": N, "pageSize": N, "totalPages": N }`
- 错误: `{ "ok": false, "error": "...", "code": "..." }`

新增 Model 时应匹配这些响应结构。

## 构建与测试

### 构建

```bash
xcodebuild -project Jupiter.xcodeproj \
  -scheme Jupiter \
  -destination 'generic/platform=iOS Simulator' \
  build
```

### 运行测试

```bash
xcodebuild test -project Jupiter.xcodeproj \
  -scheme Jupiter \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### 测试规范

- 测试文件放在 `JupiterTests/` 目录下
- 网络层测试使用 `URLProtocolStub` 模拟 HTTP 响应
- 测试方法名遵循 `test_功能_场景` 格式
- 在 `setUp` / `tearDown` 中重置共享状态

## 关键配置

运行时配置位于 `Jupiter/Resources/AppConfig.swift`：

```swift
enum AppConfig {
    static let baseURL = URL(string: "https://w.wpista.com")!
    static let defaultLocale = "zh"
}
```

修改 API 地址只需更改 `baseURL`，无需改动其他代码。

## 注意事项

- **UI 字符串**: 当前为中文硬编码，未使用本地化框架。新增 UI 文本保持中文。
- **图片加载**: 统一使用 Kingfisher（通过 `RemoteImage` / `LazyRemoteImage` 组件），不要直接使用 `AsyncImage`。
- **分页**: 页面大小默认 20（MediaFeed）或 50（AlbumDetail），分页逻辑在 ViewModel 中实现。
- **Token 缓存**: 受保护相册的 token 通过 `AlbumTokenStore`（UserDefaults）持久化，不要引入额外存储方案。
- **CoreData**: 项目中存在 CoreData 配置但未实际使用，不要在其上构建新功能。
- **单例模式**: `APIClient.shared`、`AlbumTokenStore.shared`、`PersistenceController.shared` 为既有单例，新增服务优先使用 struct 实例而非单例。
- **错误处理**: ViewModel 中 `do/catch` 捕获错误后设置状态或静默处理，不要使用 `try!` 或 `fatalError`。
- **并发安全**: ViewModel 必须标注 `@MainActor`，确保 UI 更新在主线程。
