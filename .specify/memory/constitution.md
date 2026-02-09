# Jupiter Constitution

## Core Principles

### I. User Experience Consistency First
所有视觉与交互改动必须优先保证一致性和稳定性，尤其是安全区、手势冲突、转场与抽屉行为。  
任何新交互若影响现有核心路径（首页滚动、图片详情、相册详情），必须提供回归验证步骤。

### II. API Contract Driven Development
客户端开发必须以后端契约为准，所有请求路径、字段映射、分页与错误处理需在实现前明确。  
若 API 行为不稳定，必须在客户端提供可见降级（错误提示、重试、占位状态），禁止静默失败。

### III. Testable by Default
涉及 `Networking`、`Services`、`ViewModel` 的变更必须可测试，并优先补充单元测试。  
关键交互路径修复后，必须至少保留一个可复现问题场景和一个通过场景作为回归基线。

### IV. Incremental and Reversible Delivery
复杂 UI/交互改造采用小步提交，单次改动聚焦一个问题域，保证可快速定位回归。  
每次迭代都应保留可逆策略（开关、降级路径或明确回退点），避免一次性大改导致不可控风险。

### V. Simplicity and Observability
优先选择可解释、可维护的方案，避免过度抽象和隐式状态耦合。  
遇到线上/真机难复现问题时，先补充结构化日志与最小复现路径，再扩展实现。

## Technical Constraints

- 技术栈固定为 `SwiftUI + async/await + MVVM`，服务层通过 `APIClient` 统一发起网络请求。
- 图片加载统一使用 `Kingfisher`，禁止并行引入同类图片库。
- 项目最低目标平台与构建工具以 `Jupiter.xcodeproj` 当前配置为准，文档必须同步更新。
- 公开仓库不提交本地构建产物、用户态配置和敏感信息。

## Development Workflow and Quality Gates

- 功能开发顺序：`spec` -> `plan` -> `tasks` -> `implementation`。
- 变更说明必须包含：目标问题、修改文件、风险点、验证结果。
- 合并前最低门槛：
- `xcodebuild` 可通过。
- 相关单元测试通过；若无法覆盖，必须写明原因与手工验证步骤。
- 对用户可见行为改动必须附带验收清单（至少 3 条 Given/When/Then）。

## Governance

- 本 Constitution 优先级高于临时实现偏好；所有新特性和修复均需符合本文件。
- 修订 Constitution 必须：
- 明确变更条目与原因。
- 更新版本号与修订日期。
- 在对应 spec/plan 中注明受影响条款。
- Code Review 必须显式检查 Constitution 合规性，发现冲突需先修订 spec 再编码。

**Version**: 1.0.0 | **Ratified**: 2026-02-08 | **Last Amended**: 2026-02-08
